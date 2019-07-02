package main

import (
	"log"
)

// Each job is a struct with the doc_id and text
func worker(jobs <-chan doc) {
	defer wg.Done()
	for d := range jobs {
		bar.Increment() // Just do this at the beginning rather than at each failure point as well
		score := calculateScore(d.text)
		_, err := db.Exec("UPDATE chronam_pages SET ocr_sq = $1 WHERE doc_id = $2",
			score, d.docID)
		if err != nil {
			log.Printf("Failed to update score for %s in database.\n", d.docID)
			log.Println(err)
			continue
		}
	}
}
