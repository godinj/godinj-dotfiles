package cmd

import (
	"fmt"

	"drem-sx/internal/config"
	"drem-sx/internal/fold"
)

// UnfoldAll implements `drem-sx unfold-all`.
func UnfoldAll() error {
	foldPath := fold.DefaultPath()
	state := fold.Load(foldPath)
	return state.ExpandAll()
}

// UnfoldAllTransform implements `drem-sx unfold-all-transform`.
// Used as an fzf transform action: expands all folds, builds the tree with
// annotations, writes cache, and outputs fzf reload from cache.
func UnfoldAllTransform() error {
	foldPath := fold.DefaultPath()
	state := fold.Load(foldPath)
	if err := state.ExpandAll(); err != nil {
		return err
	}

	dotfilesDir, err := config.DotfilesDir()
	if err != nil {
		return err
	}
	machineName := config.MachineName(dotfilesDir)
	pickerCfg := config.LoadPickerConfig(dotfilesDir, machineName)

	if _, err := buildAndCacheTree(dotfilesDir, machineName, foldPath); err != nil {
		return err
	}

	cachePath := fold.CachePath()
	fmt.Printf("reload(cat %s)+change-prompt(%s)", cachePath, pickerCfg.Prompt)
	return nil
}
