package tree

import (
	"drem-sx/internal/fold"
	"drem-sx/internal/icons"
	"drem-sx/internal/session"
	"fmt"
	"strings"
)

const (
	treeLastChild = "└── "
	treeMiddle    = "├── "
	foldedChar    = "▸"
	expandedChar  = "▾"
)

// Line is a single output line with original (for fzf {1}) and display (for fzf --with-nth=2).
type Line struct {
	Original string
	Display  string
}

// Format transforms a list of session entries into tree-structured lines.
// The output matches the AWK pipeline in sesh_tree_list.sh:
// - Children are emitted BEFORE their parent (fzf bottom-to-top)
// - Tree chars: └── for first/last child, ├── for middle children
// - Fold: collapsed parents show ▸ name [N], expanded show ▾ name
func Format(entries []session.Entry, foldState *fold.State) []Line {
	// Build index: bare name → entry index
	bareToIdx := make(map[string]int)
	for i, e := range entries {
		bareToIdx[e.BareName] = i
	}

	// Build parent-child relationships
	type childInfo struct {
		indices []int
	}
	// isChild[i] = parent's DisplayName if entry i is a child
	isChild := make(map[int]string)
	// childrenOf[displayName] = list of child indices
	childrenOf := make(map[string]*childInfo)

	for i, e := range entries {
		bn := e.BareName
		slashIdx := strings.Index(bn, "/")
		if slashIdx > 0 {
			parentBare := bn[:slashIdx]
			if pi, ok := bareToIdx[parentBare]; ok {
				parentDisplay := entries[pi].DisplayName
				isChild[i] = parentDisplay
				if childrenOf[parentDisplay] == nil {
					childrenOf[parentDisplay] = &childInfo{}
				}
				childrenOf[parentDisplay].indices = append(childrenOf[parentDisplay].indices, i)
			}
		}
	}

	var lines []Line
	emitted := make(map[int]bool)

	hasFoldFile := foldState != nil && foldState.HasFile()

	for i, e := range entries {
		if emitted[i] {
			continue
		}
		if _, ok := isChild[i]; ok {
			continue // Will be emitted before parent
		}

		ci := childrenOf[e.DisplayName]
		if ci != nil && len(ci.indices) > 0 {
			// Collect pending (non-emitted) children
			var pending []int
			for _, idx := range ci.indices {
				if !emitted[idx] {
					pending = append(pending, idx)
				}
			}

			parentIsFolded := foldState != nil && foldState.IsFolded(e.BareName)

			if parentIsFolded {
				// Collapsed: skip children, emit parent with ▸ and count
				for _, idx := range pending {
					emitted[idx] = true
				}
				emitted[i] = true
				display := fmt.Sprintf("%s %s [%d]", foldedChar, e.DisplayName, len(pending))
				lines = append(lines, Line{
					Original: e.DisplayName,
					Display:  display,
				})
			} else {
				// Expanded: emit children with tree chars (reversed order for fzf)
				for j := len(pending) - 1; j >= 0; j-- {
					idx := pending[j]
					emitted[idx] = true

					child := entries[idx]
					// Extract the session icon from child's display name
					childIcon := ""
					childBare := child.BareName
					displayName := child.DisplayName
					stripped := icons.StripIcon(displayName)
					if stripped != displayName {
						childIcon = displayName[:len(displayName)-len(stripped)-1]
					}

					// Extract branch name (after first "/" in bare name)
					branch := childBare
					if slashIdx := strings.Index(childBare, "/"); slashIdx >= 0 {
						branch = childBare[slashIdx+1:]
					}

					var tree string
					if j == 0 {
						tree = treeLastChild
					} else {
						tree = treeMiddle
					}

					display := fmt.Sprintf("   %s%s %s", tree, childIcon, branch)
					lines = append(lines, Line{
						Original: child.DisplayName,
						Display:  display,
					})
				}

				// Emit parent
				emitted[i] = true
				var display string
				if hasFoldFile {
					display = fmt.Sprintf("%s %s", expandedChar, e.DisplayName)
				} else {
					display = e.DisplayName
				}
				lines = append(lines, Line{
					Original: e.DisplayName,
					Display:  display,
				})
			}
		} else {
			// Standalone session
			emitted[i] = true
			lines = append(lines, Line{
				Original: e.DisplayName,
				Display:  e.DisplayName,
			})
		}
	}

	return lines
}

// FindPos returns the 1-indexed position (for fzf pos()) of the entry
// whose bare name matches the given name. Returns 0 if not found.
func FindPos(lines []Line, bareName string) int {
	for i, l := range lines {
		if icons.StripIcon(l.Original) == bareName {
			return i + 1
		}
	}
	return 0
}

// FormatString renders tree lines as tab-delimited ORIGINAL\tDISPLAY output.
func FormatString(lines []Line) string {
	var sb strings.Builder
	for i, l := range lines {
		if i > 0 {
			sb.WriteByte('\n')
		}
		sb.WriteString(l.Original)
		sb.WriteByte('\t')
		sb.WriteString(l.Display)
	}
	return sb.String()
}
