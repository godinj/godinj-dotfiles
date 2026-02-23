package fold

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"
)

// DefaultPath returns the default fold state file path.
func DefaultPath() string {
	cache := os.Getenv("XDG_CACHE_HOME")
	if cache == "" {
		cache = filepath.Join(os.Getenv("HOME"), ".cache")
	}
	return filepath.Join(cache, "drem-sx", "fold_state")
}

// CachePath returns the path for the tree output cache file.
func CachePath() string {
	cache := os.Getenv("XDG_CACHE_HOME")
	if cache == "" {
		cache = filepath.Join(os.Getenv("HOME"), ".cache")
	}
	return filepath.Join(cache, "drem-sx", "tree_cache")
}

// State holds the set of folded parent names.
type State struct {
	path   string
	folded map[string]bool
}

// Load reads the fold state from the given file path.
// A missing file means all expanded (empty set).
func Load(path string) *State {
	s := &State{
		path:   path,
		folded: make(map[string]bool),
	}
	f, err := os.Open(path)
	if err != nil {
		return s
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line != "" {
			s.folded[line] = true
		}
	}
	return s
}

// IsFolded returns whether the given parent name is in the folded set.
func (s *State) IsFolded(parent string) bool {
	return s.folded[parent]
}

// HasFile returns whether the fold state file path is set (non-empty).
// This determines whether to show ▾ indicators on expanded parents.
func (s *State) HasFile() bool {
	return s.path != ""
}

// Toggle adds parent if absent, removes if present, and writes back.
func (s *State) Toggle(parent string) error {
	if s.folded[parent] {
		delete(s.folded, parent)
	} else {
		s.folded[parent] = true
	}
	return s.write()
}

// ExpandAll clears all fold state and truncates the file.
func (s *State) ExpandAll() error {
	s.folded = make(map[string]bool)
	return s.write()
}

func (s *State) write() error {
	if s.path == "" {
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(s.path), 0o755); err != nil {
		return err
	}
	f, err := os.Create(s.path)
	if err != nil {
		return err
	}
	defer f.Close()
	for name := range s.folded {
		f.WriteString(name + "\n")
	}
	return nil
}
