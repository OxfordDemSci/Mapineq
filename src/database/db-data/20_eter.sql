--First create table,the order of the columns and their types should be the same as in the csv file. The names can differ. Make sure the year is in a column name "obsTime", the values are in the column "obsValue" and the area code is in geo. 
--For obsTime and obsValue the capitals are important.
DROP TABLE IF EXISTS public.eter CASCADE;
CREATE TABLE IF NOT EXISTS eter
(
	id					INTEGER,
	geo					TEXT,
	"obsTime"			NUMERIC,
	"obsValue"			NUMERIC,
	category			TEXT
);


--Load with  PSQL
--This part you should run with psql. Only in psql you can use local files for copy with the command \copy. The normal copy command uses only files which are on the database server.
--And of course adjust the path to the file.
\copy eter FROM 'C:\Users\douglasl\git\OxfordDemSci\MapIneq\src\database\db-data\eter.csv' HEADER DELIMITER ',' CSV

--Add an entry to the catalogue table.
--Check upfromt if the entry is not already there.
INSERT INTO public.catalogue(
        resource, 
        use, 
        provider, 
        descr, 
        short_descr, 
        url,
        meta_data_url,
        web_source_url,
        license,
        query_resource
    ) 
	VALUES (
        'eter', 
        TRUE, 
        'European Higher Education Sector Observatory', 
        'Count of higher education institutions by year and category for NUTS-2 and NUTS-3 regions.', 
        'Higher Ed Institutes', 
        'https://eter-project.com',
        'https://eter-project.com/data/overview-data/', 
        'https://eter-project.com/data/data-for-download-and-visualisations/database/',
        'https://eter-project.com/about/using-eter-data/',
        'vw_eter');

--Create a view with the name vw_tablename. Leave columns out which should not be used. A view is needed.
CREATE OR REPLACE VIEW vw_eter AS
SELECT
	geo,
	"obsTime",
	"obsValue",
    category
FROM
	eter;

--Fill some tables with information. Just run these procedures. The procedure first removes the records for the table and then add new records, so it can be run again if needed.
CALL website.fill_resource_years('eter');
CALL website.fill_resource_nuts_levels('eter');
CALL website.fill_resource_year_nuts_levels('eter');

CALL website.fill_catalogue_field_description( 'eter');
CALL website.fill_catalogue_field_value_description( 'eter');

--Check if everything is working with these control queries
SELECT * FROM website.vw_data_tables WHERE resource = 'eter';

SELECT * FROM website.resource_years WHERE resource = 'eter';
SELECT * FROM website.resource_nuts_levels WHERE resource = 'eter';
SELECT * FROM website.resource_year_nuts_levels WHERE resource = 'eter';

SELECT * FROM website.vw_data_tables WHERE resource = 'eter';
SELECT * FROM website.catalogue_field_description WHERE resource = 'eter';

