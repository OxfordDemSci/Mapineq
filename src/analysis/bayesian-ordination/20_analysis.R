# This script conducts a Bayesian latent factor analysis on Mapineq indicators

# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("dplyr", "blavaan", "semPlot")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(semPlot)
library(blavaan)
library(dplyr)
future::plan("multicore")
options(mc.cores = 4)

# # load functions
# source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "2_analysis_fun.R"))

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_select")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
dat <- read.csv(file.path(datdir, "data_select.csv"), check.names = FALSE)
var_select <- read.csv(file.path(datdir, "variable_selection.csv"))

# define latent variables
lava_econ <- c(
  # "RD_E_GERDREG", # gross domestic expenditure on R&D
  # "TEPSR_LM220", # gender employment gap
  # "YTH_EMPL_110", # youth unemployment
  "TGS00010", # employment rate
  "EDAT_LFSE_33" # , # youth NEET
  # "TESPM050_R" # poverty reduction
)
lava_edu <- c(
  "EDUC_UOE_ENRA17", # pupils pre-primary
  # "EDUC_UOE_ENRA13", # distribution of students among education types
  # "TGS00109", # tertiary educational attainment
  "EDAT_LFS_9918" # educational attainment
)
lava_health <- c(
  # "TGS00064", # hospital beds
  # "HLTH_RS_BDSNS", # care beds
  "TGS00058", # cancer deaths
  "TGS00059", # heart disease deaths
  "DEMO_R_MINFIND", # infant mortality
  # "HLTH_CD_YPERRTO", # peri- neo-natal mortality
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
drop_vars <- dat %>%
  select(var_select %>% filter(select_y == 1) %>% pull(variable_name)) %>%
  select(where(
    ~ all(is.na(.)) |
      (is.numeric(.) & n_distinct(., na.rm = TRUE) <= 1)
  )) %>%
  names()

# View(dat %>% select(all_of(drop_vars)))

# make final variable selection
var_select <- var_select %>%
  filter(select_y == 1) %>%
  filter(!variable_name %in% drop_vars) %>%
  mutate(latent_variable = case_when(
    f_resource %in% lava_econ ~ "Economy",
    f_resource %in% lava_edu ~ "Education",
    f_resource %in% lava_health ~ "Health",
    f_resource %in% lava_demo ~ "Demography",
    f_resource %in% lava_env ~ "Environment"
  ))

# specify model

# model <- "
#   Economy =~ econ1 + econ2 + econ3
#   Education =~ edu1 + edu2 + edu3
#   Health =~ health1 + health2 + health3
#   Demographics =~ demo1 + demo2 + demo3
#   Environment =~ env1 + env2 + env3
# "

lavas <- var_select %>%
  pull(latent_variable) %>%
  unique()
lavas <- lavas[!is.na(lavas)]

vars <- c()
model <- ""
for (lava in lavas) {
  vars_lava <- var_select %>%
    filter(latent_variable == lava) %>%
    select(variable_name) %>%
    pull()

  vars <- c(vars, vars_lava)

  model <- paste0(
    model,
    lava, " =~ ",
    paste(
      vars_lava,
      collapse = " + "
    ),
    "\n"
  )
}
cat(model)

# clean model data
md <- dat %>%
  select(data_year, geo, geo_name, geo_source, geo_year, all_of(vars))

# save data
write.csv(md, file.path(outdir, "md.csv"), row.names = FALSE)

# missingness
missingness <-
  sum(is.na(md[, vars])) /
    prod(dim(md[, vars]))

print(paste0("missingness: ", round(missingness, 2)))

# random seed
seed <- sample.int(.Machine$integer.max, 1L)

# run Bayesian structural equation model
time_start <- Sys.time()
fit <- bsem(
  model,
  data = md,
  target = "stan",
  burnin = 1000,
  sample = 2000,
  # save.lvs = TRUE,  # required for blavPredict(..., type = c("yhat", "ypred"))
  seed = seed
)
time_end <- Sys.time()
print(time_end - time_start)

# save model
saveRDS(fit, file.path(outdir, "fit.rds"))
saveRDS(seed, file.path(outdir, "seed.rds")) # TODO: check if this is already saved in the fit object

# model summary
summary(fit, fit.measures = TRUE, standardized = TRUE)

# visualise latent structure
jpeg(
  filename = file.path(outdir, "sempath.jpg"),
  height = 12,
  width = 12,
  units = "in",
  res = 300
)
semPaths(
  fit,
  whatLabels = "std",
  intercepts = FALSE
)
dev.off()
