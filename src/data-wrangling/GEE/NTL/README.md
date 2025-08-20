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

**NUTS**:  
Polygons (RG), 01m, EPSG:3035, years: 2003, 2006, 2010, 2013, 2016, 2021, 2024  
[Eurostat NUTS shapefiles](https://ec.europa.eu/eurostat/web/gisco/geodata/statistical-units/territorial-units-statistics)

**ITL**:  
Resolution: BGC, EPSG:27700, years: 2021, 2025  
[UK ITL shapefiles](https://www.data.gov.uk/search?q=International+Territorial+)

**EURO**:  
- EURO2021: NUTS2021 + ITL2021 + ITL0 (merged from level1)  
- EURO2025: NUTS2024 + ITL2025 + ITL0 (merged from level1)  
EPSG:8857  

---

## Nighttime Light Data

### Yearly Data

1. **Data**  
- **Data Period and Frequency:** 2013 - 2024, Annual  
- **Homepage:** [Earth Observation Group (EOG) Nighttime Lights Data](https://eogdata.mines.edu/products/vnl/)  
- **Metadata:** [Earth Observation Group (EOG) Nighttime Lights Data](https://eogdata.mines.edu/products/vnl/)  
- **Download:** Available via Google Earth Engine:  
  - [VIIRS Nighttime Day/Night Annual Band Composites V2.1 (20130101 - 20210101)](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_ANNUAL_V21)  
  - [VIIRS Nighttime Day/Night Annual Band Composites V2.2 (20220101 - 20240101)](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_ANNUAL_V22)  
- **License and Usage Notes:**  
  - Creative Commons Attribution 4.0 International (CC BY 4.0) license  
    [Official document (PDF)](https://eogdata.mines.edu/files/EOG_products_CC_License.pdf)  
  - Data and products from Colorado School of Mines are in the public domain, free of copyright, and may be used for any lawful purpose without restriction.  
  - When using these data, please cite the Earth Observation Group (EOG) as the data source.

2. **Processing Method**

The analysis used Google Earth Engine (GEE) to process VIIRS yearly nighttime light data. For each geographical unit (NUTS, ITL, or EURO regions), all light intensity values were extracted, and summary metrics were computed to describe brightness patterns within each region.

- **Code Links:**  
  - [GEE-NUTS](https://github.com/OxfordDemSci/Mapineq/blob/204-gee-sub-night-time-light/src/data-wrangling/GEE/NTL/VIIR_Annual_NUTS.js)  
  - [GEE-ITL/EURO](https://github.com/OxfordDemSci/Mapineq/blob/204-gee-sub-night-time-light/src/data-wrangling/GEE/NTL/VIIR_Annual_ITL.js)  
  - [Post_GEE](https://github.com/OxfordDemSci/Mapineq/blob/204-gee-sub-night-time-light/src/data-wrangling/GEE/NTL/NTL_post_GEE.ipynb)  
- **Metrics Explanation:**  
  Calculated metrics are based on the `avg_rad` band of VIIRS Yearly images for each region (such as `NUTS_ID`):  
  - Mean (`mean`): Average radiance within the polygon  
  - Standard Deviation (`std_dev`): Variation of radiance within the polygon  
  - Maximum (`max`): Highest radiance value within the polygon  
- **Shapefile Used:** NUTS, ITL, EURO  

---

### Monthly Data

1. **Data**  
- **Data Period and Frequency:** 2012-04-01 - 2025-03-01, Monthly  
> Note: 20120401-20120801 UK missing, so ITL starts from 2012-09-01  
- **Homepage:** [Earth Observation Group (EOG) Nighttime Lights Data]()  
- **Metadata:** [Earth Observation Group (EOG) Nighttime Lights Data]()  
- **Download:**  
  [VIIRS Nighttime Day/Night Band Composites Version 1](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_MONTHLY_V1_VCMCFG)  
- **License and Usage Notes:** Same as yearly data  

2. **Processing Method**  
- **Code Links:**  
  - [GEE-NUTS](https://github.com/OxfordDemSci/Mapineq/blob/204-gee-sub-night-time-light/src/data-wrangling/GEE/NTL/VIIR_Monthly_NUTS.js)  
  - [GEE-ITL/EURO](https://github.com/OxfordDemSci/Mapineq/blob/204-gee-sub-night-time-light/src/data-wrangling/GEE/NTL/VIIR_Monthly_ITL.js)  
  - [Post_GEE](https://github.com/OxfordDemSci/Mapineq/blob/204-gee-sub-night-time-light/src/data-wrangling/GEE/NTL/NTL_post_GEE.ipynb)  
- **Metrics Explanation:** Same as yearly data  
- **Shapefile Used:** NUTS, ITL, EURO  

---

### Monthly Stray Data

1. **Data**  
- **Data Period and Frequency:** 2014-01-01 - 2025-03-01, Monthly  
> Note: 2024-11-01 missing  
- **Homepage:** [Earth Observation Group (EOG) Nighttime Lights Data]()  
- **Metadata:** [Earth Observation Group (EOG) Nighttime Lights Data]()  
- **Download:**  
  [VIIRS Stray Light Corrected Nighttime Day/Night Band Composites Version 1](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_MONTHLY_V1_VCMSLCFG)  
- **License and Usage Notes:** Same as yearly data  

2. **Processing Method**  
- **Code Links:**  
  - [GEE-NUTS](https://github.com/OxfordDemSci/Mapineq/blob/204-gee-sub-night-time-light/src/data-wrangling/GEE/NTL/VIIR_Monthly_NUTS.js)  
  - [GEE-ITL/EURO](https://github.com/OxfordDemSci/Mapineq/blob/204-gee-sub-night-time-light/src/data-wrangling/GEE/NTL/VIIR_Monthly_ITL.js)  
  - [Post_GEE](https://github.com/OxfordDemSci/Mapineq/blob/204-gee-sub-night-time-light/src/data-wrangling/GEE/NTL/NTL_post_GEE.ipynb)  
- **Metrics Explanation:** Same as yearly data  
- **Shapefile Used:** NUTS, ITL, EURO  
