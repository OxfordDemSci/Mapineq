ALTER TABLE IF EXISTS catalogue
ADD COLUMN query_resource text;

UPDATE catalogue
SET query_resource =  CASE
							WHEN provider = 'ESTAT'::text 
								THEN resource
								ELSE 'vw_'::text || LOWER(resource)
						END  
