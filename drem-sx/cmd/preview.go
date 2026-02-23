package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"drem-sx/internal/config"
	"drem-sx/internal/icons"
	"drem-sx/internal/tmuxctl"
)

// Preview implements `drem-sx preview <name>`.
func Preview(args []string) error {
	if len(args) < 1 {
		return fmt.Errorf("usage: drem-sx preview <name>")
	}
	name := args[0]

	dotfilesDir, err := config.DotfilesDir()
	if err != nil {
		return err
	}
	machineName := config.MachineName(dotfilesDir)

	// 1. Check config for preview_command
	sessions, _ := config.Load(dotfilesDir, machineName)
	bareName := icons.StripIcon(name)
	for _, s := range sessions {
		if s.DisplayName == name || s.BareName == bareName {
			if s.PreviewCommand != "" {
				cmd := exec.Command("sh", "-c", s.PreviewCommand)
				cmd.Stdout = os.Stdout
				cmd.Stderr = os.Stderr
				return cmd.Run()
			}
			break
		}
	}

	// 2. Active tmux session → capture pane
	if tmuxctl.SessionExists(name) {
		out, err := tmuxctl.CapturePane(name)
		if err == nil {
			fmt.Print(out)
			return nil
		}
	}

	// 3. Directory path → ls
	dir := name
	if strings.HasPrefix(dir, "~/") {
		dir = os.Getenv("HOME") + dir[1:]
	}
	if info, err := os.Stat(dir); err == nil && info.IsDir() {
		cmd := exec.Command("ls", "-la", dir)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}

	fmt.Printf("No preview available for %s\n", name)
	return nil
}
