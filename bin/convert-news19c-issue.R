#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(futile.logger))
suppressPackageStartupMessages(library(xml2))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(feather))
suppressPackageStartupMessages(library(readr))

option_list <- OptionParser(
  usage = "usage: %prog [options] INPUT --metadata=METADATAPATH --texts=TEXTSPATH",
  description = c("Convert a 19th Century Newspapers issue XML to a data frame",
                  "of article texts.")
  ) %>%
  add_option("--metadata", type = "character",
             help = "Path to output file containing metadata") %>%
  add_option("--texts", type = "character",
             help = "Path to output file containing texts") %>%
  add_option(c("-d", "--debug"), action = "store_true", default = FALSE,
             help = "Turn on debugging output")

opts <- parse_args(option_list, positional_arguments = 1)

# For development
opts <- list(
  args = "/media/data/newspapers-19c/NCNP/NCNP_02/NCNP_XML_03/5AJQ-1845-JUL30.xml",
  options = list(
    debug = TRUE,
    metadata = "temp/test-news19c-metadata.csv",
    texts = "temp/test-news19c-texts.feather"
  )
)

# Check that we were passed output file paths
stopifnot(!is.null(opts$options$metadata))
stopifnot(!is.null(opts$options$metadata))

# Set up logging
invisible(flog.appender(appender.console(), name = "ROOT"))
if (opts$options$debug) {
  invisible(flog.threshold(DEBUG))
} else {
  invisible(flog.threshold(INFO))
}

input_path <- opts$args[1]
flog.info("Input file: %s", basename(input_path))
stopifnot(file.exists(input_path))

xml <- read_xml(input_path)

issue_metadata <- function(x) {
 out <- xml %>% xml_find_first(paste0("/issue/", x)) %>% xml_text()
 if (is.na(out)) flog.warn("Metadata element %s is missing", x)
 out
}

flog.info("Gathering the issue metadata")
issue_id <- issue_metadata("id")
issue_date <- issue_metadata("da") %>% mdy()
issue_ba <- issue_metadata("ba")
issue_newspaper_id <- issue_metadata("newspaperId")
issue_lccn <- issue_metadata("lccn")
issue_newspaper_title <- issue_metadata("citation/titleGroup/marcTitle")
issue_pub_country <- issue_metadata("citation/publicationPlace/pubCountry")
issue_pub_state <- issue_metadata("citation/publicationPlace/pubState")
issue_pub_county <- issue_metadata("citation/publicationPlace/pubCounty")
issue_pub_city <- issue_metadata("citation/publicationPlace/pubCity")

issue <- data_frame(
  issue_id,
  issue_date,
  issue_ba,
  issue_newspaper_id,
  issue_lccn,
  issue_newspaper_title,
  issue_pub_country,
  issue_pub_state,
  issue_pub_county,
  issue_pub_city
)
if (nrow(issue) > 1) flog.warn("More than one row in the issue metadata")

# Write issue as a CSV without any header so they can be concatenated in bash
flog.debug("Creating the metadata output directory")
dir.create(dirname(opts$options$metadata), recursive = TRUE, showWarnings = FALSE)
flog.info("Writing the metadata to %s", opts$options$metadata)
write_csv(issue, opts$options$metadata, col_names = FALSE)
