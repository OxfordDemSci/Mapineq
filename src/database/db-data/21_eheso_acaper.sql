DROP TABLE IF EXISTS public.eheso_acaper CASCADE;
CREATE TABLE IF NOT EXISTS eheso_acaper (
  id numeric primary key,
  geo TEXT,
  "obsValue" NUMERIC,
  "obsTime" NUMERIC,
  citizenship TEXT,
  gender TEXT,
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
  'eheso_acaper', 
  'vw_eheso_acaper',
  TRUE, 
  'Academic Personnel by, year, sex, citizenship, NUTS 1, NUTS 2 and NUTS 3 regions. Data collected by the European Higher Education Sector Observatory.', 
  'Acad. Personnel', 
  'https://national-policies.eacea.ec.europa.eu/eheso',
  'https://national-policies.eacea.ec.europa.eu/eheso/methodology-and-technical-documentation',
  'https://eter-project.com/data/data-for-download-and-visualisations/database/',
  'https://eter-project.com/about/using-eter-data/'
);


CREATE OR REPLACE VIEW vw_eheso_acaper AS
SELECT
  geo,
  "obsValue",
  "obsTime",
  citizenship,
  gender
FROM eheso_acaper;

CALL website.fill_resource_years('eheso_acaper');
CALL website.fill_resource_nuts_levels('eheso_acaper');
CALL website.fill_resource_year_nuts_levels('eheso_acaper');
CALL website.fill_catalogue_field_description('eheso_acaper');
CALL website.fill_catalogue_field_value_description('eheso_acaper');

SELECT * FROM website.vw_data_tables WHERE resource = 'eheso_acaper';
SELECT * FROM website.resource_years WHERE resource = 'eheso_acaper';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'eheso_acaper';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'eheso_acaper';
