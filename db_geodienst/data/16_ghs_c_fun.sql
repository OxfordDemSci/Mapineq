--First create table,the order of the columns and their types should be the same as in the csv file. The names can differ. Make sure the year is in a column name "obsTime", the values are in the column "obsValue" and the area code is in geo. 
--For obsTime and obsValue the capitals are important.
DROP TABLE IF EXISTS ghs_c_fun CASCADE;
CREATE TABLE IF NOT EXISTS ghs_c_fun
(
    id 			INTEGER,
    geo 		TEXT,
    "obsValue" 	NUMERIC,
    indicator 	TEXT,
    freq 		TEXT,
    "obsTime" 	INTEGER,
    unit 		TEXT,
    geo_source 	TEXT
)

--Load with  PSQL
--This part you should run with psql. Only in psql you can use local files for copy with the command \copy. The normal copy command uses only files which are on the database server.
--And of course adjust the path to the file.
\copy ghs_c_fun FROM 'c:\projects\mapineq\db_geodienst\data\ghs_c_fun.csv' HEADER DELIMITER ',' CSV

--Add an entry to the catalogue table.
--Check upfromt if the entry is not already there.
 DELETE FROM catalogue where resource = 'ghs_c_fun';
INSERT INTO public.catalogue(
	provider, resource, descr,   use, short_descr, query_resource)
	VALUES ('Global Human Settlement Layer', 'ghs_c_fun', 'Non-/residential functional classification of the built domain', TRUE, 'ghs_c_fun','vw_ghs_c_fun');

--Create a view with the name vw_tablename. Leave columns out which should not be used. A view is needed.
DROP VIEW IF EXISTS vw_ghs_c_fun;
CREATE OR REPLACE VIEW vw_ghs_c_fun AS
SELECT
    geo,
    "obsValue",
    indicator,
    "obsTime",
    unit
FROM
	ghs_c_fun;

--Fill some tables with information. Just run these procedures. The procedure first removes the records for the table and then add new records, so it can be run again if needed.
CALL website.fill_resource_years('ghs_c_fun');
CALL website.fill_resource_nuts_levels('ghs_c_fun');
CALL website.fill_resource_year_nuts_levels('ghs_c_fun');

CALL website.fill_catalogue_field_description( 'ghs_c_fun');
CALL website.fill_catalogue_field_value_description( 'ghs_c_fun');

--Check if everythin if working with these control queries
SELECT * FROM website.vw_data_tables WHERE resource = 'ghs_c_fun';

SELECT * FROM website.resource_years WHERE resource = 'ghs_c_fun' order by year;
SELECT * FROM website.resource_nuts_levels WHERE resource = 'ghs_c_fun' order by level;
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'ghs_c_fun' order by 3,2;

SELECT * FROM website.catalogue_field_description WHERE resource = 'ghs_c_fun';
SELECT * FROM website.catalogue_field_value_description WHERE resource = 'ghs_c_fun';


