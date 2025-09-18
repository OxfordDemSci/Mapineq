DROP TABLE IF EXISTS public.eheso_erasmedlevel CASCADE;
CREATE TABLE IF NOT EXISTS eheso_erasmedlevel (
  id numeric primary key,
  geo TEXT,
  "obsValue" numeric,
  "obsTime" numeric,
  education_level TEXT,
  direction TEXT,
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
  'eheso_erasmedlevel', 
  'vw_eheso_erasmedlevel',
  TRUE, 
  'Erasmus students count by year, education level, direction, NUTS 1, NUTS 2 and NUTS 3 regions. Data collected by the European Higher Education Sector Observatory.', 
  'Erasmus students', 
  'https://national-policies.eacea.ec.europa.eu/eheso',
  'https://national-policies.eacea.ec.europa.eu/eheso/methodology-and-technical-documentation',
  'https://eter-project.com/data/data-for-download-and-visualisations/database/',
  'https://eter-project.com/about/using-eter-data/'
);


CREATE OR REPLACE VIEW vw_eheso_erasmedlevel AS
SELECT
  geo,
  "obsValue",
  "obsTime",
  education_level,
  direction
FROM eheso_erasmedlevel;

CALL website.fill_resource_years('eheso_erasmedlevel');
CALL website.fill_resource_nuts_levels('eheso_erasmedlevel');
CALL website.fill_resource_year_nuts_levels('eheso_erasmedlevel');
CALL website.fill_catalogue_field_description('eheso_erasmedlevel');
CALL website.fill_catalogue_field_value_description('eheso_erasmedlevel');

SELECT * FROM website.vw_data_tables WHERE resource = 'eheso_erasmedlevel';
SELECT * FROM website.resource_years WHERE resource = 'eheso_erasmedlevel';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'eheso_erasmedlevel';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'eheso_erasmedlevel';
