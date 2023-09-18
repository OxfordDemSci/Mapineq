if ("rvest" %in% rownames(installed.packages()) == FALSE) { install.packages("rvest")}
if ("progress" %in% rownames(installed.packages()) == FALSE) { install.packages("progress")}

library(httr)
library(rvest)
library(progress)

complete_url <- function(base, path){
  return(paste0(base, path))
}

dive_or_get_file_url <- function (url, base_url) {
  if (endsWith(url, '.h5')) {
    return(list(url))
  } else {
    print(url)
    urls <- read_html(url) %>% html_elements('.product-cell') %>% html_node('a') %>% html_attr('href')
    urls <- lapply(urls, complete_url, base = base_url)
    return (lapply(urls, dive_or_get_file_url, base_url = base_url))
  }
}

get_file_urls <- function (catalogue_file, base_url, base_path) {
  ntl_conn <- file(catalogue_file)
  if (file.exists(catalogue_file)) {
    file_urls <- readLines(ntl_conn)
  } else {
    base_archive_url <- paste0(base_url, base_path)
    file_urls <- dive_or_get_file_url(base_archive_url, base_url)
    file_urls <- unlist(file_urls, recursive=TRUE)

    writeLines(file_urls, ntl_conn)
  }
  close(ntl_conn)
  return(file_urls)
}

download_data <- function (file_urls, outdir, access_token) {
  pb <- progress_bar$new(format = "[:bar] :current/:total (:percent)", total = length(file_urls))
  for (i in 1:length(file_urls)) {
    filename <-  tail(strsplit(file_urls[i], '/')[[1]], n = 1)
    
    if (!file.exists(file.path(outdir, filename))) {
      # Write file to disk using the current directory/filename
      response <- httr::GET(file_urls[i], add_headers(Authorization = paste('Bearer', access_token)), write_disk(file.path(outdir, filename), overwrite = TRUE))
    }
    pb$tick()
  }
}