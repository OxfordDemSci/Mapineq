# cleanup
rm(list=ls()); gc(); cat("\014"); try(dev.off(), silent=T); options(scipen=999)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), 
                "..", "..", ".."))

# define directories
srcdir <- file.path('src', 'scrapers', 'environmental')
outdir <- file.path('out', 'environmental')
dir.create(outdir, showWarnings=F, recursive=T)

# load functions
source(file.path(srcdir, 'functions.R'))

# define list of URLs to scrape data from
begin_url = "https://files.worldwildlife.org/wwfcmsprod/files/Publication/file/"
end_url = "_ga=2.6743986.1226121816.1690982761-579293559.1690982761"
lake_wet_urls = list(
  level1 = paste0(begin_url, "8ark3lcpfw_GLWD_level1.zip?", end_url),
  level2 = paste0(begin_url, "65sv5l285i_GLWD_level2.zip?", end_url),
  level3 = paste0(begin_url, "9slil0ww7t_GLWD_level3.zip?", end_url)
)

# get data
for (idx in seq_along(lake_wet_urls)){
  temp = tempfile()
  download.file(lake_wet_urls[[idx]], temp)
  temp2 = tempfile()
  unzip(zipfile = temp, exdir = temp2)
  get_data(paste0("glwd_", idx, ".shp"), temp2, outdir)
  unlink(c(temp, temp2))
}
