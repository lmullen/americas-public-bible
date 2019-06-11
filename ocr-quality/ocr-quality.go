// The OCR quality script creates a simple numeric measure of the quality of the
// OCR in a text document, by calculating this ratio:
//
// words that appear in a dictionary / all words + 1
//
// See the explanation here: http://doi.acm.org/10.1145/2595188.2595214
package main

import (
	"fmt"
	"github.com/euskadi31/go-tokenizer"
	"io/ioutil"
	"log"
	"strings"
)

func main() {

	// Turn the text file of words into a map which can be used to check for the
	// existance of a word. The words are lowercase.
	dictBytes, err := ioutil.ReadFile("words.txt")
	if err != nil {
		log.Fatal(err)
	}
	dictSlice := strings.Split(string(dictBytes), "\n")
	dict := make(map[string]struct{}, len(dictSlice))
	for _, d := range dictSlice {
		d = strings.ToLower(d)
		dict[d] = struct{}{}
	}

	t := tokenizer.New()

	keeperBytes, _ := ioutil.ReadFile("test-keep.txt")
	keeperWords := t.Tokenize(string(keeperBytes))

	rejectBytes, _ := ioutil.ReadFile("test-reject.txt")
	rejectWords := t.Tokenize(string(rejectBytes))
	fmt.Println(calculateScore(rejectWords, dict))
	fmt.Println(calculateScore(keeperWords, dict))

}
