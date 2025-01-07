CREATE TABLE IF NOT EXISTS public.catalogue
(
	id				SERIAL PRIMARY KEY,
    provider 		TEXT,
    resource 		TEXT,
    descr 			TEXT,
    version 		INTEGER,
    url 			TEXT,
    use 			BOOLEAN,
    short_descr 	CHARACTER VARYING(20),
    query_resource 	TEXT,
    meta_data_url 	TEXT,
    web_source_url 	TEXT,
    license 		TEXT
);

CREATE OR REPLACE VIEW website.vw_data_tables
 AS
SELECT 
	catalogue.*
FROM 
	catalogue
	INNER JOIN information_schema.tables
		ON query_resource = table_name
WHERE
	use
	AND EXISTS(SELECT 1 FROM information_schema.columns WHERE  table_name = query_resource AND column_name = 'geo');


CREATE OR REPLACE FUNCTION website.get_query_resource(TEXT)
RETURNS TEXT
AS
$BODY$
	SELECT query_resource FROM website.vw_data_tables WHERE resource = $1;

$BODY$
LANGUAGE SQL IMMUTABLE;

DROP PROCEDURE IF EXISTS website.set_table_status(TEXT, TEXT, BOOLEAN);
CREATE OR REPLACE PROCEDURE website.set_table_status(strProvider TEXT, strResource TEXT, bStatus BOOLEAN)
AS
$BODY$
DECLARE 
	UPDATE_STATUS CONSTANT TEXT := $$UPDATE catalogue SET use = %L WHERE provider ILIKE %L AND resource ILIKE %L$$;
BEGIN
	EXECUTE FORMAT (UPDATE_STATUS, bStatus, strProvider, strResource);
END;
$BODY$
LANGUAGE PLPGSQL;

DROP PROCEDURE IF EXISTS website.set_table_description(TEXT, TEXT, TEXT);
CREATE OR REPLACE PROCEDURE website.set_table_description(strProvider TEXT, strResource TEXT, strDescription TEXT)
AS
$BODY$
DECLARE 
	UPDATE_DESCRIPTION CONSTANT TEXT := $$UPDATE catalogue SET descr = %L WHERE provider ILIKE %L AND resource ILIKE %L$$;
BEGIN
	EXECUTE  FORMAT (UPDATE_DESCRIPTION, strDescription , strProvider, strResource);
END;
$BODY$
LANGUAGE PLPGSQL;

DROP PROCEDURE IF EXISTS website.set_table_description(TEXT, TEXT, TEXT);
CREATE OR REPLACE PROCEDURE website.set_table_short_description(strProvider TEXT, strResource TEXT, strShortDescription TEXT)
AS
$BODY$
DECLARE 
	UPDATE_SHORT_DESCRIPTION CONSTANT TEXT := $$UPDATE catalogue SET short_descr = %L WHERE provider ILIKE %L AND resource ILIKE %L$$;
BEGIN
	EXECUTE  FORMAT (UPDATE_SHORT_DESCRIPTION, LEFT(strShortDescription,20) , strProvider, strResource);
END;
$BODY$
LANGUAGE PLPGSQL;
