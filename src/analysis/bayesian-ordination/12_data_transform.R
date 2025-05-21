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
data_wide <- read.csv(file.path(datdir, "data_wide.csv"))

# manual data repairs
data_wide[which(data_wide$TEPSR_LM220_1 < 0), "TEPSR_LM220_1"] <- NA

# variable list
vars <- unique(data_raw$variable_name)

# remove variables with insufficient data
drop_vars <- which(apply(data_wide[vars], 2, function(x) all(is.na(x)) | length(unique(x)) < 3))
if(length(drop_vars) > 0){
  vars <- vars[-drop_vars]
}

# summary statistics
sumstats <- data.frame(
  variable_name = vars,
  min = apply(data_wide[, vars], 2, min, na.rm = T),
  max = apply(data_wide[, vars], 2, max, na.rm = T),
  mean = apply(data_wide[, vars], 2, mean, na.rm = T),
  sd = apply(data_wide[, vars], 2, sd, na.rm = T)
)

# # vars to logit transform
# vars_percent <- data_raw |>
#   filter(variable_name %in% vars) |>
#   filter(unit %in% c("PC", "PC_GDP", "PC_IND")) |>
#   pull(variable_name) |>
#   unique()
# sumstats$logit <- FALSE
# sumstats[vars_percent, "logit"] <- TRUE

# vars to log transform
vars_no_log <- rownames(sumstats |> filter(min < 0))
sumstats <- sumstats %>% mutate(log = TRUE) # !sumstats$logit
sumstats[vars_no_log, "log"] <- FALSE
vars_log <- sumstats$variable_name[sumstats$log]

#---- transform data ----#
data_trans <- data_wide

# log transform
x <- data_wide[, vars_log]
data_trans[, vars_log] <- log(x + 1)

# # logit transform
# eps <- 1e-3
# for(var in vars_percent){
#   x <- data_wide[,var] / 100
#   x <- pmin(pmax(x, eps, na.rm=T), 1-eps, na.rm=T)
#   data_trans[,var] <- log(x / (1-x))
# }

# update summary statistics
sumstats$mean_trans <- apply(data_trans[, vars], 2, mean, na.rm = T)
sumstats$sd_trans <- apply(data_trans[, vars], 2, sd, na.rm = T)

# # scale variables
# data_scale <- data_trans
# for(var in vars){
#   mu <- sumstats[var, "mean_trans"]
#   sigma <- sumstats[var, "sd_trans"]
#   data_scale[,var] <- (data_trans[,var] - mu) / sigma
# }

# scale variables
data_scale <- data_wide
for (var in vars) {
  mu <- sumstats[var, "mean"]
  sigma <- sumstats[var, "sd"]
  data_scale[, var] <- (data_wide[, var] - mu) / sigma
}

# spot-check histograms
var <- vars[sample(1:length(vars), 1)]
hist(data_wide[, var], main = var)
hist(data_trans[, var], main = var)
hist(data_scale[, var], main = var)

#---- save to disk ----#
write.csv(data_scale, file.path(outdir, "data_scale.csv"), row.names = FALSE)
write.csv(sumstats, file.path(outdir, "sumstats.csv"), row.names = FALSE)
