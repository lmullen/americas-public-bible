# The drake plan for processing all the data files

library(drake)
suppressPackageStartupMessages(library(tidyverse))

pkgconfig::set_config("drake::strings_in_dots" = "literals")

source("R/lds.R")

plan <- drake_plan(
  lds_raw = read_csv(file_in("raw/lds-scriptures.csv"), col_types = "iiiicccccccccciiccc"),
  process_lds(lds_raw, file_out("data/lds.csv"))
)

make(plan)
