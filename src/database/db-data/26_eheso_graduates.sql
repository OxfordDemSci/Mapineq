DROP TABLE IF EXISTS public.eheso_graduates CASCADE;
CREATE TABLE IF NOT EXISTS eheso_graduates (
  id numeric primary key,
  to_drop numeric,
  geo TEXT,
  "obsValue" numeric,
  "obsTime" numeric,
  citizenship TEXT,
  level TEXT,
  gender TEXT,
  field TEXT,
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
  'eheso_graduates', 
  'vw_eheso_graduates',
  TRUE, 
  'Academic Graduates by year, citizenship, level, gender, field, NUTS 1, NUTS 2 and NUTS 3 regions. Data collected by the European Higher Education Sector Observatory.', 
  'Acad. Graduates', 
  'https://national-policies.eacea.ec.europa.eu/eheso',
  'https://national-policies.eacea.ec.europa.eu/eheso/methodology-and-technical-documentation',
  'https://eter-project.com/data/data-for-download-and-visualisations/database/',
  'https://eter-project.com/about/using-eter-data/'
);


CREATE OR REPLACE VIEW vw_eheso_graduates AS
SELECT
  geo,
  "obsValue",
  "obsTime",
  citizenship,
  level,
  gender,
  field
FROM eheso_graduates;

CALL website.fill_resource_years('eheso_graduates');
CALL website.fill_resource_nuts_levels('eheso_graduates');
CALL website.fill_resource_year_nuts_levels('eheso_graduates');
CALL website.fill_catalogue_field_description('eheso_graduates');
CALL website.fill_catalogue_field_value_description('eheso_graduates');

SELECT * FROM website.vw_data_tables WHERE resource = 'eheso_graduates';
SELECT * FROM website.resource_years WHERE resource = 'eheso_graduates';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'eheso_graduates';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'eheso_graduates';
