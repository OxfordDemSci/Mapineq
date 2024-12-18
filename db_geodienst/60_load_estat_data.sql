DROP PROCEDURE IF EXISTS get_estat_catalogue_info(TEXT, TEXT);
CREATE OR REPLACE PROCEDURE get_estat_catalogue_info(strTable TEXT, strUrl TEXT)
AS
$BODY$
DECLARE
	rec	RECORD;

	JSON_URL		CONSTANT TEXT := $$curl "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/dataflow/ESTAT/all?detail=allstubs&format=JSON"$$;
	CAT_DELETE		CONSTANT TEXT := $$DELETE FROM catalogue WHERE provider = %L AND resource = %L $$;
	CAT_INSERT		CONSTANT TEXT := $$INSERT INTO catalogue (provider, resource, descr, version, url, use, short_descr, query_resource,meta_data_url, web_source_url) VALUES(%L,%L,%L,%L,%L,TRUE,%L, %L, %L, %L) $$;
	WEB_SOURCE_URL	CONSTANT TEXT := $$https://doi.org/10.2908/%s$$;
	META_DATA_URL	CONSTANT TEXT := $$https://doi.org/10.2908/%s$$;
BEGIN
	SET client_min_messages TO 'warning';
	CREATE TEMPORARY TABLE IF NOT EXISTS tmpDictionary(id SERIAL, result_json TEXT);
	TRUNCATE TABLE tmpDictionary;
	
	EXECUTE 'copy tmpDictionary(result_json) from program ' || QUOTE_LITERAL(JSON_URL);
	WITH cte AS
	(
		select 
			jsonb_array_elements(result_json::JSONB -> 'link' -> 'item') jj
		from 
			tmpDictionary
	)
	SELECT
		jj -> 'extension' ->> 'agencyId'	AS provider,
		jj -> 'extension' ->> 'id'			AS resource,
		jj ->> 'label'						AS descr,
		(jj -> 'extension' ->> 'version')::NUMERIC::INTEGER	AS version
	INTO
		rec
	FROM
		cte
	WHERE
		jj -> 'extension' ->> 'id'	= strTable;

	IF rec.resource IS NOT NULL THEN
		EXECUTE FORMAT(CAT_DELETE, rec.provider, rec.resource);
		EXECUTE FORMAT(CAT_INSERT, rec.provider, rec.resource, rec.descr,rec.version,strUrl, LEFT(rec.descr,20),rec.resource, FORMAT(WEB_SOURCE_URL,rec.resource), FORMAT(META_DATA_URL,rec.resource));
	END IF;
	
END;
$BODY$
LANGUAGE PLPGSQL;



DROP FUNCTION IF EXISTS load_estat_data(TEXT);
CREATE OR REPLACE FUNCTION load_estat_data(strTable TEXT)
RETURNS TEXT
AS
$BODY$
DECLARE
    rec                 RECORD;
    strHeaderRow        TEXT;

	frequence			TEXT;
	
    strColumnName       TEXT;
	i					INTEGER := 0;
	arrCols				TEXT[]; 
    arrColType			TEXT[] := ARRAY['INT','NUMERIC','TIMESTAMP','TEXT'];
    colType				TEXT;

	arrDropColumn		TEXT[] := ARRAY['dataflow', 'last_update'];
	dropColumn			TEXT;
	
	URL					CONSTANT TEXT := $$https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/%s?format=SDMX-CSV$$;

	CHARDELIMITER		CONSTANT TEXT := ',';
	TABLE_SCHEMA		CONSTANT TEXT := 'public';
	DROP_TABLE 			CONSTANT TEXT := $$DROP TABLE IF EXISTS %I.%I CASCADE$$;
	CREATE_TABLE		CONSTANT TEXT := $$CREATE UNLOGGED TABLE %I.%I () $$;
	ADD_COLUMN			CONSTANT TEXT := $$ALTER TABLE %I.%I ADD COLUMN %I TEXT $$;
	COL					CONSTANT TEXT := $$(STRING_TO_ARRAY(content, ',', ''))[%s]$$;
	INSERT_DATA			CONSTANT TEXT := $$INSERT INTO %I.%I SELECT %s FROM tmpHeaderRow OFFSET 1 $$;
	
	DROP_COLUMN			CONSTANT TEXT := $$ALTER TABLE %I.%I DROP COLUMN IF EXISTS %I $$;
	GET_COLTYPE			CONSTANT TEXT := $$SELECT %I::%s FROM %I.%I $$;
	ALTER_COLTYPE		CONSTANT TEXT := $$ALTER TABLE %I.%I ALTER COLUMN %I TYPE %s USING %I::%s $$;
	QUERY_FREQ			CONSTANT TEXT := $$SELECT DISTINCT freq FROM %I$$;
BEGIN
	SET client_min_messages TO ERROR;
    
    DROP TABLE IF EXISTS tmpHeaderRow;
    
    CREATE TEMPORARY TABLE tmpHeaderRow (content text);
    
    EXECUTE 'COPY tmpHeaderRow FROM PROGRAM ' || QUOTE_LITERAL('curl ' || FORMAT(URL,strTable)) ;
	RAISE INFO '% - data file imported', clock_timestamp();
	
	IF (SELECT COUNT(*) FROM tmpHeaderRow) < 2 THEN
		RETURN 'Table Creation failed';
	END IF;
    
    SELECT content INTO strHeaderRow FROM tmpHeaderRow LIMIT 1 ;
	
    EXECUTE FORMAT(DROP_TABLE,TABLE_SCHEMA,strTable);  

	EXECUTE FORMAT(CREATE_TABLE, TABLE_SCHEMA, strTable);

	DROP TABLE IF EXISTS tmpColumn;
	
	CREATE TEMPORARY TABLE tmpColumn (id SERIAL, col_name TEXT, col_type TEXT);
	
    FOR rec IN SELECT * FROM REGEXP_SPLIT_TO_TABLE(strHeaderRow, CHARDELIMITER) AS columnName
    LOOP
        strColumnName := LOWER(REPLACE(rec.columnName, ' ', '_'));
		
		IF strColumnName = 'time_period' THEN
			strColumnName := 'obsTime';
		END IF;

		IF strColumnName = 'obs_value' THEN
			strColumnName := 'obsValue';
		END IF;
		
		IF strColumnName NOT IN ('dataflow', 'last_update') THEN
			INSERT INTO tmpColumn (col_name) VALUES (strColumnName);
		END IF;

		EXECUTE FORMAT(ADD_COLUMN, TABLE_SCHEMA, strTable, strColumnName);
		i := i + 1;
		arrCols := ARRAY_APPEND(arrCols, FORMAT(COL,i) );		
    END LOOP;
	
	
	EXECUTE FORMAT (INSERT_DATA,TABLE_SCHEMA, strTable, array_to_string(arrCols,CHARDELIMITER));
	
	FOREACH dropColumn IN ARRAY arrDropColumn
	LOOP
		EXECUTE FORMAT(DROP_COLUMN,TABLE_SCHEMA, strTable, dropColumn);
	END LOOP;
	
	FOREACH colType IN ARRAY arrColType
	LOOP
		FOR rec IN SELECT * FROM tmpColumn WHERE col_type IS NULL
		LOOP
			BEGIN
				EXECUTE FORMAT(GET_COLTYPE,rec.col_name, colType, TABLE_SCHEMA, strTable);
				UPDATE tmpColumn
				SET
					col_type = colType
				WHERE
					id = rec.id;
			EXCEPTION
				WHEN OTHERS THEN
					NULL;
			END;
		END LOOP;
	END LOOP;
	
	FOR rec IN SELECT * from tmpColumn ORDER BY id
	LOOP
		EXECUTE FORMAT (ALTER_COLTYPE, TABLE_SCHEMA, strTable, rec.col_name, rec.col_type,rec.col_name, rec.col_type);
	END LOOP;
	CALL get_estat_catalogue_info(strTable, FORMAT(URL, strTable));
	
	EXECUTE FORMAT (QUERY_FREQ, strTable) INTO frequence;
	IF LOWER(frequence) IN ('q','s','m','w') THEN
		CALL create_estat_views(strTable);
	END IF;
	RETURN 'Table created';
END;
$BODY$
LANGUAGE plpgsql;


DROP PROCEDURE IF EXISTS website.import_estat_data(TEXT);
CREATE OR REPLACE PROCEDURE website.import_estat_data(strTable TEXT)
AS
$BODY$
DECLARE
	strResult TEXT;
BEGIN
	strTable := UPPER(strTable);
	SELECT * INTO strResult FROM load_estat_data(strTable) ;
	RAISE INFO '%', strResult;
	CALL website.estat_fill_field_description(strTable);
	CALL website.fill_resource_years(strTable);
	CALL website.fill_resource_nuts_levels(strTable);
	CALL website.fill_resource_year_nuts_levels(strTable);
END;
$BODY$
LANGUAGE PLPGSQL;


 