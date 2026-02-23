package fold

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLoadMissing(t *testing.T) {
	s := Load("/nonexistent/path")
	if s.IsFolded("anything") {
		t.Error("missing file should have no folded entries")
	}
}

func TestLoadExisting(t *testing.T) {
	tmp := t.TempDir()
	path := filepath.Join(tmp, "fold_state")
	os.WriteFile(path, []byte("alpha\nbeta\n"), 0o644)

	s := Load(path)
	if !s.IsFolded("alpha") {
		t.Error("alpha should be folded")
	}
	if !s.IsFolded("beta") {
		t.Error("beta should be folded")
	}
	if s.IsFolded("gamma") {
		t.Error("gamma should not be folded")
	}
}

func TestToggle(t *testing.T) {
	tmp := t.TempDir()
	path := filepath.Join(tmp, "fold_state")

	s := Load(path)
	// Toggle on
	if err := s.Toggle("proj"); err != nil {
		t.Fatal(err)
	}
	if !s.IsFolded("proj") {
		t.Error("proj should be folded after toggle on")
	}

	// Toggle off
	if err := s.Toggle("proj"); err != nil {
		t.Fatal(err)
	}
	if s.IsFolded("proj") {
		t.Error("proj should not be folded after toggle off")
	}

	// Verify persistence: reload from file
	s2 := Load(path)
	if s2.IsFolded("proj") {
		t.Error("proj should not be folded after reload")
	}
}

func TestExpandAll(t *testing.T) {
	tmp := t.TempDir()
	path := filepath.Join(tmp, "fold_state")
	os.WriteFile(path, []byte("alpha\nbeta\n"), 0o644)

	s := Load(path)
	if err := s.ExpandAll(); err != nil {
		t.Fatal(err)
	}
	if s.IsFolded("alpha") || s.IsFolded("beta") {
		t.Error("all entries should be cleared after ExpandAll")
	}

	// Verify file is empty
	data, _ := os.ReadFile(path)
	if len(data) != 0 {
		t.Errorf("fold file should be empty, got %q", string(data))
	}
}

func TestCachePath(t *testing.T) {
	path := CachePath()
	if path == "" {
		t.Fatal("CachePath should not be empty")
	}
	if !strings.HasSuffix(path, filepath.Join("drem-sx", "tree_cache")) {
		t.Errorf("CachePath should end with drem-sx/tree_cache, got %q", path)
	}
}

func TestHasFile(t *testing.T) {
	s := &State{path: "", folded: make(map[string]bool)}
	if s.HasFile() {
		t.Error("empty path should return false")
	}

	s2 := &State{path: "/some/path", folded: make(map[string]bool)}
	if !s2.HasFile() {
		t.Error("non-empty path should return true")
	}
}
