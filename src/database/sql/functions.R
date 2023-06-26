# libraries
library(xml2)

# print with timestamp
tprint <- function(x){
  message(paste0('[', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '] ', x))
}

# Try to load Eurostat data files from folder
load_data_file = function(
    dir,
    file
){
  tryCatch({
    tprint(dfile)
    return(read.csv(paste0(dir, "/", file)))
  }, error = function(e) {
    tprint(paste0('     Problem with loading data file, skipping it: ', file))
    tprint(e)
  })
}


# Convert XML metadata to a data frame
# that contains intuitive descriptions 
# for variables and values
meta_xml_to_data_frame = function(
    xml_file
){
  
  # Load the metadata
  meta_xml = xml2::read_xml(xml_file)
  (current_node <- xml_find_all(meta_xml, "//s:Code"))
  
  # Create a matching dataframe from metadata
  df = data.frame(matrix(NA, nrow = length(xml_text(current_node)), ncol = 0))
  rownames(df) = unlist(lapply(xml_attrs(current_node), function(x){ return(x["id"]) }))
  child_atts = xml_attrs(xml_children(current_node))
  
  # Include descriptions from different languages available
  langs = unique(unlist(lapply(child_atts, function(x){ return(x["lang"]) })))
  for (lang in na.omit(langs)){
    match_str = paste0(".//c:Name[@xml:lang='", lang, "']")
    df[lang] = xml_find_all(current_node, match_str) |> xml_text()
  }
  
  # Return matching data frame
  return(df)
}

