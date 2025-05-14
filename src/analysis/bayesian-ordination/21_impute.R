# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("plotly", "htmlwidgets") # "befa"
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(blavaan)

# # load functions
# source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "3_vis_fun.R"))

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "imputate")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
fit <- readRDS(file.path(datdir, "fit.rds"))
md <- read.csv(file.path(datdir, "md.csv"))

# posterior predictive samples
pp_samples <- blavInspect(fit, "ypred")

# row attributes
md_attributes <- md %>%
  select(data_year, geo, geo_name, geo_source, geo_year)

# model data
md <- md %>%
  select(-all_of(c("data_year", "geo", "geo_name", "geo_source", "geo_year")))

# identify missing data
missing_idx <- is.na(md)

# median posterior predictions
imputed <- apply(pp_samples, c(2, 3), median)

# combined data
md_imputed <- md
md_imputed[missing_idx] <- imputed[missing_idx]
md_imputed <- cbind(md_attributes, md_imputed)

# save to disk
write.csv(md_imputed, file.path(outdir, "md.csv"), row.names = FALSE)
