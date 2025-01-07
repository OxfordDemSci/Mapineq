DROP PROCEDURE IF EXISTS create_estat_views(TEXT);
CREATE OR REPLACE PROCEDURE create_estat_views(strTable TEXT DEFAULT NULL)
AS
$BODY$
DECLARE
	rec					RECORD;
	frequence			TEXT;
	arrColumns			TEXT[];
	QUERY_FREQ			CONSTANT TEXT := $$SELECT DISTINCT freq FROM %I$$;
	UPDATE_CATALOGUE	CONSTANT TEXT := $$UPDATE catalogue SET query_resource = 'vw_%s' WHERE resource = %L AND provider = 'ESTAT'$$;
	CLEAR_CATALOGUE		CONSTANT TEXT := $$UPDATE catalogue SET query_resource = NULL WHERE resource = %L AND provider = 'ESTAT'$$;
	DROP_VIEW			CONSTANT TEXT := $$DROP VIEW IF EXISTS vw_%s$$;
	COLUMN_SPLIT		CONSTANT TEXT := $$ SPLIT_PART(%I, '-',%s) AS %I$$;
	COLUMN_VIEW 		CONSTANT TEXT := $$%I$$;
	CREATE_VIEW			CONSTANT TEXT := $$CREATE VIEW vw_%s AS SELECT %s FROM %I$$;
	
BEGIN
	SET client_min_messages = WARNING;
	EXECUTE FORMAT (QUERY_FREQ, strTable) INTO frequence;
	FOR rec IN
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
			provider = 'ESTAT'
			AND (table_name = strTable OR strTable IS NULL)
		ORDER BY 1, ordinal_position
	LOOP
		IF LOWER(rec.column_name) != 'obstime' THEN
			arrColumns := ARRAY_APPEND(arrColumns,FORMAT(COLUMN_VIEW,rec.column_name));
		ELSE
			arrColumns := ARRAY_APPEND(arrColumns,FORMAT(COLUMN_SPLIT,rec.column_name,1,'obsTime'));
			arrColumns := ARRAY_APPEND(arrColumns,FORMAT(COLUMN_SPLIT,rec.column_name,2,frequence));
		END IF;
		IF rec.last_column THEN
			BEGIN
				EXECUTE FORMAT (DROP_VIEW, LOWER(rec.table_name));
				EXECUTE FORMAT(CREATE_VIEW,LOWER(rec.table_name),ARRAY_TO_STRING(arrColumns, ', '),rec.table_name);
				EXECUTE FORMAT(UPDATE_CATALOGUE,LOWER(rec.table_name), rec.table_name);
			EXCEPTION
				WHEN OTHERS THEN
					EXECUTE FORMAT(CLEAR_CATALOGUE, rec.table_name);
					RAISE WARNING 'table: % - error: % ', rec.table_name,SQLERRM;
			END;
		END IF;
	END LOOP;
END;
$BODY$
LANGUAGE PLPGSQL;


