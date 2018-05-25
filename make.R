# The drake plan for processing all the data files

library(tidyverse)
library(drake)
library(fs)
library(readxl)

pkgconfig::set_config("drake::strings_in_dots" = "literals",
                      "drake::verbose" = 1)

source("R/lds.R")
source("R/kjv.R")
source("R/assorted.R")

# Read in and clean the LDS CSV file then write it to a CSV
lds_plan <- drake_plan(
  lds_raw = read_csv(file_in("raw/lds/lds-scriptures.csv"), col_types = "iiiicccccccccciiccc"),
  lds = process_lds(lds_raw),
  write_csv(lds, file_out("data/lds.csv"))
)

# Read in and process the KJV text files then write them to a CSV
kjv_plan <- drake_plan(
  kjv = process_kjv(),
  write_csv(kjv, file_out("data/kjv.csv"))
)

# Read in, process, and split apart the three versions in assorted
assorted_plan <- drake_plan(
  assorted_raw = suppressWarnings(read_excel(file_in("raw/assorted/bibles.xlsx"))),
  assorted_cleaned = process_assorted(assorted_raw),
  asv = dplyr::filter(assorted_cleaned, version == "ASV"),
  dr = dplyr::filter(assorted_cleaned, version == "Douay-Rheims"),
  rv = dplyr::filter(assorted_cleaned, version == "RV"),
  write_csv(asv, file_out("data/asv.csv")),
  write_csv(dr, file_out("data/douay-rheims.csv")),
  write_csv(rv, file_out("data/rv.csv"))
)

master_plan <- bind_plans(
  lds_plan,
  kjv_plan,
  assorted_plan
)

config <- drake_config(master_plan)
vis_drake_graph(config, targets_only = TRUE)

make(master_plan, jobs  = 4)
