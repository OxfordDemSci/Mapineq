# libraries
library(rsdmx)
library(xml2)


# print with timestamp
tprint <- function(x){
  message(paste0('[', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '] ', x, '\n'))
}


# get all data from endpoint
get_data <- function(endpoint, datdir, overwrite=F){
  
  tryCatch({

    tprint(endpoint)
    
    dir.create(datdir, showWarnings = F, recursive = T)
    
    result <- data.frame()
    
    # retrieve data
    datpath <- file.path(datdir, paste0(endpoint, '.csv'))
    if(!overwrite & file.exists(datpath)){
      
      tprint(paste0('     File exists and overwrite=F. Loading data from file: ', datpath))

      result <- read.csv(datpath)
      
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
    
  }, finally = {
    
    return(result)
    
  })
}


# Get xml metadata for endpoint
get_xml <- function(endpoint, datdir, overwrite=FALSE){
  tryCatch({
    
    dir.create(datdir, showWarnings = F, recursive = T)
    
    # define metadata query
    query <- paste0('https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/categoryscheme/ESTAT/',
                    endpoint)
    
    tprint(endpoint)
    
    # retrieve data
    datpath <- file.path(datdir, paste0(endpoint, '.xml'))
    if(!overwrite & file.exists(datpath)){
      
      tprint(paste0('     File exists and overwrite=F. Loading data from file: ', datpath))
      
      result <- xml2::read_xml(datpath)
      
    } else {
      
      # query metadata
      result <- xml2::read_xml(query)

      # write to disk
      xml2::write_xml(result, 
                      file = datpath)
      
      tprint('     Metadata XML saved to disk.')
      
    }
  }, error = function(e) {
    
    tprint(e)
    
  }, finally = {
    
    return(result)
    
  })
}


# Get list of indicators and their descriptions for endpoint
# TODO: Doesn't work for endpoints without code list item named "Indicators" 
get_codelist <- function(endpoint, datdir, overwrite=FALSE){
  
  tryCatch({
    
    dir.create(datdir, showWarnings = F, recursive = T)
    result <- data.frame()
    
    # define metadata query
    query <- paste0('https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/codelist/ESTAT/',
                    endpoint)
    
    tprint(endpoint)
    
    # retrieve data
    datpath <- file.path(datdir, paste0(endpoint, '_codebook.csv'))
    if(!overwrite & file.exists(datpath)){
      
      tprint(paste0('     File exists and overwrite=F. Loading metadata from file: ', datpath))
      
      result <- read.csv(datpath)
      
    } else {
      
      # query metadata
      dsd <- rsdmx::readSDMX(query)
      
      # find list of indicators
      i <- which(sapply(dsd@codelists@codelists, 
                        function(x) slot(x, "Name")$en) == 'Indicator')
      
      # indicator code list
      cl <- dsd@codelists@codelists[[i]]@Code
      
      # empty data frame for results
      result <- data.frame(matrix(NA, 
                                  nrow=length(cl), 
                                  ncol=4))
      names(result) <- c('dataset', 'indicator', 'description_en', 'description_fr')
      
      
      # empty data frame for results
      result <- data.frame(matrix(NA, 
                                  nrow=length(cl), 
                                  ncol=4))
      names(result) <- c('dataset', 'indicator', 'description_en', 'description_fr')
      
      # put results into data frame
      for(i in 1:nrow(result)){
        x <- cl[[i]]
        result[i,] <- c(endpoint,
                        x@id,
                        x@description$en,
                        x@description$fr)
      }
      
      # write to disk
      write.csv(result, 
                file = datpath,
                row.names = FALSE)
      
      tprint('     Metadata saved to disk.')
      
    }
  }, error = function(e) {
    
    tprint(e)
    
  }, finally = {
    
    return(result)
    
  })
}


build_codebook <- function(datdir){
  lf <- list.files(datdir)
  lf <- lf[grepl('codebook', lf)]
  result <- read.csv(file.path(datdir, lf[1]))
  for(i in 2:length(lf)){
    result <- rbind(result, 
                    read.csv(file.path(datdir, lf[i])))
  }
  return(result)
}
