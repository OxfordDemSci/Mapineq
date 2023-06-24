# cleanup
rm(list=ls()); gc(); cat("\014"); try(dev.off(), silent=T); options(scipen=999)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), 
                "..", "..", ".."))

# define directories
srcdir <- file.path('src', 'scrapers', 'eurostat')
indir <- file.path('in', 'eurostat')
outdir <- file.path('out', 'eurostat')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))


if(file.exists(file.path(indir, 'eurostat_catalogue.csv'))){
  
  # load eurostat catalogue
  eurostat_catalogue <- read.csv(file.path(indir, 'eurostat_catalogue.csv'))
  
  # identify data-of-interest from prepared catalogue
  endpoints <- eurostat_catalogue$id[eurostat_catalogue$mapineq==1 & !is.na(eurostat_catalogue$mapineq)]
  
} else {
  
  # get eurostat catalogue
  ec_url <- 'https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/dataflow/ESTAT/all?detail=allstubs'
  eurostat_catalogue <- as.data.frame(readSDMX(ec_url))
  
  # identify data-of-interest in this list
  endpoints <- c('')
  eurostat_catalogue$mapineq <- as.numeric(eurostat_catalogue$id %in% endpoints)
  
  # save catalogue
  write.csv(eurostat_catalogue, file.path(outdir, 'eurostat_catalogue.csv'), row.names=F)
}


# get data
dat <- list()
for(endpoint in endpoints){
  get_data(endpoint = endpoint,
           datdir = file.path(outdir, 'data'),
           overwrite = FALSE)
}

#---------------------------------------------------------------
# Obtain XML files of all codelists available 
# for interpreting variable (values)
#---------------------------------------------------------------

# Identify all the different codelists available
cl_url = 'https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/codelist/ESTAT/all?detail=allstubs'
clists = xml2::read_xml(cl_url)
(current_node <- xml_find_all(clists, "//s:Codelists"))
meta_files = unlist(lapply(
  xml_attrs(xml_children(current_node)), 
  function(x){ return(x["id"]) }
))

# Load the codelists using the SDMX API
# and save them to the data directory
mdat <- list()
for (mfile in meta_files){
  mdat[[mfile]] <- get_meta_xml(
    endpoint = mfile,
    datdir = file.path(outdir, 'data'),
    overwrite = FALSE
  )
}

