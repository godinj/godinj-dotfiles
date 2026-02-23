package session

import (
	"os/exec"
	"strings"
)

// ListZoxide returns zoxide directory entries.
func ListZoxide() ([]Entry, error) {
	out, err := exec.Command("zoxide", "query", "-l").Output()
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
			Source:      SourceZoxide,
		})
	}
	return entries, nil
}
