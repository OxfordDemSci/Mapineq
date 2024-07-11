DROP FUNCTION IF EXISTS postgisftw.get_column_values_source_json(TEXT,  JSONB, INTEGER  );
CREATE OR REPLACE FUNCTION postgisftw.get_column_values_source_json(_resource TEXT, source_selections JSONB DEFAULT NULL::JSONB, _use_case INTEGER DEFAULT NULL)
RETURNS TABLE
(
	field			TEXT,
	field_label		TEXT, 
	field_values	JSONB
)
AS
$BODY$
DECLARE 
	strQueryResource	TEXT;
	strProvider			TEXT;
	recCaseOptions		RECORD;
	recOverlap			RECORD;
	recSelected			RECORD;	
	recField			RECORD;
	recValue			RECORD;
	strWhere			TEXT := '';
	arrWhere			TEXT[];
	strQuery			TEXT;
	active_loop			TEXT;
	bValueOptions		BOOLEAN;
	LOOP_QUERY		CONSTANT TEXT := $$	SELECT
											table_name,
											column_name::TEXT,
											label::TEXT
										FROM
											information_schema.columns c
											INNER JOIN website.catalogue_field_description d
												ON column_name = d.field
										WHERE
											provider = %L
											AND table_name = %L 
											AND (resource = %L or resource IS NULL) $$;

	VALUES_QUERY	CONSTANT TEXT:= $$
					WITH cte AS
						(SELECT DISTINCT 
							%I as field_value
						FROM
							%I  
						%s 
						ORDER BY
							field_value
						)
						SELECT
							jsonb_agg(JSONB_BUILD_OBJECT('value',value,'label',	label)) AS field_values
						FROM
							cte
							INNER JOIN website.catalogue_field_value_description d
								ON field_value::TEXT = d.value
						WHERE
							provider = %L
							AND (resource = %L OR resource IS NULL)
							AND field = %L $$;		
	WHEREPART		CONSTANT TEXT := ' %I = %L ';

	VALUES_OPTIONS	CONSTANT TEXT := $$
						SELECT
							j->>'tableColumnValueOtions' != '*'
						FROM
							website.use_cases,
							jsonb_array_elements(case_options) AS j
						WHERE
							use_case = %s
							AND j ->> 'tableName' = %L $$;

	OPTIONS_QUERY	CONSTANT TEXT := $$
									SELECT
										key 					AS column_name,
										ARRAY_AGG(column_value) AS column_values
									FROM
										website.use_cases,
										jsonb_array_elements(case_options) AS j,
										jsonb_each_text(j->'tableColumnValueOtions') AS key_value,
										jsonb_array_elements_text(key_value.value::jsonb) AS column_value
									WHERE
										use_case = %s AND
										j ->> 'tableName' = %L AND
										key = %L
									GROUP BY column_name$$;
	OPTIONS_EXTRA	CONSTANT TEXT := $$ AND field_value::TEXT = ANY(%L) $$;
	
BEGIN
	
	SELECT
		query_resource,
		provider
	INTO
		strQueryResource,
		strProvider
	FROM
		website.vw_data_tables
	WHERE
		resource = _resource;


	IF source_selections ->> 'year' IS NOT NULL THEN 
		arrWhere = ARRAY_APPEND(arrWhere,FORMAT(WHEREPART,'obsTime', source_selections ->> 'year'));
	END IF;
	
	FOR recSelected IN
	SELECT
		j ->> 'field'  as field,
		j ->> 'value' as value
	FROM
		jsonb_array_elements(source_selections -> 'selected') AS j		
	LOOP
		arrWhere = array_append(arrWhere, FORMAT(WHEREPART,recSelected.field, recSelected.value));
	END LOOP;

	IF COALESCE(array_length(arrWhere,1),0) > 0 THEN
		strWhere = ' WHERE '  || ARRAY_TO_STRING(arrWhere, ' AND ');
	END IF;

	IF _use_case IS NOT NULL THEN
		EXECUTE FORMAT(VALUES_OPTIONS, _use_case, _resource) INTO bValueOptions;
		RAISE INFO '%', bValueOptions;
	END IF;
	RAISE INFO '%', FORMAT(LOOP_QUERY,strProvider, strQueryResource, _resource);
	FOR recField IN EXECUTE FORMAT(LOOP_QUERY,strProvider, strQueryResource, _resource)
	LOOP

		strQuery := FORMAT(VALUES_QUERY,recField.column_name, strQueryResource, strWhere, strProvider, _resource,  recField.column_name);
		
		IF _use_case IS NOT NULL AND bValueOptions THEN
			EXECUTE FORMAT(OPTIONS_QUERY, _use_case, _resource, recField.column_name) INTO recCaseOptions;
			IF recCaseOptions.column_values != '{*}' THEN
				strQuery := strQuery || FORMAT(OPTIONS_EXTRA,recCaseOptions.column_values );
			END IF;	
		END IF;
		
		EXECUTE strQuery INTO recValue;
		field			= recField.column_name::TEXT;
		field_label		= recField.label::TEXT;
		field_values	= recValue.field_values::JSONB;
		
		RETURN NEXT;
	END LOOP;
	
END;
$BODY$
LANGUAGE PLPGSQL;