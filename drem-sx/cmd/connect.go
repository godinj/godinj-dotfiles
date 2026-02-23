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

	// 1. If tmux session exists → switch to it
	if tmuxctl.SessionExists(name) {
		return tmuxctl.SwitchTo(name)
	}

	// 2. Look up by display name in config
	sessions, err := config.Load(dotfilesDir, machineName)
	if err != nil {
		return err
	}

	for _, s := range sessions {
		if s.DisplayName == name || s.BareName == name {
			sessionName := s.DisplayName
			if err := tmuxctl.NewSession(sessionName, s.Path); err != nil {
				return err
			}
			cmd := s.StartupCommand
			if *cmdFlag != "" {
				cmd = *cmdFlag
			}
			if cmd != "" {
				tmuxctl.SendKeys(sessionName, cmd)
			}
			return tmuxctl.SwitchTo(sessionName)
		}
	}

	// 3. Try matching with icon prefix applied
	bareName := icons.StripIcon(name)
	for _, s := range sessions {
		if s.BareName == bareName {
			sessionName := s.DisplayName
			if err := tmuxctl.NewSession(sessionName, s.Path); err != nil {
				return err
			}
			cmd := s.StartupCommand
			if *cmdFlag != "" {
				cmd = *cmdFlag
			}
			if cmd != "" {
				tmuxctl.SendKeys(sessionName, cmd)
			}
			return tmuxctl.SwitchTo(sessionName)
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
