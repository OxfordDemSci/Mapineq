# cleanup
rm(list=ls()); gc(); cat("\014"); try(dev.off(), silent=T); options(scipen=999)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), 
                "..", "..", ".."))

# define directories
srcdir <- file.path('src', 'scrapers', 'worldclim')
outdir <- file.path('out', 'worldclim', 'data')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))

# define list of URLs to scrape data from
base = "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/"
version = "2.1"
resolution = "10m"
climate_urls = list(
  minimum_temperature = paste0(base, "wc", version, "_", resolution, "_tmin.zip"),
  maximum_temperature = paste0(base, "wc", version, "_", resolution, "_tmax.zip"),
  average_temperature = paste0(base, "wc", version, "_", resolution, "_tavg.zip"),
  precipitation = paste0(base, "wc", version, "_", resolution, "_prec.zip"),
  solar_radiation = paste0(base, "wc", version, "_", resolution, "_srad.zip"),
  wind_speed = paste0(base, "wc", version, "_", resolution, "_wind.zip"),
  water_vapor_pressure = paste0(base, "wc", version, "_", resolution, "_vapr.zip")
)

# get data
lapply(climate_urls, load_climate_data, outdir)
