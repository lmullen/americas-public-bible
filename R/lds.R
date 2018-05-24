# Process the LDS scriptures

download_lds <- function() {
  dir.create("raw", showWarnings = FALSE)
  download.file("http://scriptures.nephi.org/downloads/lds-scriptures.csv.zip",
                "raw/lds-scriptures.csv.zip")
  unzip("raw/lds-scriptures.csv.zip", exdir = "raw")
}

process_lds <- function(data, out_csv) {
  cleaned <- data %>%
    filter(volume_title != "Old Testament",
           volume_title != "New Testament") %>%
    mutate(part = volume_title) %>%
    select(version = volume_title,
           part = part,
           book = book_title,
           chapter = chapter_number,
           verse = verse_number,
           doc_id = verse_title,
           citation = verse_short_title,
           text = scripture_text)

  dir.create(dirname(out_csv), showWarnings = FALSE)
  write_csv(cleaned, out_csv)
}
