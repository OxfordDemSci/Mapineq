CREATE OR REPLACE PROCEDURE create_oecd_views()
AS
$BODY$
DECLARE
	rec			RECORD;
	arrColumns	TEXT[];
	bGeo		BOOLEAN := FALSE;
	bTime		BOOLEAN := FALSE;
	DROP_VIEW	CONSTANT TEXT := $$DROP VIEW IF EXISTS vw_%s$$;
	COLUMN_AS	CONSTANT TEXT := $$ %I AS %I$$;
	COLUMN_VIEW CONSTANT TEXT := $$%I$$;
	CREATE_VIEW	CONSTANT TEXT := $$CREATE VIEW vw_%s AS SELECT %s FROM %I$$;
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
			AND LOWER(column_name) != 'obs_status'
			-- AND table_name IN ('REGION_DEMOGR', 'GID2')
		ORDER BY 1, ordinal_position
	LOOP

		IF LOWER(rec.column_name) IN ('location','cou', 'country', 'reg_id', 'geo') THEN
			arrColumns := ARRAY_APPEND(arrColumns,FORMAT(COLUMN_AS,rec.column_name,'geo'));
			bGeo := TRUE;
		ELSIF LOWER(rec.column_name) IN ('obstime', 'time') THEN
			arrColumns := ARRAY_APPEND(arrColumns,FORMAT(COLUMN_AS, rec.column_name,'obsTime'));
			bTime := TRUE;
		ELSE
			arrColumns := ARRAY_APPEND(arrColumns,FORMAT(COLUMN_VIEW,rec.column_name));
		END IF;
		IF rec.last_column THEN		
			EXECUTE FORMAT(DROP_VIEW,LOWER(rec.table_name));
			IF bGeo AND bTime THEN
				BEGIN
					EXECUTE FORMAT(CREATE_VIEW,LOWER(rec.table_name),ARRAY_TO_STRING(arrColumns, ', '),rec.table_name);
					-- RAISE INFO '%', rec.table_name;
				EXCEPTION
					WHEN OTHERS THEN
						RAISE WARNING 'table: % - error: % ', rec.table_name,SQLERRM;
				END;
			ELSE
				RAISE WARNING 'tabel: % geo column presnt: %, time column present: %',rec.table_name,bGeo::TEXT,bTime::TEXT;
			END IF;
			arrColumns := NULL;
			bGeo := FALSE;
			bTime := FALSE;
		END IF;
	END LOOP;
	
END;
$BODY$
LANGUAGE PLPGSQL;

CALL create_oecd_views()



