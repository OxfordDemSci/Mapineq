# libraries
library(httr)
library(jsonlite)
library(raster)
library(sf)
library(stringr)

# print with timestamp
tprint <- function(x){
  message(paste0('[', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '] ', x))
}

# load zip file for particular environmental variable
load_data = function(url){
  split_url = str_split(url, "/")[[1]]
  base_url = gsub(".zip", "", split_url[length(split_url)])
  temp = tempfile()
  download.file(url, temp)
  for (month in 1:12){
    file = paste0(base_url, '_', sprintf("%02d", month), '.tif')
    get_data(file, temp, outdir)
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
      raster_df = raster(unzip(zipdir, file))
      writeRaster(raster_df, datpath)
      tprint('     Data saved to disk.')
      
    }
  }, error = function(e) {
    
    tprint(e)
    
  })
}
