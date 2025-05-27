# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("dplyr", "tidyr")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(dplyr)
library(tidyr)

# load functions
source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "10_data_fun.R"))

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_get")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_derive")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
data_raw <- read.csv(file.path(datdir, "data_raw.csv"))
filter_dictionary <- read.csv(file.path(datdir, "filter_dictionary.csv"))
data_catalogue <- read.csv(file.path(datdir, "catalogue.csv"))

# filters
filter_cols <- unique(filter_dictionary$field)

#---- gender gaps and sex ratios ----#
key_filters <- setdiff(filter_cols, "sex")

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
data_raw_derive <- rbind(data_raw, data_ratio)


#---- post-process derived data ----#

# remove variables with insufficient data (renames variables)
data_raw_derive <- data_raw_derive %>%
  variable_names(filter_cols = filter_cols) %>%
  group_by(variable_name) %>%
  mutate(drop = case_when(
    all(is.na(value)) ~ TRUE,
    n_distinct(value, na.rm = TRUE) < 3 ~ TRUE,
    TRUE ~ FALSE
  )) %>%
  ungroup() %>%
  filter(drop == FALSE) %>%
  select(-drop) %>%
  variable_names(filter_cols = filter_cols)

# transform to wide-format
data_wide <- data_to_wide(
  dat = data_raw_derive,
  drop_rows = TRUE
)

# create variable selection spreadsheet
vars_df <- variable_select(
  dat = data_raw_derive,
  filter_cols = filter_cols,
  catalogue = data_catalogue
)


#---- quick test ----#
test_var_raw <- data_raw %>% filter(f_resource == 'DEMO_R_FIND2' & indic_de=='AGEMOTH' & unit=='YR') %>% pull(variable_name) %>% unique()
test_var_derive <- data_raw_derive %>% filter(f_resource == 'DEMO_R_FIND2' & indic_de=='AGEMOTH' & unit=='YR') %>% pull(variable_name) %>% unique()

x <- data_raw %>% filter(variable_name == test_var_raw) %>% pull(value)
mean(is.na(x))
x <- data_raw_derive %>% filter(variable_name == test_var_derive) %>% pull(value)
mean(is.na(x))
x <- data_wide[,test_var_derive]
mean(is.na(x))

x <- dat %>% filter(variable_name == test_var_derive) %>% pull(value)
mean(is.na(x))

y <- result %>% pull(test_var_derive)
mean(is.na(y))

nuts_raw <- data_raw |> filter(variable_name == test_var_raw) |> select(geo_name, geo) |> distinct()
nuts_wide <- data_wide |> select(geo_name, geo) |> distinct()



#---- save to disk ----#
write.csv(data_raw_derive, file.path(outdir, "data_raw.csv"), row.names = FALSE)
write.csv(data_wide, file.path(outdir, "data_wide.csv"), row.names = FALSE)
write.csv(vars_df, file.path(outdir, "variable_selection.csv"), row.names = FALSE)
