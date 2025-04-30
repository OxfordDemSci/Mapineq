# cleanup
rm(list = ls())
gc()

#---- USER OPTIONS ----#
#----------------------#

# install libraries (if needed)
required_packages <- c("dplyr", "tidyr", "rlang")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(dplyr)
library(tidyr)
library(rlang)

# load functions
source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "10_data_fun.R"))

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_get")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_derive")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
data_raw <- read.csv(file.path(datdir, "data_raw.csv"))
filter_dictionary <- read.csv(file.path(datdir, "filter_dictionary.csv"))

# filters
filter_names <- unique(filter_dictionary$field)

#---- gender gaps and sex ratios ----#
key_filters <- setdiff(filter_names, "sex")

data_ratio <- data_raw %>%
  filter(sex %in% c("F", "M")) %>%
  group_by(resource, data_year, geo, across(all_of(key_filters))) %>%
  mutate(
    total_f = sum(if_else(sex == "F", value, 0), na.rm = TRUE),
    total_m = sum(if_else(sex == "M", value, 0), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(total_f > 0, total_m > 0) %>%
  distinct(resource, data_year, geo, across(all_of(key_filters)), .keep_all = TRUE) %>%
  mutate(
    sex = "R",
    value = total_f / total_m,
    variable_name = NA,
    variable_name_long = NA
  ) %>%
  select(-total_f, -total_m)

# combine derived raw data with original raw data
data_raw_derive <- bind_rows(data_raw, data_ratio)




# add variable names to derived data (potentially revising old variable names)
data_raw_derive <- variable_names(
  dat = data_raw_derive,
  filter_cols = filter_names
)

# save to disk
write.csv(data_raw_derive, file.path(outdir, "data_raw.csv"), row.names = FALSE)
