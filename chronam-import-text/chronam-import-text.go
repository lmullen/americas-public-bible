package main

import (
	"database/sql"
	_ "github.com/lib/pq"
	"gopkg.in/cheggaaa/pb.v1"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// WORKERS is how many workers to use at once
const WORKERS int = 30

// BUFFERSIZE is how many files to keep in the queue at one time
const BUFFERSIZE int = 100000

// PAGESGUESS is how many pages we think there are for the progress bar
const PAGESGUESS int = 15006843

var wg sync.WaitGroup

// Each job is a string representing a path to an OCR text file on disk
func worker(jobs <-chan string, baseDir string, bar *pb.ProgressBar, db *sql.DB) {
	defer wg.Done()
	for path := range jobs {
		// Just increment the progress bar at the start instead of the end because
		// there are multiple failure possibilities and we dont need to include this
		// for each one.
		time.Sleep(1 * time.Second)
		bar.Increment()
		docid := getDocid(path, baseDir)

		// Check whether this docid exists. If it does skip the rest of the parsing,
		// especially reading in the file.
		var exists bool
		err := db.QueryRow("SELECT EXISTS (SELECT 1 FROM pages_test WHERE doc_id = $1)", docid).Scan(&exists)
		if err != nil {
			log.Printf("Failed to check if %s already is in the database.", docid)
			log.Println(err)
		}
		if exists {
			continue
		}
		lccn, date, page := getMetadata(docid)
		text, err := getText(path)
		if err != nil {
			log.Printf("Failed to read %s\n.", path)
			log.Println(err)
			continue
		}
		wordcount := countWords(text)
		_, err = db.Exec("INSERT INTO pages_test VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT DO NOTHING;",
			docid, lccn, date, page, wordcount, text)
		if err != nil {
			log.Printf("Failed to write %s to database.\n", docid)
			log.Println(err)
			continue
		}
	}
}

func main() {

	dataDir := os.Args[1]

	db, err := sql.Open("postgres", "user=lmullen dbname=lmullen sslmode=disable")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Create the jobs channel which will hold filenames
	jobs := make(chan string, BUFFERSIZE)

	bar := pb.New(PAGESGUESS)
	bar.SetRefreshRate(time.Second)
	bar.ShowTimeLeft = true

	// Start the workers which will begin to pull jobs off the channel
	for w := 1; w <= WORKERS; w++ {
		wg.Add(1)
		go worker(jobs, dataDir, bar, db)
	}

	bar.Start()
	err = filepath.Walk(dataDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && filepath.Ext(path) == ".txt" {
			jobs <- path
			return nil
		}
		return nil

	})

	close(jobs)
	wg.Wait()
	bar.FinishPrint("Finished processing.")
}
