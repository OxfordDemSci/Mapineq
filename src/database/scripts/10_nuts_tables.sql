DROP TABLE IF EXISTS areas.nuts_2003;

CREATE TABLE IF NOT EXISTS areas.nuts_2003
(
    id 			SERIAL PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    nuts_id 	TEXT,
    levl_code 	INTEGER,
    cntr_code 	TEXT,
    nuts_name 	TEXT,
    fid 		TEXT
);

CREATE INDEX IF NOT EXISTS sidx_nuts_2003_geom
    ON areas.nuts_2003 
	USING gist (geom);

DROP TABLE IF EXISTS areas.nuts_2006;

CREATE TABLE IF NOT EXISTS areas.nuts_2006
(
    id 			SERIAL PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    nuts_id 	TEXT,
    levl_code 	INTEGER,
    cntr_code 	TEXT,
    nuts_name 	TEXT,
    name_latn 	TEXT,
    fid 		TEXT
);

CREATE INDEX IF NOT EXISTS sidx_nuts_2006_geom
    ON areas.nuts_2006 
	USING gist (geom);

DROP TABLE IF EXISTS areas.nuts_2010;

CREATE TABLE IF NOT EXISTS areas.nuts_2010
(
    id 			SERIAL PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    levl_code 	INTEGER,
    nuts_id 	TEXT,
    cntr_code 	TEXT,
    nuts_name 	TEXT,
    name_latn 	TEXT,
    fid 		TEXT
);

CREATE INDEX IF NOT EXISTS sidx_nuts_2010_geom
    ON areas.nuts_2010 
	USING gist (geom);	

DROP TABLE IF EXISTS areas.nuts_2013;

CREATE TABLE IF NOT EXISTS areas.nuts_2013
(
    id 			SERIAL PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    nuts_id 	TEXT,
    levl_code 	INTEGER,
    cntr_code 	TEXT,
    name_latn 	TEXT,
    nuts_name 	TEXT,
    fid 		TEXT
);

CREATE INDEX IF NOT EXISTS sidx_nuts_2013_geom
    ON areas.nuts_2013 
	USING gist(geom);

DROP TABLE IF EXISTS areas.nuts_2016;

CREATE TABLE IF NOT EXISTS areas.nuts_2016
(
    id 			SERIAL PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    levl_code 	INTEGER,
    nuts_id 	TEXT,
    cntr_code 	TEXT,
    name_latn 	TEXT,
    nuts_name 	TEXT,
    mount_type 	INTEGER,
    urbn_type 	INTEGER,
    coast_type 	INTEGER,
    fid 		TEXT
);

CREATE INDEX IF NOT EXISTS sidx_nuts_2016_geom
    ON areas.nuts_2016 
	USING gist (geom);

DROP TABLE IF EXISTS areas.nuts_2021;

CREATE TABLE IF NOT EXISTS areas.nuts_2021
(
    id 			SERIAL PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    nuts_id 	TEXT,
    levl_code 	INTEGER,
    cntr_code 	TEXT,
    name_latn 	TEXT,
    nuts_name 	TEXT,
    mount_type 	INTEGER,
    urbn_type 	INTEGER,
    coast_type 	INTEGER,
    fid 		TEXT
);

CREATE INDEX IF NOT EXISTS sidx_nuts_2021_geom
    ON areas.nuts_2021 
	USING gist (geom);

DROP TABLE IF EXISTS areas.nuts_2024;

CREATE TABLE IF NOT EXISTS areas.nuts_2024
(
    id 			SERIAL PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    nuts_id 	TEXT,
    levl_code 	INTEGER,
    cntr_code 	TEXT,
    name_latn 	TEXT,
    nuts_name 	TEXT,
    mount_type 	INTEGER,
    urbn_type 	INTEGER,
    coast_type 	INTEGER
);

CREATE INDEX IF NOT EXISTS sidx_nuts_2024_geom
    ON areas.nuts_2024 
	USING gist (geom);
	
	