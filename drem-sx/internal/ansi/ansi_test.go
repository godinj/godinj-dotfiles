package ansi

import "testing"

func TestFgValidHex(t *testing.T) {
	got := Fg("hello", "#fabd2f")
	want := "\033[38;2;250;189;47mhello\033[0m"
	if got != want {
		t.Errorf("Fg(hello, #fabd2f) = %q, want %q", got, want)
	}
}

func TestFgEmptyHex(t *testing.T) {
	got := Fg("hello", "")
	if got != "hello" {
		t.Errorf("Fg with empty hex should return text unchanged, got %q", got)
	}
}

func TestFgInvalidHex(t *testing.T) {
	for _, hex := range []string{"#xyz", "#12", "nope", "#1234567"} {
		got := Fg("hello", hex)
		if got != "hello" {
			t.Errorf("Fg(hello, %q) = %q, want %q", hex, got, "hello")
		}
	}
}

func TestFgBlack(t *testing.T) {
	got := Fg("text", "#000000")
	want := "\033[38;2;0;0;0mtext\033[0m"
	if got != want {
		t.Errorf("Fg(text, #000000) = %q, want %q", got, want)
	}
}

func TestFgWhite(t *testing.T) {
	got := Fg("text", "#FFFFFF")
	want := "\033[38;2;255;255;255mtext\033[0m"
	if got != want {
		t.Errorf("Fg(text, #FFFFFF) = %q, want %q", got, want)
	}
}
