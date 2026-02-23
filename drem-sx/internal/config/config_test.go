package config

import (
	"os"
	"path/filepath"
	"testing"

	"drem-sx/internal/icons"
)

func TestLoadMergeOrder(t *testing.T) {
	// Create temp directory structure mimicking dotfiles
	tmp := t.TempDir()

	// sesh/sessions/
	seshDir := filepath.Join(tmp, "sesh", "sessions")
	os.MkdirAll(seshDir, 0o755)

	// config.toml (shared)
	writeFile(t, filepath.Join(seshDir, "config.toml"), `
[[session]]
name = "godinj-dotfiles"
path = "~/git/godinj-dotfiles.git/master/"
startup_command = "nvim"
`)

	// tools.toml (shared)
	writeFile(t, filepath.Join(seshDir, "tools.toml"), `
[[session]]
name = "fastfetch"
path = "~"
startup_command = "fastfetch"
`)

	// local.toml (should come last)
	writeFile(t, filepath.Join(seshDir, "local.toml"), `
[[session]]
name = "local-only"
path = "~/local"
`)

	// machines/test/sesh/sessions/
	machineDir := filepath.Join(tmp, "machines", "test", "sesh", "sessions")
	os.MkdirAll(machineDir, 0o755)

	// worktrees.toml (machine, comes after shared, before other machine files)
	writeFile(t, filepath.Join(machineDir, "worktrees.toml"), `
[[session]]
name = "proj/feature/auth"
path = "~/git/proj.git/feature/auth/"

[[session]]
name = "proj"
path = "~/git/proj.git/main/"
`)

	// projects.toml (machine)
	writeFile(t, filepath.Join(machineDir, "projects.toml"), `
[[session]]
name = "drem-ninja"
path = "~/git/drem-ninja.git/main/"
startup_command = "nvim"
`)

	sessions, err := Load(tmp, "test")
	if err != nil {
		t.Fatalf("Load() error: %v", err)
	}

	// Verify order: shared (config, tools) → machine worktrees → machine projects → local
	expected := []struct {
		displayName string
		bareName    string
	}{
		// config.toml → Config icon
		{icons.Config + " godinj-dotfiles", "godinj-dotfiles"},
		// tools.toml → Tool icon
		{icons.Tool + " fastfetch", "fastfetch"},
		// worktrees.toml → Worktree icon for name with /
		{icons.Worktree + " proj/feature/auth", "proj/feature/auth"},
		// worktrees.toml → WorktreeProject icon for name without /
		{icons.WorktreeProject + " proj", "proj"},
		// projects.toml → Project icon
		{icons.Project + " drem-ninja", "drem-ninja"},
		// local.toml → Project icon
		{icons.Project + " local-only", "local-only"},
	}

	if len(sessions) != len(expected) {
		t.Fatalf("got %d sessions, want %d", len(sessions), len(expected))
	}
	for i, exp := range expected {
		if sessions[i].DisplayName != exp.displayName {
			t.Errorf("sessions[%d].DisplayName = %q, want %q", i, sessions[i].DisplayName, exp.displayName)
		}
		if sessions[i].BareName != exp.bareName {
			t.Errorf("sessions[%d].BareName = %q, want %q", i, sessions[i].BareName, exp.bareName)
		}
	}
}

func TestLoadEmptyDir(t *testing.T) {
	tmp := t.TempDir()
	os.MkdirAll(filepath.Join(tmp, "sesh", "sessions"), 0o755)

	sessions, err := Load(tmp, "nonexistent")
	if err != nil {
		t.Fatalf("Load() error: %v", err)
	}
	if len(sessions) != 0 {
		t.Errorf("expected 0 sessions, got %d", len(sessions))
	}
}

func TestExpandHome(t *testing.T) {
	home := os.Getenv("HOME")
	tests := []struct {
		input string
		want  string
	}{
		{"~/git/foo", filepath.Join(home, "git/foo")},
		{"~", home},
		{"/absolute/path", "/absolute/path"},
		{"relative/path", "relative/path"},
	}
	for _, tt := range tests {
		if got := expandHome(tt.input); got != tt.want {
			t.Errorf("expandHome(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func writeFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}
