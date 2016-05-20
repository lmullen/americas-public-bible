load("data/bible.rda")

compute_runs_test <- function(page, verse) {
  text <- readr::read_file(paste0("data/sample/", page, "/ocr.txt"))
  tokens <- bible_tokenizer(text)[[1]]
  verse_tokens <- bible_verses[bible_verses$reference == verse, "tokens"][[1]]
  matches <- tokens %in% verse_tokens
  match_tokens <- tokens[matches]
  message(paste(sum(matches), " tokens match"))
  message(paste(match_tokens, collapse = ", "))
  message(paste(which(matches), collapse = ", "))
  run <- as.factor(matches)
  tseries::runs.test(run)$p.value
}

# Match
compute_runs_test("sn84026925/1892/01/13/ed-1/seq-2/", "Mark 16:15 (KJV)")

# Match
compute_runs_test("sn88064181/1914/11/13/ed-1/seq-4/", "Romans 13:9 (KJV)")

# No match
compute_runs_test("sn84024283/1910/07/21/ed-1/seq-3/", "Genesis 39:5 (KJV)")

# Match with few tokens
compute_runs_test("sn97067613/1889/08/29/ed-1/seq-4/", "Mark 14:50 (KJV)")

# Not a match, one token
compute_runs_test("sn83030313/1920/01/11/ed-1/seq-58/", "Deuteronomy 29:16 (KJV)")

# Not a match, three tokens
compute_runs_test("sn82014296/1869/07/29/ed-1/seq-4/", "Nehemiah 5:4 (KJV)")
