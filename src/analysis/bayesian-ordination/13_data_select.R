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
datdir <- file.path(getwd(), "wd", "out", "bayesian-ordination")
outdir <- file.path(getwd(), "wd", "out", "bayesian-ordination", "data_select")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# load data
dat <- read.csv(file.path(datdir, "data_transform", "data_scale.csv"))
var_select <- read.csv(file.path(datdir, "data_derive", "variable_selection.csv"))

# make selection programatically (if not done manually in the csv)
var_select <- var_select %>%
  mutate(select_y = 0) %>%
  mutate(
    select_y = ifelse(
      f_resource %in% c(
        "DEMO_R_FIND2",
        "DEMO_R_MINFIND",
        "EDUC_UOE_ENRA17",
        "pm25",
        "TEPSR_LM220",
        "TESPM050_R",
        "TGS00050",
        "TGS00058",
        "TGS00059",
        "TGS00064",
        "TGS00099",
        "TGS00103",
        "TRAN_R_ACCI", 
        "TGS00101"
      ), 1, select_y
    )
  ) %>%
    mutate(
      select_y = ifelse(
        f_resource == "BD_SIZE_R3" &
          indic_sb %in% c("V97010", "V97020", "V97030") & 
          sizeclas == "TOTAL",
        1,
        select_y
      )
    ) %>%
    mutate(
    select_y = ifelse(
      f_resource == "EDUC_UOE_ENRA13" &
        isced11 %in% c("ED34", "ED35"),
      1,
      select_y
    )
  ) %>%
  mutate(
    select_y = ifelse(
      f_resource == "DEMO_R_MLIFEXP" &
        sex %in% c("T", "R") &
        age %in% c("Y5", paste0("Y", seq(20, 80, 20))),
      1,
      select_y
    )
  ) %>%
  mutate(
    select_y = ifelse(
      f_resource == "EDAT_LFS_9918" &
        sex %in% c("T", "R") &
        age == "Y25-64" &
        citizen == "TOTAL",
      1,
      select_y
    )
  ) %>%
  mutate(
    select_y = ifelse(
      f_resource == "EDAT_LFSE_33" &
        sex %in% c("T", "R") &
        age == "Y18-34" &
        duration == "TOTAL" &
        isced11 %in% c("TOTAL", "ED0-2", "ED3_4", "ED5-8"),
      1,
      select_y
    )
  ) %>%
  mutate(
    select_y = ifelse(
      f_resource == "HLTH_CD_YPERRTO" &
        resid == "TOT_IN" &
        indic_de == "PERIMORRT",
      1,
      select_y
    )
  ) %>%
  mutate(
    select_y = ifelse(
      f_resource == "HLTH_RS_BDSNS" &
        unit == "P_HTHAB",
      1,
      select_y
    )
  ) %>%
  mutate(
    select_y = ifelse(
      f_resource == "ookla" &
        quarter == "1" &
        direction == "download",
      1,
      select_y
    )
  ) %>%
  mutate(
    select_y = ifelse(
      f_resource == "RD_E_GERDREG" &
        unit == "PPS_HAB_KP05",
      1,
      select_y
    )
  ) %>%
  mutate(
    select_y = ifelse(
      f_resource == "TGS00010" &
        sex %in% c("T", "R"),
      1,
      select_y
    )
  ) %>%
  mutate(
    select_y = ifelse(
      f_resource == "TGS00109" &
        sex %in% c("T", "R"),
      1,
      select_y
    )
  ) %>%
    mutate(
      select_y = ifelse(
        f_resource == "YTH_EMPL_030" &
          sex %in% c("T", "R") &
          age %in% c("Y20-29"),
        1,
        select_y
      )
    )
  #   mutate(
  #   select_y = ifelse(
  #     f_resource == "YTH_EMPL_110" &
  #       sex %in% c("T", "R") &
  #       age %in% c("Y15-19", "Y20-24", "Y25-29"),
  #     1,
  #     select_y
  #   )
  # )

var_select %>%
  filter(select_y == 1) %>%
  View()

# apply selection to wide format data
vars <- var_select %>%
  filter(select_y == 1) %>%
  pull(variable_name)

dat_select <- dat %>%
  select(data_year, geo, geo_name, geo_source, geo_year, all_of(vars))

#---- save to disk ----#
write.csv(dat_select, file.path(outdir, "data_select.csv"), row.names = FALSE)
write.csv(var_select, file.path(outdir, "variable_selection.csv"), row.names = FALSE)
