package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"drem-sx/internal/config"
	"drem-sx/internal/fold"
	"drem-sx/internal/gitstatus"
	"drem-sx/internal/icons"
	"drem-sx/internal/session"
	"drem-sx/internal/tree"
)

// FoldTransform implements `drem-sx fold-transform <name>`.
// Used as an fzf transform action: toggles fold state, then outputs fzf
// actions to reload from cache and position the cursor on the parent project.
func FoldTransform(args []string) error {
	if len(args) < 1 {
		return fmt.Errorf("usage: drem-sx fold-transform <name>")
	}
	name := args[0]

	// Strip icon prefix to get bare name
	bareName := icons.StripIcon(name)

	// Derive parent: prefix before first "/"
	parent := bareName
	if idx := strings.Index(bareName, "/"); idx > 0 {
		parent = bareName[:idx]
	}

	if parent == "" {
		return nil
	}

	// Toggle fold state
	foldPath := fold.DefaultPath()
	state := fold.Load(foldPath)
	if err := state.Toggle(parent); err != nil {
		return err
	}

	// Load picker config to get the prompt
	dotfilesDir, err := config.DotfilesDir()
	if err != nil {
		return err
	}
	machineName := config.MachineName(dotfilesDir)
	pickerCfg := config.LoadPickerConfig(dotfilesDir, machineName)

	lines, err := buildAndCacheTree(dotfilesDir, machineName, foldPath)
	if err != nil {
		return err
	}

	pos := tree.FindPos(lines, parent)
	cachePath := fold.CachePath()

	if pos > 0 {
		fmt.Printf("reload-sync(cat %s)+change-prompt(%s)+pos(%d)", cachePath, pickerCfg.Prompt, pos)
	} else {
		fmt.Printf("reload(cat %s)+change-prompt(%s)", cachePath, pickerCfg.Prompt)
	}

	return nil
}

// buildAndCacheTree loads sessions concurrently, annotates, formats as tree,
// writes the output to the cache file, and returns the tree lines.
func buildAndCacheTree(dotfilesDir, machineName, foldPath string) ([]tree.Line, error) {
	configSessions, err := config.Load(dotfilesDir, machineName)
	if err != nil {
		return nil, err
	}

	var tmuxEntries, zoxideEntries []session.Entry
	var wg sync.WaitGroup
	wg.Add(2)
	go func() {
		defer wg.Done()
		tmuxEntries, _ = session.ListTmux()
	}()
	go func() {
		defer wg.Done()
		zoxideEntries, _ = session.ListZoxide()
	}()
	wg.Wait()

	entries := session.Merge(configSessions, tmuxEntries, zoxideEntries, nil)

	// Annotate with cached tmux checker (no per-entry subprocess)
	session.Annotate(entries, gitstatus.GitChecker{}, session.NewCachedTmuxChecker(tmuxEntries))

	// Resolve content colors
	colors := resolveContentColors(dotfilesDir, machineName)

	// Re-read fold state (caller may have just written it)
	state := fold.Load(foldPath)
	lines := tree.Format(entries, state, colors)

	// Write cache
	cachePath := fold.CachePath()
	if err := os.MkdirAll(filepath.Dir(cachePath), 0o755); err != nil {
		return nil, err
	}
	output := tree.FormatString(lines)
	if len(lines) > 0 {
		output += "\n"
	}
	if err := os.WriteFile(cachePath, []byte(output), 0o644); err != nil {
		return nil, err
	}

	return lines, nil
}
