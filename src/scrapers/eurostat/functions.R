# libraries
library(rsdmx)
library(xml2)


# print with timestamp
tprint <- function(x){
  message(paste0('[', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '] ', x))
}


# get all data from endpoint
get_data <- function(endpoint, datdir, overwrite=F){
  
  tryCatch({

    tprint(endpoint)
    
    dir.create(datdir, showWarnings = F, recursive = T)
    
    result <- data.frame()
    
    # retrieve data
    datpath <- file.path(datdir, paste0(endpoint, '.csv'))
    if(file.exists(datpath) & !overwrite){
      
      tprint(paste0('     File exists and overwrite=F. Skipping endpoint: ', endpoint))

    } else {
      
      query <- paste0('https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/', 
                      endpoint)
      
      # GET data
      result <- as.data.frame(rsdmx::readSDMX(query))
      
      # write data to disk
      write.csv(result, 
                file = datpath, 
                row.names = F)
      
      tprint('     Data saved to disk.')
      
    }
  }, error = function(e) {
    
    tprint(e)
    
  })
}


# load data
load_data <- function(datdir){
  
  # list data
  lf <- list.files(datdir)
  
  # load data
  if(length(lf) == 0){
    tprint(paste('No data:', datdir))
    result <- NULL
  } else if(length(lf == 1)){
    result <- read.csv(file.path(datdir, f))
  } else {
    result <- list()
    for(f in lf){
      endpoint <- tools::file_path_sans_ext(f)
      result[[endpoint]] <- read.csv(file.path(datdir, f))
    }
  }
  return(result)
}

#---------------------------------------------------------------
# Obtain XML files of all codelists available 
# for interpreting variable (values)
#---------------------------------------------------------------

get_meta_xml  <- function(
    endpoint, # API endpoint
    datdir, # Data directory
    overwrite=F # Overwrite existing files?
){
  
  tryCatch({
    
    tprint(endpoint)
    dir.create(datdir, showWarnings = F, recursive = T)
    datpath <- file.path(datdir, paste0(endpoint, '.xml'))
    
    # Retrieve data (from file if exists and no overwriting, otherwise from API)
    if(file.exists(datpath) & !overwrite){
      
      tprint(paste0('     File exists and overwrite=F. Skipping endpoint: ', endpoint))
      result <- xml2::read_xml(datpath)
      
    } else {
      
      query <- paste0('https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/codelist/ESTAT/', endpoint)
      result <- xml2::read_xml(query)
      xml2::write_xml(result, file = datpath)
      tprint('     Metadata XML saved to disk.')
      
    }
  }, error = function(e) {
    
    tprint(e)
    
  })
}

