package main

import (
	"fmt"
	"os"

	"drem-sx/cmd"
	"drem-sx/internal/tmuxctl"
)

func main() {
	args := os.Args[1:]

	// Parse global -L <socket> flag before subcommand.
	if len(args) >= 2 && args[0] == "-L" {
		tmuxctl.Socket = args[1]
		args = args[2:]
	}

	subcmd := "pick"
	if len(args) > 0 {
		subcmd = args[0]
		args = args[1:]
	}

	var err error
	switch subcmd {
	case "pick":
		err = cmd.Pick()
	case "list":
		err = cmd.List(args)
	case "connect":
		err = cmd.Connect(args)
	case "preview":
		err = cmd.Preview(args)
	case "fold":
		err = cmd.Fold(args)
	case "fold-transform":
		err = cmd.FoldTransform(args)
	case "unfold-all":
		err = cmd.UnfoldAll()
	case "unfold-all-transform":
		err = cmd.UnfoldAllTransform()
	case "kill":
		err = cmd.Kill(args)
	case "promote":
		err = cmd.Promote(args)
	default:
		fmt.Fprintf(os.Stderr, "drem-sx: unknown command %q\n", subcmd)
		fmt.Fprintf(os.Stderr, "Usage: drem-sx [-L socket] [pick|list|connect|preview|fold|unfold-all|kill|promote]\n")
		os.Exit(1)
	}

	if err != nil {
		fmt.Fprintf(os.Stderr, "drem-sx %s: %v\n", subcmd, err)
		os.Exit(1)
	}
}
