package cmd

import (
	"drem-sx/internal/colorscheme"
	"drem-sx/internal/config"
)

// resolveContentColors returns content colors from the machine's color scheme,
// falling back to defaults.
func resolveContentColors(dotfilesDir, machineName string) *colorscheme.ContentColors {
	if dotfilesDir == "" {
		c := colorscheme.DefaultContentColors()
		return &c
	}
	pickerCfg := config.LoadPickerConfig(dotfilesDir, machineName)
	if pickerCfg.ColorScheme != "" {
		if s := colorscheme.Lookup(pickerCfg.ColorScheme); s != nil {
			return &s.Content
		}
	}
	c := colorscheme.DefaultContentColors()
	return &c
}
