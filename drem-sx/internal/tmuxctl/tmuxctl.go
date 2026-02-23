package tmuxctl

import (
	"os"
	"os/exec"
)

// SessionExists checks if a tmux session with the given name exists.
func SessionExists(name string) bool {
	return exec.Command("tmux", "has-session", "-t", "="+name).Run() == nil
}

// NewSession creates a new detached tmux session.
func NewSession(name, dir string) error {
	args := []string{"new-session", "-d", "-s", name}
	if dir != "" {
		args = append(args, "-c", dir)
	}
	return exec.Command("tmux", args...).Run()
}

// SwitchTo switches to or attaches to the named tmux session.
func SwitchTo(name string) error {
	if IsInsideTmux() {
		return exec.Command("tmux", "switch-client", "-t", "="+name).Run()
	}
	cmd := exec.Command("tmux", "attach-session", "-t", "="+name)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// SendKeys sends keys to the named tmux session.
func SendKeys(session, keys string) error {
	return exec.Command("tmux", "send-keys", "-t", "="+session, keys, "Enter").Run()
}

// KillSession kills the named tmux session.
func KillSession(name string) error {
	return exec.Command("tmux", "kill-session", "-t", "="+name).Run()
}

// IsInsideTmux checks whether we're running inside a tmux session.
func IsInsideTmux() bool {
	return os.Getenv("TMUX") != ""
}

// CapturePane captures the visible content of a tmux pane.
func CapturePane(session string) (string, error) {
	out, err := exec.Command("tmux", "capture-pane", "-t", "="+session, "-p", "-e").Output()
	if err != nil {
		return "", err
	}
	return string(out), nil
}
