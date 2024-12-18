DROP FUNCTION IF EXISTS postgisftw.search_sources(TEXT);
CREATE OR REPLACE FUNCTION postgisftw.search_sources(_search_string TEXT DEFAULT NULL)
RETURNS TABLE
(
	f_provider			TEXT,
	f_resource 			TEXT, 
	f_description 		TEXT, 
	f_short_description TEXT,
	f_years				JSONB,
	f_levels			JSONB
)
AS
$BODY$
DECLARE
	rec	RECORD;
	strQuery	TEXT;
BEGIN
	RETURN QUERY 
	EXECUTE FORMAT ($$SELECT
		provider,
		c.resource,
		descr,
		short_descr::TEXT,
		(SELECT json_agg(year) FROM website.resource_years r WHERE r.resource = c.resource )::JSONB,
		(SELECT json_agg(level) FROM website.resource_nuts_levels r WHERE r.resource = c.resource )::JSONB
	FROM
		website.vw_data_tables c
	WHERE
		provider || c.resource || descr || short_descr ILIKE '%%%s%%'$$,_search_string) ;
END;
$BODY$
LANGUAGE PLPGSQL;

