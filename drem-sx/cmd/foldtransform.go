package cmd

import (
	"fmt"
	"os"
	"strings"

	"drem-sx/internal/config"
	"drem-sx/internal/fold"
	"drem-sx/internal/icons"
	"drem-sx/internal/session"
	"drem-sx/internal/tree"
)

// FoldTransform implements `drem-sx fold-transform <name>`.
// Used as an fzf transform action: toggles fold state, then outputs fzf
// actions to reload the list and position the cursor on the parent project.
func FoldTransform(args []string) error {
	if len(args) < 1 {
		return fmt.Errorf("usage: drem-sx fold-transform <name>")
	}
	name := args[0]

	// Strip icon prefix to get bare name
	bareName := icons.StripIcon(name)

	// Derive parent: prefix before first "/"
	parent := bareName
	if idx := strings.Index(bareName, "/"); idx > 0 {
		parent = bareName[:idx]
	}

	if parent == "" {
		return nil
	}

	// Toggle fold state
	foldPath := fold.DefaultPath()
	state := fold.Load(foldPath)
	if err := state.Toggle(parent); err != nil {
		return err
	}

	self, err := os.Executable()
	if err != nil {
		return fmt.Errorf("resolve executable: %w", err)
	}

	// Load picker config to get the prompt
	dotfilesDir, err := config.DotfilesDir()
	if err != nil {
		return err
	}
	machineName := config.MachineName(dotfilesDir)
	pickerCfg := config.LoadPickerConfig(dotfilesDir, machineName)

	// Load sessions and format tree to find parent position
	configSessions, err := config.Load(dotfilesDir, machineName)
	if err != nil {
		return err
	}
	tmuxEntries, _ := session.ListTmux()
	zoxideEntries, _ := session.ListZoxide()
	entries := session.Merge(configSessions, tmuxEntries, zoxideEntries, nil)

	// Re-read fold state (we just wrote it)
	state = fold.Load(foldPath)
	lines := tree.Format(entries, state, nil)

	pos := tree.FindPos(lines, parent)

	reloadCmd := fmt.Sprintf("%s list -t -c -z --tree", self)
	if pos > 0 {
		fmt.Printf("reload-sync(%s)+change-prompt(%s)+pos(%d)", reloadCmd, pickerCfg.Prompt, pos)
	} else {
		fmt.Printf("reload(%s)+change-prompt(%s)", reloadCmd, pickerCfg.Prompt)
	}

	return nil
}
