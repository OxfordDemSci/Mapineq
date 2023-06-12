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
endpoints <- c('BLI', 'CWB', 'EPER', 'FAMILY', 'GBARD_NABS2007', 'GENDER_EMP', 
               'GENDER_ENT1', 'GID2', 'GIDDB2012', 'GIDDB2014', 'GIDDB2019', 
               'GIDDB2023', 'HGRR', 'HOURSPOV', 'IA', 'IDD', 'IMW', 'MEM4', 
               'METR', 'MW_CURP', 'NCC', 'NRR', 'PAG', 'RDTAX', 
               'REG_BUSI_DEMOG', 'REGION_DEMOGR', 'REGION_ECONOM', 
               'REGION_EDUCAT', 'REGION_INNOVATION', 'REGION_LABOUR', 
               'REGION_MIGRANTS', 'REGION_SOCIAL', 'REGION_ST', 'RWB', 'SBE', 
               'SIGI2014', 'SIGI2019', 'SIGI2023', 'SNA_TABLE10', 'SNA_TABLE11', 
               'SOCR', 'SOCR_REF', 'SOCX_AGG', 'SOCX_DET', 'SOCX_REF', 
               'TIME_USE', 'WEALTH')

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
codebook <- build_codebook(datdir = file.path(outdir, 'data'))
write.csv(codebook, file = file.path(outdir, 'codebook.csv'), row.names = FALSE)

# get data
dat <- list()
for(endpoint in endpoints){
  
  # get data
  dat[[endpoint]] <- get_data(endpoint = endpoint,
                              datdir = file.path(outdir, 'data'),
                              query = '/all?',
                              overwrite = FALSE)
}

