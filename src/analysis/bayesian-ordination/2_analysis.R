# This script conducts a Bayesian latent factor analysis on Mapineq indicators

# cleanup
rm(list = ls())
gc()

#---- USER OPTIONS ----#
#----------------------#

# install libraries (if needed)
required_packages <- c("blavaan", "semPlot") # "befa"
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(blavaan)

# # load functions
# source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "2_analysis_fun.R"))

# directories
datadir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
dat <- read.csv(file.path(datadir, "data_wide.csv"))

# define latent variables
latent_variables <- list(
  "Economy" = c(
    "RD_E_GERDREG", # gross domestic expenditure on R&D
    "TEPSR_LM220", # gender employment gap
    "YTH_EMPL_110", # youth unemployment
    "TGS00010", # employment rate
    "EDAT_LFSE_33", # youth NEET
    "TESPM050_R" # poverty reduction
  ),
  "Education" = c(
    "EDUC_UOE_ENRA17", # pupils pre-primary
    "EDUC_UOE_ENRA13", # distribution of students among education types
    "TGS00109", # tertiary educational attainment
    "EDAT_LFS_9918" # educational attainment
  ),
  "Health" = c(
    "TGS00064", # hospital beds
    "HLTH_RS_BDSNS", # care beds
    "TGS00058", # cancer deaths
    "TGS00059", # heart disease deaths
    "DEMO_R_MINFIND", # infant mortality
    "HLTH_CD_YPERRTO", # peri- neo-natal mortality
    "DEMO_R_MLIFEXP" # life expectancy
  ),
  "Demographics" = c(
    "TGS00099", # population change (natural, migration, total)
    "DEMO_R_FIND2" # fertility indicators
  ),
  "Environment" = c(
    "pm25", # air particulates
    "ookla", # internet speed
    "TGS00050" # internet usage
  )
)

# specify model
model <- "
  Economy =~ econ1 + econ2 + econ3
  Education =~ edu1 + edu2 + edu3
  Health =~ health1 + health2 + health3
  Demographics =~ demo1 + demo2 + demo3
  Environment =~ env1 + env2 + env3
"

model <- ""
for (latent_variable in names(latent_variables)) {
  model <- c(
    model,
    paste(latent_variable, "=~", paste(latent_variables[[latent_variable]], collapse = "+"))
  )
}

# run Bayesian structural equation model
fit <- bsem(
  model,
  data = dat,
  target = "stan",
  burnin = 2000,
  sample = 4000,
  cores = 4,
  seed = 2600
)

summary(fit, fit.measures = TRUE, standardized = TRUE)

# visualise latent structure
semPaths(
  fit,
  whatLabels = "std",
  intercepts = FALSE
)
