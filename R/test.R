test_version <- function(df) {
  types <- vapply(df, class, character(1))
  schema <- c(doc_id = "character", version = "character", part = "character",
              book = "character", chapter = "integer", verse = "integer", text = "character")
  stopifnot(identical(types, schema))
}
