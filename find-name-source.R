
library(dplyr)

source("cb_name_usage.R")


# cb_name_parser("4KSC7")

col_id = cb_name_usage("Calopteryx splendens")$usage$id[1]
col_id
get_dataset_source(col_id)

