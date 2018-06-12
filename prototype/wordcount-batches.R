#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(docopt))

"Take a data frame of texts from a ChronAm batch and count the words by year.

Usage: wordcount-batches.R [--debug] <input> -o <output>

Options:
  <input>                 Path to a feather file containing ChronAm texts.
  -o --output <output>    Path to an output feather data frame of word counts.
  -d --debug              Show debugging messages.
  -h --help               Show this message." -> doc

opt <- docopt(doc)
# For testing
# opt <- docopt(doc, args = "--debug /media/data/public-bible/argo-out/chronam-df/batch_nbu_alliance_ver01.tar.bz2.feather -o temp/test-wordcount.feather")

suppressPackageStartupMessages(library(futile.logger))
suppressPackageStartupMessages(library(feather))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(stringi))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(lubridate))

# Set up logging
invisible(flog.appender(appender.console(), name = "ROOT"))
if (opt$debug) {
  invisible(flog.threshold(DEBUG))
} else {
  invisible(flog.threshold(INFO))
}

batch_id <- str_extract(basename(opt$input), "\\w+")
flog.debug("%s: Beginning this batch", batch_id)
stopifnot(file.exists(opt$input))
outputdir <- dirname(opt$output)
flog.debug("%s: Creating output directory at %s", batch_id, outputdir)
dir.create(outputdir, showWarnings = FALSE, recursive = TRUE)

flog.debug("%s: Reading texts at %s", batch_id, opt$input)
texts <- read_feather(opt$input)

wordcounts <- texts %>%
  mutate(year = as.integer(year(date))) %>%
  mutate(wordcount = stri_count_words(text)) %>%
  group_by(year) %>%
  summarize(pages = n(),
            wordcount = sum(wordcount, na.rm = TRUE)) %>%
  mutate(batch = batch_id) %>%
  select(batch, year, pages, wordcount) %>%
  arrange(batch, year)

flog.debug("%s: Writing wordcounts to %s", batch_id, opt$output)
write_feather(wordcounts, opt$output)

flog.info("%s: Finished counting words in this batch", batch_id)
