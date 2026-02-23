package tree

import (
	"drem-sx/internal/fold"
	"drem-sx/internal/icons"
	"drem-sx/internal/session"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// Helper to create entries from display names (simulating sesh list output).
func makeEntry(displayName string) session.Entry {
	return session.Entry{
		Original:    displayName,
		DisplayName: displayName,
		BareName:    icons.StripIcon(displayName),
		Source:      session.SourceConfig,
	}
}

func TestStandalonePassthrough(t *testing.T) {
	entries := []session.Entry{makeEntry(icons.Tool + " fastfetch")}
	lines := Format(entries, nil)

	if len(lines) != 1 {
		t.Fatalf("expected 1 line, got %d", len(lines))
	}
	if lines[0].Original != icons.Tool+" fastfetch" {
		t.Errorf("Original = %q, want %q", lines[0].Original, icons.Tool+" fastfetch")
	}
	if lines[0].Display != icons.Tool+" fastfetch" {
		t.Errorf("Display = %q, want %q", lines[0].Display, icons.Tool+" fastfetch")
	}
}

func TestChildGroupsUnderParent(t *testing.T) {
	entries := []session.Entry{
		makeEntry(icons.WorktreeProject + " myproject"),
		makeEntry(icons.Worktree + " myproject/feature/auth"),
	}
	lines := Format(entries, nil)

	if len(lines) != 2 {
		t.Fatalf("expected 2 lines, got %d", len(lines))
	}
	// Child emitted before parent
	if !strings.Contains(lines[0].Display, "└──") {
		t.Errorf("child should have └──, got %q", lines[0].Display)
	}
	if !strings.Contains(lines[0].Display, "feature/auth") {
		t.Errorf("child should contain branch name, got %q", lines[0].Display)
	}
	if !strings.Contains(lines[1].Display, "myproject") {
		t.Errorf("parent should contain project name, got %q", lines[1].Display)
	}
}

func TestMultipleChildrenTreeChars(t *testing.T) {
	entries := []session.Entry{
		makeEntry(icons.WorktreeProject + " proj"),
		makeEntry(icons.Worktree + " proj/feature/a"),
		makeEntry(icons.Worktree + " proj/feature/b"),
	}
	lines := Format(entries, nil)

	if len(lines) != 3 {
		t.Fatalf("expected 3 lines, got %d", len(lines))
	}
	// Children emitted in reverse order: feature/b first (├──), feature/a last (└──)
	if !strings.Contains(lines[0].Display, "├──") || !strings.Contains(lines[0].Display, "feature/b") {
		t.Errorf("first child (feature/b) should have ├──, got %q", lines[0].Display)
	}
	if !strings.Contains(lines[1].Display, "└──") || !strings.Contains(lines[1].Display, "feature/a") {
		t.Errorf("last child (feature/a) should have └──, got %q", lines[1].Display)
	}
	if !strings.Contains(lines[2].Display, "proj") {
		t.Errorf("parent line should contain proj, got %q", lines[2].Display)
	}
}

func TestOrphanChildPassthrough(t *testing.T) {
	entries := []session.Entry{
		makeEntry(icons.Worktree + " orphan/feature/x"),
	}
	lines := Format(entries, nil)

	if len(lines) != 1 {
		t.Fatalf("expected 1 line, got %d", len(lines))
	}
	// No parent in list, passes through as standalone
	if lines[0].Display != icons.Worktree+" orphan/feature/x" {
		t.Errorf("orphan should pass through, got %q", lines[0].Display)
	}
}

func TestFoldedParentHidesChildren(t *testing.T) {
	tmp := t.TempDir()
	foldPath := filepath.Join(tmp, "fold_state")
	os.WriteFile(foldPath, []byte("proj\n"), 0o644)
	state := fold.Load(foldPath)

	entries := []session.Entry{
		makeEntry(icons.WorktreeProject + " proj"),
		makeEntry(icons.Worktree + " proj/feature/a"),
		makeEntry(icons.Worktree + " proj/feature/b"),
	}
	lines := Format(entries, state)

	if len(lines) != 1 {
		t.Fatalf("expected 1 line (folded), got %d", len(lines))
	}
	if !strings.Contains(lines[0].Display, "▸") {
		t.Errorf("folded parent should have ▸, got %q", lines[0].Display)
	}
	if !strings.Contains(lines[0].Display, "[2]") {
		t.Errorf("folded parent should show [2] count, got %q", lines[0].Display)
	}
}

func TestExpandedParentWithFoldFile(t *testing.T) {
	tmp := t.TempDir()
	foldPath := filepath.Join(tmp, "fold_state")
	os.WriteFile(foldPath, []byte(""), 0o644) // empty = all expanded
	state := fold.Load(foldPath)

	entries := []session.Entry{
		makeEntry(icons.WorktreeProject + " proj"),
		makeEntry(icons.Worktree + " proj/feature/a"),
	}
	lines := Format(entries, state)

	if len(lines) != 2 {
		t.Fatalf("expected 2 lines, got %d", len(lines))
	}
	// Parent (last line) should have ▾
	if !strings.Contains(lines[1].Display, "▾") {
		t.Errorf("expanded parent with fold file should have ▾, got %q", lines[1].Display)
	}
	// Child should have tree chars
	if !strings.Contains(lines[0].Display, "└──") {
		t.Errorf("child should have └──, got %q", lines[0].Display)
	}
}

func TestMixedFoldState(t *testing.T) {
	tmp := t.TempDir()
	foldPath := filepath.Join(tmp, "fold_state")
	os.WriteFile(foldPath, []byte("alpha\n"), 0o644)
	state := fold.Load(foldPath)

	entries := []session.Entry{
		makeEntry(icons.WorktreeProject + " alpha"),
		makeEntry(icons.Worktree + " alpha/feature/x"),
		makeEntry(icons.WorktreeProject + " beta"),
		makeEntry(icons.Worktree + " beta/feature/y"),
	}
	lines := Format(entries, state)

	// alpha is folded: 1 line
	// beta is expanded: 2 lines (child + parent)
	if len(lines) != 3 {
		t.Fatalf("expected 3 lines, got %d", len(lines))
	}

	// First line: alpha collapsed
	if !strings.Contains(lines[0].Display, "▸") || !strings.Contains(lines[0].Display, "[1]") {
		t.Errorf("alpha should be folded with ▸ [1], got %q", lines[0].Display)
	}
	// Second line: beta's child
	if !strings.Contains(lines[1].Display, "└──") {
		t.Errorf("beta child should have └──, got %q", lines[1].Display)
	}
	// Third line: beta expanded
	if !strings.Contains(lines[2].Display, "▾") {
		t.Errorf("beta should have ▾, got %q", lines[2].Display)
	}
}

func TestStandaloneWithFoldFile(t *testing.T) {
	tmp := t.TempDir()
	foldPath := filepath.Join(tmp, "fold_state")
	os.WriteFile(foldPath, []byte(""), 0o644)
	state := fold.Load(foldPath)

	entries := []session.Entry{makeEntry(icons.Tool + " fastfetch")}
	lines := Format(entries, state)

	if len(lines) != 1 {
		t.Fatalf("expected 1 line, got %d", len(lines))
	}
	// Standalone should pass through unchanged even with fold file
	if lines[0].Display != icons.Tool+" fastfetch" {
		t.Errorf("standalone with fold file should be unchanged, got %q", lines[0].Display)
	}
}

func TestMissingFoldFileTreatedAsExpanded(t *testing.T) {
	tmp := t.TempDir()
	foldPath := filepath.Join(tmp, "nonexistent")
	state := fold.Load(foldPath)

	entries := []session.Entry{
		makeEntry(icons.WorktreeProject + " proj"),
		makeEntry(icons.Worktree + " proj/feature/a"),
	}
	lines := Format(entries, state)

	if len(lines) != 2 {
		t.Fatalf("expected 2 lines, got %d", len(lines))
	}
	// Parent should have ▾ (fold file path is set even though file doesn't exist)
	if !strings.Contains(lines[1].Display, "▾") {
		t.Errorf("expanded parent with fold file path should have ▾, got %q", lines[1].Display)
	}
	if !strings.Contains(lines[0].Display, "└──") {
		t.Errorf("child should have └──, got %q", lines[0].Display)
	}
}

func TestOriginalColumnUnchangedForFolded(t *testing.T) {
	tmp := t.TempDir()
	foldPath := filepath.Join(tmp, "fold_state")
	os.WriteFile(foldPath, []byte("proj\n"), 0o644)
	state := fold.Load(foldPath)

	entries := []session.Entry{
		makeEntry(icons.WorktreeProject + " proj"),
		makeEntry(icons.Worktree + " proj/feature/a"),
	}
	lines := Format(entries, state)

	if len(lines) != 1 {
		t.Fatalf("expected 1 line, got %d", len(lines))
	}
	if lines[0].Original != icons.WorktreeProject+" proj" {
		t.Errorf("Original should be unmodified, got %q", lines[0].Original)
	}
}

func TestFormatString(t *testing.T) {
	lines := []Line{
		{Original: "orig1", Display: "disp1"},
		{Original: "orig2", Display: "disp2"},
	}
	got := FormatString(lines)
	want := "orig1\tdisp1\norig2\tdisp2"
	if got != want {
		t.Errorf("FormatString = %q, want %q", got, want)
	}
}
