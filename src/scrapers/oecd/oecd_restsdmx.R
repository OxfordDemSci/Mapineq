# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), "..", "..", ".."))

# directories
srcdir <- file.path('src', 'scrapers', 'oecd')
outdir <- file.path('out', 'oecd')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))

# load data
oecd_regions <- read.csv(file.path('in', 'oecd', 'regions', 'OECD_TL3_2020.csv'))

# mapineq countries
oecd_regions <- oecd_regions[oecd_regions$mapineq, ]

# GET REGION_DEMOGR
dat_list <- get_region_demogr(oecd_key = oecd_regions)

for(i in c('tl1', 'tl2', 'tl3')){
  write.csv(dat_list[[i]], 
            file = file.path(outdir, paste0('region_demogr_',i,'.csv')), 
            row.names = F)
}
