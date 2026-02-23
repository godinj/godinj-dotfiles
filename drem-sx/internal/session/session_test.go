package session

import (
	"drem-sx/internal/config"
	"drem-sx/internal/icons"
	"testing"
)

func TestMerge(t *testing.T) {
	configSessions := []config.ResolvedSession{
		{DisplayName: icons.Tool + " fastfetch", BareName: "fastfetch", Path: "/home/user", StartupCommand: "fastfetch"},
		{DisplayName: icons.Config + " dotfiles", BareName: "dotfiles", Path: "/home/user/dotfiles", StartupCommand: "nvim"},
	}

	tmuxSessions := []Entry{
		{Original: icons.Tool + " fastfetch", DisplayName: icons.Tool + " fastfetch", BareName: "fastfetch", Source: SourceTmux},
		{Original: "other-session", DisplayName: "other-session", BareName: "other-session", Source: SourceTmux},
	}

	zoxideSessions := []Entry{
		{Original: "/tmp/zox", DisplayName: "/tmp/zox", BareName: "/tmp/zox", Path: "/tmp/zox", Source: SourceZoxide},
	}

	result := Merge(configSessions, tmuxSessions, zoxideSessions, nil)

	// Tmux sessions first (2), then config not in tmux (1), then zoxide (1)
	if len(result) != 4 {
		t.Fatalf("expected 4 entries, got %d", len(result))
	}

	// First entry: tmux fastfetch with config metadata merged
	if result[0].DisplayName != icons.Tool+" fastfetch" {
		t.Errorf("entry 0 DisplayName = %q", result[0].DisplayName)
	}
	if result[0].Path != "/home/user" {
		t.Errorf("entry 0 should have config path merged, got %q", result[0].Path)
	}
	if result[0].StartupCommand != "fastfetch" {
		t.Errorf("entry 0 should have config startup_command merged, got %q", result[0].StartupCommand)
	}

	// Second entry: tmux-only session (no config match)
	if result[1].DisplayName != "other-session" {
		t.Errorf("entry 1 DisplayName = %q", result[1].DisplayName)
	}

	// Third entry: config dotfiles (not in tmux)
	if result[2].DisplayName != icons.Config+" dotfiles" {
		t.Errorf("entry 2 DisplayName = %q", result[2].DisplayName)
	}

	// Fourth entry: zoxide
	if result[3].Source != SourceZoxide {
		t.Errorf("entry 3 should be zoxide, got source %d", result[3].Source)
	}
}

func TestFilterWorktrees(t *testing.T) {
	entries := []Entry{
		{BareName: "proj"},
		{BareName: "proj/feature/auth"},
		{BareName: "fastfetch"},
		{BareName: "proj/feature/main"},
	}

	filtered := FilterWorktrees(entries)
	if len(filtered) != 2 {
		t.Fatalf("expected 2 worktree entries, got %d", len(filtered))
	}
	if filtered[0].BareName != "proj/feature/auth" {
		t.Errorf("filtered[0] = %q", filtered[0].BareName)
	}
	if filtered[1].BareName != "proj/feature/main" {
		t.Errorf("filtered[1] = %q", filtered[1].BareName)
	}
}
