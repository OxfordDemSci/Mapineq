# libraries
library(httr)
library(jsonlite)
library(raster)
library(sf)
library(stringr)
options(timeout=3600)

# print with timestamp
tprint <- function(x){
  message(paste0('[', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '] ', x))
}

# load zip file for particular environmental variable
load_climate_data = function(url, datdir){
  split_url = str_split(url, "/")[[1]]
  base_url = gsub(".zip", "", split_url[length(split_url)])
  temp = tempfile()
  download.file(url, temp)
  for (month in 1:12){
    file = paste0(base_url, '_', sprintf("%02d", month), '.tif')
    get_data(file, temp, datdir)
  }
  unlink(temp)
}


# obtain monthly data from zip file of environmental variable
get_data <- function(file, zipdir, datdir, overwrite=F){
  
  tryCatch({
    
    tprint(file)
    dir.create(datdir, showWarnings = F, recursive = T)
    
    # retrieve data
    datpath <- file.path(datdir, file)
    if(file.exists(datpath) & !overwrite){
      
      tprint(paste0('     File exists and overwrite=F. Skipping file: ', file))
      
    } else {
      
      # obtain data and write to disk
      if (grepl(".tif", file)){
        raster(unzip(zipdir, file, exdir = datdir))
      } else if (grepl(".shp", file) | grepl(".csv", file)){
        if (length(zipdir) > 1){
          file_to_read = zipdir[grepl(".gpkg", zipdir)]
        } else {
          file_to_read = zipdir
        }
        polygon_df = st_read(file_to_read)
        if (grepl(".csv", file)){
          lo = "GEOMETRY=AS_XY"
        } else {
          lo = NULL
        }
        st_write(polygon_df, datpath, layer_options = lo, append = !overwrite)
      } else {
        break("Data type not recognized -- should be either 'raster (.tif)' or 'polygon (.shp)'.")
      }
      
      tprint('     Data saved to disk.')
      
    }
    
    return(T)
    
  }, error = function(e) {
    
    tprint(e)
    return(F)
    
  })
}
