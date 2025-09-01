# WorldClim Processing

This document provides an overview of **Accessibility to Cities 2015** dataset processed in Google Earth Engine (GEE) using JavaScript. It includes details about the data sources, processing methods, and metrics used.

---

## 1. Data Overview

For each dataset, the following information is documented:

- **Homepage:** Official webpage or source of the dataset  
- **Metadata:** Description and attributes of the dataset  
- **Download Link:** Where to access or download the dataset  
- **License:** Usage rights and restrictions  
- **Reference Paper:** Related publications or documentation (if available)  

---

## 2. Processing Methodology

The analysis used Google Earth Engine (GEE) to process WorldClim bioclimatic and climatology data. For each geographical unit (NUTS, ITL, or EURO regions), all values from the selected bands were extracted, and summary metrics were computed to describe climatic patterns within each region. Metrics included mean, minimum, maximum, median, standard deviation, and key percentiles (10th, 25th, 75th, 90th), providing a comprehensive overview of spatial variability.

- **Code Link**  
- **Metrics Explanation:** Description of the metrics or statistics calculated  
- **Shapefile Used:** Description or link to the shapefile or vector data used for spatial processing  
    - **NUTS**:  
Polygons (RG), 01m, EPSG:3035, years: 2003, 2006, 2010, 2013, 2016, 2021, 2024  
[Eurostat NUTS shapefiles](https://ec.europa.eu/eurostat/web/gisco/geodata/statistical-units/territorial-units-statistics)  
Total row: 13517   
    
    - **ITL**:  
Resolution: BGC, EPSG:27700, years: 2021, 2025  
[UK ITL shapefiles](https://www.data.gov.uk/search?q=International+Territorial+)  
Total row: 472   

    - **EURO**:  
EURO2021: NUTS2021 + ITL2021 + ITL0 (merged from level1)  
EURO2025: NUTS2024 + ITL2025 + ITL0 (merged from level1)  
EPSG:8857   
Total row: 4282  

---

## WorldClim Climatology V1

1. **Data**  
- **Data Period and Frequency:** 2015–2016  
- **Homepage:** [Malaria Atlas Project](https://malariaatlas.org/)  
- **Metadata:** [Accessibility to Cities 2015 (GEE)](https://developers.google.com/earth-engine/datasets/catalog/Oxford_MAP_accessibility_to_cities_2015_v1_0#description)  
- **Download:** [Accessibility to Cities 2015 (GEE)](https://developers.google.com/earth-engine/datasets/catalog/Oxford_MAP_accessibility_to_cities_2015_v1_0#description)  
- **License and Usage Notes:**  
  CC-BY-SA-4.0
- **Reference Paper:** [A global map of travel time to cities to assess inequalities in accessibility in 2015](https://www.nature.com/articles/nature25181)
  
The most recent version of the dataset is not yet available. 
  
2. **Processing Method**

- **Code Links:**  
  - [GEE-WC_Bio](https://github.com/OxfordDemSci/Mapineq/blob/208-gee-sub-worldclim/src/data-wrangling/GEE/WorldClim/WC_Bio.js)  
  - [Post_GEE](https://github.com/OxfordDemSci/Mapineq/blob/208-gee-sub-worldclim/src/data-wrangling/GEE/WorldClim/GEE_WC.ipynb)  
- **Metrics Explanation:**  
Calculated metrics for each region (NUTS, ITL, EURO) are derived from the `accessibility` band of the accessibility_to_cities_2015_v1_0 data.  The calculated statistical metrics are summarised below:  
    - Mean (`mean`): Average value across all pixels within the polygon  
    - Minimum (`min`): Lowest value within the polygon  
    - Maximum (`max`): Highest value within the polygon  
    - Median (`median`): Middle value within the polygon  
    - Standard Deviation (`stdDev`): Variation of values within the polygon
    - Coefficient of Variation (`CV`)  
      Measures relative variability by comparing the standard deviation to the mean.  
      **Formula:  CV = stdDev / mean**
      - High CV → Greater variability relative to the mean.  
      - Low CV → More consistent values.
    - Mean-to-Median Ratio (`Mean/Median`) 
      Indicates potential data skewness.  
      **Formula: Mean/Median = mean/median**
      - ≈ 1 → Data is approximately symmetric.  
      - \> 1 → Right-skewed (mean > median).  
      - < 1 → Left-skewed (mean < median).

- **Shapefile Used:** NUTS, ITL, EURO  
