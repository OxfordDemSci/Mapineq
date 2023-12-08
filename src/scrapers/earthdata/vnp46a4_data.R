# Check for required packages, install if not previously installed
if ("sys" %in% rownames(installed.packages()) == FALSE) {install.packages("sys")}
if ("getPass" %in% rownames(installed.packages()) == FALSE) { install.packages("getPass")}
if ("httr" %in% rownames(installed.packages()) == FALSE) { install.packages("httr")}
if ("rvest" %in% rownames(installed.packages()) == FALSE) { install.packages("rvest")}
if ("readr" %in% rownames(installed.packages()) == FALSE) { install.packages("readr")}

# Load necessary packages into R
library(sys)
library(getPass)
library(httr)
library(rvest)
library(readr)

setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), "..", "..", ".."))

srcdir <- file.path('src', 'scrapers', 'earthdata')
indir <- file.path('in', 'earthdata')
outdir <- file.path('out', 'earthdata', 'nighttime_lights', 'data')
dir.create(outdir, showWarnings=F, recursive=T)

source(file.path(srcdir, 'functions.R'))

token_file <- file.path(srcdir,'.access_token', fsep = .Platform$file.sep)
catalogue_file <- file.path(indir, 'nighttime_lights_catalogue.txt', fsep = .Platform$file.sep)

if (file.exists(token_file)) {
  access_token <- read_file(token_file)
} else {
    access_token <- getPass::getPass("Earthdata access token: ")
    write_file(access_token, token_file)
}

base_url <- 'https://ladsweb.modaps.eosdis.nasa.gov'
archive_path <- '/archive/allData/5000/VNP46A4'

file_urls <- get_file_urls(catalogue_file, base_url, archive_path)
download_data(file_urls, outdir, access_token)