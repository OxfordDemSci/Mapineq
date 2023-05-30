# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# Load necessary libraries
library(httr)
library(jsonlite)
library(tidyr)
library(stringr)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), "..", "..", ".."))

# directories
srcdir = file.path('src', 'scrapers', 'oecd')
outdir <- file.path('data', 'oecd')
dir.create(outdir, showWarnings=F, recursive=T)

# Function to reformat data for merging later on
correct_format = function(
    df, # Data frame from OECD API (already reformatted from API)
    id.vars # ID columns that are the same in each OECD data frame
){
  
  # Subset the ID vars of the data sets and determine columns to spread by
  # Remove white space in spreading columns
  id_vars = id.vars[which(id.vars %in% names(df))]
  spread_col = names(df)[!names(df) %in% c(id_vars, "Indicator", "Value")]
  spread_col_nowhite = gsub(" ", "", spread_col)
  for (i in 1:length(spread_col)){
    names(df)[names(df) == spread_col[i]] = spread_col_nowhite[i]
  }
  
  # Paste spreading columns for formatting and make spread happen
  if (length(spread_col) > 0){
    df["Indicator"] = apply( df[ , c("Indicator", spread_col_nowhite)] , 1, paste, collapse = ".")
    df = df[, !names(df) %in% spread_col_nowhite]
  }
  df = pivot_wider(df, values_from = "Value", names_from = "Indicator", values_fn = list)
  
  # Add unpresent variables for consistency with other data sets
  not_present = id.vars[!id.vars %in% names(df)]
  if (length(not_present) > 0){
    for (u in 1:length(not_present)){
      df[not_present[u]] = NA
    }
  }
  
  # Return result
  return(df)
}

# Function to retrieve and reformat data from API
api_to_data_set = function(
    url, # API URL
    id.vars # ID columns that are the same in each OECD data frame
){
  
  # Load the data set through the API
  res = GET(url)
  data = fromJSON(rawToChar(res$content))
  df = data$dataSets$observations
  colnams = data$structure$dimensions$observation$name
  vals = data$structure$dimensions$observation$values
  
  # Make sure the data set becomes in the correct format
  final = data.frame(matrix(NA, nrow = ncol(df), ncol = length(colnams)))
  names(final) = colnams
  colvals = lapply(names(df), function(x){ str_split(x, ":")[[1]] })
  for (i in 1:length(colnams)){
    var = unlist(lapply(colvals, function(x, i){ as.integer(x[i]) + 1 }, i = i))
    final[, i] = vals[[i]][var, "name"]
  }
  final["Measure"] = apply(df, 2, function(x){ x[[1]][1] })
  
  # Rename columns where necessary for consistency
  names(final)[names(final) == "Measure"] = "Value"
  names(final)[names(final) == "Sex"] = "Gender"
  names(final)[names(final) == "Time"] = "Year"
  
  # Split data in country- and region-level if needed
  if (!"Country" %in% names(final) & "Regions" %in% names(final)){
    reg_ind = which(colnams == "Regions")
    final["iso3"] = vals[[reg_ind]]$id[match(final$Regions, vals[[reg_ind]]$name)]
    names(final)[names(final) == "Regions"] = "Region"
    final_list = list(
      final_regions = final[grepl("\\d", final$iso3), ],
      final_countries = final[!grepl("\\d", final$iso3), ]
    )
  } else {
    final["iso3"] = vals[[which(colnams == "Country")]]$id[match(final$Country, vals[[which(colnams == "Country")]]$name)]
    final_list = list(
      final_regions = final
    )
  }
  
  # Spread data to wide format and add missing columns for consistency between data sets
  final_list = lapply(final_list, correct_format, id.vars)
  
  # Return the final result as a list
  return(final_list)
}

# Load API URLs and define ID variables for data sets
id.vars = c("Country", "iso3", "Region", "Gender", "Year")
url_list = as.list(as.character(read.delim(file.path(srcdir, 'oecd_api_urls.txt'), sep = ',', header = F, colClasses = "character")[1, ]))

# Regional statistics on education (selection of countries and regions)
oecd_education_country = api_to_data_set(url_list[[1]], id.vars)[[1]]
oecd_education_region = api_to_data_set(url_list[[2]], id.vars)[[1]]

# Regional statistics on well-being (selection of countries and regions)
data_wellbeing = api_to_data_set(url_list[[3]], id.vars)
oecd_wellbeing_country = data_wellbeing$final_countries
oecd_wellbeing_region = data_wellbeing$final_regions

# Policy-relevant gender data variables
# Might take a bit longer because OECD data are large
oecd_gender_country = api_to_data_set(url_list[[4]], id.vars)[[1]]

# Combine OECD data into one data frame
oecd_df_list = list(
  oecd_education_country,
  oecd_education_region,
  oecd_wellbeing_country,
  oecd_wellbeing_region,
  oecd_gender_country
)
df_oecd = Reduce(function(dtf1, dtf2) merge(dtf1, dtf2, by = id.vars, all.x = TRUE), oecd_df_list)
write.csv(df_oecd, file.path(outdir, "oecd_data.csv"))
