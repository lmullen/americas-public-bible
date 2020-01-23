package main

import (
	"strings"
)

func countWords(s string) int {
	return len(strings.Fields(s))
}
