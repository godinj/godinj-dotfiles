package session

import (
	"drem-sx/internal/config"
	"drem-sx/internal/gitstatus"
	"strings"
	"sync"
)

// Source identifies where a session entry came from.
type Source int

const (
	SourceConfig Source = iota
	SourceTmux
	SourceZoxide
	SourceFind
)

// Status indicates the visual state of a session entry.
type Status int

const (
	StatusNone     Status = iota
	StatusDirty           // worktree has uncommitted changes
	StatusInactive        // promoted config entry with no running tmux session
)

// TmuxChecker reports whether a tmux session exists.
type TmuxChecker interface {
	Exists(name string) bool
}

// Entry is a unified session entry from any source.
type Entry struct {
	// Original is the raw string from the source (e.g., tmux session name).
	Original string
	// DisplayName is the icon-prefixed name for display.
	DisplayName string
	// BareName is the name without any icon prefix.
	BareName string
	// Path is the session directory (may be empty for tmux-only sessions).
	Path string
	// StartupCommand is the command to run on session creation.
	StartupCommand string
	// PreviewCommand is the command for fzf preview.
	PreviewCommand string
	// Source identifies where this entry came from.
	Source Source
	// Status is the visual state (dirty, inactive, or none).
	Status Status
}

// Merge combines sessions from multiple sources.
// Config entries provide metadata; tmux entries indicate active sessions.
// Dedup: tmux sessions matching config DisplayNames get config metadata merged in.
// Order: tmux first, config second, zoxide last.
func Merge(configSessions []config.ResolvedSession, tmuxSessions, zoxideSessions, findSessions []Entry) []Entry {
	var result []Entry

	// Index config sessions by display name for quick lookup
	configByDisplay := make(map[string]*config.ResolvedSession)
	for i := range configSessions {
		configByDisplay[configSessions[i].DisplayName] = &configSessions[i]
	}

	// Track which config sessions have been seen via tmux
	seen := make(map[string]bool)

	// 1. Tmux sessions first — merge with config metadata if available
	for _, tmux := range tmuxSessions {
		entry := tmux
		if cfg, ok := configByDisplay[tmux.DisplayName]; ok {
			entry.Path = cfg.Path
			entry.StartupCommand = cfg.StartupCommand
			entry.PreviewCommand = cfg.PreviewCommand
			entry.BareName = cfg.BareName
			seen[cfg.DisplayName] = true
		}
		result = append(result, entry)
	}

	// 2. Config sessions not already in tmux
	for _, cfg := range configSessions {
		if seen[cfg.DisplayName] {
			continue
		}
		result = append(result, Entry{
			Original:       cfg.DisplayName,
			DisplayName:    cfg.DisplayName,
			BareName:       cfg.BareName,
			Path:           cfg.Path,
			StartupCommand: cfg.StartupCommand,
			PreviewCommand: cfg.PreviewCommand,
			Source:         SourceConfig,
		})
	}

	// 3. Zoxide sessions
	result = append(result, zoxideSessions...)

	// 4. Find sessions
	result = append(result, findSessions...)

	return result
}

// FilterWorktrees returns only entries whose BareName contains "/".
func FilterWorktrees(entries []Entry) []Entry {
	var result []Entry
	for _, e := range entries {
		if strings.Contains(e.BareName, "/") {
			result = append(result, e)
		}
	}
	return result
}

// CachedTmuxChecker implements TmuxChecker using a pre-fetched set of session names.
// This avoids spawning a `tmux has-session` subprocess per entry.
type CachedTmuxChecker struct {
	names map[string]bool
}

// NewCachedTmuxChecker builds a checker from tmux Entry results (e.g. from ListTmux).
func NewCachedTmuxChecker(tmuxEntries []Entry) *CachedTmuxChecker {
	names := make(map[string]bool, len(tmuxEntries))
	for _, e := range tmuxEntries {
		names[e.DisplayName] = true
	}
	return &CachedTmuxChecker{names: names}
}

// Exists returns whether the given session name is in the cached set.
func (c *CachedTmuxChecker) Exists(name string) bool {
	return c.names[name]
}

// Annotate sets the Status field on worktree entries based on git dirty state
// and tmux session existence. Dirty takes priority over inactive.
// Non-worktree entries and entries without a parent are left as StatusNone.
func Annotate(entries []Entry, git gitstatus.Checker, tmux TmuxChecker) {
	// Index bare names for parent lookup
	bareToIdx := make(map[string]int)
	for i, e := range entries {
		bareToIdx[e.BareName] = i
	}

	// Build parent→children index
	type parentInfo struct {
		idx      int
		children []int
	}
	parents := make(map[string]*parentInfo) // keyed by parent bare name

	for i, e := range entries {
		slashIdx := strings.Index(e.BareName, "/")
		if slashIdx <= 0 {
			continue
		}
		parentBare := e.BareName[:slashIdx]
		if pi, ok := bareToIdx[parentBare]; ok {
			if parents[parentBare] == nil {
				parents[parentBare] = &parentInfo{idx: pi}
			}
			parents[parentBare].children = append(parents[parentBare].children, i)
		}
	}

	// Phase 1: Run git dirty checks concurrently
	var wg sync.WaitGroup
	for _, pi := range parents {
		for _, ci := range pi.children {
			child := &entries[ci]
			if child.Path == "" {
				continue
			}
			wg.Add(1)
			go func(e *Entry, path string) {
				defer wg.Done()
				if git.IsDirty(path) {
					e.Status = StatusDirty
				}
			}(child, child.Path)
		}
	}
	wg.Wait()

	// Phase 2: Set inactive on non-dirty config entries (cheap map lookups)
	for _, pi := range parents {
		for _, ci := range pi.children {
			child := &entries[ci]
			if child.Status == StatusNone && child.Source == SourceConfig && !tmux.Exists(child.DisplayName) {
				child.Status = StatusInactive
			}
		}
	}

	// Annotate parents: inherit dirty from any child, otherwise check inactive
	for _, pi := range parents {
		hasDirtyChild := false
		for _, ci := range pi.children {
			if entries[ci].Status == StatusDirty {
				hasDirtyChild = true
				break
			}
		}
		parent := &entries[pi.idx]
		if hasDirtyChild {
			parent.Status = StatusDirty
		} else if parent.Source == SourceConfig && !tmux.Exists(parent.DisplayName) {
			parent.Status = StatusInactive
		}
	}
}
