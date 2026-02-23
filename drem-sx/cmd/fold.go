package cmd

import (
	"fmt"
	"strings"

	"drem-sx/internal/fold"
	"drem-sx/internal/icons"
)

// Fold implements `drem-sx fold <name>`.
// Receives fzf's {1} (ORIGINAL column = icon-prefixed session name).
func Fold(args []string) error {
	if len(args) < 1 {
		return fmt.Errorf("usage: drem-sx fold <name>")
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

	foldPath := fold.DefaultPath()
	state := fold.Load(foldPath)
	return state.Toggle(parent)
}
