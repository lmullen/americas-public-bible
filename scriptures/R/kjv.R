process_kjv <- function() {

  # Load the Bible text files
  ot_files <- dir_ls("raw/kjv/OldTestament", glob = "*.txt", recursive = TRUE)
  ap_files <- dir_ls("raw/kjv/Apocrypha", glob = "*.txt", recursive = TRUE)
  nt_files <- dir_ls("raw/kjv/NewTestament", glob = "*.txt", recursive = TRUE)
  chapter_files <- c(ot_files, ap_files, nt_files)

  book_names <- chapter_files %>%
    basename() %>%
    str_remove("\\.txt") %>%
    str_remove("(\\d+)$")

  chapter_nums <- chapter_files %>%
    basename() %>%
    str_remove("\\.txt") %>%
    str_extract("\\d+$") %>%
    as.integer()

  verse_texts <- chapter_files %>%
    map(read_lines)

  kjv <- data_frame(
    version = "KJV",
    part = c(rep("Old Testament", length(ot_files)),
             rep("Apocrypha", length(ap_files)),
             rep("New Testament", length(nt_files))),
    book = book_names,
    chapter = chapter_nums,
    text = verse_texts
  ) %>%
    unnest() %>%
    mutate(verse = text %>%
             str_extract("^\\d+") %>%
             as.integer()) %>%
    mutate(text = text %>%
             str_remove("^\\d+\\s")) %>%
    mutate(doc_id = str_c(book, " ", chapter, ":", verse, " (", version, ")")) %>%
  select(doc_id, version, part, book, chapter, verse, text)

  test_version(kjv)

  kjv

}
