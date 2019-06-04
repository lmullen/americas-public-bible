package main

import "testing"

func Test_countWords(t *testing.T) {
	type args struct {
		s string
	}
	tests := []struct {
		name string
		args args
		want int
	}{{
		"a brief sentence",
		args{"How many words do I have?"},
		6,
	}, {
		"longer sentence",
		args{"This has an isn't in it. Harder to count words; I do declare."},
		13,
	}}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := countWords(tt.args.s); got != tt.want {
				t.Errorf("countWords() = %v, want %v", got, tt.want)
			}
		})
	}
}
