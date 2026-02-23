package colorscheme

import (
	"strings"
	"testing"
)

func TestLookupKnown(t *testing.T) {
	s := Lookup("gruvbox")
	if s == nil {
		t.Fatal("Lookup(gruvbox) returned nil")
	}
	if s.Name != "gruvbox" {
		t.Errorf("Name = %q, want %q", s.Name, "gruvbox")
	}
}

func TestLookupCaseInsensitive(t *testing.T) {
	for _, name := range []string{"Gruvbox", "GRUVBOX", "GrUvBoX"} {
		if s := Lookup(name); s == nil {
			t.Errorf("Lookup(%q) returned nil", name)
		}
	}
}

func TestLookupUnknown(t *testing.T) {
	if s := Lookup("nonexistent"); s != nil {
		t.Errorf("Lookup(nonexistent) = %v, want nil", s)
	}
}

func TestFzfColorStringContents(t *testing.T) {
	s := Lookup("gruvbox")
	if s == nil {
		t.Fatal("Lookup(gruvbox) returned nil")
	}
	got := s.FzfColorString()

	for _, want := range []string{"bg:#282828", "fg:#ebdbb2", "border:#d5c4a1", "pointer:#fb4934"} {
		if !strings.Contains(got, want) {
			t.Errorf("FzfColorString() = %q, missing %q", got, want)
		}
	}
}

func TestFzfColorStringDeterministic(t *testing.T) {
	s := Lookup("gruvbox")
	if s == nil {
		t.Fatal("Lookup(gruvbox) returned nil")
	}
	first := s.FzfColorString()
	for i := 0; i < 10; i++ {
		if got := s.FzfColorString(); got != first {
			t.Errorf("FzfColorString() not deterministic: call 0 = %q, call %d = %q", first, i+1, got)
		}
	}
}

func TestNames(t *testing.T) {
	names := Names()
	if len(names) < 4 {
		t.Fatalf("Names() returned %d entries, want at least 4", len(names))
	}
	// Verify sorted
	for i := 1; i < len(names); i++ {
		if names[i] < names[i-1] {
			t.Errorf("Names() not sorted: %q before %q", names[i-1], names[i])
		}
	}
	// Verify known schemes present
	have := map[string]bool{}
	for _, n := range names {
		have[n] = true
	}
	for _, want := range []string{"gruvbox", "tokyonight", "kanagawa", "rosepine"} {
		if !have[want] {
			t.Errorf("Names() missing %q", want)
		}
	}
}
