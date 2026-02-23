package main

import (
	"fmt"
	"os"

	"drem-sx/cmd"
)

func main() {
	subcmd := "pick"
	if len(os.Args) > 1 {
		subcmd = os.Args[1]
	}

	var err error
	switch subcmd {
	case "pick":
		err = cmd.Pick()
	case "list":
		err = cmd.List(os.Args[2:])
	case "connect":
		err = cmd.Connect(os.Args[2:])
	case "preview":
		err = cmd.Preview(os.Args[2:])
	case "fold":
		err = cmd.Fold(os.Args[2:])
	case "unfold-all":
		err = cmd.UnfoldAll()
	case "kill":
		err = cmd.Kill(os.Args[2:])
	case "promote":
		err = cmd.Promote(os.Args[2:])
	default:
		fmt.Fprintf(os.Stderr, "drem-sx: unknown command %q\n", subcmd)
		fmt.Fprintf(os.Stderr, "Usage: drem-sx [pick|list|connect|preview|fold|unfold-all|kill|promote]\n")
		os.Exit(1)
	}

	if err != nil {
		fmt.Fprintf(os.Stderr, "drem-sx %s: %v\n", subcmd, err)
		os.Exit(1)
	}
}
