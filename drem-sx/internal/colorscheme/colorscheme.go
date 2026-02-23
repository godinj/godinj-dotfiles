package colorscheme

import (
	"fmt"
	"sort"
	"strings"
)

// Scheme holds an fzf color scheme mapping slot names to hex values.
type Scheme struct {
	Name   string
	Colors map[string]string
}

// FzfColorString renders the scheme as an fzf --color value string
// with keys sorted for deterministic output.
func (s *Scheme) FzfColorString() string {
	keys := make([]string, 0, len(s.Colors))
	for k := range s.Colors {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	parts := make([]string, 0, len(keys))
	for _, k := range keys {
		parts = append(parts, fmt.Sprintf("%s:%s", k, s.Colors[k]))
	}
	return strings.Join(parts, ",")
}

var registry = map[string]*Scheme{
	"gruvbox": {
		Name: "gruvbox",
		Colors: map[string]string{
			"bg":         "#282828",
			"fg":         "#ebdbb2",
			"border":     "#d5c4a1",
			"header":     "#fabd2f",
			"prompt":     "#fabd2f",
			"pointer":    "#fb4934",
			"info":       "#b8bb26",
			"preview-bg": "#1d2021",
		},
	},
	"tokyonight": {
		Name: "tokyonight",
		Colors: map[string]string{
			"border":  "#7aa2f7",
			"header":  "#e0af68",
			"prompt":  "#e0af68",
			"pointer": "#f7768e",
			"info":    "#9ece6a",
		},
	},
	"kanagawa": {
		Name: "kanagawa",
		Colors: map[string]string{
			"bg":      "#1F1F1F",
			"fg":      "#F9E7C0",
			"border":  "#938AA9",
			"header":  "#FFAA44",
			"prompt":  "#FFAA44",
			"pointer": "#FF5D62",
			"info":    "#98BB6C",
		},
	},
	"rosepine": {
		Name: "rosepine",
		Colors: map[string]string{
			"bg":      "#232136",
			"fg":      "#e0def4",
			"border":  "#c4a7e7",
			"header":  "#f6c177",
			"prompt":  "#f6c177",
			"pointer": "#eb6f92",
			"info":    "#9ccfd8",
		},
	},
}

// Lookup returns the named scheme or nil if not found. Case-insensitive.
func Lookup(name string) *Scheme {
	return registry[strings.ToLower(name)]
}

// Names returns a sorted list of available scheme names.
func Names() []string {
	names := make([]string, 0, len(registry))
	for k := range registry {
		names = append(names, k)
	}
	sort.Strings(names)
	return names
}
