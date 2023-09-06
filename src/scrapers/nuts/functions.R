# Function to create API URLs using previously defined args
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

# Function to load data from API 
# based on URL, returning raw data
url_to_data_frame = function(url){
  res = GET(url)
  data = geojson_sf(rawToChar(res$content))
  data$FID = seq(1, nrow(data))
  data[,paste0('id_nuts_', 0:3)] <- NA
  data[,paste0('tl', 0:3, '_id')] <- NA
  return(data)
}