CALL website.remove_resource('JRC-COIN', 'jrccoin_cultgems');

DROP TABLE IF EXISTS public.jrccoin_cultgems CASCADE;
CREATE TABLE IF NOT EXISTS jrccoin_cultgems (
  id numeric primary key,
  geo TEXT,
  "obsValue" numeric,
  broad_category TEXT,
  category TEXT,
  "obsTime" numeric,
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
  'JRC-COIN', 
  'jrccoin_cultgems', 
  'vw_jrccoin_cultgems',
  TRUE, 
  'Cultural Gems (places of cultural interest) count by category, NUTS 1, NUTS 2 and NUTS 3 regions. Data collected by European Commission’s Competence Centre on Composite Indicators and Scoreboards (COIN) at the Joint Research Centre (JRC).', 
  'Cultural Gems', 
  'https://cultural-gems.jrc.ec.europa.eu/homepage',
  'https://data.jrc.ec.europa.eu/dataset/9ee32efe-af81-48e4-8ad6-a0db06802e03',
  'https://cultural-gems.jrc.ec.europa.eu/map',
  'https://opendatacommons.org/licenses/odbl/'
);


CREATE OR REPLACE VIEW vw_jrccoin_cultgems AS
SELECT
  geo,
  "obsValue",
  "obsTime",
  broad_category,
  category
FROM jrccoin_cultgems;

CALL website.fill_resource_years('jrccoin_cultgems');
CALL website.fill_resource_nuts_levels('jrccoin_cultgems');
CALL website.fill_resource_year_nuts_levels('jrccoin_cultgems');
CALL website.fill_catalogue_field_description('jrccoin_cultgems');
CALL website.fill_catalogue_field_value_description('jrccoin_cultgems');

SELECT * FROM website.vw_data_tables WHERE resource = 'jrccoin_cultgems';
SELECT * FROM website.resource_years WHERE resource = 'jrccoin_cultgems';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'jrccoin_cultgems';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'jrccoin_cultgems';
