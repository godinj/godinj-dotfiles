package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestMachineName(t *testing.T) {
	tmp := t.TempDir()

	// Create machine directory
	os.MkdirAll(filepath.Join(tmp, "machines", "mba"), 0o755)
	os.MkdirAll(filepath.Join(tmp, "machines", "default"), 0o755)

	// No .machine file → "default"
	if got := MachineName(tmp); got != "default" {
		t.Errorf("no .machine file: got %q, want %q", got, "default")
	}

	// Write .machine file
	writeFile(t, filepath.Join(tmp, ".machine"), "mba\n")
	if got := MachineName(tmp); got != "mba" {
		t.Errorf(".machine=mba: got %q, want %q", got, "mba")
	}

	// Write .machine with comment
	writeFile(t, filepath.Join(tmp, ".machine"), "# comment\nmba\n")
	if got := MachineName(tmp); got != "mba" {
		t.Errorf(".machine with comment: got %q, want %q", got, "mba")
	}

	// Non-existent machine dir → "default"
	writeFile(t, filepath.Join(tmp, ".machine"), "nonexistent\n")
	if got := MachineName(tmp); got != "default" {
		t.Errorf(".machine=nonexistent: got %q, want %q", got, "default")
	}
}

func TestLoadPickerConfig(t *testing.T) {
	tmp := t.TempDir()
	pickerDir := filepath.Join(tmp, "machines", "test", "sesh")
	os.MkdirAll(pickerDir, 0o755)

	writeFile(t, filepath.Join(pickerDir, "picker.sh"), `SESH_BORDER_LABEL=" mba sesh "
SESH_PROMPT="⚡  "
SESH_POPUP_SIZE="80%,70%"
SESH_PREVIEW_WINDOW="right:75%"
SESH_COLOR="border:#7aa2f7"
`)

	cfg := LoadPickerConfig(tmp, "test")
	if cfg.BorderLabel != " mba sesh " {
		t.Errorf("BorderLabel = %q, want %q", cfg.BorderLabel, " mba sesh ")
	}
	if cfg.Color != "border:#7aa2f7" {
		t.Errorf("Color = %q, want %q", cfg.Color, "border:#7aa2f7")
	}
}

func TestLoadPickerConfigDefaults(t *testing.T) {
	tmp := t.TempDir()
	cfg := LoadPickerConfig(tmp, "nonexistent")
	def := DefaultPickerConfig()
	if cfg.BorderLabel != def.BorderLabel {
		t.Errorf("default BorderLabel = %q, want %q", cfg.BorderLabel, def.BorderLabel)
	}
	if cfg.Prompt != def.Prompt {
		t.Errorf("default Prompt = %q, want %q", cfg.Prompt, def.Prompt)
	}
}

func TestLoadPickerConfigColorScheme(t *testing.T) {
	tmp := t.TempDir()
	pickerDir := filepath.Join(tmp, "machines", "test", "sesh")
	os.MkdirAll(pickerDir, 0o755)

	writeFile(t, filepath.Join(pickerDir, "picker.sh"), `SESH_COLOR_SCHEME="gruvbox"
`)

	cfg := LoadPickerConfig(tmp, "test")
	if cfg.ColorScheme != "gruvbox" {
		t.Errorf("ColorScheme = %q, want %q", cfg.ColorScheme, "gruvbox")
	}
	if cfg.Color != "" {
		t.Errorf("Color = %q, want empty", cfg.Color)
	}
}

func TestParseShellAssignment(t *testing.T) {
	tests := []struct {
		line    string
		wantKey string
		wantVal string
		wantOK  bool
	}{
		{`KEY="value"`, "KEY", "value", true},
		{`KEY=value`, "KEY", "value", true},
		{`SESH_COLOR="border:#7aa2f7,label:#7aa2f7"`, "SESH_COLOR", "border:#7aa2f7,label:#7aa2f7", true},
		{"", "", "", false},
		{"# comment", "", "", false},
	}
	for _, tt := range tests {
		key, val, ok := parseShellAssignment(tt.line)
		if ok != tt.wantOK || key != tt.wantKey || val != tt.wantVal {
			t.Errorf("parseShellAssignment(%q) = (%q, %q, %v), want (%q, %q, %v)",
				tt.line, key, val, ok, tt.wantKey, tt.wantVal, tt.wantOK)
		}
	}
}
