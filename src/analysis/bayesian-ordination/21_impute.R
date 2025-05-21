# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("blavaan", "dplyr")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(blavaan)
library(dplyr)

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

# posterior predictions
ymis <- blavPredict(fit, type = "ymis")

# posterior prediction summary statistic
ymis_mean <- apply(ymis, 2, mean)
ymis_lower <- apply(ymis, 2, quantile, probs=c(0.1))
ymis_upper <- apply(ymis, 2, quantile, probs=c(0.9))

# subset model data to only variables used by the model
vars_model <- lavaan::lavNames(fit, type = "ov.nox")
md_impute_mean <- md %>%
  select(all_of(vars_model))

# setup data frame to include mean, lower, and upper
md_impute_lower <- md_impute_mean
md_impute_upper <- md_impute_mean

# fill in missing data
for (var in names(ymis_mean)) {
  split_str <- strsplit(var, "[", fixed = TRUE)[[1]]
  col <- split_str[1]
  row <- as.numeric(gsub("]", "", split_str[2], fixed = TRUE))

  md_impute_mean[row, col] <- ymis_mean[var]
  md_impute_lower[row, col] <- ymis_lower[var]
  md_impute_upper[row, col] <- ymis_upper[var]
}

names(md_impute_lower) <- paste0(names(md_impute_mean), "_lower")
names(md_impute_upper) <- paste0(names(md_impute_mean), "_upper")

# combine row id info, mean, lower, and upper
md_impute <- cbind(id_md, md_impute_mean, md_impute_lower, md_impute_upper)

# save to disk
write.csv(md_impute, file.path(outdir, "md.csv"), row.names = FALSE)
