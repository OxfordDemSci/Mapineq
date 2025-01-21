DROP PROCEDURE IF EXISTS  create_oecd_views(TEXT);
CREATE OR REPLACE PROCEDURE create_oecd_views(strTable TEXT DEFAULT NULL)
AS
$BODY$
DECLARE
	rec					RECORD;
	arrColumns			TEXT[];
	bGeo				BOOLEAN := FALSE;
	bTime				BOOLEAN := FALSE;
	bFieldValueExists	BOOLEAN;
	UPDATE_CATALOGUE	CONSTANT TEXT := $$UPDATE catalogue SET query_resource = 'vw_%s' WHERE resource = %L AND provider = 'OECD'$$;
	CLEAR_CATALOGUE		CONSTANT TEXT := $$UPDATE catalogue SET query_resource = NULL WHERE resource = %L AND provider = 'OECD'$$;	
	DROP_VIEW			CONSTANT TEXT := $$DROP VIEW IF EXISTS vw_%s$$;
	COLUMN_AS			CONSTANT TEXT := $$ %I AS %I$$;
	COLUMN_VIEW 		CONSTANT TEXT := $$%I$$;
	CREATE_VIEW			CONSTANT TEXT := $$CREATE VIEW vw_%s AS SELECT %s FROM %I$$;

	FIELD_VALUE_EXISTS	CONSTANT TEXT := $$SELECT EXISTS (SELECT 1 FROM %1$I WHERE %2$I IS NOT NULL AND LENGTH(%2$I) >0) $$;
	
BEGIN
	SET client_min_messages = WARNING;
	FOR rec in
		SELECT  
			table_name,
			column_name,
			table_name != COALESCE(LEAD(table_name) OVER (PARTITION BY table_name ORDER BY ordinal_position), '') AS last_column,
			ordinal_position
		FROM
			information_schema.columns
			INNER JOIN catalogue
				ON table_name = resource
		WHERE
			provider = 'OECD'
			AND column_name NOT ILIKE '%parent%'
			AND column_name NOT ILIKE '%_desc.en'
			AND LOWER(column_name) NOT ILIKE 'obs_status%'
			AND (table_name = strTable OR strTable IS NULL)
		ORDER BY 1, ordinal_position
	LOOP

		IF LOWER(rec.column_name) IN ('location','cou', 'country', 'reg_id', 'geo') AND NOT bGeo THEN
			arrColumns := ARRAY_APPEND(arrColumns,FORMAT(COLUMN_AS,rec.column_name,'geo'));
			bGeo := TRUE;
		ELSIF LOWER(rec.column_name) IN ('obstime', 'time') THEN
			arrColumns := ARRAY_APPEND(arrColumns,FORMAT(COLUMN_AS, rec.column_name,'obsTime'));
			bTime := TRUE;
		ELSE
			EXECUTE FORMAT(FIELD_VALUE_EXISTS, strTable, rec.column_name) INTO bFieldValueExists;
			IF bFieldValueExists  THEN
				arrColumns := ARRAY_APPEND(arrColumns,FORMAT(COLUMN_VIEW,rec.column_name));
			END IF;		
		END IF;
		IF rec.last_column THEN		
			EXECUTE FORMAT(DROP_VIEW,LOWER(rec.table_name));
			IF bGeo AND bTime THEN
				BEGIN
					EXECUTE FORMAT(CREATE_VIEW,LOWER(rec.table_name),ARRAY_TO_STRING(arrColumns, ', '),rec.table_name);
					EXECUTE FORMAT(UPDATE_CATALOGUE,LOWER(rec.table_name), rec.table_name);
				EXCEPTION
					WHEN OTHERS THEN
						RAISE WARNING 'table: % - error: % ', rec.table_name,SQLERRM;
				END;
			ELSE
				EXECUTE FORMAT(CLEAR_CATALOGUE, rec.table_name);
				RAISE WARNING 'tabel: % geo column present: %, time column present: %',rec.table_name,bGeo::TEXT,bTime::TEXT;
			END IF;
			arrColumns := NULL;
			bGeo := FALSE;
			bTime := FALSE;
		END IF;
	END LOOP;
	
END;
$BODY$
LANGUAGE PLPGSQL;







