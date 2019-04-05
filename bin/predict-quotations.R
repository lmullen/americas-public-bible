#!/usr/bin/env Rscript

# Given a file of potential quotations, return the probabilities
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(parsnip))
suppressPackageStartupMessages(library(recipes))
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(futile.logger))

parser <- OptionParser(
  description = "Predict probabilities for potential quotations.",
  usage = "Usage: %prog [options] BATCH --out=OUTPUT",
  epilogue = paste("Input and output files are assumed to be stored as .csv files.",
                   "The prediction model should be a .rda file.")) %>%
  add_option(c("-o", "--out"),
             action = "store", type = "character", default = NULL,
             help = "Path to the output file.") %>%
  add_option(c("-b", "--model"),
             action = "store", type = "character", default = NULL,
             help = "Path to the prediction model.")
if (!interactive()) {
  # Command line usage
  args <- parse_args(parser, positional_arguments = 1)
} else {
  # For testing
  flog.warn("Using the testing command line arguments since session is interactive.")
  args <- parse_args(parser,
                     args = c("./data/wvu_lincoln_ver01-quotations.csv",
                              "--out=temp/predicted-quotations-test.csv",
                              "--model=bin/prediction-payload.rda"),
                     positional_arguments = 1)
}

# Short versions of options and checks for validity
in_file <- args$args[1]
out_file <- args$options$out
model_file <- args$options$model

if (!file.exists(in_file)) {
  flog.fatal("File %s does not exist.", in_file)
  quit(save = "no", status = 1)
}
if (is.null(out_file)) {
  flog.fatal("An output path must be specified.")
  quit(save = "no", status = 1)
}
if (is.null(model_file) || !file.exists(model_file)) {
  flog.fatal("Model payload file %s does not exist or was not specified.", model_file)
  quit(save = "no", status = 1)
}
if (!dir.exists(dirname(out_file))) {
  flog.fatal("The output directory must exist.")
  quit(save = "no", status = 1)
}
if (file.exists(out_file)) {
  flog.warn("The output file already exists. It will be overwritten.")
}

# Read in the data and the model file
raw <- read_csv(in_file, col_types = "ccidd",
                col_names = c("verse_id", "doc_id", "tokens", "tfidf", "proportion"))
load(model_file)

# Center and scale the measurements as we did the training data
measurements <- bake(data_recipe, new_data = raw %>% select(-verse_id, -doc_id)) %>% select(-match)

# Do the predictions
predictions <-  raw %>%
  select(verse_id, doc_id) %>%
  bind_cols(
    predict(model, measurements, type = "prob") %>%
      select(probability = .pred_quotation)
  )

quotations <- predictions %>% filter(probability >= 0.5)

write_csv(quotations, out_file, col_names = FALSE)
flog.info("Successfully predicted the quotations.")
