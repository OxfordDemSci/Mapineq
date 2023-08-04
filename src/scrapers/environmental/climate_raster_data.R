# cleanup
rm(list=ls()); gc(); cat("\014"); try(dev.off(), silent=T); options(scipen=999)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), 
                "..", "..", ".."))

# define directories
srcdir <- file.path('src', 'scrapers', 'environmental')
outdir <- file.path('out', 'environmental')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))

# define list of URLs to scrape data from
base = "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/"
climate_urls = list(
  minimum_temperature = paste0(base, "wc2.1_30s_tmin.zip"),
  maximum_temperature = paste0(base, "wc2.1_30s_tmax.zip"),
  average_temperature = paste0(base, "wc2.1_30s_tavg.zip"),
  precipitation = paste0(base, "wc2.1_30s_prec.zip"),
  solar_radiation = paste0(base, "wc2.1_30s_srad.zip"),
  wind_speed = paste0(base, "wc2.1_30s_wind.zip"),
  water_vapor_pressure = paste0(base, "wc2.1_30s_vapr.zip")
)

# get data
lapply(climate_urls, load_data)
