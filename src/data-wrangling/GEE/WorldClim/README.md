# Dataset Documentation for Google Earth Engine Processing

This document provides an overview of all datasets processed in Google Earth Engine (GEE) using JavaScript. It includes details about the data sources, processing methods, and metrics used.

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

For each dataset, the following processing details are included:

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
- EURO2021: NUTS2021 + ITL2021 + ITL0 (merged from level1)  
- EURO2025: NUTS2024 + ITL2025 + ITL0 (merged from level1)  
EPSG:8857   
Total row: 4282  

---

## WorldClim

### WorldClim Climatology V1

1. **Data**  
- **Data Period and Frequency:** 1960 - 1991, Aggregated by month  
- **Homepage:** [Earth Observation Group (EOG) Nighttime Lights Data](https://eogdata.mines.edu/products/vnl/)  
- **Metadata:** [Earth Observation Group (EOG) Nighttime Lights Data](https://eogdata.mines.edu/products/vnl/)  
- **Download:** Available via Google Earth Engine:  
  - [WorldClim Climatology V1](https://developers.google.com/earth-engine/datasets/catalog/WORLDCLIM_V1_MONTHLY)  
- **License and Usage Notes:**  
  - CC-BY-SA-4.0
     
2. **Processing Method**

The analysis used Google Earth Engine (GEE) to process VIIRS yearly nighttime light data. For each geographical unit (NUTS, ITL, or EURO regions), all light intensity values were extracted, and summary metrics were computed to describe brightness patterns within each region.

- **Code Links:**  
  - [GEE-WC_Bio](https://github.com/OxfordDemSci/Mapineq/blob/208-gee-sub-worldclim/src/data-wrangling/GEE/WorldClim/WC_Bio.js)  
  - [Post_GEE](src/data-wrangling/GEE/WorldClim/GEE_WC.ipynb)  
- **Metrics Explanation:**  
Calculated metrics are based on all bioclimatic bands from the WorldClim dataset for each region:  
    - Mean (`mean`): Average value across all pixels within the polygon  
    - Minimum (`min`): Lowest value within the polygon  
    - Maximum (`max`): Highest value within the polygon  
    - Median (`median`): Middle value within the polygon  
    - Standard Deviation (`stdDev`): Variation of values within the polygon  
    - Percentiles (`10th_percentile`, `25th_percentile`, `75th_percentile`, `90th_percentile`): Values at the 10th, 25th, 75th, and 90th percentiles within the polygon  

- **Shapefile Used:** NUTS, ITL, EURO  

---

### WorldClim BIO Variables V1

1. **Data**  
- **Data Period and Frequency:** 2012-04-01 - 2025-03-01, Monthly  
> Note: 20120401-20120801 UK missing, so ITL starts from 2012-09-01  
- **Homepage:** [Earth Observation Group (EOG) Nighttime Lights Data](https://eogdata.mines.edu/products/vnl/)  
- **Metadata:** [Earth Observation Group (EOG) Nighttime Lights Data](https://eogdata.mines.edu/products/vnl/)  
- **Download:**  
  [WorldClim BIO Variables V1](https://developers.google.com/earth-engine/datasets/catalog/WORLDCLIM_V1_BIO)  
- **License and Usage Notes:**  
  - CC-BY-SA-4.0
                                                                            
2. **Processing Method**  
- **Code Links:**  
  - [GEE-WC_Climatology](https://github.com/OxfordDemSci/Mapineq/blob/208-gee-sub-worldclim/src/data-wrangling/GEE/WorldClim/WC_Climatology.js)  
  - [Post_GEE](src/data-wrangling/GEE/WorldClim/GEE_WC.ipynb)  
- **Metrics Explanation:** 
Calculated climatology metrics are based on all bands from the WorldClim dataset for each region:  
- Mean (`mean`): Average climatic value within the polygon  
- Minimum (`min`): Lowest climatic value within the polygon  
- Maximum (`max`): Highest climatic value within the polygon  
- Median (`median`): Middle climatic value within the polygon  
- Standard Deviation (`stdDev`): Variation of climatic values within the polygon  
- Percentiles (`10th_percentile`, `25th_percentile`, `75th_percentile`, `90th_percentile`): Climatic values at the 10th, 25th, 75th, and 90th percentiles within the polygon  

- **Shapefile Used:** NUTS, ITL, EURO  

---
