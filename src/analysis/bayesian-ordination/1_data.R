# This script acquires data for analysis by querying the Mapineq API
# see https://docs.mapineq.org for more information about querying the Mapineq API from R, Python, or other software.

# cleanup
rm(list = ls())
gc()

#---- USER OPTIONS ----#
year <- 2020
level <- 2
drop_resources <- c("HLTH_CD_ACDR2")
#----------------------#

# source functions
source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "1_data_fun.R"))

# directories
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# get mapineq data catalogue
catalogue <- get_catalogue(level)

# drop resources
catalogue <- catalogue |> 
  filter(!f_resource %in% drop_resources)

# keep data for selected year
catalogue <- catalogue_for_year(catalogue, year)

# add filters to catalogue
catalogue <- catalogue_filters(catalogue, year, level)

# expand catalogue to include all combinations of filters
catalogue_expanded <- expand_catalogue(catalogue)

# get data for all items in the catalogue
dat <- catalogue_data(catalogue_expanded, year, level)

# save to disk
write.csv(dat, file.path(outdir, "data.csv"), row.names = FALSE)
write.csv(catalogue, file.path(outdir, "catalogue.csv"), row.names = FALSE)
write.csv(catalogue_expanded, file.path(outdir, "catalogue_expanded.csv"), row.names = FALSE)
