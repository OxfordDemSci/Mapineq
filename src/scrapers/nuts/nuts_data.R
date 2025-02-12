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
srcdir <- file.path('src', 'scrapers', 'nuts')
outdir <- file.path('out', 'nuts', 'data')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))

# Define the arguments for the type of data to retrieve
nuts_args = list(
  year = "2021",
  filetype = "geojson",
  geotype = "RG",
  scale = "01",
  epsg = "4326"
)

# Create API URLs using previously defined args
base_url = "https://gisco-services.ec.europa.eu/distribution/v2/nuts/"
urls = create_api_url(nuts_args)

# Retrieve data for each URL
df_list = lapply(urls, url_to_data_frame)

# Add higher-level NUTS to lower-level NUTS data
# For example, for NUTS1 also add relevant NUTS0
# For NUTS2 also add relevant NUTS1 and NUTS0
# For NUTS3 also add relevant NUTS2, NUTS1 and NUTS0, etc.
eu_countries = c("UK", countrycode::codelist$iso2c[!is.na(countrycode::codelist$eu28)])
exc_countries = c('DE', 'BE', 'UK')
for (i in 1:length(df_list)){
  vals = seq(0, i - 1)
  for (j in vals){
    if (i == (j + 1)){
      df_list[[i]][paste0("id_nuts_", j)] = df_list[[i]]$NUTS_ID
    } else {
      df_list[[i]][paste0("id_nuts_", j)] = substr(df_list[[i]]$NUTS_ID, 1, j + 2)
    }
    eu_ind = which(df_list[[i]]$id_nuts_0 %in% eu_countries)
    exc_ind = which(df_list[[i]]$id_nuts_0 %in% exc_countries)
    df_list[[i]][paste0("tl", j, "_id")] = NA
    df_list[[i]][eu_ind, paste0("tl", j, "_id")] = sf::st_drop_geometry(df_list[[i]])[eu_ind, paste0("id_nuts_", j)]
    if (j == 2){
      df_list[[i]][exc_ind, paste0("tl", j, "_id")] = sf::st_drop_geometry(df_list[[i]])[exc_ind, paste0("id_nuts_", j - 1)]
      df_list[[i]][exc_ind, paste0("tl", j - 1, "_id")] = NA
    }
  }
}

# Write the data sets for different NUTS levels to .csv
for (i in 1:length(df_list)){
  sf::st_write(
    obj = df_list[[i]],
    dsn = file.path(outdir, paste0("nuts", i - 1, ".gpkg")),
    append = FALSE)
}

