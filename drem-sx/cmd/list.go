package cmd

import (
	"fmt"
	"os"

	"drem-sx/internal/config"
	"drem-sx/internal/fold"
	"drem-sx/internal/session"
	"drem-sx/internal/tree"
)

// List implements `drem-sx list [-t] [-c] [-z] [-f] [--tree] [--worktrees]`.
func List(args []string) error {
	var (
		useTmux      bool
		useConfig    bool
		useZoxide    bool
		useFind      bool
		showTree     bool
		showWorktree bool
	)

	for _, a := range args {
		switch a {
		case "-t":
			useTmux = true
		case "-c":
			useConfig = true
		case "-z":
			useZoxide = true
		case "-f":
			useFind = true
		case "--tree":
			showTree = true
		case "--worktrees":
			showWorktree = true
		}
	}

	// Default: -t -c -z if no source flags given
	if !useTmux && !useConfig && !useZoxide && !useFind {
		useTmux = true
		useConfig = true
		useZoxide = true
	}

	var configSessions []config.ResolvedSession
	var tmuxEntries, zoxideEntries, findEntries []session.Entry

	if useConfig || useTmux {
		dotfilesDir, err := config.DotfilesDir()
		if err != nil {
			return err
		}
		machineName := config.MachineName(dotfilesDir)
		sessions, err := config.Load(dotfilesDir, machineName)
		if err != nil {
			return err
		}
		if useConfig {
			configSessions = sessions
		}
	}

	if useTmux {
		var err error
		tmuxEntries, err = session.ListTmux()
		if err != nil {
			return err
		}
	}

	if useZoxide {
		var err error
		zoxideEntries, err = session.ListZoxide()
		if err != nil {
			return err
		}
	}

	if useFind {
		var err error
		findEntries, err = session.ListFind()
		if err != nil {
			return err
		}
	}

	entries := session.Merge(configSessions, tmuxEntries, zoxideEntries, findEntries)

	if showWorktree {
		entries = session.FilterWorktrees(entries)
	}

	if showTree {
		foldPath := fold.DefaultPath()
		state := fold.Load(foldPath)
		lines := tree.Format(entries, state)
		fmt.Print(tree.FormatString(lines))
		if len(lines) > 0 {
			fmt.Println()
		}
	} else {
		for _, e := range entries {
			fmt.Fprintln(os.Stdout, e.DisplayName)
		}
	}

	return nil
}
