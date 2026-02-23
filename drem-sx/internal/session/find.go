package session

import (
	"os"
	"os/exec"
	"strings"
)

// ListFind returns directories from fd (or find fallback).
func ListFind() ([]Entry, error) {
	home := os.Getenv("HOME")
	out, err := exec.Command("fd", "-H", "-d", "2", "-t", "d", "-E", ".Trash", ".", home).Output()
	if err != nil {
		return nil, nil
	}

	var entries []Entry
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		entries = append(entries, Entry{
			Original:    line,
			DisplayName: line,
			BareName:    line,
			Path:        line,
			Source:      SourceFind,
		})
	}
	return entries, nil
}
