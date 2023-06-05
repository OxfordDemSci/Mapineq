# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# Load necessary libraries
library(httr)
library(jsonlite)
library(tidyr)
library(stringr)
library(readsdmx)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), "..", "..", ".."))

# directories
srcdir <- file.path('src', 'scrapers', 'oecd')
outdir <- file.path('out', 'oecd')
dir.create(outdir, showWarnings=F, recursive=T)

# country list
countries <- c()