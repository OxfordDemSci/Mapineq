# Load libraries
library(httr)
library(jsonlite)
library(tidyr)
library(stringr)

# Define the arguments for the type of data to retrieve
nuts_args = list(
  year = "2021",
  filetype = "geojson",
  geotype = "RG",
  scale = "20",
  epsg = "4326"
)

# Function to create API URLs using previously defined args
base_url = "https://gisco-services.ec.europa.eu/distribution/v2/nuts/"
create_api_url = function(args){
  url_list = list()
  for (i in 0:3){
    url_list[[i + 1]] = paste0(
      base_url,
      args$filetype, "/",
      "NUTS_", args$geotype, "_", 
      args$scale, "M_", 
      args$year, "_", 
      args$epsg, 
      "_LEVL_", i, ".", 
      args$filetype
    )
  }
  return(url_list)
}

# Create API urls from args
urls = create_api_url(nuts_args)

# Function to load data from API 
# based on URL, returning raw data
url_to_data_frame = function(url){
  res = GET(url)
  data = fromJSON(rawToChar(res$content))
  return(data$features)
}

# Retrieve data for each URL
df_list = lapply(urls, url_to_data_frame)

# Add higher-level NUTS to lower-level NUTS data
# For example, for NUTS1 also add relevant NUTS0
# For NUTS2 also add relevant NUTS1 and NUTS0
# For NUTS3 also add relevant NUTS2, NUTS1 and NUTS0, etc.
for (i in 1:length(df_list)){
  vals = seq(0, i - 1)
  for (j in vals){
    if (i == (j + 1)){
      df_list[[i]][paste0("id_nuts_", j)] = df_list[[i]]$id
    } else {
      df_list[[i]][paste0("id_nuts_", j)] = substr(df_list[[i]]$id, 1, j + 2)
    }
  }
}

# Write the data sets for different NUTS levels to .csv
for (i in 1:length(df_list)){
  df_list[[i]] = df_list[[i]] %>%
    unnest(c(geometry, properties), names_sep = ".")
  jsonlite::write_json(path = paste0("nuts", i - 1, "_info.json"), df_list[[i]], pretty = TRUE)
}
