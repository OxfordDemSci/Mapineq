CALL website.remove_resource('GRACED', 'graced_co2');

DROP TABLE IF EXISTS public.graced_co2 CASCADE;
CREATE TABLE IF NOT EXISTS graced_co2 (
  id numeric primary key,
  "obsTime" numeric,
  "obsValue" numeric,
  geo TEXT,
  metric TEXT,
  freq TEXT,
  month TEXT,
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
  'GRACED', 
  'graced_co2', 
  'vw_graced_co2',
  TRUE, 
  'Global gRidded dAily CO2 Emissions Dataset (the total CO2 emissions) from daily netCDF data to yearly and monthly mean and sum data by 2003, 2006, 2010, 2013, 2016, 2021, and 2024 NUTS regions', 
  'GRACED CO2', 
  'https://carbonmonitor-graced.com/index.html',
  'https://carbonmonitor-graced.com/datasets.html#about-graced',
  'https://carbonmonitor-graced.com/datasets.html#data-download',
  'https://creativecommons.org/licenses/by/4.0/'
);


CREATE OR REPLACE VIEW vw_graced_co2 AS
SELECT
  geo,
  "obsValue",
  "obsTime",
  metric,
  freq,
  month
FROM graced_co2;

CALL website.fill_resource_years('graced_co2');
CALL website.fill_resource_nuts_levels('graced_co2');
CALL website.fill_resource_year_nuts_levels('graced_co2');
CALL website.fill_catalogue_field_description('graced_co2');
CALL website.fill_catalogue_field_value_description('graced_co2');

SELECT * FROM website.vw_data_tables WHERE resource = 'graced_co2';
SELECT * FROM website.resource_years WHERE resource = 'graced_co2';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'graced_co2';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'graced_co2';

INSERT INTO website.catalogue_field_value_description_order(provider, resource, field, order_json)
VALUES
(
'GRACED',
'graced_co2',
'metric',
'{
"top": ["mean"],
"bulk": "asc"
}'
)
