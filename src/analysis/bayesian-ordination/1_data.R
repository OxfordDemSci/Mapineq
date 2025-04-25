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
  "RD_E_GERDREG", # gross domestic expenditure on R&D
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
  "TEPSR_LM220", # gender employment gap
  "YTH_EMPL_110", # youth unemployment
  "TGS00010", # employment rate
  "EDAT_LFSE_33", # youth NEET
  "TESPM050_R", # poverty reduction
  "TGS00099", # population change (natural, migration, total)
  "DEMO_R_FIND2" # fertility indicators
)
#----------------------#

# load functions
source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "1_data_fun.R"))

# directories
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# get mapineq data catalogue
data_catalogue <- get_catalogue(level)

# drop resources
if (length(drop_resources) > 0) {
  data_catalogue <- data_catalogue |>
    filter(!f_resource %in% drop_resources)
}

# keep resources
if (length(keep_resources) > 0) {
  data_catalogue <- data_catalogue |>
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

# reduce for testing
if (TEST) {
  i_select <- sample(x = 1:nrow(catalogue_expanded), size = min(nrow(catalogue_expanded), n_test))
} else {
  i_select <- 1:nrow(catalogue_expanded)
}

# get data for all items in the catalogue
results <- catalogue_data(catalogue_expanded[i_select, ], year, level)

dat <- bind_rows(results) 
# TODO: Troubleshoot bind_rows() with columns of different sizes
# ! Tibble columns must have compatible sizes.
# • Size 332: Columns `TGS00058`, `TGS00059`, `EDUC_UOE_ENRA13`, `HLTH_CD_YPERRTO`, `ookla`, and 6 more.
# • Size 334: Columns `TGS00064`, `EDAT_LFSE_33`, `DEMO_R_FIND2`, `TEPSR_LM220`, `DEMO_R_MINFIND`, and 5 more.
# ℹ Only values of size one are recycled.

# save to disk
write.csv(dat, file.path(outdir, "data.csv"), row.names = FALSE)
write.csv(data_catalogue, file.path(outdir, "catalogue.csv"), row.names = FALSE)
write.csv(catalogue_expanded, file.path(outdir, "catalogue_expanded.csv"), row.names = FALSE)
write.csv(filter_dictionary, file.path(outdir, "filter_dictionary.csv"), row.names = FALSE)
