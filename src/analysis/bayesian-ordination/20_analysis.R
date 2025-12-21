# This script conducts a Bayesian latent factor analysis on Mapineq indicators

# cleanup
rm(list = ls())
gc()

# install libraries (if needed)
required_packages <- c("dplyr", "blavaan", "semPlot", "caret", "coda", "bayesplot")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

# load libraries
library(semPlot)
library(blavaan)
library(dplyr)
library(caret)
library(bayesplot)
library(coda)
future::plan("multicore")
options(mc.cores = 4)

# # load functions
# source(file.path(getwd(), "src", "analysis", "bayesian-ordination", "2_analysis_fun.R"))

# directories
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_select")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "analysis")
dir.create(file.path(outdir, "traceplots"), showWarnings = FALSE, recursive = TRUE)

# load data
dat <- read.csv(file.path(datdir, "data_select.csv"), check.names = FALSE)
var_select <- read.csv(file.path(datdir, "variable_selection.csv"))

#---- define latent variables ----#

# Gender equality
lava1 <- c(
  "TEPSR_LM220" # gender employment gap
)

# Economic Development
lava2 <- c(
  "YTH_EMPL_030", # youth employment rate
  "EDAT_LFSE_33" , # youth NEET employment rates
  "TGS00103", # poverty reduction
  "TGS00010", # employment rate by education level
  "pm25", # air particulates
  "ookla", # internet speed
  "TGS00050" # internet usage
)

# Human Capital
lava3 <- c(
  "TGS00058", # cancer deaths
  "TGS00059", # heart disease deaths
  "DEMO_R_FIND2", # fertility indicators
  "TGS00101", # life expectancy at birth
  "TGS00109", # tertiary educational attainment
  "DEMO_R_MINFIND", # infant mortality
  "HLTH_CD_YPERRTO", # peri- neo-natal mortality
  "EDUC_UOE_ENRA17" # pupils pre-primary
)

# "EDAT_LFS_9918" # educational attainment
# "TGS00064", # hospital beds
# "TGS00099", # population change (natural, migration, total)
# "TRAN_R_ACCI" # transportation accidents
# "BD_SIZE_R3" # business demography (births, deaths, change)
# "EDUC_UOE_ENRA13", # distribution of students among education types

lava_vars <- c(lava1, lava2, lava3)

#---- variable selection ----#

# unselect variables not in latent variables
var_select <- var_select %>% 
  mutate(select_y = ifelse(!f_resource %in% lava_vars, 0, select_y))

# identify variables with no variance
drop_vars <- dat %>%
  select(var_select %>% filter(select_y == 1) %>% pull(variable_name)) %>%
  select(where(
    ~ all(is.na(.)) |
      (is.numeric(.) & n_distinct(., na.rm = TRUE) <= 1)
  )) %>%
  names()

kill_list <- c() # "TGS00109_4", "TGS00101_4", "TGS00101_2", "TEPSR_LM220_1"
drop_vars <- c(drop_vars, kill_list)

# make variable selection
var_select <- var_select %>%
  filter(select_y == 1) %>%
  filter(!variable_name %in% drop_vars) %>%
  mutate(latent_variable = case_when(
    f_resource %in% lava1 | sex == "R" ~ "Gender_Equality",
    f_resource %in% lava2 ~ "Economic_Development",
    f_resource %in% lava3 ~ "Human_Capital"
  )) %>%
  mutate(select_y = case_when(
    is.na(latent_variable) ~ 0,
    TRUE ~ select_y
  ))

# list variables
vars <- var_select %>%
  filter(select_y == 1) %>%
  pull(variable_name) %>%
  sort()

#---- model data ----#

# select columns
md <- dat %>%
  select(geo, geo_name, all_of(vars))

# drop columns to remove collinearity
cor_mat <- cor(md %>% select(-geo, -geo_name), use = "pairwise.complete.obs")

to_drop_idx <- findCorrelation(cor_mat, cutoff = 0.9, verbose = TRUE)
to_drop_names <- colnames(cor_mat)[to_drop_idx]

md <- md %>% select(-all_of(to_drop_names))

# update variables list and selection
var_select <- var_select %>%
  mutate(select_y = case_when(
    variable_name %in% to_drop_names ~ 0,
    TRUE ~ select_y
  ))

vars <- var_select %>%
  filter(select_y == 1) %>%
  pull(variable_name) %>%
  sort()

# drop rows with insufficient data (i.e. need more than 3 data points per row)
drop_rows <- md %>%
  filter(rowSums(!is.na(select(., -geo, -geo_name))) < 4) %>%
  pull(geo)

md <- md %>%
  filter(!geo %in% drop_rows)

# country
md <- md %>%
  mutate(country = substr(geo, 1, 2))

# save data
write.csv(md, file.path(outdir, "md.csv"), row.names = FALSE)

# missingness
missingness <-
  sum(is.na(md[, vars])) /
    prod(dim(md[, vars]))

print(paste0("missingness: ", round(missingness, 2)))


#---- specify model ----#

# model <- "
#   Economy =~ econ1 + econ2 + econ3
#   Education =~ edu1 + edu2 + edu3
#   Health =~ health1 + health2 + health3
#   Demographics =~ demo1 + demo2 + demo3
#   Environment =~ env1 + env2 + env3
# "

# list latent variables
lavas <- var_select %>%
  pull(latent_variable) %>%
  unique()
lavas <- lavas[!is.na(lavas)]


model <- ""
for (lava in lavas) {
  vars_lava <- var_select %>%
    filter(latent_variable == lava & select_y == TRUE) %>%
    select(variable_name) %>%
    pull()

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


#---- run model ----#

# random seed
seed <- sample.int(.Machine$integer.max, 1L)

# inits
inits <- "simple"
# inits <- blavInspect(fit_initial, "inits")

# priors
# my_priors <- dpriors(
#   lambda = "normal(0, 1)", 
#   alpha = "normal(0, 1)"
# )

# run Bayesian structural equation model
time_start <- Sys.time()
fit <- bsem(
  model,
  data = md,
  target = "stan",
  inits = inits,
  # cluster = "country",
  burnin = 500,
  sample = 1000,
  # dpriors = my_priors,
  std.lv = TRUE,
  meanstructure = TRUE,
  # save.lvs = TRUE,  # required for blavPredict(..., type = c("yhat", "ypred"))
  seed = seed
)
time_end <- Sys.time()
print(time_end - time_start)

# save model
saveRDS(fit, file.path(outdir, "fit.rds"))
saveRDS(seed, file.path(outdir, "seed.rds"))

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


# trace plots
mcmc_list <- blavInspect(fit, "mcmc")
draws_array <- aperm(as.array(mcmc_list), c(1, 3, 2))

pars <- varnames(mcmc_list)
n_pars <- length(pars)

chunk_size <- 9
chunk_ids <- ceiling(seq_along(pars) / chunk_size)
param_chunks <- split(pars, chunk_ids)

for (i in seq_along(param_chunks)) {
  this_pars <- param_chunks[[i]]

  jpeg(
    filename = file.path(outdir, "traceplots", paste0("traceplots_", i, ".jpg")),
    width = 1200,
    height = 1200,
    quality = 95
  )

  p <- mcmc_trace(
    draws_array,
    pars       = this_pars,
    facet_args = list(ncol = 3)
  ) +
    ggtitle(sprintf(
      "Traceplots for parameters %d–%d",
      (i - 1) * chunk_size + 1,
      min(i * chunk_size, n_pars)
    ))
  print(p)
  dev.off()
}
