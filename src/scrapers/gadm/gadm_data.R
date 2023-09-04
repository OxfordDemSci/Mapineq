# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# Load libraries
library(utils)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), "..", "..", ".."))

# output directory
outdir = file.path('out', 'gadm', 'data')
dir.create(outdir, showWarnings=F, recursive=T)

# Write the GADM data set into geopackage file
options(timeout = max(1000, getOption("timeout")))
gadm_url = "https://geodata.ucdavis.edu/gadm/gadm4.1/gadm_410-gpkg.zip"
gadm_file = file.path(outdir, 'gadm_410-gpkg.zip')
download.file(gadm_url, gadm_file, mode = "wb")

# Unzip the geopackage, load and save in correct format
gadm_df = sf::st_read(unzip(gadm_file))
file.remove(gadm_file)
sf::st_write(gadm_df, file.path(outdir, 'gadm_410.gpkg'))
