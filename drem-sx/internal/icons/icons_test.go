package icons

import "testing"

func TestForFile(t *testing.T) {
	tests := []struct {
		filename string
		want     string
	}{
		{"tools.toml", Tool},
		{"config.toml", Config},
		{"worktrees.toml", ""},
		{"projects.toml", Project},
		{"local.toml", Project},
		{"anything.toml", Project},
	}
	for _, tt := range tests {
		t.Run(tt.filename, func(t *testing.T) {
			if got := ForFile(tt.filename); got != tt.want {
				t.Errorf("ForFile(%q) = %q, want %q", tt.filename, got, tt.want)
			}
		})
	}
}

func TestForWorktreeName(t *testing.T) {
	tests := []struct {
		name string
		want string
	}{
		{"myproject", WorktreeProject},
		{"myproject/feature/auth", Worktree},
		{"myproject/main", Worktree},
		{"simple", WorktreeProject},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := ForWorktreeName(tt.name); got != tt.want {
				t.Errorf("ForWorktreeName(%q) = %q, want %q", tt.name, got, tt.want)
			}
		})
	}
}

func TestStripIcon(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{Tool + " fastfetch", "fastfetch"},
		{Config + " godinj-dotfiles", "godinj-dotfiles"},
		{Project + " drem-ninja", "drem-ninja"},
		{Worktree + " proj/feature/auth", "proj/feature/auth"},
		{WorktreeProject + " proj", "proj"},
		{"no-icon-name", "no-icon-name"},
		{"", ""},
	}
	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			if got := StripIcon(tt.input); got != tt.want {
				t.Errorf("StripIcon(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}
