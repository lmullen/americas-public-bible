# JPS 1917 Tanakh from Sefaria

# Take the JSON file for a book and turn it into a data frame
parse_jps_json <- function(json) {
  out <- data_frame(book = json$work,
                    version = "JPS 1917",
                    part = "Old Testament",
                    chapter = names(json$text),
                    text = json$text)
  out$verse <- map(out$text, names)
  out %>%
    unnest(text, verse) %>%
    unnest() %>%
    mutate(chapter = as.integer(chapter) + 1L,
           verse = as.integer(verse) + 1L) %>%
    mutate(book = book %>%
             str_replace("^I ", "1 ") %>%
             str_replace("^II ", "2 ")) %>%
    arrange(chapter, verse) %>%
    mutate(doc_id = str_c(book, " ", chapter, ":", verse, " (", version, ")")) %>%
    select(doc_id, version, part, book, chapter, verse, text)
}

process_jps <- function() {
  files <- dir_ls("raw/jps/", glob = "*.json")
  out <- files %>%
    map(read_json) %>%
    map_df(parse_jps_json)
  test_version(out)
  out
}
