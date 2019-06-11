package main

import (
	"strings"
)

func calculateScore(words []string, dict map[string]struct{}) float64 {
	var good int
	for _, word := range words {
		word = strings.ToLower(word)
		_, exists := dict[word]
		if exists {
			good++
		}
	}
	score := float64(good) / (float64(len(words)) + 1)
	return score
}
