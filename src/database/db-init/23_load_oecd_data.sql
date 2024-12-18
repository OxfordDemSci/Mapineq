-- DROP PROCEDURE IF EXISTS load_oecd_data(TEXT, TEXT. TEXT, TEXT);

CREATE OR REPLACE PROCEDURE load_oecd_data(strAgencyIndentifier TEXT, strDataFlowIndentifier TEXT, strDescription TEXT,  strShortDescription TEXT)
AS
$BODY$
DECLARE
	rec					RECORD;
	i					INTEGER := 0;
	bBoth				BOOLEAN;
	arrIndexColumns		INTEGER[];
	arrBothColumns		BOOLEAN[];
	
	arrColumns			TEXT[];
	strColumn			TEXT;
	strColumnName		TEXT;
	
	strResource			TEXT;
	URL					CONSTANT TEXT := $$https://sdmx.oecd.org/public/rest/v2/data/dataflow/%s/%s/1.0/?$$;
	CURL				CONSTANT TEXT := $$curl -H "Accept: application/vnd.sdmx.data+csv; version=2; labels=both" "%s"$$;
	arrInsertValues		TEXT[];

	CHARDELIMITER		CONSTANT TEXT := ',';
	TABLE_SCHEMA		CONSTANT TEXT := 'public';
	READ_CSV			CONSTANT TEXT := $$COPY %I.%I FROM PROGRAM ' curl %s' WITH DELIMITER %L CSV HEADER $$;
	DROP_TABLE 			CONSTANT TEXT := $$DROP TABLE IF EXISTS %I.%I CASCADE$$;
	CREATE_TABLE		CONSTANT TEXT := $$CREATE TABLE %I.%I () $$;
	ADD_COLUMN			CONSTANT TEXT := $$ALTER TABLE %I.%I ADD COLUMN %I TEXT $$;
	
	GET_COLTYPE			CONSTANT TEXT := $$SELECT %I::%s FROM %I.%I $$;
	ALTER_COLTYPE		CONSTANT TEXT := $$ALTER TABLE %I.%I ALTER COLUMN %I TYPE %s USING %I::%s $$;
	INSERT_QUERY		CONSTANT TEXT := $$INSERT INTO %I.%I VALUES (%s)$$;
	DELETE_CATALOGUE	CONSTANT TEXT := $$DELETE FROM catalogue WHERE provider = 'OECD' AND resource = %L$$;
	INSERT_CATALOGUE	CONSTANT TEXT := $$INSERT INTO public.catalogue(provider, resource, descr, url, use, short_descr) VALUES ('OECD', %L, %L, %L, TRUE, %L) $$;
	
BEGIN
    SET client_min_messages TO ERROR;
    
    DROP TABLE IF EXISTS tmpCSV;
    CREATE TEMPORARY TABLE tmpCSV (content text);

	strResource := SPLIT_PART(strDataFlowIndentifier,'@',2);
   
    EXECUTE 'COPY tmpCSV FROM PROGRAM ' || QUOTE_LITERAL(FORMAT(CURL,FORMAT(URL,strAgencyIndentifier, strDataFlowIndentifier))) ;
	
	EXECUTE FORMAT(DROP_TABLE, TABLE_SCHEMA, strResource );
	EXECUTE FORMAT(CREATE_TABLE,TABLE_SCHEMA,  strResource );
	
	SELECT (STRING_TO_ARRAY(content, ',')) INTO arrColumns FROM tmpCSV LIMIT 1 ;
	
	FOREACH strColumn IN ARRAY arrColumns
    LOOP
		i :=  i + 1;
		bBoth := FALSE;
        strColumn := LOWER(REPLACE(strColumn, ' ', '_'));
		strColumnName := 
		CASE 
			WHEN
		 		SPLIT_PART(strColumn,':',1) = 'ref_area' THEN 'geo'
			WHEN
		 		SPLIT_PART(strColumn,':',1) = 'time_period' THEN 'obsTime'		
			WHEN
		 		SPLIT_PART(strColumn,':',1) = 'obs_value' THEN 'obsValue'
			ELSE
				SPLIT_PART(strColumn,':',1)
		END;
		IF STRPOS(strColumn, ':') > 0 OR (strColumnName IN ('obsValue', 'obs_value')) THEN
			EXECUTE FORMAT(ADD_COLUMN,TABLE_SCHEMA, strResource, strColumnName );
			IF LOWER(strColumnName) NOT IN ('geo', 'obstime', 'obsvalue') AND LOWER(strColumnName) NOT LIKE '%obs_status%' THEN
				EXECUTE FORMAT(ADD_COLUMN,TABLE_SCHEMA, strResource,  strColumnName || '_DESC.EN' );
				bBoth := TRUE;
			END IF;
			arrIndexColumns := ARRAY_APPEND(arrIndexColumns,i); 
			arrBothColumns := ARRAY_APPEND(arrBothColumns,bBoth); 
		END IF;	
	END LOOP;
	UPDATE tmpCSV
	SET content = regexp_replace(content, '"([^"]*),([^"]*)"', '"\1\2"', 'g')
	WHERE content ~ '"[^"]*,[^"]*"';
	FOR rec in SELECT (STRING_TO_ARRAY(content, ',')) AS arrContent FROM tmpCSV   OFFSET 1
	LOOP
		arrInsertValues := NULL;
		FOR i IN ARRAY_LOWER(arrIndexColumns,1)..ARRAY_UPPER(arrIndexColumns,1)
		LOOP
			arrInsertValues := ARRAY_APPEND(arrInsertValues, QUOTE_LITERAL(TRIM(SPLIT_PART(rec.arrContent[arrIndexColumns[i]],':',1)) ));
			IF arrBothColumns[i] THEN
				arrInsertValues := ARRAY_APPEND(arrInsertValues, QUOTE_LITERAL(TRIM(SPLIT_PART(rec.arrContent[arrIndexColumns[i]],':',2))) );
			END IF;
		END LOOP;
		EXECUTE FORMAT(INSERT_QUERY,TABLE_SCHEMA, strResource, REPLACE(ARRAY_TO_STRING(arrInsertValues, ','), '"', ''));
	END LOOP;

	BEGIN
		EXECUTE FORMAT (ALTER_COLTYPE, TABLE_SCHEMA, strResource,'obsValue', 'numeric','obsValue', 'numeric');
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
	END;
	
	EXECUTE FORMAT(DELETE_CATALOGUE, strResource);
	EXECUTE FORMAT(INSERT_CATALOGUE, strResource, strDescription, FORMAT(URL,strAgencyIndentifier, strDataFlowIndentifier), strShortDescription);
END;
$BODY$
LANGUAGE PLPGSQL;

DROP PROCEDURE IF EXISTS website.import_oecd_data(TEXT, TEXT, TEXT, TEXT);
CREATE OR REPLACE PROCEDURE website.import_oecd_data(strAgencyIndentifier TEXT, strDataFlowIndentifier TEXT, strDescription TEXT,  strShortDescription TEXT)
AS
$BODY$
DECLARE
	strResource	TEXT; 
BEGIN
	strResource := SPLIT_PART(strDataFlowIndentifier,'@',2);
	CALL load_oecd_data (strAgencyIndentifier, strDataFlowIndentifier, strDescription,  strShortDescription);
	CALL create_oecd_views(strResource);
	CALL website.oecd_fill_catalogue_field_value_description(strResource);
	CALL website.fill_catalogue_field_description(strResource);
	CALL website.fill_resource_years(strResource);
	CALL website.fill_resource_nuts_levels(strResource);
	CALL website.fill_resource_year_nuts_levels(strResource);
END;
$BODY$
LANGUAGE PLPGSQL;


