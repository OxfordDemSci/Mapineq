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

# get data
start_idx = res = 0
while (!is.null(res)){
  url = paste0("https://geo.woudc.org/ows?service=WFS&version=1.1.0&request=GetFeature&outputformat=GeoJSON&typename=filelist&filter=%3Cogc:Filter%3E%3Cogc:And%3E%3Cogc:BBOX%3E%3CPropertyName%3EmsGeometry%3C/PropertyName%3E%3CBox%20srsName=%22EPSG:4326%22%3E%3Ccoordinates%3E-189.14062500000003,-83.67694304841552%20189.84375,85.51339830988749%3C/coordinates%3E%3C/Box%3E%3C/ogc:BBOX%3E%3Cogc:PropertyIsBetween%3E%3Cogc:PropertyName%3Einstance_datetime%3C/ogc:PropertyName%3E%3Cogc:LowerBoundary%3E1924-01-01%2000:00:00%3C/ogc:LowerBoundary%3E%3Cogc:UpperBoundary%3E2023-12-30%2023:59:59%3C/ogc:UpperBoundary%3E%3C/ogc:PropertyIsBetween%3E%3C/ogc:And%3E%3C/ogc:Filter%3E&sortby=instance_datetime%20DESC&startindex=", start_idx * 1e4,"&maxfeatures=10000")
  res = get_data(paste0('ozone_uv_', start_idx + 1, '.csv'), url, outdir)
  start_idx = start_idx + 1
}
