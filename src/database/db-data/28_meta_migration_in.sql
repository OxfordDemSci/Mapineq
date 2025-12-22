CALL website.remove_resource('META', 'meta_migration_in');

DROP TABLE IF EXISTS public.meta_migration_in CASCADE;
CREATE TABLE IF NOT EXISTS meta_migration_in (
  id numeric primary key,
  geo TEXT,
  origin TEXT,
  "obsValue" numeric,
  "obsTime" numeric,
  month TEXT,
  time_granularity TEXT,
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
  'META', 
  'meta_migration_in', 
  'vw_meta_migration_in',
  TRUE, 
  'META estimation of migration inflow at the country level from 2019 to 2022 by country, time granularity and flow type. Data matched to NUTS 2024 regions and the UK (from NUTS 2021)', 
  'META Migration In', 
  'https://data.humdata.org/dataset/international-migration-flows',
  'https://www.pnas.org/doi/10.1073/pnas.2409418122',
  'https://data.humdata.org/dataset/international-migration-flows',
  'https://creativecommons.org/licenses/by/4.0/legalcode'
);


CREATE OR REPLACE VIEW vw_meta_migration_in AS
SELECT
  geo,
  "obsValue",
  "obsTime",
  origin,
  month,
  time_granularity
FROM meta_migration_in;

CALL website.fill_resource_years('meta_migration_in');
CALL website.fill_resource_nuts_levels('meta_migration_in');
CALL website.fill_resource_year_nuts_levels('meta_migration_in');
CALL website.fill_catalogue_field_description('meta_migration_in');
CALL website.fill_catalogue_field_value_description('meta_migration_in');

SELECT * FROM website.vw_data_tables WHERE resource = 'meta_migration_in';
SELECT * FROM website.resource_years WHERE resource = 'meta_migration_in';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'meta_migration_in';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'meta_migration_in';

INSERT INTO website.catalogue_field_value_description_order(provider, resource, field, order_json)
VALUES
(
'META',
'meta_migration_in',
'time_granularity',
'{
"top": ["Annual"],
"bulk": "asc"
}'
)

INSERT INTO website.catalogue_field_value_description_order(provider, resource, field, order_json)
VALUES
(
'META',
'meta_migration_in',
'month',
'{
"top": ["All"],
"bulk": "asc"
}'
)
