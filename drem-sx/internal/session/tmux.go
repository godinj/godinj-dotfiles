package session

import (
	"drem-sx/internal/icons"
	"os/exec"
	"strings"
)

// ListTmux returns active tmux session names as entries.
func ListTmux() ([]Entry, error) {
	out, err := exec.Command("tmux", "list-sessions", "-F", "#{session_name}").Output()
	if err != nil {
		// tmux not running or no sessions is not a fatal error
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
			BareName:    icons.StripIcon(line),
			Source:      SourceTmux,
		})
	}
	return entries, nil
}
