package icons

// Icon constants matching sesh/icons.sh.
// Unicode code points encoded as Go string literals.
const (
	Tool             = "\U000F1616" // 󱘖
	Config           = "\U000F1064" // 󱁤
	Project          = "\U0000E7C5" //
	Worktree         = "\U000F001C" // 󰀜
	WorktreeProject  = "\U000F1064" // 󱁤 (same as Config)
)

// AllIcons returns every known icon string for stripping purposes.
func AllIcons() []string {
	return []string{Tool, Config, Project, Worktree, WorktreeProject}
}

// ForFile maps a TOML filename to its icon category.
func ForFile(filename string) string {
	switch filename {
	case "tools.toml":
		return Tool
	case "config.toml":
		return Config
	case "worktrees.toml":
		return "" // sentinel: handled by ForWorktreeName
	default:
		return Project
	}
}

// ForWorktreeName returns the appropriate icon for a worktree session name.
// Names containing "/" get the Worktree icon; others get WorktreeProject.
func ForWorktreeName(name string) string {
	for i := 0; i < len(name); i++ {
		if name[i] == '/' {
			return Worktree
		}
	}
	return WorktreeProject
}

// StripIcon removes a leading icon + space prefix from a session name.
// Returns the bare name without any icon prefix.
func StripIcon(name string) string {
	for _, icon := range AllIcons() {
		prefix := icon + " "
		if len(name) >= len(prefix) && name[:len(prefix)] == prefix {
			return name[len(prefix):]
		}
	}
	return name
}
