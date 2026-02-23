package cmd

import (
	"os"
	"path/filepath"
	"strings"

	"drem-sx/internal/config"
	"drem-sx/internal/fold"
	"drem-sx/internal/gitstatus"
	"drem-sx/internal/icons"
	"drem-sx/internal/picker"
	"drem-sx/internal/session"
	"drem-sx/internal/tmuxctl"
	"drem-sx/internal/tree"
)

// Pick implements `drem-sx pick` — the full fzf picker lifecycle.
func Pick() error {
	dotfilesDir, err := config.DotfilesDir()
	if err != nil {
		return err
	}
	machineName := config.MachineName(dotfilesDir)
	pickerCfg := config.LoadPickerConfig(dotfilesDir, machineName)

	// Generate initial list
	configSessions, err := config.Load(dotfilesDir, machineName)
	if err != nil {
		return err
	}
	tmuxEntries, _ := session.ListTmux()
	entries := session.Merge(configSessions, tmuxEntries, nil, nil)

	// Annotate worktree entries with dirty/inactive status
	session.Annotate(entries, gitstatus.GitChecker{}, session.NewCachedTmuxChecker(tmuxEntries))

	// Resolve content colors
	colors := resolveContentColors(dotfilesDir, machineName)

	foldPath := fold.DefaultPath()
	state := fold.Load(foldPath)
	lines := tree.Format(entries, state, colors)
	initialInput := tree.FormatString(lines)
	if len(lines) > 0 {
		initialInput += "\n"
	}

	selected, err := picker.Run(initialInput, pickerCfg)
	if err != nil {
		return err
	}
	if selected == "" {
		return nil
	}

	// Create directory if selection looks like a path
	dir := selected
	if strings.HasPrefix(dir, "~/") {
		dir = filepath.Join(os.Getenv("HOME"), dir[2:])
	}
	if strings.HasPrefix(dir, "/") {
		if _, err := os.Stat(dir); os.IsNotExist(err) {
			os.MkdirAll(dir, 0o755)
		}
	}

	// Connect to the session
	return connectToSession(selected, "", dotfilesDir, machineName)
}

// connectToSession creates/switches to a tmux session.
func connectToSession(name, cmdOverride, dotfilesDir, machineName string) error {
	// If tmux session already exists, just switch
	if tmuxctl.SessionExists(name) {
		return tmuxctl.SwitchTo(name)
	}

	// Look up config to get path and startup command
	sessions, _ := config.Load(dotfilesDir, machineName)
	for _, s := range sessions {
		if s.DisplayName == name {
			if err := tmuxctl.NewSession(name, s.Path); err != nil {
				return err
			}
			cmd := s.StartupCommand
			if cmdOverride != "" {
				cmd = cmdOverride
			}
			if cmd != "" {
				tmuxctl.SendKeys(name, cmd)
			}
			return tmuxctl.SwitchTo(name)
		}
	}

	// Bare name lookup (strip icon then try matching)
	bareName := icons.StripIcon(name)
	for _, s := range sessions {
		if s.BareName == bareName {
			displayName := s.DisplayName
			if err := tmuxctl.NewSession(displayName, s.Path); err != nil {
				return err
			}
			cmd := s.StartupCommand
			if cmdOverride != "" {
				cmd = cmdOverride
			}
			if cmd != "" {
				tmuxctl.SendKeys(displayName, cmd)
			}
			return tmuxctl.SwitchTo(displayName)
		}
	}

	// Treat as directory path
	dir := name
	if strings.HasPrefix(dir, "~/") {
		dir = filepath.Join(os.Getenv("HOME"), dir[2:])
	}
	sessionName := filepath.Base(dir)
	if err := tmuxctl.NewSession(sessionName, dir); err != nil {
		return err
	}
	if cmdOverride != "" {
		tmuxctl.SendKeys(sessionName, cmdOverride)
	}
	return tmuxctl.SwitchTo(sessionName)
}
