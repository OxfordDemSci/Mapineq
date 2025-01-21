CREATE  TABLE website.catalogue_field_value_description_order
(
	id			SERIAL PRIMARY KEY,
	provider	TEXT,
	resource	TEXT,
	field		TEXT,
	order_json	JSONB
);


TRUNCATE TABLE website.catalogue_field_value_description_order;
INSERT INTO website.catalogue_field_value_description_order(provider, resource, field, order_json)
VALUES
(
	'ESTAT', 
	NULL,
	'SEX',
	'{
		"top": ["Total"],
		"bulk": "asc",
		"bottom": ["Unknown", "Not applicable","No response" ]
	}'
),
(
	'European Higher Education Sector Observatory', 
	'eter',
	'category',
	'{
		"top": ["All"],
		"bulk": "asc"
	}'
);

DROP FUNCTION IF EXISTS website.catalogue_field_value_order_by(TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION website.catalogue_field_value_order_by(i_provider TEXT, i_resource TEXT, i_field TEXT)
RETURNS TEXT
AS
$BODY$
DECLARE
	rec					RECORD;
	strReturn			TEXT := '';
	strWhen				TEXT := '';
	strBulkDirection	TEXT;
	jsonb_order_field	JSONB;
	WHEN_PART			CONSTANT TEXT := $$WHEN label = %L THEN %s $$;
BEGIN
	SELECT
		order_json
	INTO
		jsonb_order_field
	FROM
		website.catalogue_field_value_description_order
	WHERE
		provider ILIKE i_provider AND
		(i_resource IS NULL OR resource ILIKE i_resource) AND
		field ILIKE i_field;
	RAISE INFO '%', jsonb_order_field;
	FOR rec IN
		SELECT 
	    	order_field,
			COUNT(*) OVER() * -1 + ROW_NUMBER() OVER() -1 AS rank
		FROM 
	    	jsonb_array_elements_text(jsonb_order_field->'top') AS order_field
	LOOP
		strWhen := strWhen || FORMAT(WHEN_PART,rec.order_field, rec.rank);
	END LOOP;

	FOR rec IN
		SELECT 
	    	order_field,
			ROW_NUMBER() OVER() AS rank
		FROM 
	    	jsonb_array_elements_text(jsonb_order_field->'bottom') AS order_field
	LOOP
		strWhen := strWhen || FORMAT(WHEN_PART,rec.order_field, rec.rank);
	END LOOP;

	SELECT 
    	jsonb_order_field->>'bulk'
	INTO
		strBulkDirection;

	IF LENGTH(strWhen) > 0 THEN
		strReturn := 'CASE ' || strWhen || ' ELSE 0 END';
	END IF;

	IF LENGTH(strWhen) > 0 AND LENGTH(strBulkDirection) > 0 THEN
		strReturn := strReturn || ' , ';
	END IF;

	IF LENGTH(strBulkDirection) > 0 THEN
		strReturn := strReturn || ' label ' || strBulkDirection;
	END IF;
	RETURN strReturn ;
END;
$BODY$
LANGUAGE PLPGSQL STABLE;


DROP FUNCTION IF EXISTS website.catalogue_field_value_order (TEXT, TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION website.catalogue_field_value_order (i_provider TEXT, i_resource TEXT, i_field TEXT, i_value TEXT)
RETURNS INTEGER
AS
$BODY$
DECLARE
	i_return	INTEGER;
	QUERY		CONSTANT TEXT := $$ 
				SELECT 
					provider, 
					resource, 
					field, 
					value, 
					label, 
					ROW_NUMBER() OVER(ORDER BY %4$s) AS order_num
			FROM 
				website.catalogue_field_value_description
			WHERE 	
				provider ILIKE %1$L AND
				(%2$L IS NULL OR resource ILIKE %2$L) AND
				field ILIKE %3$L$$;
BEGIN
	IF (SELECT COUNT(*) FROM website.catalogue_field_value_description_order WHERE provider ILIKE i_provider AND (resource ILIKE i_resource OR i_resource IS NULL) AND field ILIKE i_field) = 0  THEN
		RETURN 1;
	ELSE
		IF NOT (SELECT to_regclass('pg_temp.tmpOrder') IS NOT NULL) THEN
			EXECUTE $$CREATE TEMPORARY TABLE IF NOT EXISTS tmpOrder AS  $$ || FORMAT(QUERY, i_provider, i_resource, i_field,website.catalogue_field_value_order_by(i_provider, i_resource, i_field) );
		ELSIF (SELECT COUNT(*) FROM tmpOrder WHERE provider = i_provider AND (resource = i_resource OR i_resource IS NULL) AND field = i_field) = 0 THEN
			TRUNCATE TABLE tmpOrder;
			EXECUTE $$INSERT INTO tmpOrder   $$ || FORMAT(QUERY, i_provider, i_resource, i_field, website.catalogue_field_value_order_by(i_provider, i_resource, i_field) );
		END IF;
	END IF;

	RETURN (SELECT order_num FROM tmpOrder WHERE provider = i_provider AND field ILIKE i_field AND value = i_value);

END;
$BODY$
LANGUAGE PLPGSQL;
