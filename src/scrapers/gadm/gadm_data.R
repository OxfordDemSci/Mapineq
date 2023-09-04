# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# Load libraries
library(httr)
library(tidyr)
library(stringr)
library(geojsonsf)
library(sf)
library(countrycode)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), "..", "..", ".."))

# output directory
outdir = file.path('out', 'gadm')
dir.create(outdir, showWarnings=F, recursive=T)

# Write the GADM data set into geopackage file
gadm_url = "https://geodata.ucdavis.edu/gadm/gadm4.1/gadm_410-gpkg.zip"
gadm_file = paste0(outdir, "/gadm_410.gpkg")
download.file(gadm_url, gadm_file, mode = "wb")