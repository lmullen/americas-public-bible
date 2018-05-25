# The drake plan for processing all the data files

library(tidyverse)
library(drake)
library(fs)

pkgconfig::set_config("drake::strings_in_dots" = "literals")

source("R/lds.R")
source("R/kjv.R")

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

master_plan <- bind_plans(
  lds_plan,
  kjv_plan
)

config <- drake_config(master_plan)
vis_drake_graph(config, targets_only = FALSE)

make(master_plan, jobs  = 2)
