psql -U $POSTGRES_USER -d $POSTGRES_DB -c \
"
CREATE ROLE reader LOGIN PASSWORD '${POSTGRES_RPASS}';

CREATE TABLE NUTS(
  id VARCHAR(5) PRIMARY KEY,
  country CHAR(3),
  level SMALLINT,
  name VARCHAR(70),
  urban SMALLINT,
  mount SMALLINT,
  coast SMALLINT,
  nuts0_id CHAR(2),
  nuts1_id VARCHAR(5),
  nuts2_id VARCHAR(5),
  nuts3_id VARCHAR(5),
  tl_id VARCHAR(5),
  geom GEOMETRY
);
GRANT SELECT ON NUTS TO reader;

CREATE TABLE catalogue(
  id SERIAL PRIMARY KEY,
  provider VARCHAR(5),
  resource VARCHAR(40),
  descr VARCHAR(300),
  version VARCHAR(20),
  url VARCHAR(150),
  UNIQUE(provider, resource, version)
);
GRANT SELECT ON catalogue TO reader;
"
psql -U $POSTGRES_USER -d $POSTGRES_DB -c \
"
COPY catalogue(provider, resource, descr, version, url)
FROM '/var/lib/postgresql/init_data/catalogue.csv'
DELIMITER ','
CSV HEADER;
"