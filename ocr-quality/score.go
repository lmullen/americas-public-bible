package main

import (
	"strings"
)

func calculateScore(text string) float64 {
	var good int
	words := t.Tokenize(text)
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
