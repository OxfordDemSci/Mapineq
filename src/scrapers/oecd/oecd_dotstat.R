# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# Load necessary libraries
library(httr)
library(jsonlite)
library(tidyr)
library(stringr)
library(rsdmx)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), "..", "..", ".."))

# directories
srcdir <- file.path('src', 'scrapers', 'oecd')
outdir <- file.path('out', 'oecd')
dir.create(outdir, showWarnings=F, recursive=T)

# load data
oecd_regions <- read.csv(file.path('in', 'oecd', 'regions', 'OECD_TL3_2020.csv'))

# mapineq countries
oecd_regions <- oecd_regions[oecd_regions$mapineq, ]

# query demographic variables
query_string <- paste0('http://stats.oecd.org/restsdmx/sdmx.ashx/GetData/REGION_DEMOGR/2.',
                       '.',
                       'T.T.ALL.',
                       '2021',
                       '/all?')

tl2_popwgt <- as.data.frame(readSDMX(query_string))
