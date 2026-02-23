package cmd

import (
	"fmt"
	"os"
	"sync"

	"drem-sx/internal/config"
	"drem-sx/internal/fold"
	"drem-sx/internal/gitstatus"
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

	// Default: -t -c if no source flags given (zoxide hidden by default)
	if !useTmux && !useConfig && !useZoxide && !useFind {
		useTmux = true
		useConfig = true
	}

	var configSessions []config.ResolvedSession
	var tmuxEntries, zoxideEntries, findEntries []session.Entry
	var dotfilesDir, machineName string

	if useConfig || useTmux {
		var err error
		dotfilesDir, err = config.DotfilesDir()
		if err != nil {
			return err
		}
		machineName = config.MachineName(dotfilesDir)
		sessions, err := config.Load(dotfilesDir, machineName)
		if err != nil {
			return err
		}
		if useConfig {
			configSessions = sessions
		}
	}

	// Fetch tmux/zoxide/find concurrently
	var wg sync.WaitGroup
	if useTmux {
		wg.Add(1)
		go func() {
			defer wg.Done()
			tmuxEntries, _ = session.ListTmux()
		}()
	}
	if useZoxide {
		wg.Add(1)
		go func() {
			defer wg.Done()
			zoxideEntries, _ = session.ListZoxide()
		}()
	}
	if useFind {
		wg.Add(1)
		go func() {
			defer wg.Done()
			findEntries, _ = session.ListFind()
		}()
	}
	wg.Wait()

	entries := session.Merge(configSessions, tmuxEntries, zoxideEntries, findEntries)

	// Annotate worktree entries with dirty/inactive status
	session.Annotate(entries, gitstatus.GitChecker{}, session.NewCachedTmuxChecker(tmuxEntries))

	if showWorktree {
		entries = session.FilterWorktrees(entries)
	}

	// Resolve content colors
	colors := resolveContentColors(dotfilesDir, machineName)

	if showTree {
		foldPath := fold.DefaultPath()
		state := fold.Load(foldPath)
		lines := tree.Format(entries, state, colors)
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
