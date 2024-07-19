DROP TABLE IF EXISTS website.catalogue_field_description;
CREATE TABLE website.catalogue_field_description
(
	provider	TEXT,
	resource	TEXT,
	field		TEXT,
	label		TEXT
);

DROP TABLE IF EXISTS  website.catalogue_field_value_description;
CREATE TABLE website.catalogue_field_value_description
(
	provider	TEXT,
	resource	TEXT,
	field		TEXT,
	value		TEXT,
	label		TEXT
);

DROP PROCEDURE IF EXISTS website.oecd_fill_catalogue_field_value_description();
DROP PROCEDURE IF EXISTS website.oecd_fill_catalogue_field_value_description(TEXT);
CREATE OR REPLACE PROCEDURE website.oecd_fill_catalogue_field_value_description(strResource TEXT DEFAULT NULL)
AS
$BODY$
DECLARE
	rec	RECORD;
	QUERY	CONSTANT TEXT := $$
		INSERT INTO website.catalogue_field_value_description
		SELECT DISTINCT
			'OECD',
			'%1$s',
			'%2$s',
			"%2$s",
			"%2$s_DESC.EN"
		FROM
			"%1$s"
		$$;
BEGIN
	DELETE FROM website.catalogue_field_value_description WHERE provider = 'OECD' AND (resource = strResource OR strResource IS NULL);
	FOR rec IN 
	SELECT DISTINCT 
		resource ,
		column_name
	FROM
		information_schema.columns
		INNER JOIN website.vw_data_tables
			ON table_name = query_resource
	WHERE
		provider = 'OECD'
		AND (resource = strResource OR strResource IS NULL)
		AND LOWER(column_name ) NOT IN ('obstime','obsvalue','geo', 'time_format','tl', 'territorial_level','country', 'territorial_type' )
	ORDER BY 1,2
	LOOP
		BEGIN
			-- RAISE INFO '%', FORMAT(QUERY,rec.table_name, rec.column_name);
			EXECUTE FORMAT(QUERY,rec.resource, rec.column_name);
		EXCEPTION
			WHEN OTHERS THEN
				RAISE INFO 'Error: % with: % %, Query: %',SQLERRM, rec.resource, rec.column_name, FORMAT(QUERY,rec.resource, rec.column_name);
		END;
	END LOOP;
END;
$BODY$ LANGUAGE PLPGSQL;

DROP PROCEDURE IF EXISTS website.fill_catalogue_field_value_description(TEXT);
CREATE OR REPLACE PROCEDURE website.fill_catalogue_field_value_description(strResource TEXT)
AS
$BODY$
DECLARE
	rec	RECORD;
	QUERY	CONSTANT TEXT := $$
		INSERT INTO website.catalogue_field_value_description
		SELECT DISTINCT
			%1$L,
			%2$L,
			%3$L,
			%3$I,
			%3$I
		FROM
			"%2$s"
		$$;
BEGIN
	DELETE FROM website.catalogue_field_value_description WHERE provider NOT IN ('OECD', 'ESTAT') AND (resource = strResource OR strResource IS NULL);
	FOR rec IN 
	SELECT DISTINCT
		provider,
		resource,
		column_name::TEXT
	FROM
		information_schema.columns c
		INNER JOIN website.vw_data_tables t
			ON table_name = query_resource
	WHERE
		provider NOT IN ('OECD', 'ESTAT')
		AND (resource = strResource OR strResource IS NULL)
		AND LOWER(column_name) NOT IN ('obstime','obsvalue','geo')
	ORDER BY 1, 2, 3
	LOOP
		BEGIN
			--RAISE INFO '%', FORMAT(QUERY,rec.provider, rec.resource, rec.column_name);
			EXECUTE FORMAT(QUERY,rec.provider, rec.resource, rec.column_name);
		EXCEPTION
			WHEN OTHERS THEN
				RAISE INFO 'Error: % with: % %, Query: %',SQLERRM, rec.resource, rec.column_name, FORMAT(QUERY,rec.resource, rec.column_name);
		END;
	END LOOP;
END;
$BODY$ LANGUAGE PLPGSQL;

DROP PROCEDURE IF EXISTS website.fill_catalogue_field_description(TEXT);
DROP PROCEDURE IF EXISTS website.fill_catalogue_field_description(TEXT, TEXT);
CREATE OR REPLACE PROCEDURE website.fill_catalogue_field_description(strResource TEXT DEFAULT NULL, strProvider TEXT DEFAULT NULL)
AS
$BODY$
DECLARE
	rec		RECORD;
	QUERY	CONSTANT TEXT := $$INSERT INTO website.catalogue_field_description VALUES (%L,%L,%L,%L)$$;
BEGIN
	DELETE FROM website.catalogue_field_description WHERE provider != 'ESTAT' AND (provider = strProvider OR strProvider IS NULL) AND  (resource = strResource OR strResource IS NULL);
	FOR rec IN
	SELECT
		provider,
		resource,
		column_name::TEXT,
		LOWER(column_name::TEXT) as label
	FROM
		information_schema.columns c
		INNER JOIN website.vw_data_tables t
			ON table_name = query_resource
	WHERE
		provider != 'ESTAT'
		AND (resource = strResource OR strResource IS NULL)
		AND (provider = strProvider OR strProvider IS NULL)
		AND LOWER(column_name) NOT IN ('obstime','obsvalue','geo', 'time_format', 'tl', 'territorial_level','country', 'territorial_type' )
	LOOP
		EXECUTE FORMAT (QUERY, rec.provider, rec.resource, rec.column_name, rec.label);
	END LOOP;
END;
$BODY$
LANGUAGE PLPGSQL;



-- CALL website.fill_catalogue_field_value_description();

DROP PROCEDURE IF EXISTS website.estat_import_dictinary(TEXT);
CREATE OR REPLACE PROCEDURE website.estat_import_dictinary(strDict TEXT)
AS
$BODY$
DECLARE
	field_description			TEXT;
	DELETE_FIELD_DESCRIPTION	CONSTANT TEXT := $$DELETE FROM website.catalogue_field_description WHERE provider = 'ESTAT' AND field = %L $$;
	INSERT_FIELD_DESCRIPTION	CONSTANT TEXT := $$INSERT INTO website.catalogue_field_description VALUES ('ESTAT', NULL, %L, %L) $$;
	DELETE_FIELD_VALUE			CONSTANT TEXT := $$DELETE FROM website.catalogue_field_value_description WHERE provider = 'ESTAT' AND field = %L $$;
	INSERT_FIELD_VALUE			CONSTANT TEXT := $$INSERT INTO website.catalogue_field_value_description 
													SELECT
														'ESTAT',
														NULL,
														%L,
														j ->> 'Notation',
														j ->> 'Label'
													FROM
														(SELECT jsonb_array_elements(jj::JSONB -> 'concepts') AS j FROM tmpJSON) as foo;$$;
	
	URL							CONSTANT TEXT := $$curl "https://dd.eionet.europa.eu/vocabulary/eurostat/%s/json"  $$;
	COPY_OPTIONS				CONSTANT TEXT := $$ WITH csv  DELIMITER E'\007' ESCAPE  E'\'' QUOTE  E'\'' $$;
BEGIN
	SET client_min_messages TO 'warning';
	CREATE TEMPORARY TABLE IF NOT EXISTS tmpDictionary(id SERIAL, result_json TEXT);
	TRUNCATE TABLE tmpDictionary;
	
	EXECUTE 'copy tmpDictionary(result_json) from program ' || QUOTE_LITERAL(FORMAT(URL, strDict)) || COPY_OPTIONS;
	CREATE TEMPORARY TABLE IF NOT EXISTS tmpJSON (jj JSONB);
	TRUNCATE TABLE tmpJSON;
	INSERT INTO tmpJSON 
	SELECT 
		(string_agg(result_json,''))::JSONB jj 
	FROM 
		tmpDictionary ;

	EXECUTE FORMAT(DELETE_FIELD_DESCRIPTION, strDict);

	SELECT
		TRIM(both '"' from (jj -> '@context' -> 'Label')::TEXT)
	INTO
		field_description
	FROM
		tmpJSON;
	EXECUTE FORMAT (INSERT_FIELD_DESCRIPTION,strDict, field_description) ;
	
	EXECUTE FORMAT(DELETE_FIELD_VALUE, strDict);
	
	EXECUTE FORMAT (INSERT_FIELD_VALUE,strDict);
	
END;
$BODY$
LANGUAGE PLPGSQL;

DROP PROCEDURE IF EXISTS website.estat_fill_field_description (TEXT);
CREATE OR REPLACE PROCEDURE website.estat_fill_field_description (strResource TEXT DEFAULT NULL) 
AS
$BODY$
DECLARE
	rec			RECORD;	
	aantal		INTEGER;
	i			INTEGER := 0;
	QUERY		CONSTANT TEXT := $$CALL  website.estat_import_dictinary(%L)$$;
	
BEGIN	
	FOR rec IN 
		SELECT 
			COALESCE(column_name, '__')	AS column_name,
			COUNT(DISTINCT column_name)	AS aantal
		FROM 
			website.vw_data_tables
			INNER JOIN information_schema.columns
				ON query_resource = table_name
		WHERE 
			provider = 'ESTAT' 
			AND LOWER(column_name) NOT IN ('obstime','obsvalue','obs_flag','geo','metroreg')
			AND (resource = strResource OR strResource IS NULL)
		GROUP BY
			CUBE(column_name)
		ORDER BY
			column_name
	LOOP
		IF rec.column_name = '__' THEN
			aantal = rec.aantal;
		END IF;
		CONTINUE WHEN rec.column_name = '__';
		i := i + 1;
		RAISE INFO 'Busy: % (% from %)',rec.column_name, i, aantal;
		IF (SELECT EXISTS (SELECT 1 FROM website.catalogue_field_description WHERE field = rec.column_name)) = FALSE OR
			(SELECT EXISTS (SELECT 1 FROM website.catalogue_field_value_description WHERE field = rec.column_name)) = FALSE THEN 
			EXECUTE FORMAT(QUERY, rec.column_name);
		END IF;
	END LOOP;
	DROP TABLE IF EXISTS tmpDictionary;
	DROP TABLE IF EXISTS tmpJSON;
END;
$BODY$ LANGUAGE PLPGSQL;


-- call website.fill_eurostat_field_description ();

DROP PROCEDURE IF EXISTS website.import_field_description(BOOLEAN, BOOLEAN, BOOLEAN);
CREATE OR REPLACE PROCEDURE website.import_field_description(bEstat BOOLEAN DEFAULT FALSE, bOECD BOOLEAN DEFAULT FALSE, bOXFORD BOOLEAN DEFAULT FALSE)
AS
$BODY$
BEGIN
	IF bESTAT THEN
		CALL website.estat_fill_field_description ();
	END IF;
	IF bOECD THEN
		CALL website.oecd_fill_catalogue_field_value_description();
		CALL website.fill_catalogue_field_description(strProvider := 'OECD');
	END IF;
	IF bOxford THEN
		CALL website.fill_catalogue_field_value_description(); 
		CALL website.fill_catalogue_field_description(strProvider := 'OXFORD');
	END IF;
END;
$BODY$ LANGUAGE PLPGSQL;

--CALL website.import_field_description(TRUE, TRUE, TRUE);