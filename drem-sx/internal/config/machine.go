package config

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"
)

// PickerConfig holds machine-specific fzf picker settings.
type PickerConfig struct {
	BorderLabel   string
	Prompt        string
	PopupSize     string
	PreviewWindow string
	Color         string
}

// DefaultPickerConfig returns the default picker settings.
func DefaultPickerConfig() PickerConfig {
	return PickerConfig{
		BorderLabel:   " sesh ",
		Prompt:        "⚡  ",
		PopupSize:     "80%,70%",
		PreviewWindow: "right:75%",
	}
}

// MachineName reads the machine profile name from dotfilesDir/.machine.
func MachineName(dotfilesDir string) string {
	data, err := os.ReadFile(filepath.Join(dotfilesDir, ".machine"))
	if err != nil {
		return "default"
	}
	name := strings.TrimSpace(string(data))
	// Skip comment lines
	for _, line := range strings.Split(name, "\n") {
		line = strings.TrimSpace(line)
		if line != "" && !strings.HasPrefix(line, "#") {
			name = line
			break
		}
	}
	if name == "" {
		return "default"
	}
	// Verify the machine directory exists
	machineDir := filepath.Join(dotfilesDir, "machines", name)
	if _, err := os.Stat(machineDir); os.IsNotExist(err) {
		return "default"
	}
	return name
}

// LoadPickerConfig reads machine-specific picker settings from picker.sh.
// The file is parsed as simple KEY=VALUE (shell variable assignments).
func LoadPickerConfig(dotfilesDir, machineName string) PickerConfig {
	cfg := DefaultPickerConfig()

	pickerFile := filepath.Join(dotfilesDir, "machines", machineName, "sesh", "picker.sh")
	f, err := os.Open(pickerFile)
	if err != nil {
		return cfg
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, val, ok := parseShellAssignment(line)
		if !ok {
			continue
		}
		switch key {
		case "SESH_BORDER_LABEL":
			cfg.BorderLabel = val
		case "SESH_PROMPT":
			cfg.Prompt = val
		case "SESH_POPUP_SIZE":
			cfg.PopupSize = val
		case "SESH_PREVIEW_WINDOW":
			cfg.PreviewWindow = val
		case "SESH_COLOR":
			cfg.Color = val
		}
	}
	return cfg
}

// parseShellAssignment parses a line like KEY="value" or KEY=value.
func parseShellAssignment(line string) (key, val string, ok bool) {
	eq := strings.IndexByte(line, '=')
	if eq < 1 {
		return "", "", false
	}
	key = strings.TrimSpace(line[:eq])
	val = strings.TrimSpace(line[eq+1:])
	// Remove surrounding quotes
	if len(val) >= 2 && val[0] == '"' && val[len(val)-1] == '"' {
		val = val[1 : len(val)-1]
	}
	return key, val, true
}
