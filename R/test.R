test_version <- function(df) {
  types <- vapply(df, class, character(1))
  schema <- c(doc_id = "character", version = "character", part = "character",
              book = "character", chapter = "integer", verse = "integer", text = "character")
  if (!identical(types, schema)) {
    print(types)
    print(schema)
    stop("This version does not have the right schema.")
  }
}
