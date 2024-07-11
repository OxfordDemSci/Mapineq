-- DROP PROCEDURE IF EXISTS load_oecd_data(TEXT, TEXT);

CREATE OR REPLACE PROCEDURE load_oecd_data(strAgencyIndentifier TEXT, strDataFlowIndentifier TEXT)
AS
$BODY$
DECLARE
	rec					RECORD;
	strHeaderRow		TEXT;
	strColumnName		TEXT;
	strColumnNameDesc	TEXT;
	strTableName		TEXT;
	URL					CONSTANT TEXT := $$"https://sdmx.oecd.org/public/rest/data/%s,%s,1.0/all?dimensionAtObservation=AllDimensions&format=csvfilewithlabels&lastNObservations=2"  $$;
	

	CHARDELIMITER		CONSTANT TEXT := ',';
	TABLE_SCHEMA		CONSTANT TEXT := 'public';
	TABLE_SCHEMA		CONSTANT TEXT := 'public';
	READ_CSV			CONSTANT TEXT := $$COPY %I.%I FROM PROGRAM ' curl %s' WITH DELIMITER %L CSV HEADER $$;
	DROP_TABLE 			CONSTANT TEXT := $$DROP TABLE IF EXISTS %I.%I $$;
	CREATE_TABLE		CONSTANT TEXT := $$CREATE TEMPORARY TABLE %I.%I () $$;
	ADD_COLUMN			CONSTANT TEXT := $$ALTER TABLE %I.%I ADD COLUMN %I TEXT $$;
	DROP_COLUMN			CONSTANT TEXT := $$ALTER TABLE %I.%I DROP COLUMN IF EXISTS %I $$;
	GET_COLTYPE			CONSTANT TEXT := $$SELECT %I::%s FROM %I.%I $$;
	ALTER_COLTYPE		CONSTANT TEXT := $$ALTER TABLE %I.%I ALTER COLUMN %I TYPE %s USING %I::%s $$;
BEGIN
    SET client_min_messages TO ERROR;
    
    DROP TABLE IF EXISTS tmpHeaderRow;
    
    CREATE TEMPORARY TABLE tmpHeaderRow (content text);

	 COPY tmpHeaderRow FROM 'c:\\temp\\output.csv';
    
    -- EXECUTE 'COPY tmpHeaderRow FROM PROGRAM ' || QUOTE_LITERAL('curl ' || FORMAT(URL,strAgencyIndentifier, strDataFlowIndentifier)) ;

	SELECT content INTO strHeaderRow FROM tmpHeaderRow LIMIT 1 ;
	FOR rec IN SELECT * FROM regexp_split_to_table(strHeaderRow, CHARDELIMITER) AS columnName
    LOOP
        strColumnName := LOWER(REPLACE(rec.columnName, ' ', '_'));
		IF strpos(strColumnName, ':') > 0 THEN
			strColumnNameDesc := SPLIT_PART(strColumnName,':',2);
			strColumnName := SPLIT_PART(strColumnName,':',1);
			RAISE INFO 'Splits - % - % ',strColumnName, strColumnNameDesc;
			
		END IF;

		RAISE INFO '%',  strColumnName;
	END LOOP;
	
END;
$BODY$
LANGUAGE PLPGSQL;

CALL load_oecd_data ('OECD.ELS.HD','DSD_HEALTH_PROC@DF_SCREEN')

create temporary table test as select * from tmpHeaderRow 

truncate table tmpHeaderRow
