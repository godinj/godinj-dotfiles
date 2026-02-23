package cmd

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"drem-sx/internal/config"
	"drem-sx/internal/icons"
	"drem-sx/internal/tmuxctl"
)

// Connect implements `drem-sx connect [-c cmd] <name>`.
func Connect(args []string) error {
	fs := flag.NewFlagSet("connect", flag.ContinueOnError)
	cmdFlag := fs.String("c", "", "override startup command")
	if err := fs.Parse(args); err != nil {
		return err
	}

	if fs.NArg() < 1 {
		return fmt.Errorf("usage: drem-sx connect [-c cmd] <name>")
	}
	name := fs.Arg(0)

	dotfilesDir, err := config.DotfilesDir()
	if err != nil {
		return err
	}
	machineName := config.MachineName(dotfilesDir)

	// 1. If tmux session exists by exact name → switch to it
	if tmuxctl.SessionExists(name) {
		return tmuxctl.SwitchTo(name)
	}

	// 2. Look up by display name or bare name in config
	sessions, err := config.Load(dotfilesDir, machineName)
	if err != nil {
		return err
	}

	for _, s := range sessions {
		if s.DisplayName == name || s.BareName == name {
			return connectSession(s, *cmdFlag)
		}
	}

	// 3. Try matching with icon prefix stripped
	bareName := icons.StripIcon(name)
	for _, s := range sessions {
		if s.BareName == bareName {
			return connectSession(s, *cmdFlag)
		}
	}

	// 4. Treat as directory path
	dir := name
	if strings.HasPrefix(dir, "~/") {
		dir = filepath.Join(os.Getenv("HOME"), dir[2:])
	}
	sessionName := filepath.Base(dir)
	if err := tmuxctl.NewSession(sessionName, dir); err != nil {
		return err
	}
	if *cmdFlag != "" {
		tmuxctl.SendKeys(sessionName, *cmdFlag)
	}
	return tmuxctl.SwitchTo(sessionName)
}

// connectSession switches to an existing session or creates a new one from config.
func connectSession(s config.ResolvedSession, cmdOverride string) error {
	sessionName := s.DisplayName

	// If the session already exists (e.g. icon-prefixed name), just switch to it
	if tmuxctl.SessionExists(sessionName) {
		return tmuxctl.SwitchTo(sessionName)
	}

	if err := tmuxctl.NewSession(sessionName, s.Path); err != nil {
		return err
	}
	cmd := s.StartupCommand
	if cmdOverride != "" {
		cmd = cmdOverride
	}
	if cmd != "" {
		tmuxctl.SendKeys(sessionName, cmd)
	}
	return tmuxctl.SwitchTo(sessionName)
}
