package picker

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"drem-sx/internal/colorscheme"
	"drem-sx/internal/config"
)

// Run launches fzf with the given initial input and picker config.
// Returns the selected ORIGINAL column value, or empty string if cancelled.
func Run(initialInput string, cfg config.PickerConfig) (string, error) {
	self, err := os.Executable()
	if err != nil {
		return "", fmt.Errorf("resolve executable: %w", err)
	}

	// Build reload commands using self-referencing binary
	reloadAll := fmt.Sprintf("%s list -t -c -z --tree", self)
	reloadTmux := fmt.Sprintf("%s list -t --tree", self)
	reloadConfig := fmt.Sprintf("%s list -c --tree", self)
	reloadZoxide := fmt.Sprintf("%s list -z --tree", self)
	reloadWorktrees := fmt.Sprintf("%s list -t --tree --worktrees", self)
	reloadFind := fmt.Sprintf("%s list -f --tree", self)

	args := []string{
		"--tmux", fmt.Sprintf("center,%s", cfg.PopupSize),
		"--no-sort", "--ansi",
		"--border-label", cfg.BorderLabel,
		"--prompt", cfg.Prompt,
		"--delimiter", "\t",
		"--with-nth", "2",
		"--accept-nth", "1",
		"--header", "  ^a all ^t tmux ^g configs ^x zoxide ^w worktrees ^d tmux kill ^f find ^e fold M-e unfold",
		"--bind", "tab:down,btab:up",
		"--bind", fmt.Sprintf("ctrl-a:change-prompt(%s)+reload(%s)", cfg.Prompt, reloadAll),
		"--bind", fmt.Sprintf("ctrl-t:change-prompt(🪟  )+reload(%s)", reloadTmux),
		"--bind", fmt.Sprintf("ctrl-g:change-prompt(⚙️  )+reload(%s)", reloadConfig),
		"--bind", fmt.Sprintf("ctrl-x:change-prompt(📁  )+reload(%s)", reloadZoxide),
		"--bind", fmt.Sprintf("ctrl-w:change-prompt(  )+reload(%s)", reloadWorktrees),
		"--bind", fmt.Sprintf("ctrl-f:change-prompt(🔎  )+reload(%s)", reloadFind),
		"--bind", fmt.Sprintf("ctrl-d:execute(%s kill {1})+change-prompt(%s)+reload(%s)", self, cfg.Prompt, reloadAll),
		"--bind", fmt.Sprintf("ctrl-e:execute-silent(%s fold {1})+change-prompt(%s)+reload(%s)", self, cfg.Prompt, reloadAll),
		"--bind", fmt.Sprintf("alt-e:execute-silent(%s unfold-all)+change-prompt(%s)+reload(%s)", self, cfg.Prompt, reloadAll),
		"--preview-window", cfg.PreviewWindow,
		"--preview", fmt.Sprintf("%s preview {1}", self),
	}

	if c := resolveColor(cfg); c != "" {
		args = append(args, "--color="+c)
	}

	cmd := exec.Command("fzf", args...)
	cmd.Stdin = strings.NewReader(initialInput)
	cmd.Stderr = os.Stderr

	out, err := cmd.Output()
	if err != nil {
		// fzf returns exit code 130 on cancel
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 130 {
			return "", nil
		}
		// exit code 1 = no match
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 1 {
			return "", nil
		}
		return "", err
	}

	return strings.TrimSpace(string(out)), nil
}

// resolveColor returns the fzf --color value string.
// Priority: raw SESH_COLOR > named SESH_COLOR_SCHEME > empty.
func resolveColor(cfg config.PickerConfig) string {
	if cfg.Color != "" {
		return cfg.Color
	}
	if cfg.ColorScheme != "" {
		if s := colorscheme.Lookup(cfg.ColorScheme); s != nil {
			return s.FzfColorString()
		}
	}
	return ""
}
