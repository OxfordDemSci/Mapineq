DROP TABLE IF  EXISTS website.catalogue_tag;

CREATE TABLE IF NOT EXISTS website.catalogue_tag
(
	id			SERIAL,
	descr 		TEXT NOT NULL
);

CREATE UNIQUE INDEX catalogue_tag_descr_unique
    ON website.catalogue_tag 
	USING btree ((LOWER(descr)));

DROP TABLE IF EXISTS website.resource_tag	;

CREATE TABLE IF NOT EXISTS website.resource_tag
(
	resource	TEXT,
	tag_id		INTEGER,
	CONSTRAINT 	pk_resource_tag PRIMARY KEY (resource, tag_id)
);

DROP FUNCTION IF EXISTS website.add_tag(TEXT);

CREATE OR REPLACE FUNCTION website.add_tag(strTag TEXT)
RETURNS TEXT
AS
$BODY$
BEGIN
	INSERT INTO website.catalogue_tag(descr) VALUES (strTag);
	RETURN FORMAT ('Tag %s added', strTag);
	EXCEPTION
		WHEN SQLSTATE '23505' THEN
			RETURN FORMAT('Tag %s already exists', strTag);
		WHEN OTHERS THEN
			RETURN FORMAT('Something went wrong, tag %s is not added', strTag);
END;
$BODY$
LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS website.add_resource_tag(TEXT, TEXT);
CREATE OR REPLACE FUNCTION website.add_resource_tag(strTag TEXT,strResource TEXT)
RETURNS TEXT
AS
$BODY$
DECLARE
	intTagId		INTEGER;
	strDataResource	TEXT;
	
BEGIN
	SELECT
		id
	INTO
		intTagId
	FROM
		website.catalogue_tag
	WHERE
		descr ILIKE strTag;
		
	IF intTagId IS NULL
	THEN
		RETURN FORMAT('Tag %s does not exist', strTag);
	END IF;

	SELECT 
		resource
	INTO
		strDataResource
	FROM 
		website.vw_data_tables
	WHERE 
		resource ILIKE strResource;
	
	IF strDataResource IS NULL 
	THEN
		RETURN FORMAT('Resource %s does not exist', strResource);
	END IF;
	BEGIN
		INSERT INTO website.resource_tag VALUES (strDataResource, intTagId);
		RETURN FORMAT('Tag %s is added to resource %s', strTag, strResource);	
	EXCEPTION
		WHEN SQLSTATE '23505' THEN
			RETURN FORMAT('Tag %s already exists for resource %s', strTag, strDataResource);
		WHEN OTHERS THEN
			RETURN FORMAT('Something went wrong, tag %s is not added to resource %s', strTag, strResource);		
	END;
	
END;
$BODY$
LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS website.get_resources_by_tag(TEXT, BOOLEAN);

CREATE OR REPLACE FUNCTION website.get_resources_by_tag(strTag TEXT, bMatchAll BOOLEAN DEFAULT TRUE)
RETURNS TEXT[] 
AS
$BODY$
DECLARE
	retArray	TEXT[];
	QUERY		CONSTANT TEXT := $$
		WITH cte AS
			(SELECT 
				DISTINCT resource 
			 FROM  
				website.resource_tag rt
				INNER JOIN website.catalogue_tag ct
					ON ct.id = tag_id
			 WHERE 
			 	ct.descr = ANY (STRING_TO_ARRAY(%1$L,',')) 
			 GROUP BY 
			 	resource 
			 HAVING 
			 	COUNT(*) = ARRAY_LENGTH(STRING_TO_ARRAY(%1$L,','),1)
				 OR %2$s = 0)
				 
		SELECT
			ARRAY_AGG(resource) 
		FROM	
			cte $$;
BEGIN
	
	EXECUTE FORMAT (QUERY, strTag, bMatchAll::INTEGER) INTO retArray;
	IF retArray IS NULL THEN
		retArray := ARRAY[]::text[];
	END IF;
	RETURN retArray;
END;
$BODY$
LANGUAGE PLPGSQL;
