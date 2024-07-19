DROP FUNCTION IF EXISTS areas.get_nuts_areas(INT, INT);

CREATE OR REPLACE FUNCTION areas.get_nuts_areas(intYear INTEGER, intLevel	INTEGER DEFAULT NULL)
RETURNS TABLE
	(
		f_nuts_id	TEXT,
		cntr_code	TEXT, 
		nuts_name	TEXT, 
		levl_code	INTEGER, 
		geom		GEOMETRY(MultiPolygon,4326)
	)
AS
$BODY$
DECLARE
	activeMapYear	INTEGER;
	QUERY			CONSTANT TEXT := $$SELECT nuts_id, cntr_code, %s, levl_code, geom FROM areas.nuts_%s %s$$;
	LEVEL_SELECT	CONSTANT TEXT := $$ WHERE levl_code = %1$L OR %1$L IS NULL $$;
BEGIN
	WITH cte(map_year,start_year,end_year) AS
	(
		VALUES 
			(2003,0,2007),
			(2006,2008,2011),
			(2010,2012,2014),
			(2013,2015,2017),
			(2016,2018,2020),
			(2021,2021,2099)
	)
	SELECT 
		map_year
	INTO 
		activeMapYear
	FROM
		cte
	WHERE
		intYear BETWEEN start_year AND end_year;
	-- RAISE INFO '%', FORMAT(QUERY,CASE WHEN activeMapYear = 2003 THEN 'nuts_name' ELSE 'name_latn' END, activeMapYear, FORMAT(LEVEL_SELECT, intLevel));
	RETURN QUERY EXECUTE FORMAT(QUERY,CASE WHEN activeMapYear = 2003 THEN 'nuts_name' ELSE 'name_latn' END, activeMapYear, FORMAT(LEVEL_SELECT, intLevel));
END;
$BODY$
LANGUAGE PLPGSQL STABLE;

CREATE OR REPLACE FUNCTION areas.get_nuts_areas_tiles(z INTEGER, x INTEGER, y INTEGER, year INTEGER, intLevel INTEGER DEFAULT NULL)
RETURNS bytea
AS $BODY$

DECLARE
    result bytea;
BEGIN
	WITH
    bounds AS (
      SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    mvtgeom AS (
      SELECT 
		ST_AsMVTGeom(ST_Transform(n.geom, 3857), bounds.geom) AS geom,
        f_nuts_id AS nuts_id, 
		nuts_name 
		
      FROM 
			bounds, 
			areas.get_nuts_areas(year, intLevel) n
      WHERE 
			ST_Intersects(n.geom, ST_Transform(bounds.geom, 4326))
    ) 
    SELECT 
		ST_AsMVT(mvtgeom, 'default')
    INTO 
		result
    FROM 
		mvtgeom;

    RETURN result;
END;
$BODY$
LANGUAGE 'plpgsql' STABLE PARALLEL SAFE 






