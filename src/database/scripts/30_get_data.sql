DROP PROCEDURE IF EXISTS areas.get_nuts_codes(TEXT, INTEGER, TEXT);
CREATE OR REPLACE PROCEDURE areas.get_nuts_codes (strSource TEXT, intLevel INTEGER, tmpTable TEXT)
AS
$BODY$
DECLARE
	origin	TEXT;

	QUERY	CONSTANT TEXT := $$UPDATE %s
							SET
								f_geo = nuts_code
							FROM
								areas.nuts_gadm
							WHERE
								f_geo = gadm_code $$;
BEGIN
	SELECT provider INTO origin FROM catalogue WHERE resource = strSource;
	IF origin = 'OECD' AND intLevel = 0 THEN
		EXECUTE FORMAT(QUERY,tmpTable);
	END IF;
END;
$BODY$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS website.get_data_source_level_year(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION website.get_data_source_level_year(intYear INTEGER, source_conditions JSONB)
RETURNS TABLE
	(
		f_geo 	TEXT,
		f_value	NUMERIC
	)
AS
$BODY$
DECLARE
	rec			RECORD;
	strSource	TEXT;
	strQuery	TEXT;
	BASIC_QUERY	CONSTANT TEXT := $$SELECT geo, "obsValue"::NUMERIC FROM public.%I WHERE "obsTime" = %L $$;
	PLUS_QUERY	CONSTANT TEXT := $$ AND %I = %L $$;
BEGIN
	
	strQuery = FORMAT(BASIC_QUERY,website.get_query_resource(source_conditions ->> 'source'),intYear );

	FOR rec IN
	SELECT
		j ->> 'field'  	AS column,
		j ->> 'value' 	AS value
	FROM
		jsonb_array_elements(source_conditions -> 'conditions') AS j	
	LOOP
		strQuery := strQuery || FORMAT(PLUS_QUERY, rec.column, rec.value) ;
		
	END LOOP;
	RAISE INFO '%', strQuery;
	RETURN QUERY EXECUTE strQuery;
END;
$BODY$
LANGUAGE PLPGSQL;
