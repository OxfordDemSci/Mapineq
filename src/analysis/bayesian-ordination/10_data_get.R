# This script acquires data for analysis by querying the Mapineq API
# see https://docs.mapineq.org for more information about querying the Mapineq API from R, Python, or other software.

# cleanup
rm(list = ls())
gc()

#---- USER OPTIONS ----#
TEST <- FALSE
n_test <- 10

year <- 2020
level <- 2

drop_resources <- c("HLTH_CD_ACDR2")

# keep_resources <- c(
#   "pm25", # air particulates
#   "ookla", # internet speed
#   "TGS00050", # internet usage
#   "TGS00064", # hospital beds
#   "HLTH_RS_BDSNS", # care beds
#   "TGS00058", # cancer deaths
#   "TGS00059", # heart disease deaths
#   "DEMO_R_MINFIND", # infant mortality
#   "HLTH_CD_YPERRTO", # peri- neo-natal mortality
#   "DEMO_R_MLIFEXP", # life expectancy
#   "EDUC_UOE_ENRA17", # pupils pre-primary
#   "EDUC_UOE_ENRA13", # distribution of students among education types
#   "TGS00109", # tertiary educational attainment
#   "EDAT_LFS_9918", # educational attainment
#   "RD_E_GERDREG", # gross domestic expenditure on R&D
#   "TEPSR_LM220", # gender employment gap
#   "YTH_EMPL_110", # youth unemployment
#   "TGS00010", # employment rate
#   "EDAT_LFSE_33", # youth NEET
#   "TESPM050_R", # poverty reduction
#   "TGS00099", # population change (natural, migration, total)
#   "DEMO_R_FIND2" # fertility indicators
# )
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
  # "DEMO_R_MLIFEXP", # life expectancy
  "EDUC_UOE_ENRA17", # pupils pre-primary
  "EDUC_UOE_ENRA13", # distribution of students among education types
  "TGS00109", # tertiary educational attainment
  "EDAT_LFS_9918", # educational attainment
  "TEPSR_LM220", # gender employment gap
  # "YTH_EMPL_110", # youth unemployment
  "TGS00010", # unemployment rate
  "EDAT_LFSE_33", # youth NEET
  "TESPM050_R", # poverty reduction
  "TGS00099", # population change (natural, migration, total)
  "DEMO_R_FIND2", # fertility indicators
  "BD_SIZE_R3", # Business demography TODO: select filters in data_select.R
  "TGS00103", # At-risk-of-poverty rate
  "TRAN_R_ACCI", # Injuries from vehicle accidents
  "TGS00101", # life expectancy at birth
  "YTH_EMPL_030" # Youth employment
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
filter_cols <- unique(filter_dictionary$field)

# expand catalogue to include all combinations of filters
catalogue_expanded <- expand_catalogue(data_catalogue)

# create variable names
catalogue_expanded <- variable_names(
  dat = catalogue_expanded,
  filter_cols = filter_cols
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
  filter_cols = filter_cols,
  year = year,
  level = level
)

# bind data together
data_raw <- bind_rows(data_list)

data_raw <- data_raw %>%
  left_join(
    data_catalogue |>
      select(f_resource, f_short_description, f_description)
  )


# save to disk
write.csv(data_raw, file.path(outdir, "data_raw.csv"), row.names = FALSE)
write.csv(data_catalogue, file.path(outdir, "catalogue.csv"), row.names = FALSE)
write.csv(catalogue_expanded, file.path(outdir, "catalogue_expanded.csv"), row.names = FALSE)
write.csv(filter_dictionary, file.path(outdir, "filter_dictionary.csv"), row.names = FALSE)
