#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(docopt))

"Take a bzipped batch of Chronicling America OCR text files and turn it into
a serialized data frame for future use.

Usage: convert-batches.R [--debug --log <log>] <input> -o <output>

Options:
  <input>                 Path to the bzip file containing a ChronAm batch.
  -o --output <output>    Path to an output filename for the serialized data frame.
  -d --debug              Show debugging messages.
  -l --log <log>          Path to a log file; otherwise logged only to console.
  -h --help               Show this message." -> doc

opt <- docopt(doc)
# For testing
# opt <- docopt(doc, args = "--debug --log logs/script-debugging.log temp/batch_az_elephanttree_ver01.tar.bz2 -o temp/test-batch.feather")
# opt <- docopt(doc, args = "--debug temp/batch_az_elephanttree_ver01.tar.bz2 -o temp/test-batch.feather")

suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(futile.logger))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(feather))

# Setup debugging
if (!is.null(opt$log)) {
  invisible(flog.appender(appender.tee(opt$log), name = "ROOT"))
} else {
  invisible(flog.appender(appender.console(), name = "ROOT"))
}

if (opt$debug) {
  invisible(flog.threshold(DEBUG))
} else {
  invisible(flog.threshold(INFO))
}

batch_id <- str_replace(basename(opt$input), "\\.tar\\.bz2$", "")
flog.debug("%s: Batch ID is %s", batch_id, batch_id)

flog.debug("%s: Input file is %s", batch_id, opt$input)
stopifnot(file.exists(opt$input))

flog.debug("%s: Output file is %s", batch_id, opt$output)
outputdir <- dirname(opt$output)
flog.debug("%s: Creating output directory at %s", batch_id, outputdir)
dir.create(outputdir, showWarnings = FALSE, recursive = TRUE)

# Use scratch on slurm, otherwise use /tmp
# Getting tar errors on scratch, so going back to /tmp
# scratchdir <- "/data/scratch/lmullen"
# if (dir.exists(scratchdir)) {
#   temppath <- file.path(scratchdir, batch_id)
#   if (dir.exists(temppath)) {
#     flog.warn("%s: temp directory already exists in scratch directory", batch_id)
#   }
#   # If we use scratch, we have to clean up our temporary files. Do that on exit.
#   .Last <- function() {
#     unlink(temppath, recursive = TRUE)
#     flog.debug("%s: Deleted temporary files in scratch directory", batch_id)
#   }
# } else {
temppath <- file.path(tempdir(), batch_id)
# }
flog.debug("%s: Temp directory for unzipping OCR files is %s", batch_id, temppath)
dir.create(temppath, showWarnings = TRUE, recursive = TRUE)

flog.info("%s: Unzipping the batch to a temp directory", batch_id)
tar_args <- str_c("--overwrite -xf ", opt$input, " -C ", temppath,
             " --wildcards '*.txt'")
ftry(system2("tar", tar_args),
     error = function(c) {
       flog.error("%s: Unzipping failed for this batch", batch_id)
       flog.trace(c)
       quit("no", status = 10, runLast = TRUE)
     })
flog.debug("%s: Done unzipping the batch", batch_id)

ocr <- list.files(temppath, pattern = "\\.txt$", full.names = TRUE, recursive = TRUE)
flog.info("%s: There are %s pages in this batch", batch_id, length(ocr))

path_to_id <- function(p) {
  # Convert a path to the page ID used on the ChronAm website
  p %>%
    str_extract( "\\w+/\\d{4}/\\d{2}/\\d{2}/.+ocr.txt") %>%
    str_replace("ocr.txt", "") %>%
    str_replace("(\\d{4})/(\\d{2})/(\\d{2})", "\\1-\\2-\\3")
}

pageids <- path_to_id(ocr)
dates <- str_extract(pageids, "\\d{4}-\\d{2}-\\d{2}") %>% as.Date()
editions <- str_extract(ocr, "ed-\\d+") %>% str_extract("\\d+") %>% as.integer()
pages <- str_extract(ocr, "seq-\\d+") %>% str_extract("\\d+") %>% as.integer()
publication_ids <- str_extract(pageids, "^.+\\/\\d{4}") %>% str_replace("\\/\\d{4}", "")

flog.info("%s: Reading in the OCR text files", batch_id)
read_safely <- purrr::possibly(read_file, NA_character_)
texts <- ocr %>% map_chr(read_safely)

results <- data_frame(
  pageid = pageids,
  batch_id = batch_id,
  publication = publication_ids,
  date = dates,
  edition = editions,
  page = pages,
  text = texts
) %>%
  arrange(publication, date, edition, page)

failed_reads <- results %>% filter(is.na(text)) %>% nrow()
flog.info("%s: Failed to read %s out of %s OCR text files",
          batch_id, failed_reads, length(ocr))

flog.info("%s: Writing the results to disk", batch_id)
write_feather(results, opt$output)

flog.info("%s: Finished converting batch to data frame", batch_id)
