# libraries
library(xml2)
library(plyr)
library(raster)

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
    tprint(file)
    whole_file = paste0(dir, "/", file)
    if (grepl(".csv", file)){
      df = read.csv(whole_file)
    } else if (grepl(".shp", file)){
      df = sf::st_read(whole_file)
    } else if (grepl(".tif", file)){
      # df = data.frame(rasterToPoints(raster::raster(whole_file)))
      df = raster::raster(whole_file)
    } else {
      break
    }
    return(df)
  }, error = function(e) {
    tprint(paste0('     Problem with loading data file, skipping it: ', file))
    tprint(e)
  })
}

# Convert XML metadata to a data frame
# that contains intuitive descriptions 
# for variables and values (OECD data)
oecd_meta_xml_to_data_frame = function(
    xml_file
){
  meta_xml = xml2::read_xml(xml_file)
  (current_node <- xml_find_all(meta_xml, "//message:CodeLists"))
  variables = xml_children(current_node)
  df_vars = list()
  for (var in variables){
    atts = xml_attrs(xml_children(var))
    lang_atts = atts[unlist(lapply(atts, function(x){"lang" %in% names(x)}))]
    code_inds = unlist(lapply(atts, function(x){"value" %in% names(x)}))
    code_atts = atts[code_inds]
    code_child = xml_children(var)[code_inds]
    df_rows = list()
    for (i in 1:length(code_atts)){
      df_rows[[i]] = data.frame(matrix(code_atts[[i]], nrow = 1))
      names(df_rows[[i]]) = names(code_atts[[i]])
      if (!"parentCode" %in% names(code_atts[[i]])){
        df_rows[[i]]["parentCode"] = df_rows[[i]]$value
      }
      for (j in 1:length(lang_atts)){
        df_rows[[i]][paste0("desc_", unname(lang_atts[[j]]))] = xml_text(xml_children(code_child[[i]])[[j]])
      }
    }
    code_df = rbind.fill(df_rows)
    for (i in 1:length(lang_atts)){
      code_df[[unname(lang_atts[[i]])]] = xml_text(xml_children(var)[[i]])
    }
    code_df["id"] = xml_attrs(var)["id"]
    code_df["agencyID"] = xml_attrs(var)["agencyID"]
    df_vars[[xml_attrs(var)["id"]]] = code_df
  }
  return(rbind.fill(df_vars))
}


# Convert XML metadata to a data frame
# that contains intuitive descriptions 
# for variables and values (Eurostat data)
eurostat_meta_xml_to_data_frame = function(
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

