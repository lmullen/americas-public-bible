// The OCR quality script creates a simple numeric measure of the quality of the
// OCR in a text document, by calculating this ratio:
//
// words that appear in a dictionary / all words + 1
//
// See the explanation here: http://doi.acm.org/10.1145/2595188.2595214
package main

import (
	"database/sql"
	"fmt"
	"github.com/euskadi31/go-tokenizer"
	_ "github.com/lib/pq"
	"gopkg.in/cheggaaa/pb.v1"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"sync"
)

// WORKERS is how many workers to use at once
const WORKERS int = 200

// BUFFERSIZE is how many documents to keep in the queue at one time
const BUFFERSIZE int = 10000

// A document from the database
type doc struct {
	docID string
	text  string
}

// Global variables
var wg sync.WaitGroup
var db *sql.DB
var dict map[string]struct{}
var bar *pb.ProgressBar
var t tokenizer.Tokenizer

func main() {

	// Connect to the database
	constr := fmt.Sprintf("user=lmullen dbname=lmullen password=%s sslmode=disable host=%s", os.Getenv("DBPASS"), os.Getenv("DBHOST"))
	var err error
	db, err = sql.Open("postgres", constr)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}

	var totalPages int
	err = db.QueryRow("SELECT COUNT(*) FROM chronam_pages WHERE ocr_sq IS NULL;").Scan(&totalPages)
	if err != nil {
		log.Fatal(err)
	}

	// Turn the text file of words into a map which can be used to check for the
	// existance of a word. The words are lowercase.
	dictBytes, err := ioutil.ReadFile("words.txt")
	if err != nil {
		log.Fatal(err)
	}
	dictSlice := strings.Split(string(dictBytes), "\n")
	dict = make(map[string]struct{}, len(dictSlice))
	for _, d := range dictSlice {
		d = strings.ToLower(d)
		dict[d] = struct{}{}
	}

	// Create the jobs channel which will hold doc_ids and texts
	jobs := make(chan doc, BUFFERSIZE)

	t = tokenizer.New()

	bar = pb.New(totalPages)
	bar.ShowTimeLeft = true

	// Start the workers which will begin to pull jobs off the channel
	for w := 1; w <= WORKERS; w++ {
		wg.Add(1)
		go worker(jobs)
	}

	bar.Start()

	// Query for documents which don't have an OCR score and add them to the jobs channel
	rows, err := db.Query("SELECT doc_id, text FROM chronam_pages WHERE ocr_sq IS NULL LIMIT 20;")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()
	var row doc
	for rows.Next() {
		err = rows.Scan(&row.docID, &row.text)
		if err != nil {
			log.Println(err)
			continue
		}
		jobs <- row
	}
	err = rows.Err()
	if err != nil {
		log.Println(err)
	}

	close(jobs)
	wg.Wait()
	bar.FinishPrint("Finished processing.")

}
