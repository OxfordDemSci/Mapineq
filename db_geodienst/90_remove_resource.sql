DROP PROCEDURE IF EXISTS website.remove_resource(TEXT, TEXT);

CREATE OR REPLACE PROCEDURE website.remove_resource(strProvider TEXT, strResource TEXT)
AS
$BODY$
DECLARE
	DROP_TABLE	CONSTANT TEXT := $$DROP TABLE IF EXISTS %I CASCADE$$;
BEGIN
	DELETE FROM catalogue WHERE provider = strProvider AND resource = strResource;
	DELETE FROM website.resource_years WHERE resource = strResource;
	DELETE FROM website.resource_nuts_levels WHERE resource = strResource;
	DELETE FROM website.resource_year_nuts_levels WHERE resource = strResource;
	DELETE FROM website.catalogue_field_description WHERE provider = strProvider AND resource = strResource;
	DELETE FROM website.catalogue_field_value_description WHERE provider = strProvider AND resource = strResource;
	EXECUTE FORMAT(DROP_TABLE, strResource);
END;
$BODY$ LANGUAGE PLPGSQL;