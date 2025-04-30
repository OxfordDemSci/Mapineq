# This script conducts a Bayesian latent factor analysis on Mapineq indicators

# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("blavaan", "semPlot") # "befa"
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(blavaan)
future::plan("multicore")

# # load functions
# source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "2_analysis_fun.R"))

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
dat <- read.csv(file.path(datdir, "data_wide.csv"), check.names = FALSE)
var_select <- read.csv(file.path(datdir, "variable_selection.csv"))

# define latent variables
lava_econ <- c(
  "RD_E_GERDREG", # gross domestic expenditure on R&D
  "TEPSR_LM220", # gender employment gap
  "YTH_EMPL_110", # youth unemployment
  "TGS00010", # employment rate
  "EDAT_LFSE_33", # youth NEET
  "TESPM050_R" # poverty reduction
)
lava_edu <- c(
  "EDUC_UOE_ENRA17", # pupils pre-primary
  "EDUC_UOE_ENRA13", # distribution of students among education types
  "TGS00109", # tertiary educational attainment
  "EDAT_LFS_9918" # educational attainment
)
lava_health <- c(
  "TGS00064", # hospital beds
  "HLTH_RS_BDSNS", # care beds
  "TGS00058", # cancer deaths
  "TGS00059", # heart disease deaths
  "DEMO_R_MINFIND", # infant mortality
  "HLTH_CD_YPERRTO", # peri- neo-natal mortality
  "DEMO_R_MLIFEXP" # life expectancy
)
lava_demo <- c(
  "TGS00099", # population change (natural, migration, total)
  "DEMO_R_FIND2" # fertility indicators
)
lava_env <- c(
  "pm25", # air particulates
  "ookla", # internet speed
  "TGS00050" # internet usage
)

# identify variables with no variance 
drop_vars <- dat |> 
  select(var_select$variable_name) |>
  select(where(
    ~ all(is.na(.)) |
      (is.numeric(.) & n_distinct(., na.rm = TRUE) <= 1)
  )) |>
  names()

# make final variable selection
var_select <- var_select |>
  filter(select_y == 1) |>
  filter(!variable_name %in% drop_vars) |>
  mutate(latent_variable = case_when(
    resource %in% lava_econ ~ "Economy",
    resource %in% lava_edu ~ "Education",
    resource %in% lava_health ~ "Health",
    resource %in% lava_demo ~ "Demography",
    resource %in% lava_env ~ "Environment"
  ))

# specify model

# model <- "
#   Economy =~ econ1 + econ2 + econ3
#   Education =~ edu1 + edu2 + edu3
#   Health =~ health1 + health2 + health3
#   Demographics =~ demo1 + demo2 + demo3
#   Environment =~ env1 + env2 + env3
# "

model <- ""
for (lava in unique(var_select$latent_variable)) {
  model <- paste(
    model,
    lava, "=~",
    paste(
      var_select |>
        filter(latent_variable == lava) |>
        select(variable_name) |>
        pull(),
      collapse = " + "
    ),
    "\n"
  )
}

# clean model data
md <- dat |> 
  select(var_select$variable_name)

# run Bayesian structural equation model
fit <- bsem(
  model,
  data = md,
  target = "stan",
  burnin = 2000,
  sample = 4000,
  seed = 2600
)

summary(fit, fit.measures = TRUE, standardized = TRUE)

# visualise latent structure
semPaths(
  fit,
  whatLabels = "std",
  intercepts = FALSE
)
