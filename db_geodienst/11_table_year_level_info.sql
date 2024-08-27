
CREATE TABLE IF NOT EXISTS website.resource_years
(
    resource 	TEXT,
    year 		TEXT
);

CREATE TABLE IF NOT EXISTS website.resource_nuts_levels
(
	resource	TEXT,
	level		INTEGER
);

CREATE TABLE IF NOT EXISTS website.resource_year_nuts_levels
(
	resource	TEXT,
	level		INTEGER,
	year		TEXT
);

DROP PROCEDURE IF EXISTS website.fill_resource_years(TEXT);
CREATE OR REPLACE PROCEDURE website.fill_resource_years(strTable TEXT DEFAULT NULL)
AS
$BODY$
DECLARE
	rec	 			RECORD;
	DELETE_QUERY	CONSTANT TEXT := $$DELETE FROM website.resource_years WHERE resource = %L $$;
	INSERT_QUERY	CONSTANT TEXT := $$INSERT INTO website.resource_years SELECT DISTINCT %L,  t."obsTime"::TEXT FROM %I as t $$;
BEGIN
	IF strTable IS NULL THEN
		TRUNCATE TABLE website.resource_years;
	ELSE
		EXECUTE FORMAT(DELETE_QUERY, strTable);
	END IF;
	FOR rec IN
	SELECT 
		*
	FROM 
		website.vw_data_tables 
	WHERE
		resource = strTable 
		OR strTable IS NULL
	LOOP
		EXECUTE FORMAT(INSERT_QUERY, rec.resource, rec.query_resource);
	END LOOP;
	
END;
$BODY$
LANGUAGE PLPGSQL;

DROP PROCEDURE IF EXISTS website.fill_resource_nuts_levels(TEXT);
CREATE OR REPLACE PROCEDURE website.fill_resource_nuts_levels(strTable TEXT DEFAULT NULL)
AS
$BODY$
DECLARE
	rec	 			RECORD;
	DELETE_QUERY	CONSTANT TEXT := $$DELETE FROM website.resource_nuts_levels WHERE resource = %L $$;
	QUERY_NUTS		CONSTANT TEXT := $$INSERT INTO website.resource_nuts_levels SELECT DISTINCT %L, levl_code FROM %I as t INNER JOIN areas.nuts_2021 ON t.geo  = nuts_id $$;
	QUERY_GADM 		CONSTANT TEXT := $$INSERT INTO website.resource_nuts_levels SELECT DISTINCT %L, 0 FROM %I AS t INNER JOIN areas.nuts_gadm ON t.geo = gadm_code $$;
BEGIN
	IF strTable IS NULL THEN
		TRUNCATE TABLE website.resource_nuts_levels;
	ELSE
		EXECUTE FORMAT(DELETE_QUERY, strTable);
		RAISE INFO '%', FORMAT(DELETE_QUERY, strTable);
	END IF;
	FOR rec IN
		SELECT 
			*
		FROM 
			website.vw_data_tables
		WHERE
			resource = strTable
			OR strTable IS NULL
	LOOP
		IF rec.provider = 'OECD' THEN
			EXECUTE FORMAT(QUERY_GADM, rec.resource, rec.query_resource);
		END IF;
		EXECUTE FORMAT(QUERY_NUTS, rec.resource, rec.query_resource);
	END LOOP;
	
END;
$BODY$
LANGUAGE PLPGSQL;

DROP PROCEDURE IF EXISTS website.fill_resource_year_nuts_levels(TEXT);
CREATE OR REPLACE PROCEDURE website.fill_resource_year_nuts_levels(strTable TEXT DEFAULT NULL)
AS
$BODY$
DECLARE
	rec	record;
	DELETE_QUERY	CONSTANT TEXT := $$DELETE FROM website.resource_year_nuts_levels WHERE resource = %L $$;
	QUERY_NUTS		CONSTANT TEXT := $$INSERT INTO website.resource_year_nuts_levels SELECT DISTINCT 
		%L,  
		levl_code,
		t."obsTime"::TEXT
	FROM 
		%I as t
		INNER JOIN areas.nuts_2021 
			ON t.geo  = nuts_id  $$;
	QUERY_GADM 	CONSTANT TEXT := $$INSERT INTO website.resource_year_nuts_levels SELECT DISTINCT %L, 0, t."obsTime"::TEXT FROM %I AS t INNER JOIN areas.nuts_gadm ON t.geo = gadm_code$$;
BEGIN
	IF strTable IS NULL THEN
		TRUNCATE TABLE website.resource_year_nuts_levels;
	ELSE
		EXECUTE FORMAT(DELETE_QUERY, strTable);
	END IF;
	FOR rec IN
		SELECT 
			*
		FROM 
			website.vw_data_tables	
		WHERE
			resource = strTable
			OR strTable IS NULL
	LOOP
		IF rec.provider = 'OECD' THEN
			EXECUTE FORMAT(QUERY_GADM, rec.resource, rec.query_resource);
		END IF;
		EXECUTE FORMAT(QUERY_NUTS, rec.resource, rec.query_resource);
	END LOOP;
	
END;
$BODY$
LANGUAGE PLPGSQL;


