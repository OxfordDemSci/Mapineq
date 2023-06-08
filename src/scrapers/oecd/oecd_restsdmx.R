# cleanup
rm(list=ls()); gc(); cat("\014"); try(dev.off(), silent=T); options(scipen=999)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), 
                "..", "..", ".."))

# define directories
srcdir <- file.path('src', 'scrapers', 'oecd')
outdir <- file.path('out', 'oecd')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))

# define queries
query <- list(region_st = paste0('REGION_ST/',  # endpoint FAIL 400
                                 '1+2+3.',  # TL
                                 '.',  # REG_ID
                                 '.',  # IND
                                 ''),  # TIME
              region_econom = paste0('REGION_ECONOM/',  # endpoint SUCCESS
                                     '1+2+3.',  # TL
                                     '.',  # REG_ID
                                     'SNA_2008.',  # SERIES
                                     '.',  # VAR
                                     '.',  # MEAS,
                                     'ALL.',  # POS
                                     ''),  # TIME
              region_busi_demog = paste0('REGION_BUSI_DEMOG/',  # endpoint FAIL 500
                                     '1+2+3.',  # TL
                                     '.',  # REG_ID
                                     '.',  # VAR
                                     '.',  # SECTOR
                                     '.',  # SIZECLASS
                                     ''),  # TIME
              region_demogr = paste0('REGION_DEMOGR/',  # endpoint SUCCESS
                                     '1+2+3.',  # TL
                                     '.',  # REG_ID
                                     '.',  # VAR
                                     'T+F+M.',  # SEX
                                     'ALL.',  # POS
                                     '',  # TIME
                                     '/all?'),
              region_labour = paste0('REGION_LABOUR/',  # endpoint SUCCESS
                                     '1+2+3.',  # TL
                                     '.',  # REG_ID
                                     '.',  # VAR
                                     'T+F+M.',  # SEX
                                     'ALL.',  # POS
                                     ''),  # TIME
              region_educat = paste0('REGION_EDUCAT/',  # endpoint FAIL 400
                                     '.',  # LOCATION
                                     '.',  # REG_ID
                                     '.',  # IND
                                     '.',  # ISC11
                                     'T+F+M.',  # GENDER
                                     '.',  # MEAS
                                     ''),  # TIME
              region_innovation = paste0('REGION_INNOVATION/',  # endpoint SUCCESS
                                         '1+2+3.',  # TL
                                         '.',  # REG_ID
                                         '.',  # VAR
                                         'ALL.',  # POS
                                         ''),  # TIME
              region_social = paste0('REGION_SOCIAL/',  # endpoint SUCCESS
                                     '1+2+3.',  # TL
                                     '.',  # REG_ID
                                     '.',  # VAR
                                     'ALL.',  # POS
                                     ''),  # TIME
              region_migrants = paste0('REGION_MIGRANTS/',  # endpoint FAIL 400
                                       '1+2+3.',  # TL
                                       '.',  # REG_ID
                                       '.',  # ORIGIN
                                       '.',  # IND
                                       'ALL.',  # POS
                                       ''),  # TIME
              region_rwb = paste0('REGION_RWB/',  # endpoint FAIL 500
                                 '1+2+3.',  # TL
                                 '.',  # REG_ID
                                 '.',  # VAR
                                 '.',  # MEAS
                                 'ALL.',  # POS
                                 '')  # TIME
)

# submit http requests
dat <- list()
for(endpoint in names(query)){
  dat[[endpoint]] <- request_oecd(query = query[[endpoint]], 
                                  fname = file.path(outdir, paste0(endpoint, '.csv')),
                                  overwrite = FALSE)
}
