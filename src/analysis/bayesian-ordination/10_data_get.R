# This script acquires data for analysis by querying the Mapineq API
# see https://docs.mapineq.org for more information about querying the Mapineq API from R, Python, or other software.

# cleanup
rm(list = ls())
gc()

#---- USER OPTIONS ----#
TEST <- FALSE
n_test <- 100

year <- 2020
level <- 2

drop_resources <- c("HLTH_CD_ACDR2")

keep_resources <- c(
  "pm25", # air particulates
  "ookla", # internet speed
  "TGS00050", # internet usage
  "TGS00064", # hospital beds
  "HLTH_RS_BDSNS", # care beds
  "TGS00058", # cancer deaths
  "TGS00059", # heart disease deaths
  "DEMO_R_MINFIND", # infant mortality
  "HLTH_CD_YPERRTO", # peri- neo-natal mortality
  "DEMO_R_MLIFEXP", # life expectancy
  "EDUC_UOE_ENRA17", # pupils pre-primary
  "EDUC_UOE_ENRA13", # distribution of students among education types
  "TGS00109", # tertiary educational attainment
  "EDAT_LFS_9918", # educational attainment
  "RD_E_GERDREG", # gross domestic expenditure on R&D
  "TEPSR_LM220", # gender employment gap
  "YTH_EMPL_110", # youth unemployment
  "TGS00010", # employment rate
  "EDAT_LFSE_33", # youth NEET
  "TESPM050_R", # poverty reduction
  "TGS00099", # population change (natural, migration, total)
  "DEMO_R_FIND2" # fertility indicators
)
#----------------------#

# install libraries (if needed)
required_packages <- c("dplyr", "tidyr")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(dplyr)
library(tidyr)

# load functions
source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "10_data_fun.R"))

# directories
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_get")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# get mapineq data catalogue
data_catalogue <- get_catalogue(level)

# drop resources
if (length(drop_resources) > 0) {
  data_catalogue <- data_catalogue %>%
    filter(!f_resource %in% drop_resources)
}

# keep resources
if (length(keep_resources) > 0) {
  data_catalogue <- data_catalogue %>%
    filter(f_resource %in% keep_resources)
}

# keep data only for selected year
data_catalogue <- catalogue_for_year(data_catalogue, year)

# add filters to catalogue
data_catalogue <- catalogue_filters(data_catalogue, year, level)

# filter labels
filter_dictionary <- filter_labels(data_catalogue)

# expand catalogue to include all combinations of filters
catalogue_expanded <- expand_catalogue(data_catalogue)

# create variable names
catalogue_expanded <- variable_names(
  dat = catalogue_expanded |> 
    rename(
      resource = f_resource,
      short_description = f_short_description,
      description = f_description
    ), 
  filter_cols = unique(filter_dictionary$field)
)

# reduce for testing
if (TEST) {
  i_select <- sample(x = 1:nrow(catalogue_expanded), size = min(nrow(catalogue_expanded), n_test))
} else {
  i_select <- 1:nrow(catalogue_expanded)
}

# get data for all items in the catalogue
data_list <- catalogue_data(
  catalogue = catalogue_expanded[i_select, ], 
  year = year, 
  level = level)
data_raw <- bind_rows(data_list)

data_raw <- data_raw %>%
  left_join(
    data_catalogue |>
      rename(
        resource = f_resource,
        short_description = f_short_description,
        description = f_description
      ) |>
      select(resource, short_description, description)
  )

# wide-format data
data_wide <- wide_catalogue_data(data_raw)

# variable selection
vars_df <- data_raw %>%
  select(variable_name, variable_name_long, resource) %>%
  distinct() %>%
  left_join(
    catalogue %>% 
      rename(
        resource = f_resource,
        description = f_description,
        short_description = f_short_description
      ) %>% 
      select(resource, short_description, description)
  ) %>% 
  mutate(
    select_y = 1,
    select_x = 0
  )

# drop locations with no data
vars <- unique(vars_df$variable_name)
rows_no_data <- apply(data_wide[, vars], 1, function(x) all(is.na(x)))
data_wide <- data_wide[!rows_no_data, ]

# save to disk
write.csv(data_raw, file.path(outdir, "data_raw.csv"), row.names = FALSE)
write.csv(data_wide, file.path(outdir, "data_wide.csv"), row.names = FALSE)
write.csv(data_catalogue, file.path(outdir, "catalogue.csv"), row.names = FALSE)
write.csv(catalogue_expanded, file.path(outdir, "catalogue_expanded.csv"), row.names = FALSE)
write.csv(filter_dictionary, file.path(outdir, "filter_dictionary.csv"), row.names = FALSE)
write.csv(vars_df, file.path(outdir, "variable_selection.csv"), row.names = FALSE)
