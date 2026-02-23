package gitstatus

import (
	"os/exec"
	"strings"
)

// Checker reports whether a directory has uncommitted git changes.
type Checker interface {
	IsDirty(path string) bool
}

// GitChecker implements Checker using git status --porcelain.
type GitChecker struct{}

func (GitChecker) IsDirty(path string) bool {
	if path == "" {
		return false
	}
	out, err := exec.Command("git", "-C", path, "status", "--porcelain").Output()
	if err != nil {
		return false
	}
	return strings.TrimSpace(string(out)) != ""
}
