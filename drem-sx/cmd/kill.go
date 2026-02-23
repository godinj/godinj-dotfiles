package cmd

import (
	"fmt"

	"drem-sx/internal/tmuxctl"
)

// Kill implements `drem-sx kill <name>`.
func Kill(args []string) error {
	if len(args) < 1 {
		return fmt.Errorf("usage: drem-sx kill <name>")
	}
	name := args[0]
	return tmuxctl.KillSession(name)
}
