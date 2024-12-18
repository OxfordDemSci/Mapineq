--First create table,the order of the columns and their types should be the same as in the csv file. The names can differ. Make sure the year is in a column name "obsTime", the values are in the column "obsValue" and the area code is in geo. 
--For obsTime and obsValue the capitals are important.
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


--Load with  PSQL
--This part you should run with psql. Only in psql you can use local files for copy with the command \copy. The normal copy command uses only files which are on the database server.
--And of course adjust the path to the file.
\copy ookla FROM 'C:\Users\RonnieLassche\Downloads\ookla.csv' HEADER DELIMITER ',' CSV

--Add an entry to the catalogue table.
--Check upfromt if the entry is not already there.
INSERT INTO public.catalogue(
	provider, resource, descr,   use, short_descr, query_resource)
	VALUES ('Ookla', 'ookla', 'Internet speed by ookla', TRUE, 'Ookla', 'vw_ookla');

--Create a view with the name vw_tablename. Leave columns out which should not be used. A view is needed.
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

--Fill some tables with information. Just run these procedures. The procedure first removes the records for the table and then add new records, so it can be run again if needed.
CALL website.fill_resource_years('ookla');
CALL website.fill_resource_nuts_levels('ookla');
CALL website.fill_resource_year_nuts_levels('ookla');

CALL website.fill_catalogue_field_description( 'ookla');
CALL website.fill_catalogue_field_value_description( 'ookla');

--Check if everythin if working with these control queries
SELECT * FROM website.vw_data_tables WHERE resource = 'ookla';

SELECT * FROM website.resource_years WHERE resource = 'ookla';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'ookla';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'ookla';

SELECT * FROM website.vw_data_tables WHERE resource = 'ookla';
SELECT * FROM website.catalogue_field_description WHERE resource = 'ookla';

