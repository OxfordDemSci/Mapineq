

DROP TABLE IF EXISTS public.urban_green_area CASCADE;
CREATE TABLE IF NOT EXISTS urban_green_area
(
	id			INTEGER,
    geo 		TEXT,
    freq 		TEXT,
    "obsTime" 	NUMERIC,
    indicator 	TEXT,
    "obsValue" 	NUMERIC,
    unit 		TEXT
);

Load with  PSQL
truncate table urban_green_area
\copy urban_green_area FROM 'c:\projects\mapineq\db_geodienst\data\urban_green_area.csv' HEADER DELIMITER ',' CSV

DELETE FROM catalogue WHERE resource = 'urban_green_area';
INSERT INTO public.catalogue(
	provider, resource, descr,   use, short_descr, query_resource)
	VALUES ('Urban Atlas', 'urban_green_area', 'Urban green area', TRUE, 'Urban green', 'vw_urban_green_area');

DROP VIEW IF EXISTS vw_urban_green_area;
CREATE OR REPLACE VIEW vw_urban_green_area AS
SELECT
	geo,
	freq,
	"obsTime",
	indicator,
	"obsValue",
	unit
FROM
	urban_green_area;


CALL website.fill_resource_years('urban_green_area');
CALL website.fill_resource_nuts_levels('urban_green_area');
CALL website.fill_resource_year_nuts_levels('urban_green_area');

CALL website.fill_catalogue_field_description( 'urban_green_area');
CALL website.fill_catalogue_field_value_description( 'urban_green_area');

--control queries
SELECT * FROM website.vw_data_tables WHERE resource = 'urban_green_area';

SELECT * FROM website.resource_years WHERE resource = 'urban_green_area';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'urban_green_area';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'urban_green_area';

SELECT * FROM website.vw_data_tables where resource = 'urban_green_area';
SELECT * FROM website.catalogue_field_description where resource = 'urban_green_area';

