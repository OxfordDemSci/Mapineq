# Migration Dataset Processing

This document provides an overview of **International Migration** dataset processed.   
It includes details about the data sources, processing methods, and metrics used.   
The international migration part includes two dataset:   
- Meta International Migration Flows  
- World Net Migration 

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

## Meta International Migration Flows

1. **Data**  
- **Data Period and Frequency:** 2019–2022, monthly  
- **Homepage:** [Meta Data for Good](https://dataforgood.facebook.com/)  
- **Metadata:** [International Migration Flows (HDX)](https://dataforgood.facebook.com/dfg/international-migration-flows)   
- **Download:** [International Migration Flows (HDX)](https://data.humdata.org/dataset/international-migration-flows)  
- **License and Usage Notes:**  
  CC-BY
- **Reference Paper:** [Measuring global migration flows using online data](https://www.pnas.org/doi/10.1073/pnas.2409418122)
  
2. **Processing Method**
The dataset contains summed inflows (or outflows) of migrants for each reporting country (geo).  
Values are aggregated over origin countries (or destination countries for outflows) and time.  
The output is `meta_migration_i`n and `meta_migration_out`.  

- **Code Links:**  
  - [Meta_international_migration.ipynb](src/data-wrangling/Migration/Meta_international_migration.ipynb)  
- **Metrics Explanation:**  
    - `origin` / `destination`:   
        - All countries: a summary row representing the global total inflow (or outflow).  
        - Individual countries: a list of all available partner countries contributing to the inflow (or receiving the outflow) for the reporting country (geo). Typically ~180 countries.
    - `month`:
        - All: a summary row representing the total annual flow.  
        - Individual months: specific monthly values within the time range.

- **Shapefile Used:** NUTS


---

## World Net Migration 

1. **Data**  
- **Data Period and Frequency:** 2000–2019  
- **Metadata:** [Data for: World's human migration patterns in 2000-2019 unveiled by high-resolution data (zenodo)](https://zenodo.org/records/7997134)   
- **Download:** [Data for: World's human migration patterns in 2000-2019 unveiled by high-resolution data (zenodo)](https://zenodo.org/records/7997134)  
- **License and Usage Notes:**  
  CC-BY-4.0
- **Reference Paper:** [World’s human migration patterns in 2000–2019 unveiled by high-resolution data](https://www.nature.com/articles/s41562-023-01689-4)

  
2. **Processing Method**
This dataset provides annual net migration values aggregated from raster data (2000–2019) over NUTS regions. For each polygon and year, summary statistics are calculated from the underlying raster pixels, capturing both total values and within-region variation.

- **Code Links:**  
  - [Net_Migration.ipynb](src/data-wrangling/Migration/Net_Migration.ipynb)  
- **Metrics Explanation:**   
  Calculated metrics for each region (NUTS) are derived from the raster bands, where band `i` corresponds to year = 2000 + (i − 1) (i.e., 2000–2019).    
  The following statistical metrics are computed for each NUTS polygon:    
    - Mean (`mean`): Average raster value across all pixels intersecting the polygon
    - Sum (`sum`) of raster values across pixels 
    - Minimum (`min`): Minimum pixel value within the polygon  
    - Maximum (`max`): Maximum pixel value within the polygon  
    - Median (`median`): Median pixel value within the polygon  
    - Standard Deviation (`stdDev`): Variation of pixel values within the polygon

- **Shapefile Used:** NUTS
