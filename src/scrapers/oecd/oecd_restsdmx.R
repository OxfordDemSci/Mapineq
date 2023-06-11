# cleanup
rm(list=ls()); gc(); cat("\014"); try(dev.off(), silent=T); options(scipen=999)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), 
                "..", "..", ".."))

# define directories
srcdir <- file.path('src', 'scrapers', 'oecd')
indir <- file.path('in', 'oecd')
outdir <- file.path('out', 'oecd')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))


# get OECD catalogue
oecd_catalogue <- as.data.frame(readSDMX('https://stats.oecd.org/restsdmx/sdmx.ashx/GetDataStructure/ALL'))

# data-of-interest
endpoints <- c('SOCR', 'SOCR_REF', 'SOCX_AGG', 'SOCX_DET', 'SOCX_REF', 'PAG', 
               'IDD', 'WEALTH', 'NRR', 'HGRR', 'METR', 'IA', 'HOURSPOV', 'SBE', 
               'IMW', 'NCC', 'BLI', 'GIDDB2023', 'SIGI2023', 'GIDDB2019', 
               'SIGI2019', 'GIDDB2014', 'SIGI2014', 'GIDDB2012', 'GID2', 
               'GENDER_ENT1', 'GENDER_EMP', 'TIME_USE', 'FAMILY', 'CWB',
               'REGION_ST', 'REGION_ECONOM', 'REG_BUSI_DEMOG', 'REGION_DEMOGR', 
               'REGION_LABOUR', 'REGION_EDUCAT', 'REGION_INNOVATION', 
               'REGION_SOCIAL', 'REGION_MIGRANTS', 'RWB')

oecd_catalogue$mapineq <- as.numeric(oecd_catalogue$id %in% endpoints)

# save catalogue
write.csv(oecd_catalogue, file.path(outdir, 'oecd_catalogue.csv'), row.names=F)


# get xml metadata
mdat <- list()
for(endpoint in endpoints){
  
  # get metadata
  mdat[[endpoint]] <- get_xml(endpoint = endpoint,
                              datdir = file.path(outdir, 'data'),
                              overwrite = FALSE)
}

# get indicator lists
indicators <- list()
for(endpoint in endpoints){
  
  # get metadata
  indicators[[endpoint]] <- get_indicators(endpoint = endpoint,
                                           datdir = file.path(outdir, 'data'),
                                           overwrite = FALSE)
}

# get data
dat <- list()
for(endpoint in endpoints){
  
  # get data
  dat[[endpoint]] <- get_data(endpoint = endpoint,
                              datdir = file.path(outdir, 'data'),
                              query = '/all?',
                              overwrite = FALSE)
}

