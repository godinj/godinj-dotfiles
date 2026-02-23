package config

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"drem-sx/internal/icons"

	"github.com/BurntSushi/toml"
)

// Session represents a single [[session]] entry from a TOML file.
type Session struct {
	Name           string `toml:"name"`
	Path           string `toml:"path"`
	StartupCommand string `toml:"startup_command"`
	PreviewCommand string `toml:"preview_command"`
}

// ResolvedSession is a session with its display name (icon-prefixed) and bare name.
type ResolvedSession struct {
	DisplayName    string
	BareName       string
	Path           string
	StartupCommand string
	PreviewCommand string
}

// sessionFile is the TOML structure for files containing [[session]] arrays.
type sessionFile struct {
	Session []Session `toml:"session"`
}

// Load discovers and merges all session TOML files, applying icons.
// dotfilesDir is the root of the dotfiles repo.
// machineName is the resolved machine profile name.
func Load(dotfilesDir, machineName string) ([]ResolvedSession, error) {
	var result []ResolvedSession

	seshDir := filepath.Join(dotfilesDir, "sesh", "sessions")
	machineDir := filepath.Join(dotfilesDir, "machines", machineName, "sesh", "sessions")

	// 1. Shared sessions (sesh/sessions/*.toml, excluding local.toml)
	shared, err := listTOMLFiles(seshDir)
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	for _, f := range shared {
		base := filepath.Base(f)
		if base == "local.toml" {
			continue
		}
		sessions, err := loadFile(f, base)
		if err != nil {
			return nil, err
		}
		result = append(result, sessions...)
	}

	// 2. Machine worktrees (machines/<name>/sesh/sessions/worktrees.toml)
	wtFile := filepath.Join(machineDir, "worktrees.toml")
	if fileExists(wtFile) {
		sessions, err := loadFile(wtFile, "worktrees.toml")
		if err != nil {
			return nil, err
		}
		result = append(result, sessions...)
	}

	// 3. Machine sessions (machines/<name>/sesh/sessions/*.toml, excluding worktrees.toml)
	machineFiles, err := listTOMLFiles(machineDir)
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	for _, f := range machineFiles {
		base := filepath.Base(f)
		if base == "worktrees.toml" {
			continue
		}
		sessions, err := loadFile(f, base)
		if err != nil {
			return nil, err
		}
		result = append(result, sessions...)
	}

	// 4. Local overrides (sesh/sessions/local.toml)
	localFile := filepath.Join(seshDir, "local.toml")
	if fileExists(localFile) {
		sessions, err := loadFile(localFile, "local.toml")
		if err != nil {
			return nil, err
		}
		result = append(result, sessions...)
	}

	return result, nil
}

// loadFile parses a single TOML session file and applies icons based on filename.
func loadFile(path, filename string) ([]ResolvedSession, error) {
	var sf sessionFile
	if _, err := toml.DecodeFile(path, &sf); err != nil {
		return nil, err
	}

	icon := icons.ForFile(filename)
	var result []ResolvedSession

	for _, s := range sf.Session {
		bareName := s.Name
		var displayName string

		if icon == "" {
			// worktrees.toml: choose icon based on name content
			wtIcon := icons.ForWorktreeName(bareName)
			displayName = wtIcon + " " + bareName
		} else {
			displayName = icon + " " + bareName
		}

		result = append(result, ResolvedSession{
			DisplayName:    displayName,
			BareName:       bareName,
			Path:           expandHome(s.Path),
			StartupCommand: s.StartupCommand,
			PreviewCommand: s.PreviewCommand,
		})
	}

	return result, nil
}

// listTOMLFiles returns sorted paths of all .toml files in dir.
func listTOMLFiles(dir string) ([]string, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	var files []string
	for _, e := range entries {
		if !e.IsDir() && strings.HasSuffix(e.Name(), ".toml") {
			files = append(files, filepath.Join(dir, e.Name()))
		}
	}
	sort.Strings(files)
	return files, nil
}

// expandHome replaces a leading ~ with $HOME.
func expandHome(path string) string {
	if strings.HasPrefix(path, "~/") {
		return filepath.Join(os.Getenv("HOME"), path[2:])
	}
	if path == "~" {
		return os.Getenv("HOME")
	}
	return path
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// DotfilesDir resolves the dotfiles directory.
// Validates the path contains machine.sh as a marker file.
// Tries: $DOTFILES_DIR env var → ~/tmux-config symlink → walk up from executable.
func DotfilesDir() (string, error) {
	// 1. Check $DOTFILES_DIR env var (validate it still exists)
	if d := os.Getenv("DOTFILES_DIR"); d != "" {
		if fileExists(filepath.Join(d, "machine.sh")) {
			return d, nil
		}
	}

	// 2. Follow ~/tmux-config symlink (points to $DOTFILES_DIR/tmux)
	home := os.Getenv("HOME")
	if home != "" {
		tmuxLink := filepath.Join(home, "tmux-config")
		if target, err := os.Readlink(tmuxLink); err == nil {
			if !filepath.IsAbs(target) {
				target = filepath.Join(filepath.Dir(tmuxLink), target)
			}
			candidate := filepath.Dir(target)
			if fileExists(filepath.Join(candidate, "machine.sh")) {
				return candidate, nil
			}
		}
	}

	// 3. Walk up from executable location
	exe, err := os.Executable()
	if err != nil {
		return "", err
	}
	dir := filepath.Dir(exe)
	for i := 0; i < 5; i++ {
		if fileExists(filepath.Join(dir, "machine.sh")) {
			return dir, nil
		}
		dir = filepath.Dir(dir)
	}

	return "", fmt.Errorf("cannot find dotfiles directory (no machine.sh marker found)")
}
