package cmd

import "drem-sx/internal/fold"

// UnfoldAll implements `drem-sx unfold-all`.
func UnfoldAll() error {
	foldPath := fold.DefaultPath()
	state := fold.Load(foldPath)
	return state.ExpandAll()
}
