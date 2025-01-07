# Mapineq Link: Spatial Data for Inequality Research

![Mapineq logo](./mapineq_logo_bw_rgb.png)

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-GPLv3-green)
![Funding](https://img.shields.io/badge/funding-HorizonEurope-yellow)
![DOI](https://img.shields.io/badge/doi-10.5281/zenodo.14609989-red)

The source code in this repository built the spatial data tools that you can explore at: [https://mapineq.org](https://mapineq.org). 

The [Mapineq Project](https://mapineq.eu) is an international collaboration that aims to link innovative and interdisplinary data sources to empower researchers, policy-makers, and the general public to better understand how location helps shape the opportunities and ultimate outcomes that you may experience throughout your life--and to chart a path towards reducing inequalities at every step. We think that putting data on the map and exploring spatial relationships among drivers of inequality is a key component of this work, and we want to share the exciting tools that we've been developing to make this a little bit easier. The Mapineq team believes strongly in the power of Free and Open Source Software and [FAIR research principles](https://www.go-fair.org/fair-principles/), so we are giving away our source code here for free so that you can reproduce our work, modify our code as you like, share it with your friends and colleagues, cite us when you find these tools useful, and get involved with the Mapineq Project to help make it better. This open-access repository contains the source code for the Mapineq Link database, API, and interactive mapping dashboard that are available from [https://mapineq.org](https://mapineq.org).

## Using MapineqLink

The **main website** for MapineqLink is at [https://mapineq.org](https://mapineq.org).  

The **data catalogue** is available to be searched at [https://dashboard.mapineq.org/datacatalogue](https://dashboard.mapineq.org/datacatalogue).

The **interactive dashboard** can be explored at [https://dashboard.mapineq.org](https://dashboard.mapineq.org).

The **open-access API** is available from [https://api.mapineq.org](https://api.mapineq.org)

**Documentation** is available from [https://docs.mapineq.org](https://docs.mapineq.org). 

## Get Involved

We welcome your engagement with the project! If you spot bugs or you would like to request new features or new data, please [raise an issue](https://github.com/OxfordDemSci/Mapineq/issues) in this GitHub repository. If you would like to contribute to the code, please feel free to fork the repository and submit pull requests to help us resolve issues (please submit pull requests to merge into the `dev` branch of this repository). 

It is relatively easy for us to import data from [EuroStat](https://ec.europa.eu/eurostat/databrowser/explore/all/all_themes?lang=en&display=list&sort=category) and [OECD](https://data-explorer.oecd.org/) into MapineqLink. If you find data that you think would be a good addition to MapineqLink, please raise an issue to let us know and be sure to provide a link to the data.

If you have an idea for other data (e.g. remote sensing, digital traces, geospatial), then please raise an issue to let us know, and we will work together to integrate these data sources where possible. Note: We can only integrate data with a license permitting this use and that contain no personal data.

Here are some projects from the wider Mapineq community that you may find useful:  
- **mapineqr**: An R package to access data from the Mapineq API and dashboard ([Kotov 2024a](https://github.com/e-kotov/mapineqr))
- **mapineqpy**: A Python package to access data from the Mapineq API and dashboard ([Kotov 2024b](https://github.com/e-kotov/mapineqpy))

## Repository Structure

The `docs` directory contains source code for all of the documentation available at [https://docs.mapineq.org](https://docs.mapineq.org). 

The `src` directory contains the source code for our software:  
- **database**: Source code for a dockerised PostgreSQL database with a PostGIS extension with functions to import and manage data from EuroStat, OECD, and other sources. This database is the backend database for the MapineqLink dashboard, API, and data catalogue.
- **dashboard**: Source code for the interactive mapping dashboard and API.
- **scrapers**: Scrapers that we have used to get various data that are integrated into the MapineqLink database.
- **data-wrangling**: Code that we use to prepare data from diverse sources for integration into the Mapineq Link database.

## License

This repository is made available under the terms of a [GNU General Public License v3](LICENSE). This means that you can use, modify, and redistribute the contents of this repository for any purpose, but you must apply the same license to modified materials to keep the code open-source, include the license with redistributed material, identify any modifications that you have made, and please cite us as your source. 

## Suggested Citation

Leasure DR, van Ruler N, de Jong S, Lassche R, Ao X, Lambert T, Schoof G, Mills MM. 2025. Mapineq Link: Spatial Data for Inequality Research, v1.0.0. doi:[10.5281/zenodo.14609989](https://doi.org/10.5281/zenodo.14609989). [https://github.com/OxfordDemSci/Mapineq](https://github.com/OxfordDemSci/Mapineq).

## Acknowledgements
The MapIneq project is funded by the European Union’s Horizon Europe Research and Innovation programme (202061645) and the MapineqLink database and dashboard received additional support from the Leverhulme Trust (RC-2018-003) via the Leverhulme Centre for Demographic Science at the University of Oxford. Code development was a joint effort between the [Leverhulme Centre for Demographic Science](https://demography.ox.ac.uk) at the University of Oxford and [Geodienst](https://www.rug.nl/society-business/center-for-information-technology/research/services/gis/) at the University of Groningen.

## Citations

Kotov E. (2024a). mapineqr. Access Mapineq inequality indicators via API. doi:10.32614/CRAN.package.mapineqr [https://doi.org/10.32614/CRAN.package.mapineqr](https://doi.org/10.32614/CRAN.package.mapineqr), [https://github.com/e-kotov/mapineqr](https://github.com/e-kotov/mapineqr).  

Kotov E. (2024b). mapineqpy: A Python package for accessing Mapineq API data. Available at: [https://github.com/e-kotov/mapineqpy](https://github.com/e-kotov/mapineqpy)
