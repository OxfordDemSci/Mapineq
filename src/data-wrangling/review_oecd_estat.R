# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# libraries
library(sf)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), '..', '..'))

# define directories
oecddir <- file.path('out', 'oecd', 'data')
estatdir <- file.path('out', 'eurostat', 'data')


#---- review oecd data ----#

sink('out/data_heads.txt')

# list data
lf <- list.files(oecddir, pattern='.csv')
lf <- lf[!grepl('_codebook.csv', lf)]

for(l in lf){
  tryCatch({
    cat(paste0(file.path(oecddir, l), '\n'))
    dat <- read.csv(file.path(oecddir, l))
    print(head(dat))
    print(tail(dat))
  }, error=function(e){
    print(e)
  }, finally={
    cat('\n')
  })
}


#---- estat data ----#

# list data
lf <- list.files(estatdir, pattern='.csv')

for(l in lf){
  tryCatch({
    cat(paste0(file.path(estatdir, l), '\n'))
    dat <- read.csv(file.path(estatdir, l))
    print(head(dat))
    print(tail(dat))
  }, error=function(e){
    print(e)
  }, finally={
    cat('\n')
  })
}

sink()
