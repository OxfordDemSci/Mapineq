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



