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

# Collect only relevant data from messy .csv
clean_woudc_data_csv = function(raw_df){
  month_ind = which(grepl("#monthly", raw_df[, 1]) | grepl("#MONTHLY", raw_df[, 1]))
  collect_row = raw_df[month_ind + 2, ]
  names(collect_row) = raw_df[month_ind + 1, ]
  return(collect_row)
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
        raster_df = raster(unzip(zipdir, file))
        writeRaster(raster_df, datpath)
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
