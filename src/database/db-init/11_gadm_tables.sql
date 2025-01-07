DROP TABLE IF EXISTS areas.gadm_0;

CREATE TABLE IF NOT EXISTS areas.gadm_0
(
    fid 		BIGINT PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    gid_0 		TEXT ,
    country 	TEXT
);

CREATE INDEX IF NOT EXISTS sidx_gadm_0_geom
    ON areas.gadm_0 
	USING gist (geom);

DROP TABLE IF EXISTS areas.gadm_1;

CREATE TABLE IF NOT EXISTS areas.gadm_1
(
    fid 		BIGINT PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    gid_0 		TEXT,
    country 	TEXT,
    gid_1 		TEXT,
    name_1 		TEXT,
    varname_1 	TEXT,
    nl_name_1 	TEXT,
    type_1 		TEXT,
    engtype_1 	TEXT,
    cc_1 		TEXT,
    hasc_1 		TEXT,
    iso_1 		TEXT
);

CREATE INDEX IF NOT EXISTS sidx_gadm_1_geom
    ON areas.gadm_1 
	USING gist (geom);

DROP TABLE IF EXISTS areas.gadm_2;

CREATE TABLE IF NOT EXISTS areas.gadm_2
(
    fid 		BIGINT PRIMARY KEY,
    geom 		GEOMETRY(MultiPolygon,4326),
    gid_0 		TEXT,
    country 	TEXT,
    gid_1 		TEXT,
    name_1 		TEXT,
    nl_name_1 	TEXT,
    gid_2 		TEXT,
    name_2 		TEXT,
    varname_2 	TEXT,
    nl_name_2 	TEXT,
    type_2 		TEXT,
    engtype_2 	TEXT,
    cc_2 		TEXT,
    hasc_2 		TEXT
);

CREATE INDEX IF NOT EXISTS sidx_gadm_2_geom
    ON areas.gadm_2 
	USING gist (geom);

CREATE TABLE areas.nuts_gadm
(
	nuts_code	TEXT,
	gadm_code	TEXT
);

INSERT INTO areas.nuts_gadm
VALUES
('BE','BEL'),
('BG','BGR'),
('CZ','CZE'),
('ME','MNE'),
('DK','DNK'),
('DE','DEU'),
('EE','EST'),
('IE','IRL'),
('EL','GRC'),
('ES','ESP'),
('FR','FRA'),
('HR','HRV'),
('IS','ISL'),
('IT','ITA'),
('CY','CYP'),
('LV','LVA'),
('LI','LIE'),
('LT','LTU'),
('LU','LUX'),
('HU','HUN'),
('MT','MLT'),
('NL','NLD'),
('NO','NOR'),
('AT','AUT'),
('PL','POL'),
('PT','PRT'),
('RO','ROU'),
('CH','CHE'),
('RS','SRB'),
('MK','MKD'),
('AL','ALB'),
('SI','SVN'),
('SK','SVK'),
('FI','FIN'),
('SE','SWE'),
('TR','TUR'),
('UK','GBR')