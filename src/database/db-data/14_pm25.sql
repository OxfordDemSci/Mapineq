DROP TABLE IF EXISTS pm25 CASCADE;
CREATE TABLE pm25
(
	
	geo			TEXT,
	"obsValue"	NUMERIC,
	indicator	TEXT,
	freq		TEXT,
	"obsTime"	INTEGER,
	unit		TEXT,
	geo_source	TEXT
);

truncate table pm25;
\copy pm25 FROM 'c:\projects\mapineq\db_geodienst\data\pm25.csv' HEADER DELIMITER ',' CSV

DELETE FROM catalogue WHERE resource = 'pm25';
INSERT INTO public.catalogue(
	provider, resource, descr,   use, short_descr, query_resource)
	VALUES ('Washington University in St. Louis', 'pm25', 'PM25', TRUE, 'PM25', 'vw_pm25');

CREATE OR REPLACE VIEW vw_pm25 AS
SELECT
	geo,
	indicator,
	freq,
	unit,
	"obsTime",
	"obsValue"
FROM
	pm25;

CALL website.fill_resource_years('pm25');
CALL website.fill_resource_nuts_levels('pm25');
CALL website.fill_resource_year_nuts_levels('pm25');

CALL website.fill_catalogue_field_description( 'pm25');
CALL website.fill_catalogue_field_value_description( 'pm25');

--control queries
SELECT * FROM website.vw_data_tables WHERE resource = 'pm25';

SELECT * FROM website.resource_years WHERE resource = 'pm25';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'pm25';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'pm25';

SELECT * FROM website.catalogue_field_description where resource = 'pm25';
select * from website.catalogue_field_value_description where resource = 'pm25';