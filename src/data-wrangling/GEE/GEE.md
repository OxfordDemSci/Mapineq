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

- **Code Link:** Link to the GEE script or processing code  
- **Metrics Explanation:** Description of the metrics or statistics calculated  
- **Shapefile Used:** Description or link to the shapefile or vector data used for spatial processing  

**NUTS**: 
Polygons(RG), 01m, EPSG: 3035, year:2003, 2006, 2010, 2013, 2016, 2021, 2024  
https://ec.europa.eu/eurostat/web/gisco/geodata/statistical-units/territorial-units-statistics  

**ITL**:  
resolution: BGC, EPSG: 27700, year: 2021, 2025
https://www.data.gov.uk/search?q=International+Territorial+

**EURO**: 
EURO2021: NUTS2021 + ITL2021 + ITL0(merged from level1)
EURO2025: NUTS2024 + ITL2025 + ITL0(merged from level1)
EPSG:8857
---

## Nighttime Light Data

### Yearly Data

1. **Data**  
- **Data Period and Frequency:** 2013 - 2024, Annual
- **Homepage:** [Earth Observation Group (EOG) Nighttime Lights Data](https://eogdata.mines.edu/products/vnl/)  
- **Metadata:** [Earth Observation Group (EOG) Nighttime Lights Data](https://eogdata.mines.edu/products/vnl/)   
- **Download:** Available via Google Earth Engine:  
[VIIRS Nighttime Day/Night Annual Band Composites V2.1(20130101 - 20210101)](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_ANNUAL_V21)  
[VIIRS Nighttime Day/Night Annual Band Composites V2.2(20220101 - 20240101)](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_ANNUAL_V22)  
- **License and Usage Notes:**  
    - Creative Commons Attribution 4.0 International (CC BY 4.0) license.
    official document: [EOG Products CC License (PDF)](https://eogdata.mines.edu/files/EOG_products_CC_License.pdf)  
    - Data and products from Colorado School of Mines are in the public domain, free of copyright, and may be used for any lawful purpose without restriction.
    - When using these data, please cite the Earth Observation Group (EOG) as the data source and reference relevant publications associated with the EOG products you use.

2. **Processing Method**  
- **Code Link:** [Link to GEE Processing Script]  
- **Metrics Explanation:  
Calculated metrics are based on the `avg_rad` band of VIIRS Monthly images for each `NUTS_ID` region (polygon):
    - Mean(`mean`): Average radiance within the polygon.
    - Standard Deviation(`std_dev`): Variation of radiance within the polygon.
    - Maximum(`max`): Highest radiance value within the polygon.
- **Shapefile Used:** Description of spatial boundaries  
NUTS, ITL, EURO

---

### Monthly Data

1. **Data**  
- **Data Period and Frequency:** 20120401 - 20250301, Monthly
> 20120401-20120801 UK missing, so ITL start from 20120901
- **Homepage:** [Earth Observation Group (EOG) Nighttime Lights Data]()  
- **Metadata:** [Earth Observation Group (EOG) Nighttime Lights Data]()   
- **Download:** Available via Google Earth Engine:  
[VIIRS Nighttime Day/Night Band Composites Version 1](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_MONTHLY_V1_VCMCFG)  
- **License and Usage Notes:**  
    - Creative Commons Attribution 4.0 International (CC BY 4.0) license.
    official document: [EOG Products CC License (PDF)](https://eogdata.mines.edu/files/EOG_products_CC_License.pdf)  
    - Data and products from Colorado School of Mines are in the public domain, free of copyright, and may be used for any lawful purpose without restriction.
    - When using these data, please cite the Earth Observation Group (EOG) as the data source and reference relevant publications associated with the EOG products you use.

2. **Processing Method**  
- **Code Link:** [Link to GEE Processing Script]  
- **Metrics Explanation ():**  
Calculated metrics are based on the `avg_rad` band of VIIRS monthly images for each `NUTS_ID` region (polygon):
    - Mean(`mean`): Average radiance within the polygon.
    - Standard Deviation(`std_dev`): Variation of radiance within the polygon.
    - Maximum(`max`): Highest radiance value within the polygon.
- **Shapefile Used:** Description of spatial boundaries  
NUTS, ITL, EURO

---


### Monthly Stray Data

1. **Data**  
- **Data Period and Frequency:** 20140101 - 20250301, Monthly
> 20241101 missing                                                                                                              
- **Homepage:** [Earth Observation Group (EOG) Nighttime Lights Data]()  
- **Metadata:** [Earth Observation Group (EOG) Nighttime Lights Data]()   
- **Download:** Available via Google Earth Engine:  
[VIIRS Stray Light Corrected Nighttime Day/Night Band Composites Version 1](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_MONTHLY_V1_VCMSLCFG)  
- **License and Usage Notes:**  
    - Creative Commons Attribution 4.0 International (CC BY 4.0) license.
    official document: [EOG Products CC License (PDF)](https://eogdata.mines.edu/files/EOG_products_CC_License.pdf)  
    - Data and products from Colorado School of Mines are in the public domain, free of copyright, and may be used for any lawful purpose without restriction.
    - When using these data, please cite the Earth Observation Group (EOG) as the data source and reference relevant publications associated with the EOG products you use.

2. **Processing Method**  
- **Code Link:** [Link to GEE Processing Script]  
- **Metrics Explanation:** Explanation of calculated metrics such as mean, standard deviation, max radiance  
- **Shapefile Used:** Description of spatial boundaries   
NUTS, ITL, EURO

