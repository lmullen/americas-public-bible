# Process the LDS scriptures

download_lds <- function() {
  dir.create("raw", showWarnings = FALSE)
  download.file("http://scriptures.nephi.org/downloads/lds-scriptures.csv.zip",
                "raw/lds/lds-scriptures.csv.zip")
  unzip("raw/lds/lds-scriptures.csv.zip", exdir = "raw")
}

process_lds <- function(raw) {
  require(dplyr)
  cleaned <- raw %>%
    filter(volume_title != "Old Testament",
           volume_title != "New Testament") %>%
    mutate(part = volume_title) %>%
    select(doc_id = verse_title,
           version = volume_title,
           part = part,
           book = book_title,
           chapter = chapter_number,
           verse = verse_number,
           text = scripture_text)

  test_version(cleaned)

  return(cleaned)
}
