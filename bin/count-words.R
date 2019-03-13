#!/usr/bin/env Rscript

# Count the words in a batch of texts

suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(fs))
suppressPackageStartupMessages(library(futile.logger))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(tokenizers))

parser <- OptionParser(
  description = "Count the words in a batch of texts.",
  usage = "Usage: %prog [options] BATCH --out=OUTPUT",
  epilogue = "Input and output files are assumed to be stored as .csv files."
) %>%
  add_option(c("-o", "--out"),
             action = "store", type = "character", default = NULL,
             help = "Path to the output file.") %>%
  add_option(c("-q", "--quietly"),
             action = "store_true", default = FALSE,
             help = "Run quietly.")
args <- parse_args(parser, positional_arguments = 1)
# args <- parse_args(parser,
#                    args = c("./data/az_falcon_ver01.csv",
#                             "--out=temp/word-count-test.csv"),
#                    positional_arguments = 1)

# Easier references to outputs
batch_path <- args$args[1]
batch_id <- batch_path %>% path_file() %>% path_ext_remove()
out_path <- args$options$out

# Check validity of inputs and set options
if (args$options$quietly) {
  log_threshold <- flog.threshold(ERROR)
}
if (!file_exists(batch_path)) {
  flog.fatal("Batch file %s does not exist", batch_path)
  quit(save = "no", status = 1)
}
if (is.null(out_path)) {
  flog.fatal("An output path must be specified.")
  quit(save = "no", status = 1)
}
if (!dir_exists(path_dir(out_path))) {
  flog.fatal("The output directory must exist.")
  quit(save = "no", status = 1)
}
if (file_exists(out_path)) {
  flog.warn("The output file already exists. Overwriting.")
}

flog.info("Beginning processing: %s.", batch_id)

flog.info("Reading batch of texts: %s.", batch_path)
texts <- read_csv(batch_path,
                  col_names = c("batch_id", "doc_id", "text"),
                  col_types = "ccc")

flog.info("Read in %s texts.", nrow(texts))

flog.info("Counting the words.")
wordcounts <- texts %>%
  mutate(wc = count_words(text)) %>%
  select(-text)

flog.info("Writing the word counts: %s.", out_path)
write_csv(wordcounts, out_path, col_names = FALSE)

flog.info("Finished processing: %s.", batch_id)
