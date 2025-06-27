CALL website.remove_resource('NIVA', 'net_migration_00_19');

DROP TABLE IF EXISTS public.net_migration_00_19 CASCADE;
CREATE TABLE IF NOT EXISTS net_migration_00_19 (
  id numeric primary key,
  geo TEXT,
  "obsTime" numeric,
  metric TEXT,
  "obsValue" numeric,
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
  'NIVA', 
  'net_migration_00_19', 
  'vw_net_migration_00_19',
  TRUE, 
  'Niva et al. dataset providing a global detailed annual net-migration dataset for 2000-2019, by NUTS0, NUTS1, NUTS2 and NUTS3 regions.', 
  'NIVA Net Migration', 
  'https://www.nature.com/articles/s41562-023-01689-4',
  'https://www.nature.com/articles/s41562-023-01689-4',
  'https://zenodo.org/records/7997134',
  'https://creativecommons.org/licenses/by/4.0/legalcode'
);


CREATE OR REPLACE VIEW vw_net_migration_00_19 AS
SELECT
  geo,
  "obsValue",
  "obsTime",
  metric
FROM net_migration_00_19;

CALL website.fill_resource_years('net_migration_00_19');
CALL website.fill_resource_nuts_levels('net_migration_00_19');
CALL website.fill_resource_year_nuts_levels('net_migration_00_19');
CALL website.fill_catalogue_field_description('net_migration_00_19');
CALL website.fill_catalogue_field_value_description('net_migration_00_19');

SELECT * FROM website.vw_data_tables WHERE resource = 'net_migration_00_19';
SELECT * FROM website.resource_years WHERE resource = 'net_migration_00_19';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'net_migration_00_19';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'net_migration_00_19';

INSERT INTO website.catalogue_field_value_description_order(provider, resource, field, order_json)
VALUES
(
'NIVA',
'net_migration_00_19',
'metric',
'{
"top": ["sum"],
"bulk": "asc"
}'
)
