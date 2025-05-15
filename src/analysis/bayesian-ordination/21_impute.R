# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("blavaan", "dplyr")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(blavaan)
library(dplyr)

# # load functions
# source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "3_vis_fun.R"))

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "impute")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
fit <- readRDS(file.path(datdir, "fit.rds"))
md <- read.csv(file.path(datdir, "md.csv"))

# separate row id info
id_md <- md %>%
  select(geo, geo_name, geo_source, geo_year, data_year)

# subset model data to only variables used by the model
vars_model <- lavaan::lavNames(fit, type="ov.nox")
md_impute <- md %>%
  select(all_of(vars_model))

# posterior predictions
ymis <- blavPredict(fit, type = "ymis")

# posterior prediction summary statistic
ymis_sumstat <- apply(ymis, 2, mean)

# fill in missing data
for(var in names(ymis_sumstat)){
  split_str <- strsplit(var, "[", fixed = TRUE)[[1]]
  col <- split_str[1]
  row <- as.numeric(gsub("]", "", split_str[2], fixed = TRUE))

  md_impute[row, col] <- ymis_sumstat[var] 
}

# attach row id info
md_impute <- cbind(id_md, md_impute)

# save to disk
write.csv(md_impute, file.path(outdir, "md.csv"), row.names = FALSE)
