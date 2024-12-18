ALTER TABLE IF EXISTS catalogue
ADD COLUMN IF NOT EXISTS query_resource text;

UPDATE catalogue
SET query_resource =  CASE
							WHEN provider = 'ESTAT'::text 
								THEN resource
								ELSE 'vw_'::text || LOWER(resource)
						END;

ALTER TABLE catalogue 
	ADD COLUMN IF NOT EXISTS ID serial PRIMARY KEY, 
	ADD COLUMN IF NOT EXISTS meta_data_url TEXT, 
	ADD COLUMN IF NOT EXISTS web_source_url TEXT;


UPDATE catalogue
SET
	web_source_url = FORMAT('https://doi.org/10.2908/%s', resource),
	meta_data_url = FORMAT('https://doi.org/10.2908/%s', resource),
WHERE
	provider = 'ESTAT';

