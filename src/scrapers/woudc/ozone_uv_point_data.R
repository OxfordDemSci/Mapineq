# cleanup
rm(list=ls()); gc(); cat("\014"); try(dev.off(), silent=T); options(scipen=999)

# libraries
library(plyr)
library(stringr)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), 
                "..", "..", ".."))

# define directories
srcdir <- file.path('src', 'scrapers', 'woudc')
outdir <- file.path('out', 'woudc', 'data')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))

# get data set information per 10000 features
start_idx = 0
res = T
while (res){
  url = paste0("https://geo.woudc.org/ows?service=WFS&version=1.1.0&request=GetFeature&outputformat=GeoJSON&typename=filelist&filter=%3Cogc:Filter%3E%3Cogc:And%3E%3Cogc:BBOX%3E%3CPropertyName%3EmsGeometry%3C/PropertyName%3E%3CBox%20srsName=%22EPSG:4326%22%3E%3Ccoordinates%3E-189.14062500000003,-83.67694304841552%20189.84375,85.51339830988749%3C/coordinates%3E%3C/Box%3E%3C/ogc:BBOX%3E%3Cogc:PropertyIsBetween%3E%3Cogc:PropertyName%3Einstance_datetime%3C/ogc:PropertyName%3E%3Cogc:LowerBoundary%3E1924-01-01%2000:00:00%3C/ogc:LowerBoundary%3E%3Cogc:UpperBoundary%3E2023-12-30%2023:59:59%3C/ogc:UpperBoundary%3E%3C/ogc:PropertyIsBetween%3E%3C/ogc:And%3E%3C/ogc:Filter%3E&sortby=instance_datetime%20DESC&startindex=", start_idx * 1e4,"&maxfeatures=10000")
  res = get_data(paste0('ozone_uv_', sprintf("%02d", start_idx + 1), '.csv'), url, outdir)
  start_idx = start_idx + 1
}

# combine metadata into one big dataset and write to file
data_files = as.list(list.files(outdir, '.csv', full.names = T))
df_list = lapply(data_files, read.csv)
meta_df = plyr::rbind.fill(df_list)
write.csv(meta_df, file.path(outdir, 'ozone_uv_meta.csv'))

# remove all separate files
lapply(data_files, file.remove)

# check indicators available
unique(unlist(lapply(as.list(meta_df$url), function(x){ str_split(x, "/")[[1]][6] })))

# use metadata to load actual data sets
ozone_uv = list()
pb = txtProgressBar(min = 0, max = nrow(meta_df)) 
for (idx in 1:nrow(meta_df)){
  
  tryCatch({
    # Download data and process
    dfile = read.csv(meta_df$url[idx])
    
    # Collect only relevant data from messy .csv
    ozone_uv[[idx]] = clean_woudc_data_csv(dfile)
  }, error = function(e){
    message(paste0("Error in reading URL: ", meta_df$url[idx]))
    message(paste0("Error message: ", e))
  })
  
  # Update progress bar
  setTxtProgressBar(pb, idx)
  
}
close(pb)
correct_indices = which(unlist(lapply(ozone_uv, is.data.frame)))
ozone_uv = ozone_uv[correct_indices]

# Add metadata but remove row names
ozone_uv_df = cbind(plyr::rbind.fill(ozone_uv), meta_df[correct_indices, ])
ozone_uv_df = ozone_uv_df[, names(ozone_uv_df) != "X.1"]

# Write data set to .csv
write.csv(ozone_uv_df, file.path(outdir, 'ozone_uv.csv'))
