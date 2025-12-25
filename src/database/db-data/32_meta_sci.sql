CALL website.remove_resource('META', 'meta_sci');

DROP TABLE IF EXISTS public.meta_sci CASCADE;
CREATE TABLE IF NOT EXISTS meta_sci (
  id numeric primary key,
  geo TEXT,
  friend_loc TEXT,
  "obsValue" numeric,
  "obsTime" numeric,
  geo_source TEXT,
  friend_country TEXT
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
  'meta_sci', 
  'vw_meta_sci',
  TRUE, 
  'Social Connected Index (SCI) provided by Meta (Facebook) at country level, level 2 and 3 by 2016 NUTS regions.', 
  'META SCI', 
  'https://dataforgood.facebook.com/dfg/tools/social-connectedness-index',
  'https://dataforgood.facebook.com/dfg/docs/methodology-social-connectedness-index',
  'https://data.humdata.org/dataset/social-connectedness-index',
  'https://creativecommons.org/licenses/by/4.0/'
);


CREATE OR REPLACE VIEW vw_meta_sci AS
SELECT
  geo,
  "obsValue",
  "obsTime",
  friend_country,
  friend_loc
FROM meta_sci;

CALL website.fill_resource_years('meta_sci');
CALL website.fill_resource_nuts_levels('meta_sci');
CALL website.fill_resource_year_nuts_levels('meta_sci');
CALL website.fill_catalogue_field_description('meta_sci');
CALL website.fill_catalogue_field_value_description('meta_sci');

SELECT * FROM website.vw_data_tables WHERE resource = 'meta_sci';
SELECT * FROM website.resource_years WHERE resource = 'meta_sci';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'meta_sci';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'meta_sci';


INSERT INTO website.catalogue_field_value_description_order(provider, resource, field, order_json)
VALUES
(
'GRACED',
'graced_co2',
'month',
'{
"top": ["all", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
}'
)
