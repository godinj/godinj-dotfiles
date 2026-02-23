package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"drem-sx/internal/config"
)

// Promote implements `drem-sx promote [branch]`.
// Must be run from inside a git worktree.
func Promote(args []string) error {
	dotfilesDir, err := config.DotfilesDir()
	if err != nil {
		return err
	}
	machineName := config.MachineName(dotfilesDir)

	// Find bare repo root
	out, err := exec.Command("git", "rev-parse", "--git-common-dir").Output()
	if err != nil {
		return fmt.Errorf("not inside a git repository: %w", err)
	}
	gitCommonDir := strings.TrimSpace(string(out))
	bareRoot, err := filepath.Abs(gitCommonDir)
	if err != nil {
		return err
	}

	// Extract project name (basename without .git)
	projectName := filepath.Base(bareRoot)
	projectName = strings.TrimSuffix(projectName, ".git")

	// Determine branch
	var branch string
	if len(args) > 0 {
		branch = args[0]
	} else {
		// Get current branch
		out, err := exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD").Output()
		if err != nil {
			return fmt.Errorf("cannot determine current branch: %w", err)
		}
		branch = strings.TrimSpace(string(out))
	}

	// Get default branch
	defaultBranch := getDefaultBranch()

	// Generate bare name
	var bareName string
	if branch == defaultBranch {
		bareName = projectName
	} else {
		bareName = projectName + "/" + branch
	}

	// Determine worktree path
	wtPath := filepath.Join(bareRoot, branch)

	// Target TOML file
	worktreesFile := filepath.Join(dotfilesDir, "machines", machineName, "sesh", "sessions", "worktrees.toml")

	// Check if already promoted
	if fileContainsSession(worktreesFile, bareName) {
		fmt.Printf("Session %q already in %s\n", bareName, worktreesFile)
		return nil
	}

	// Ensure directory exists
	if err := os.MkdirAll(filepath.Dir(worktreesFile), 0o755); err != nil {
		return err
	}

	// Append session entry
	f, err := os.OpenFile(worktreesFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()

	// Add newline before entry if file is non-empty
	info, _ := f.Stat()
	if info.Size() > 0 {
		f.WriteString("\n")
	}

	entry := fmt.Sprintf("[[session]]\nname = %q\npath = %q\nstartup_command = \"wt connect\"\n",
		bareName, tildeHome(wtPath))
	if _, err := f.WriteString(entry); err != nil {
		return err
	}

	fmt.Printf("Promoted %q to %s\n", bareName, worktreesFile)
	return nil
}

func getDefaultBranch() string {
	out, err := exec.Command("git", "symbolic-ref", "--short", "HEAD").Output()
	if err != nil {
		return "main"
	}
	return strings.TrimSpace(string(out))
}

func fileContainsSession(path, name string) bool {
	data, err := os.ReadFile(path)
	if err != nil {
		return false
	}
	// Simple check: look for name = "bareName" in file
	return strings.Contains(string(data), fmt.Sprintf("name = %q", name))
}

func tildeHome(path string) string {
	home := os.Getenv("HOME")
	if strings.HasPrefix(path, home+"/") {
		return "~/" + path[len(home)+1:]
	}
	if path == home {
		return "~"
	}
	return path
}
