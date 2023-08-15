# cleanup
rm(list=ls()); gc(); cat("\014"); try(dev.off(), silent=T); options(scipen=999)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), 
                "..", "..", ".."))

# define directories
srcdir <- file.path('src', 'scrapers', 'environmental')
outdir <- file.path('out', 'environmental', 'data')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))

# get data
url = "https://naciscdn.org/naturalearth/packages/natural_earth_vector.gpkg.zip"
temp = tempfile()
download.file(url, temp)
get_data("natural_earth.shp", unzip(temp), outdir)
unlink(temp)

