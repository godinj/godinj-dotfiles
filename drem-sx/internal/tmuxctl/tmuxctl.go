package tmuxctl

import (
	"fmt"
	"os"
	"os/exec"
)

// Socket is the tmux socket name (-L flag). When empty, tmux uses its default.
var Socket string

// tmuxCmd builds an exec.Cmd with the socket flag prepended when set.
func tmuxCmd(args ...string) *exec.Cmd {
	if Socket != "" {
		args = append([]string{"-L", Socket}, args...)
	}
	return exec.Command("tmux", args...)
}

// ListSessions returns the raw output of tmux list-sessions.
func ListSessions() ([]byte, error) {
	return tmuxCmd("list-sessions", "-F", "#{session_name}").Output()
}

// SessionExists checks if a tmux session with the given name exists.
func SessionExists(name string) bool {
	return tmuxCmd("has-session", "-t", "="+name).Run() == nil
}

// NewSession creates a new detached tmux session.
func NewSession(name, dir string) error {
	args := []string{"new-session", "-d", "-s", name}
	if dir != "" {
		args = append(args, "-c", dir)
	}
	cmd := tmuxCmd(args...)
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("new-session %q: %s", name, trimOutput(out, err))
	}
	return nil
}

// SwitchTo switches to or attaches to the named tmux session.
func SwitchTo(name string) error {
	if IsInsideTmux() {
		return tmuxCmd("switch-client", "-t", "="+name).Run()
	}
	cmd := tmuxCmd("attach-session", "-t", "="+name)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// SendKeys sends keys to the named tmux session.
func SendKeys(session, keys string) error {
	cmd := tmuxCmd("send-keys", "-t", session+":0", keys, "Enter")
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("send-keys %q: %s", session, trimOutput(out, err))
	}
	return nil
}

// KillSession kills the named tmux session.
func KillSession(name string) error {
	cmd := tmuxCmd("kill-session", "-t", "="+name)
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("kill-session %q: %s", name, trimOutput(out, err))
	}
	return nil
}

// IsInsideTmux checks whether we're running inside a tmux session.
func IsInsideTmux() bool {
	return os.Getenv("TMUX") != ""
}

// CapturePane captures the visible content of a tmux pane.
func CapturePane(session string) (string, error) {
	out, err := tmuxCmd("capture-pane", "-t", "="+session, "-p", "-e").Output()
	if err != nil {
		return "", fmt.Errorf("capture-pane %q: %w", session, err)
	}
	return string(out), nil
}

// trimOutput returns the tmux stderr/stdout message, falling back to the error string.
func trimOutput(out []byte, err error) string {
	s := string(out)
	if len(s) > 0 {
		// Remove trailing newline from tmux output
		if s[len(s)-1] == '\n' {
			s = s[:len(s)-1]
		}
		return s
	}
	return err.Error()
}
