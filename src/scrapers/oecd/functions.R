# libraries
library(rsdmx)


# print with timestamp
tprint <- function(x){
  message(paste0('[', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '] ', x, '\n'))
}


# http request
request_oecd <- function(query, fname, overwrite=F){
  
  tryCatch({

    result <- data.frame()
    
    if(!overwrite & file.exists(fname)){
      
      tprint(paste0('File exists and overwrite=F. Loading data from file: ', fname))

      result <- read.csv(fname)
      
    } else {
      
      tprint(query)
      
      query <- paste0('http://stats.oecd.org/restsdmx/sdmx.ashx/GetData/', query)
      
      # GET request
      result <- as.data.frame(rsdmx::readSDMX(query))
      
      # write data to disk
      write.csv(result, 
                file = fname, 
                row.names = F)
    }
  }, error = function(e) {
    tprint(e)
  }, finally = {
    return(result)
  })
}
