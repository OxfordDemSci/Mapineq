DROP TABLE IF EXISTS public.ookla CASCADE;
CREATE TABLE IF NOT EXISTS ookla
(
	id					INTEGER,
	geo					TEXT,
	quarter 			TEXT,
	unit				TEXT,
	freq				TEXT,
	"obsTime"			NUMERIC,
	network_type		TEXT,
	direction			TEXT,
	"obsValue"			NUMERIC,
	geo_source			TEXT
);

Load with  PSQL
\copy ookla FROM 'C:\Users\RonnieLassche\Downloads\ookla.csv' HEADER DELIMITER ',' CSV

SELECT * FROM catalogue

INSERT INTO public.catalogue(
	provider, resource, descr,   use, short_descr)
	VALUES ('Ookla', 'ookla', 'Internet speed by ookla', TRUE, 'Ookla');

CREATE OR REPLACE VIEW vw_ookla AS
SELECT
	geo,
	quarter,
	unit,
	freq,
	"obsTime",
	network_type,
	direction,
	"obsValue"
FROM
	ookla;

CALL website.fill_resource_years('ookla');
CALL website.fill_resource_nuts_levels('ookla');
CALL website.fill_resource_year_nuts_levels('ookla');

CALL website.fill_catalogue_field_description( 'ookla');
CALL website.fill_catalogue_field_value_description( 'ookla');

--control queries
SELECT * FROM website.vw_data_tables WHERE resource = 'ookla';

SELECT * FROM website.resource_years WHERE resource = 'ookla';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'ookla';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'ookla';

SELECT * FROM website.vw_data_tables WHERE resource = 'ookla';
SELECT * FROM website.catalogue_field_description WHERE resource = 'ookla';

