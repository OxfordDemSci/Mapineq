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
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_derive")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_transform")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
data_raw <- read.csv(file.path(datdir, "data_raw.csv"))
