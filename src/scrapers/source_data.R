# TODO: add DOIs and provisions
# TODO: add Eurostat data info

# cleanup
rm(list = ls()); gc(); cat("\014"); try(dev.off(), silent = T); options(scipen = 999)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path), '..', '..', '..'))

# libraries
library(stringr)

# directories
dir.create('out', showWarnings=F, recursive=T)

# define directories
sqldir = file.path('src', 'database', 'sql')
nutsdir = file.path('out', 'nuts', 'data')
gadmdir = file.path('out', 'gadm', 'data')
oecddir = file.path('out', 'oecd', 'data')
estatdir = file.path('out', 'eurostat', 'data')
orddir = file.path('out', 'ordnance', 'data')
wwldir = file.path('out', 'worldwildlife', 'data')
nacisdir = file.path('out', 'nacis', 'data')
woudcdir = file.path('out', 'woudc', 'data')
worldclimdir = file.path('out', 'worldclim', 'data')

# Define data sets per type
gadm_files = list.files(gadmdir, '.gpkg')
nuts_files = list.files(nutsdir, '.gpkg')
oecd_files = list.files(oecddir, '.csv')[!grepl("codebook.csv", list.files(oecddir, '.csv'))]
euro_files = list.files(estatdir, '.csv')
wclim_files = list.files(worldclimdir, '.tif')
wwf_files = list.files(wwldir, '.shp')
ordsur_files = list.files(orddir, '.shp')
nacis_files = list.files(nacisdir, '.shp')
woudc_files = list.files(woudcdir, '.csv')[!grepl("meta", list.files(woudcdir, '.csv'))]

# Define names of data files
dnams = c(
  gsub(".gpkg", "", gadm_files),
  gsub(".gpkg", "", nuts_files),
  gsub(".csv", "", oecd_files),
  gsub(".csv", "", euro_files),
  gsub(".tif", "", wclim_files),
  gsub(".shp", "", wwf_files),
  gsub(".shp", "", ordsur_files),
  gsub(".shp", "", nacis_files),
  gsub(".csv", "", woudc_files)
)

# File names for climate rasters
remove_n = 15:17
wclim_nams = unique(unlist(lapply(strsplit(gsub(".tif", ".zip", wclim_files), ""), function(x)
  paste(x[-remove_n], collapse = ""))))
  
# Create data frame with information about data (metadata)
df_source = data.frame(
  data_name = dnams,
  date_retrieval = c(
    rep(Sys.Date(), length(dnams))
  ),
  organisation = c(
    rep("GADM", length(gadm_files)),
    rep("Eurostat", length(nuts_files)),
    rep("OECD", length(oecd_files)),
    rep("Eurostat", length(euro_files)),
    rep("WorldClim", length(wclim_files)),
    rep("World Wide Fund for Nature (WWF) and Center for Environmental Systems Research, University of Kassel, Germany", length(wwf_files)),
    rep("Ordnance Survey", length(ordsur_files)),
    rep("North American Cartographic Information Society (NACIS)", length(nacis_files)),
    rep("World Ozone and Ultraviolet Radiation Data Centre (WOUDC)", length(woudc_files))
    ),
  # doi = rep(NA, length(dnams)),
  contact_info = c(
    rep("http://rasterra.com/contact/gadm_contact_form", length(gadm_files)),
    rep("ESTAT-GISCO@ec.europa.eu", length(nuts_files)),
    rep("RegionStat@oecd.org", length(oecd_files)),
    rep("https://ec.europa.eu/eurostat/web/main/contact-us/user-support", length(euro_files)),
    rep("info@worldclim.org", length(wclim_files)),
    rep("bernhard.lehner@wwfus.org", length(wwf_files)),
    rep("customerservices@ordnancesurvey.co.uk", length(ordsur_files)),
    rep("nathaniel@naturalearthdata.com", length(nacis_files)),
    rep("woudc@ec.gc.ca", length(woudc_files))
  ),
  # provisions = rep(NA, length(dnams)),
  information = c(
    rep("https://gadm.org/about.html", length(gadm_files)),
    rep("https://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units/nuts#nuts21", length(nuts_files)),
    rep("https://data.oecd.org/api/sdmx-json-documentation/", length(oecd_files)),
    rep("https://wikis.ec.europa.eu/display/EUROSTATHELP/API+for+data+access", length(euro_files)),
    rep("https://www.worldclim.org/about.html", length(wclim_files)),
    rep("https://www.worldwildlife.org/pages/global-lakes-and-wetlands-database", length(wwf_files)),
    rep("https://www.ordnancesurvey.co.uk/products/os-open-roads", length(ordsur_files)),
    rep("https://www.naturalearthdata.com/about/", length(nacis_files)),
    rep("https://woudc.org/about/index.php", length(woudc_files))
    ),
  url = c(
    rep("https://geodata.ucdavis.edu/gadm/gadm4.1/gadm_410-gpkg.zip", length(gadm_files)),
    paste0("https://gisco-services.ec.europa.eu/distribution/v2/nuts/geojson/NUTS_RG_20M_2021_4326_LEVL_", as.numeric(gsub("\\D", "", nuts_files)), ".geojson"),
    paste0('https://stats.oecd.org/restsdmx/sdmx.ashx/GetData/', gsub(".csv", "", oecd_files), '/all?'),
    paste0('https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/', gsub(".csv", "", euro_files)),
    rep(wclim_nams, each = 12),
    "https://files.worldwildlife.org/wwfcmsprod/files/Publication/file/8ark3lcpfw_GLWD_level1.zip?_ga=2.6743986.1226121816.1690982761-579293559.1690982761",
    "https://files.worldwildlife.org/wwfcmsprod/files/Publication/file/65sv5l285i_GLWD_level2.zip?_ga=2.6743986.1226121816.1690982761-579293559.1690982761",
    "https://api.os.uk/downloads/v1/products/OpenRoads/downloads?area=GB&format=GeoPackage&redirect",
    paste0("https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_", gsub(".shp", "", gsub("natural_earth_", "", nacis_files)),".zip"),
    "https://woudc.org/data/explore.php?lang=en"
    # paste0("https://geo.woudc.org/ows?service=WFS&version=1.1.0&request=GetFeature&outputformat=GeoJSON&typename=filelist&filter=%3Cogc:Filter%3E%3Cogc:And%3E%3Cogc:BBOX%3E%3CPropertyName%3EmsGeometry%3C/PropertyName%3E%3CBox%20srsName=%22EPSG:4326%22%3E%3Ccoordinates%3E-189.14062500000003,-83.67694304841552%20189.84375,85.51339830988749%3C/coordinates%3E%3C/Box%3E%3C/ogc:BBOX%3E%3Cogc:PropertyIsBetween%3E%3Cogc:PropertyName%3Einstance_datetime%3C/ogc:PropertyName%3E%3Cogc:LowerBoundary%3E1924-01-01%2000:00:00%3C/ogc:LowerBoundary%3E%3Cogc:UpperBoundary%3E2023-12-30%2023:59:59%3C/ogc:UpperBoundary%3E%3C/ogc:PropertyIsBetween%3E%3C/ogc:And%3E%3C/ogc:Filter%3E&sortby=instance_datetime%20DESC&startindex=", 0:(length(woudc_files) - 1) * 1e4,"&maxfeatures=10000")
  ),
  license = c(
    rep("The data are freely available for academic use and other non-commercial use. 
        Redistribution or commercial use is not allowed without prior permission. 
        Using the data to create maps for publishing of academic research articles is allowed. 
        Thus you can use the maps you made with GADM data for figures in articles published by 
        PLoS, Springer Nature, Elsevier, MDPI, etc. You are allowed (but not required) to publish 
        these articles (and the maps they contain) under an open license such as CC-BY as is the 
        case with PLoS journals and may be the case with other open access articles. Data for the 
        following countries is covered by a a different license Austria: Creative Commons 
        Attribution-ShareAlike 2.0 (source: Government of Ausria)", length(gadm_files)),
    
    rep('In addition to the general copyright and licence policy applicable to the whole Eurostat website, 
    the following specific provisions apply to the datasets you are downloading. The download and usage of 
    these data is subject to the acceptance of the following clauses: 
    
    The Commission agrees to grant the non-exclusive and not transferable right to use and process the Eurostat/
    GISCO geographical data downloaded from this page (the "data").
 
The permission to use the data is granted on condition that:
 
the data will not be used for commercial purposes;
the source will be acknowledged. A copyright notice, as specified below, will have to be visible on any printed or 
electronic publication using the data downloaded from this page.

Copyright notice

When data downloaded from this page is used in any printed or electronic publication, in addition to any other 
provisions applicable to the whole Eurostat website, data source will have to be acknowledged in the legend of the 
map and in the introductory page of the publication with the following copyright notice:

EN: © EuroGeographics for the administrative boundaries

FR: © EuroGeographics pour les limites administratives

DE: © EuroGeographics bezüglich der Verwaltungsgrenzen

For publications in languages other than English, French or German, the translation of the copyright notice 
in the language of the publication shall be used.

If you intend to use the data commercially, please contact EuroGeographics for information regarding their 
        licence agreements.', length(nuts_files)),
    
    rep("The use of www.oecd.org, any of its satellite or related website(s) or any of their pages (collectively 
    the “OECD Websites”), as well as any Organisation for Economic Co-operation and Development (the “ OECD”) 
    content whether digital, print or in any other medium, is governed by the terms and conditions found on this 
    page (the “Terms and Conditions”). By accessing an OECD Website and/or using any OECD content, you 
    (hereinafter referred to as “You” or the “User”) acknowledge that You have fully read and understood, 
    and agree to be bound by, these Terms and Conditions. You also acknowledge that You have fully read and 
    understood the OECD Privacy Policy and agree to its terms. These Terms and Conditions, as well as the OECD 
    Privacy Policy, may be updated from time to time at the discretion of the OECD and it is the User’s 
    responsibility to periodically review and take into account any changes.
 
The OECD encourages the use of its data, publications and multimedia products (sound, image, software, etc.), 
collectively, the 'Material'. Unless otherwise stated, the Material is the intellectual property of the OECD 
and protected by copyright or other similar rights. Some content in the Material may be owned by third parties. 
The User is responsible for verifying whether this is the case and, if so, securing the appropriate permissions 
from these third parties before using such content.
 
I. Use of Material


No Association
The User may neither represent nor imply that the OECD has participated in, approved, endorsed or otherwise 
supported his or her use or reproduction of the Material. The User may not claim any affiliation with the OECD. 
For information about use of the OECD name, acronym and logo, please see Section IV below
 
(a) Reproduction and translation of the material   
 
Except for content governed by specific terms (see sections (b) and (c)) or as may be otherwise indicated on 
the specific Material, the reproduction and translation of the Material is authorised for commercial and 
non-commercial purposes within established limits.

You may need to submit a formal request in certain circumstances. See below for further instructions:

Reproduction and translation authorisation for OECD Publications and Working Papers identified by DOI 
and/or ISBN, ISSN
- for excerpt(s), you should obtain the authorisation via Copyright Clearance Centre, Inc. (CCC) ; visit
www.copyright.com  and enter the title that you are requesting permission for in the 'Get Permission' search box  
- for requests to reproduce the complete text, please complete this form
- for requests to translate the complete text, please complete this form
 
Reproduction and translation authorisation for all Material OTHER than OECD Publications and Working Papers:
- 30% or less of a complete work or a maximum of 5 tables and/or graphs taken from a workis granted free of 
charge and without formal written permission provided You do not alter the Material in any way and You cite 
the source as follows: OECD/(co-author(s) if any) (year), (Title), URL.

In cases of translations of  such extracts, You must include the following disclaimer: “This translation was 
not created by the OECD and should not be considered an official OECD translation. The OECD shall not be liable 
for any content or error in this translation.”

- for all other requests concerning reproduction please complete this form
-  for all other requests concerning translation please complete this form
 
Note:  The OECD does not allow posting of PDF files of its Material on any Internet sites, but You are welcome 
to link to the Material and, whenever the  version is available, to share and embed it, in whole or in part, 
without the need to request permission from the OECD.
 
Read editions are optimised for browser-enabled mobile devices and can be read on screen wherever there is an 
internet connection.
 
(b) Content governed by specific terms and conditions
Certain content is governed by specific terms and conditions. Please see below: 

International Energy Agency (IEA) Material is governed by specific terms and conditions, which are available 
at http://www.iea.org/t&c/termsandconditions. 

Material licensed under a particular Creative Commons license (CC license) is governed by the specific CC 
license as well as any other conditions or restrictions as indicated on the particular Material.
If the CC license on the particular Material indicates NoDerivs (ND) but You would nonetheless like to to 
create derivative works, including translations, please send us the corresponding form:
- for requests concerning reproduction please complete this form
- for requests concerning translation please complete this form
 
- If the CC license on the particular Material indicates NonCommercial (NC) but You would nonetheless like 
to use the Material for commercial purposes, submit a request to the Copyright Clearance Centre, Inc. (CCC), 
www.copyright.com. 
 
The content from the Programme for International Student Assessment (PISA), including reports, publications, 
questionnaires, individual questions, sample tasks and any other content that may be accessed through any 
PISA-related website, except for Data (see Section I (c) below), are licensed under the Creative Commons 
Attribution-NonCommercial-ShareAlike 3.0 IGO (CC BY-NC-SA 3.0 IGO) licence.

- Translations — If You create a translation of PISA content, please add the following disclaimer along 
with the attribution: This translation was not created by the OECD and should not be considered an 
official OECD translation. The quality of the translation and its coherence with the original language 
text of the work are the sole responsibility of the author or authors of the translation.  In the event 
of any discrepancy between the original work and the translation, only the text of original work shall 
be considered valid.
We encourage You to provide your translation (PDF format) to the OECD at pubrights [at] oecd.org.

- Adaptations — If You create an adaptation of PISA content, please add the following disclaimer along 
with the attribution: This is an adaptation of an original work by the OECD. The opinions expressed and 
arguments employed in this adaptation are the sole responsibility of the author or authors of the adaptation 
and should not be reported as representing the official views of the OECD or of its member countries.
 
OECD Legal Instruments .
Official texts of OECD Legal Instruments in both OECD official languages (English and French), as well 
as related information, are made available in the Compendium of OECD Legal Instruments at 
https://legalinstruments.oecd.org.  OECD Legal Instruments may be found elsewhere, including on OECD 
websites, but You should always consult the Compendium, as it is the only source of the official and 
up do date texts and information.

You may reproduce and distribute individual OECD Legal Instruments free of charge and without requesting 
any permissions, as long as You do not alter them in any way.  You may use excerpts of a Legal Instrument, 
as long as You ensure that the legal nature/integrity of the Instrument is preserved and the excerpt is 
not used out of context or provides incomplete information or otherwise mislead the reader as to the actual 
legal nature,  scope or content of the Legal Instrument. OECD Legal Instruments may not be sold but may be 
used in the context of commercial activities such as, for example, consulting or training services. 

OECD Legal Instruments are available in the two OECD official languages (English and French). Translations 
into other languages may be available on the website, but the only official texts remain the English and French versions.

You may translate OECD Legal Instruments and related information and documents provided in the Compendium 
into other languages, as long as the translation is labelled “unofficial translation” and You include the 
following disclaimer: “This translation has been prepared by [translation author] for informational purpose 
only and its accuracy cannot be guaranteed by the OECD. The only official versions are the English and French 
texts available on the OECD website https://legalinstruments.oecd.org.

 We encourage You to provide your translation (PDF format) to the OECD, e-mail legal@oecd.org
 
(c) Data
The OECD makes data (the “Data”) available for use and consultation by the public.  Data may be subject to
restrictions beyond the scope of these Terms and Conditions, either because specific terms apply to those 
Data or because third parties may have ownership interests. It is the User’s responsibility to verify, 
either directly in the metadata or, if available, by clicking on the  icon and then referring to the 
'source' tab, whether the Data is fully or partially owned by third parties and/or whether additional 
restrictions may apply, and to contact the owner of the Data before incorporating it in your work in 
order to secure the necessary permissions. The OECD in no way represents or warrants that it owns or 
controls all rights in all Data, and the OECD will not be liable to any User for any claims brought 
against the User by third parties in connection with the use of any Data.

Permitted use
Except where additional restrictions apply as stated above, You can extract from, download, copy, adapt, 
print, distribute, share and embed Data for any purpose, even for commercial use. You must give appropriate 
credit to the OECD by using the citation associated with the relevant Data, or, if no specific citation 
is available, You must cite the source information using the following format: OECD (year), (dataset name),
(data source) DOI or URL (accessed on (date)). When sharing or licensing work created using the Data, 
You agree to include the same acknowledgment requirement in any sub-licenses that You grant, along with 
the requirement that any further sub-licensees do the same.

Availability of Data
The availability of the Data is contingent upon the availability of the OECD’s corresponding resources, 
whose capacity is subject to change at any time. The OECD may monitor your use of the Data and reserves 
the right, at its sole discretion and without limitation, to modify the amount of Data You may request 
in a single query, to modify the number of queries You may make over a specified time, to remove certain 
Data and to alter the file formats in which Data are available.

OECD Application Programming Interfaces (APIs)
You may use one or more OECD-developed application programming interfaces (“APIs”) to facilitate access 
to the Data. APIs are made available on an “as-is” basis, and use of an API is at your own risk. 
In particular, but without limitation, the OECD disclaims all warranties as to an API’s compatibility 
with your hardware and software and accepts no liability for any damages or claims arising out of or 
in connection with your use of an API and/or the underlying Data accessed through an API. For the avoidance
of doubt, the OECD accepts no obligation to provide technical, administrative or other support in connection
with the APIs or for any other purpose. The OECD may decide to suspend or terminate the provision of the APIs 
and API-accessible Data at any time.

The OECD may release updated versions of the APIs from time to time and at its sole discretion. Once the 
OECD releases updated versions, previous APIs may no longer function properly, and You therefore agree, 
for each API, to use the most up-to-date version available.

You agree not to modify, distribute, decompile, disassemble, reverse engineer or perform any similar action 
on the APIs or any of their portions or components.

The OECD reserves the right to limit or suspend any User’s IP address access to the APIs at any time and 
without notice for any reason, including if the OECD determines that You are using or are attempting to 
use the Data and/or the APIs in violation of these Terms and Conditions in such a way as to harm the OECD
or any other party, or if You are placing too great a strain on the infrastructure necessary for making 
the Data available to a reasonable number of people. You agree not to use any technical means to interfere
with the OECD’s monitoring of usage of the above-mentioned resources. The OECD reserves the right to use 
any technical means to overcome attempted technical interference with usage monitoring. Finally, the Data 
and the APIs will be unavailable from time to time, at the OECD’s sole discretion, for periodic maintenance.

When entering an API query, the OECD encourages, but does not require, You to register your details so 
that we can keep You informed of technical updates to the APIs. The information You provide to the OECD
during the voluntary registration process will be handled in accordance with the OECD Privacy Policy.  
Registration in no way impacts the application of these Terms and Conditions on You or the OECD. 

As noted above, these Terms and Conditions may be updated from time to time. By using an API, You agree
to periodically review these Terms and Conditions, to take note of any changes thereto, and to adapt 
your usage of the API accordingly.
 

II. Communication and Messaging Facilities

You shall not do any of the following in any messaging or communication facilities that may be found 
on an OECD Website:

defame, abuse, harass, threaten or otherwise violate the legal rights of others;
publish, post, distribute or disseminate any defamatory, infringing, obscene, indecent or unlawful material;
(Scam alert)
upload or attach files that contain software or other material protected by intellectual property laws 
unless You own or control the rights thereto or have received all necessary permissions;
upload or attach files that contain viruses, corrupted files, or any other similar software or programs
that may damage the operation of another's computer;
upload, e-mail, transmit or otherwise make available unsolicited advertising of any goods or services, or 
conduct or forward surveys, contests, 'spam' or chain letters; etc.

The OECD reserves the right to deny, at its sole discretion, any User’s IP address online access to the 
OECD Websites or any portion thereof without notice.

You specifically acknowledge and agree that the OECD is not liable for any conduct of any other User, 
including, but not limited to, the types of conduct listed above.
 
III. Linking to the OECD Websites

In order to promote its work, and because linking is an essential aspect of the Internet, the OECD 
encourages You to include hyperlinks to the OECD Websites without having to ask prior permission, under 
the following conditions:
These hyperlinks must not:
infringe the OECD's rights, in particular relating to its name, logo, acronym and intellectual property rights;
be used for the promotion of an organisation or company, or of any commercial products or services.
Consequently,
if You link to an OECD Website, You must refrain from creating frames, or using other visual altering tools, 
around the OECD Website;
once a link to an OECD Website has been created, it should be tested to ensure that it works and meets the 
above conditions. We would then appreciate being notified via webmaster@oecd.org.

If You have further questions about linking to the OECD Websites, e-mail webmaster@oecd.org.
 
IV. OECD Name, Acronym and Logo

OECD logo for authorship and endorsement
As stated in Section I above, You may not claim any affiliation with the OECD. If You wish to use the OECD 
name, acronym, logo or other identifying symbol in a way that implies endorsement, partnership or authorship, 
You must obtain our written permission and agreement on how the name, acronym, logo or other identifying symbol 
will be used. Send your request to logo@oecd.org. If permission is granted, it is only granted for the specific
usage referred to in OECD’s reply; each new use requires a new request.
 
V. Disclaimers

THE MATERIAL AS WELL AS ANY OTHER INFORMATION PROVIDED BY THE OECD ON THE OECD WEBSITES OR ON ANOTHER 
MEDIUM IS PROVIDED ON AN 'AS IS' AND 'AS AVAILABLE' BASIS. The OECD makes every effort to ensure, but 
does not guarantee, the accuracy or completeness of the Material (including the Data). If errors are 
brought to our attention, we will try to correct them.
 
The OECD may add, change, improve, or update the Material without notice. The OECD reserves its exclusive
right in its sole discretion to alter, limit or discontinue all or part of the OECD Websites and/or any 
Material. Under no circumstances shall the OECD be liable for any loss, damage, liability or expense 
suffered which is claimed to result from use of the OECD Websites or the Material, including without
limitation, any fault, error, omission, interruption or delay. In particular, and without limitation, 
the OECD disclaims all guarantees as to the compatibility of the OECD Websites with any hardware, 
operating system, web browser, or other means of accessing the OECD Websites. Use of the Material 
or any OECD Website or any component thereof (including the Data and APIs) is at the User's sole risk.
 
We make every effort to minimise disruption caused by technical errors. However, some Material on the 
OECD Websites may have been created or structured in files or formats which are not error-free and it 
cannot be guaranteed that the OECD Websites will not be interrupted or otherwise affected by such problems. 
The OECD accepts no responsibility with regard to such problems (failure of performance, computer virus, 
communication line failure, alteration of content, etc.) incurred as a result of using the OECD Websites 
or any link to external sites.
 
For site security purposes, and to ensure that the OECD Websites remain available to all Users, the OECD 
employs software programs to monitor network traffic to identify unauthorised attempts to upload or make 
changes to the OECD Websites or any Material, or otherwise cause damage and to detect other possible security breaches.
 
The OECD Websites may contain advice, opinions and statements from external websites. Hyperlinks to 
non-OECD Internet sites do not imply any official endorsement of or responsibility for the opinions, 
ideas, data or products presented at these locations or guarantee the validity of the information provided. 
The sole purpose of links to other sites is to indicate further information available on related topics.

The mention of specific companies or certain products does not imply that they are endorsed or recommended 
by the OECD in preference to others of a similar nature that are not mentioned.
 
Territorial disclaimers
Information contained in the Material and on the OECD Websites does not imply the expression of any 
opinion whatsoever on the part of the OECD Secretariat or its Members concerning the legal status of 
any country or of its authorities. Its content, as well as any data and any maps displayed are without
prejudice to the status of or sovereignty over any territory, to the delimitation of international 
frontiers and boundaries and to the name of any territory, city or area.

The statistical data for Israel are supplied by and under the responsibility of the relevant Israeli 
authorities. The use of such data by the OECD is without prejudice to the status of the Golan Heights, 
East Jerusalem and Israeli settlements in the West Bank under the terms of international law.


Note by Türkiye
The information in the documents with reference to “Cyprus” relates to the southern part of the Island. 
There is no single authority representing both Turkish and Greek Cypriot people on the Island. Türkiye 
recognizes the Turkish Republic of Northern Cyprus (TRNC). Until a lasting and equitable solution is
found within the context of the United Nations, Türkiye shall preserve its position concerning the “Cyprus issue”.


Note by all the European Union Member States of the OECD and the European Union
The Republic of Cyprus is recognised by all members of the United Nations with the exception of Türkiye. 
The information in the documents relates to the area under the effective control of the Government of 
the Republic of Cyprus.

Disclaimers for OECD's Social Media Accounts
The opinions expressed and arguments employed in the content displayed on the OECD’s social media accounts 
do not necessarily reflect the official views of the OECD, its Member countries, or any stakeholders who 
have contributed to or participated in any related work. 

The content displayed on the OECD's social media accounts, as well as any data and any map displayed herein,
are without prejudice to the status of or sovereignty over any territory, to the delimitation of international
frontiers and boundaries and to the name of any territory, city or area. Please refer to the Section V 
(Disclaimers) of the OECD Terms and Conditions for specific territorial disclaimers.

The OECD’s social media accounts may display third party content or include hyperlinks to third party websites
or social media accounts. The inclusion of such content or hyperlinks does not imply any endorsement of or 
responsibility for the opinions, ideas, data, products or information presented in such content or at these
locations or guarantee the validity of the information provided.

The mention of specific companies, individuals or certain products in the content displayed on OECD’s social
media accounts does not imply that they are endorsed or recommended by the OECD in preference to others of
a similar nature that are not mentioned.

The content displayed on the OECD's social media accounts may display or include hyperlinks to OECD documents, 
data, publications and multimedia products (sound, image, software, etc.). Unless otherwise stated, all 
content displayed on the OECD’s social media accounts are the intellectual property of the OECD and protected 
by copyright or other similar rights. The OECD encourages the use of the ©OECD content subject to the Section
I (Use of Materials) of the OECD Terms and Conditions. For third party content, please make sure that you 
secured the appropriate permissions from these third parties before using such content.

Please do not post any comment that is offensive, defamatory, threatening, insulting, abusive, hateful or 
embarrassing to any person or entity. 

The OECD does not guarantee the truthfulness, accuracy, or validity of any comments posted to its social
media accounts and reserves the right to delete or edit any comments that it considers inappropriate or 
unacceptable for any reason. 
   
 
VI. Preservation of immunities

Nothing herein shall constitute or be considered to be a limitation upon or a waiver of the privileges and
        immunities of the OECD or of any related body or entity, which are specifically reserved.", length(oecd_files)),
    
    rep("Eurostat has a policy of encouraging free re-use of its data, both for non-commercial and commercial purposes.
    All statistical data, metadata, content of web pages or other dissemination tools, official publications and other 
    documents published on its website, with the exceptions listed below, can be reused without any payment or written
    licence provided that:

the source is indicated as Eurostat;
when re-use involves modifications to the data or text, this must be stated clearly to the end user of the information.
Exceptions

The permission granted above does not extend to any material whose copyright is identified as belonging to a third-party, 
such as photos or illustrations from copyright holders other than the European Union. In these circumstances, authorisation
must be obtained from the relevant copyright holder(s).
 
Logos and trademarks are excluded from the above mentioned general permission, except if they are redistributed as an 
integral part of a Eurostat publication and if the publication is redistributed unchanged.
 
When reuse involves translations of publications or modifications to the data or text, this must be stated clearly to
the end user of the information. A disclaimer regarding the non-responsibility of Eurostat shall be included.
 
The following Eurostat data and documents may not be reused for commercial purposes (but non-commercial reuse is 
possible without restriction):
 
Data identified as belonging to sources other than Eurostat; all data published on Eurostat's website can be 
regarded as belonging to Eurostat for the purpose of their reuse, with the exceptions stated below, or if it 
is explicitly stated otherwise.
 
Publications or documents where the copyright belongs partly or wholly to other organisations, for example 
concerning co-publications between Eurostat and other publishers.
 
Data on countries other than
- Member States of the European Union (EU), and
- Member States of the European Free Trade Association (EFTA), and
- official EU acceding and candidate countries.
Examples are data on the United States of America, Japan or China. Often, such data are included in Eurostat 
data tables. In such cases, a re-user would need to eliminate such data from the tables before reusing them commercially.
 
Trade data originating from Liechtenstein and Switzerland (as declaring countries), from 1995 onwards, and 
concerning the following commodity classifications: HS, SITC, BEC, NSTR and national commodity classifications. 
Thus it is, for example, not allowed to sell export/import data declared by Switzerland (concerning the above 
named commodity classifications). However, it is allowed to sell Swiss export/import data declared by an EU
Member State (but see below a similar exception for Austria).
 
Trade data originating from Austria (as a declaring country) for a level of detail of the Combined Nomenclature 
of 8 digits; again, it is not allowed to sell export/import declared by Austria (concerning the above named 
commodity classifications), but it is allowed to sell Austrian export/import data declared by another EU Member State.
What to do if you want to re-use Eurostat material for commercial purposes

There is no special procedure or requirement for a written licence. Just download the material and use it
(unless the material is listed in the exceptions above).

Legal notice of the European Commission

The basis for the copyright and licence policy of Eurostat is the legal notice of the European Commission 
'Europa website' which can be found here: https://ec.europa.eu/info/legal-notice_en

Political context

This approach implements the policy of the European Statistical System (ESS), adopted in February 2013, 
under which the ESS has committed itself to provide its statistics free of charge as a public good of high quality, 
irrespective of subsequent commercial or non-commercial use.
(see https://ec.europa.eu/eurostat/web/european-statistical-system/programmes-and-activities/reuse-ess-statistics)

Contact

Any question regarding the copyright or re-use of Eurostat data or texts may be sought from the Publications 
Office of the European Union at the following address:

Publications Office,
Copyright and Legal Issues
2, rue Mercier, 2985 Luxembourg
e-mail: op-copyright@publications.europa.eu", length(euro_files)),
    
    rep("The data are freely available for academic use and other non-commercial use. Redistribution or 
        commercial use is not allowed without prior permission. Using the data to create maps for publishing 
        of academic research articles is allowed. Thus you can use the maps you made with WorldClim data for 
        figures in articles published by PLoS, Springer Nature, Elsevier, MDPI, etc. You are allowed (but not
        required) to publish these articles (and the maps they contain) under an open license such as CC-BY as
        is the case with PLoS journals and may be the case with other open access articles. ", length(wclim_files)), 
    
    rep("The data is available for free download (for non-commercial scientific, conservation and 
        educational purposes).", length(wwf_files)), 
    
    rep("The Crown (or, where applicable, Ordnance Survey’s suppliers) owns the intellectual property rights 
    in the data contained in this product. You are free to use the product on the terms of the Open 
    Government Licence, but must acknowledge the source of the data by including the following attribution
    statement: Contains Ordnance Survey data © Crown copyright and database right 2013. Additional data 
    sourced from third parties, including public sector information licensed under the Open Government Licence v1.0.", 
        length(ordsur_files)),
    
    rep("All versions of Natural Earth raster + vector map data found on this website are in the public domain. You may 
        use the maps in any manner, including modifying the content and design, electronic dissemination, and offset
        printing. The primary authors, Tom Patterson and Nathaniel Vaughn Kelso, and all other contributors renounce 
        all financial claim to the maps and invites you to use them for personal, educational, and commercial purposes.
        No permission is needed to use Natural Earth. Crediting the authors is unnecessary.", length(nacis_files)),
    
    rep("Use of the WOUDC data are governed by the World Meteorological Organization (WMO) data policy and WMO 
    Global Atmosphere Watch (GAW) data use policy.

World Meteorological Organization Data Policy
The WMO facilitates the free and unrestricted exchange of data and information, products and services in real 
or near-real time on matters relating to safety and security of society, economic welfare and the protection 
of the environment.

Resolution 40 (Cg-XII): WMO policy and practice for the exchange of meteorological and related data and products
including guidelines on the relationships in commercial meteorological activities.

Global Atmosphere Watch Data Use Policy
Use of data obtained from one of the WMO GAW World Data Centres (WDC) is subject to the following statement 
endorsed by the WMO Executive Council and the Commission for Atmospheric Sciences (EC/CAS) panel of experts
working group on environmental pollution and atmospheric chemistry [WMO, 2001a].:

WMO Policy Statement

For scientific, educational and policy related use, access to these [GAW] data is unlimited and provided 
without charge. By their use you accept that an offer of co-authorship will be made through personal 
contact with the data providers or owners whenever substantial use is made of their data. In all cases, 
an acknowledgment must be made to the data providers or owners and to the data centre when these data are
used within a publication.
Digital Object Identifiers (DOI)
WOUDC has registered DOIs for both Ozone and UV data. DOIs are persistent identifiers that allow research 
data to be accessible and citable. They make research data easier to access, reuse and verify, thereby 
making it easier to build on previous work, conduct new research and avoid duplicating already existing work.

WOUDC Digital Object Identifiers (first order)
Ozone: doi:10.14287/10000001
UV Radiation: doi:10.14287/10000002
WOUDC Digital Object Identifiers (datasets)
Total Ozone - Daily Observations: doi:10.14287/10000004
Total Ozone - Hourly Observations: doi:10.14287/10000003
Lidar: doi:10.14287/10000007
OzoneSonde: doi:10.14287/10000008
UmkehrN14 (Level 1.0): doi:10.14287/10000005
UmkehrN14 (Level 2.0): doi:10.14287/10000006
RocketSonde: doi:10.14287/10000009
Broadband: doi:10.14287/10000012
Multiband: doi:10.14287/10000010
Spectral: doi:10.14287/10000011
UV Index: doi:10.14287/10000013
Publishing Data
When publishing data retrieved from the WOUDC you are expected to acknowledge the contributors who
author these data as the data source and the WOUDC, using the appropriate citation as per the example provided.

Example (1): Citation for ozone data originating (contributed) from the Japan Meteorological Agency
(JMA) and NASA (NASA-WFF) retrieved from the WOUDC site
JMA, & NASA-WFF. World Meteorological Organization-Global Atmosphere Watch Program (WMO-GAW)/World 
Ozone and Ultraviolet Radiation Data Centre (WOUDC) [Data]. Retrieved October 24, 2013, from 
https://woudc.org. doi:10.14287/10000001
Example (2): Citation for data originating (contributed) from a large number of organizations 
retrieved from the WOUDC site
a) WMO/GAW Ozone Monitoring Community, World Meteorological Organization-Global Atmosphere Watch
Program (WMO-GAW)/World Ozone and Ultraviolet Radiation Data Centre (WOUDC) [Data]. Retrieved October 24, 2013, 
from https://woudc.org. A list of all contributors is available on the website. doi:10.14287/10000001
b) WMO/GAW UV Radiation Monitoring Community, World Meteorological Organization-Global Atmosphere 
Watch Program (WMO-GAW)/World Ozone and Ultraviolet Radiation Data Centre (WOUDC) [Data]. 
Retrieved October 24, 2013, from https://woudc.org. A list of all contributors is available 
on the website. doi:10.14287/10000002
For a complete list of all contributors refer to the contributor list.

Publishing Products
When publishing products extracted from WOUDC such as graphs, lists, maps or metadata you are expected 
to acknowledge the WOUDC, as the data and produce source, using the appropriate citation, as per the example provided.

Example (3): Citation for products originating from the WOUDC site
Environment and Climate Change Canada, Toronto (n.d.). World Meteorological Organization-Global 
        Atmosphere Watch Program (WMO-GAW)/World Ozone and Ultraviolet Radiation Data Centre (WOUDC). 
        Retrieved October 24, 2013, from https://woudc.org.", length(woudc_files))
   )
)

# Write data frame to file
write.csv(df_source, "out/source_data_info.csv")


