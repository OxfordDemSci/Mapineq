DROP VIEW IF EXISTS website.vw_data_tables;
CREATE OR REPLACE VIEW website.vw_data_tables 
AS
WITH cte as
(
	SELECT 
		*,
		CASE WHEN provider =  'ESTAT' 
			THEN 
				resource
			ELSE
				'vw_' || LOWER(resource)
		END AS query_resource
	FROM 
		catalogue
)
SELECT 
	cte.*
FROM 
	cte
	INNER JOIN information_schema.tables
		ON query_resource = table_name
WHERE
	use
	AND EXISTS(SELECT 1 FROM information_schema.columns WHERE  table_name = query_resource AND column_name = 'geo');


CREATE OR REPLACE FUNCTION website.get_query_resource(TEXT)
RETURNS TEXT
AS
$BODY$
	SELECT query_resource FROM website.vw_data_tables where resource = $1;

$BODY$
LANGUAGE SQL IMMUTABLE;