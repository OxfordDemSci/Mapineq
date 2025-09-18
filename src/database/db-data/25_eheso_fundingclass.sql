DROP TABLE IF EXISTS public.eheso_fundingclass CASCADE;
CREATE TABLE IF NOT EXISTS eheso_fundingclass (
  id numeric primary key,
  geo TEXT,
  "obsValue" numeric,
  freq TEXT,
  "obsTime" numeric,
  unit TEXT,
  class TEXT,
  geo_source TEXT
);

INSERT INTO public.catalogue (
  provider, 
  resource, 
  query_resource,
  use, 
  descr, 
  short_descr, 
  url,
  meta_data_url,
  web_source_url,
  license
) VALUES (
  'EHESO', 
  'eheso_fundingclass', 
  'vw_eheso_fundingclass',
  TRUE, 
  'Academic Funding by, year, NUTS 1, NUTS 2 and NUTS 3 regions. Data collected by the European Higher Education Sector Observatory.', 
  'Acad. Funding', 
  'https://national-policies.eacea.ec.europa.eu/eheso',
  'https://national-policies.eacea.ec.europa.eu/eheso/methodology-and-technical-documentation',
  'https://eter-project.com/data/data-for-download-and-visualisations/database/',
  'https://eter-project.com/about/using-eter-data/'
);


CREATE OR REPLACE VIEW vw_eheso_fundingclass AS
SELECT
  geo,
  "obsValue",
  "obsTime",
  unit,
  class
FROM eheso_fundingclass;

CALL website.fill_resource_years('eheso_fundingclass');
CALL website.fill_resource_nuts_levels('eheso_fundingclass');
CALL website.fill_resource_year_nuts_levels('eheso_fundingclass');
CALL website.fill_catalogue_field_description('eheso_fundingclass');
CALL website.fill_catalogue_field_value_description('eheso_fundingclass');

SELECT * FROM website.vw_data_tables WHERE resource = 'eheso_fundingclass';
SELECT * FROM website.resource_years WHERE resource = 'eheso_fundingclass';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'eheso_fundingclass';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'eheso_fundingclass';
