DROP PROCEDURE IF EXISTS website.remove_resource(TEXT, TEXT);

CREATE OR REPLACE PROCEDURE website.remove_resource(strProvider TEXT, strResource TEXT)
AS
$BODY$
DECLARE
	rec			RECORD;
	DROP_TABLE	CONSTANT TEXT := $$DROP TABLE IF EXISTS %I CASCADE$$;
BEGIN
	SELECT provider, resource INTO rec FROM catalogue WHERE LOWER(provider) = LOWER(strProvider) AND LOWER(resource) = LOWER(strResource);

	DELETE FROM catalogue WHERE provider = rec.provider AND resource = rec.resource;
	DELETE FROM website.resource_years WHERE resource = rec.resource;
	DELETE FROM website.resource_nuts_levels WHERE resource = rec.resource;
	DELETE FROM website.resource_year_nuts_levels WHERE resource = rec.resource;
	DELETE FROM website.catalogue_field_description WHERE provider = rec.provider AND resource = rec.resource;
	DELETE FROM website.catalogue_field_value_description WHERE provider = rec.provider AND resource = rec.resource;
	EXECUTE FORMAT(DROP_TABLE, rec.resource);
END;
$BODY$ LANGUAGE PLPGSQL;

DROP PROCEDURE IF EXISTS website.set_table_status(TEXT, TEXT, BOOLEAN);

CREATE OR REPLACE PROCEDURE website.set_table_status(strProvider TEXT, strResource TEXT, bStatus BOOLEAN)
AS
$BODY$
DECLARE 
	UPDATE_STATUS CONSTANT TEXT := $$UPDATE catalogue SET use = %L WHERE provider ILIKE %L AND resource ILIKE %L$$;
BEGIN
	-- RAISE INFO '%', FORMAT (UPDATE_STATUS, bStatus, strProvider, strResource);
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


