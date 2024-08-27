DROP FUNCTION IF EXISTS areas.get_preferred_nuts_year(INTEGER);

CREATE OR REPLACE FUNCTION areas.get_preferred_nuts_year(_year INTEGER)
RETURNS INTEGER 
AS
$$
	WITH cte(map_year, start_year, end_year) AS (
		VALUES 
			(2003, 0, 2007),
			(2006, 2008, 2011),
			(2010, 2012, 2014),
			(2013, 2015, 2017),
			(2016, 2018, 2020),
			(2021, 2021, 2023),
			(2024, 2024, 2099)
	)
	SELECT 
		map_year
	FROM
		cte
	WHERE
		_year BETWEEN start_year AND end_year
$$
LANGUAGE SQL IMMUTABLE;

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
			(2021,2021,2023),
			(2024,2024,2099)
	)
	SELECT 
		map_year
	INTO 
		activeMapYear
	FROM
		cte
	WHERE
		intYear BETWEEN start_year AND end_year;
	RETURN QUERY EXECUTE FORMAT(QUERY,CASE WHEN activeMapYear = 2003 THEN 'nuts_name' ELSE 'name_latn' END, activeMapYear, FORMAT(LEVEL_SELECT, intLevel));
END;
$BODY$
LANGUAGE PLPGSQL STABLE;

DROP FUNCTION IF EXISTS areas.get_nuts_areas_tiles(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER);
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
LANGUAGE 'plpgsql' STABLE PARALLEL SAFE ;

DROP TABLE IF EXISTS website.log;
CREATE TABLE website.log
(
	id 				SERIAL, 
	action_datetime	TIMESTAMP DEFAULT NOW(),		
	level 			INTEGER, 
	year 			INTEGER, 
	preferred_year 	INTEGER, 
	preferred_score INTEGER, 
	max_year 		INTEGER, 
	max_score 		INTEGER,
	x_json 			JSONB, 
	y_json 			JSONB
);

DROP FUNCTION IF EXISTS areas.get_xy_data_map_year(INTEGER, INTEGER, JSONB, JSONB);
CREATE OR REPLACE FUNCTION areas.get_xy_data_map_year(_level INTEGER, _year INTEGER, X_JSON JSONB DEFAULT NULL, Y_JSON JSONB DEFAULT NULL)
RETURNS INTEGER
AS
$BODY$
DECLARE
	preferred_year	INTEGER;
	nuts_year		INTEGER;
	nuts_years		INTEGER[] := ARRAY[2003,2006,2010,2013,2016,2021, 2024];
	best_year		INTEGER;
	best_score		INTEGER := 0;
	preferred_score	INTEGER;
	rec				RECORD;
	COUNT_QUERY 	CONSTANT TEXT := $$
							SELECT
								COUNT(*)																nr_areas,
								COUNT(*) FILTER ( WHERE x.f_geo IS NOT NULL)							nr_x_geo,
								COUNT(*) FILTER ( WHERE y.f_geo IS NOT NULL)							nr_y_geo,
								COUNT(*) FILTER ( WHERE x.f_geo IS NOT NULL AND y.f_geo IS NOT NULL) 	nr_x_y_geo
							FROM
								areas.nuts_%s
								LEFT JOIN  tmpSource_x  AS x
									ON nuts_id = x.f_geo
								LEFT JOIN  tmpSource_y  AS y
									ON nuts_id = y.f_geo
								WHERE
									levl_code = %s $$;

BEGIN
	SELECT *  INTO preferred_year FROM areas.get_preferred_nuts_year(_year) ;
	FOREACH nuts_year IN ARRAY nuts_years
	LOOP
		EXECUTE FORMAT(COUNT_QUERY, nuts_year, _level) INTO rec;
		IF rec.nr_x_y_geo > best_score THEN
			best_score := rec.nr_x_y_geo;
			best_year := nuts_year;
		END IF;
		IF nuts_year = preferred_year THEN
			preferred_score = rec.nr_x_y_geo;
		END IF;
	END LOOP;
	IF preferred_score = best_score THEN
		best_year = preferred_year;
	END IF;
	INSERT INTO website.log(level, year, preferred_year, preferred_score, max_year, max_score, x_json, y_json) values(_level, _year, preferred_year, preferred_score, best_year, best_score, x_json, y_json);
	RETURN best_year;
END;
$BODY$
LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS areas.get_xy_data_map_year(INTEGER, INTEGER, JSONB);
CREATE OR REPLACE FUNCTION areas.get_x_data_map_year(_level INTEGER, _year INTEGER, X_JSON JSONB DEFAULT NULL)
RETURNS INTEGER
AS
$BODY$
DECLARE
	preferred_year	INTEGER;
	nuts_year		INTEGER;
	nuts_years		INTEGER[] := ARRAY[2003,2006,2010,2013,2016,2021, 2024];
	best_year		INTEGER;
	best_score		INTEGER := 0;
	preferred_score	INTEGER;
	rec				RECORD;
	COUNT_QUERY 	CONSTANT TEXT := $$
							SELECT
								COUNT(*)																nr_areas,
								COUNT(*) FILTER ( WHERE x.f_geo IS NOT NULL)							nr_x_geo
							FROM
								areas.nuts_%s
								LEFT JOIN  tmpSource_x  AS x
									ON nuts_id = x.f_geo
								WHERE
									levl_code = %s $$;

BEGIN
	SELECT *  INTO preferred_year FROM areas.get_preferred_nuts_year(_year) ;
	FOREACH nuts_year IN ARRAY nuts_years
	LOOP
		EXECUTE FORMAT(COUNT_QUERY, nuts_year, _level) INTO rec;
		IF rec.nr_x_geo > best_score THEN
			best_score := rec.nr_x_geo;
			best_year := nuts_year;
		END IF;
		IF nuts_year = preferred_year THEN
			preferred_score = rec.nr_x_geo;
		END IF;
	END LOOP;
	IF preferred_score = best_score THEN
		best_year = preferred_year;
	END IF;
	INSERT INTO website.log(level, year, preferred_year, preferred_score, max_year, max_score, x_json) values(_level, _year, preferred_year, preferred_score, best_year, best_score, x_json);
	RETURN best_year;
END;
$BODY$
LANGUAGE PLPGSQL;




