package ansi

import (
	"fmt"
	"strconv"
	"strings"
)

// Fg wraps text in 24-bit ANSI foreground color escape codes.
// hex should be a "#RRGGBB" string. Returns text unchanged if hex is empty or invalid.
func Fg(text, hex string) string {
	if hex == "" {
		return text
	}
	r, g, b, ok := parseHex(hex)
	if !ok {
		return text
	}
	return fmt.Sprintf("\033[38;2;%d;%d;%dm%s\033[0m", r, g, b, text)
}

func parseHex(hex string) (r, g, b uint8, ok bool) {
	hex = strings.TrimPrefix(hex, "#")
	if len(hex) != 6 {
		return 0, 0, 0, false
	}
	rv, err := strconv.ParseUint(hex[0:2], 16, 8)
	if err != nil {
		return 0, 0, 0, false
	}
	gv, err := strconv.ParseUint(hex[2:4], 16, 8)
	if err != nil {
		return 0, 0, 0, false
	}
	bv, err := strconv.ParseUint(hex[4:6], 16, 8)
	if err != nil {
		return 0, 0, 0, false
	}
	return uint8(rv), uint8(gv), uint8(bv), true
}
