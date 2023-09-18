psql -U $POSTGRES_USER -d $POSTGRES_DB -c \
"
CREATE ROLE reader LOGIN PASSWORD '${POSTGRES_RPASS}';

CREATE TABLE IF NOT EXISTS NUTS(
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

CREATE TABLE IF NOT EXISTS catalogue(
  id SERIAL PRIMARY KEY,
  provider VARCHAR(5),
  resource VARCHAR(40),
  descr VARCHAR(300),
  version VARCHAR(20),
  url VARCHAR(150),
  UNIQUE(provider, resource, version)
);
GRANT SELECT ON catalogue TO reader;

CREATE TABLE IF NOT EXISTS ozone_uv_1(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_1 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_2(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_2 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_3(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_3 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_4(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_4 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_5(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_5 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_6(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_6 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_7(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_7 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_8(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_8 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_9(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_9 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_10(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_10 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_11(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_11 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_12(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_12 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_13(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_13 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_14(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_14 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_15(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_15 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_16(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_16 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_17(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_17 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_18(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_18 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_19(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_19 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_20(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_20 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_21(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_21 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_22(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_22 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_23(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_23 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_24(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_24 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_25(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_25 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_26(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_26 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_27(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_27 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_28(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_28 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_29(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_29 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_30(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_30 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_31(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_31 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_32(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_32 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_33(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_33 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_34(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_34 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_35(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_35 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_36(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_36 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_37(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_37 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_38(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_38 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_39(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_39 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_40(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_40 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_41(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_41 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_42(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_42 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_43(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_43 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_44(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_44 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_45(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_45 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_46(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_46 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_47(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_47 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_48(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_48 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_49(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_49 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_50(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_50 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_51(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_51 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_52(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_52 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_53(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_53 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_54(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_54 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_55(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_55 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_56(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_56 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_57(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_57 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_58(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_58 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_59(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_59 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_60(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_60 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_61(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_61 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_62(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_62 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_63(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_63 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_64(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_64 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_65(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_65 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_66(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_66 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_67(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_67 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_68(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_68 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_69(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_69 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_70(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_70 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_71(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_71 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_72(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_72 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_73(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_73 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_74(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_74 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_75(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_75 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_76(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_76 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_77(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_77 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_78(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_78 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_79(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_79 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_80(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_80 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_81(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_81 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_82(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_82 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_83(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_83 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_84(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_84 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_85(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_85 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_86(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_86 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_87(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_87 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_88(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_88 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_89(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_89 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_90(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_90 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_91(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_91 TO reader;
CREATE TABLE IF NOT EXISTS ozone_uv_92(
      X DECIMAL(5, 3),
      Y DECIMAL(5, 3),
      data_payload_id VARCHAR(6),
      platform_id VARCHAR(3),
      instance_datetime TIMESTAMP(0),
      url VARCHAR(1000),
      dataset VARCHAR(100),
      platform_type VARCHAR(10),
      instrument_name VARCHAR(10),
      processed_datetime TIMESTAMP(0),
      gaw_id VARCHAR(10),
      platform_name VARCHAR(10),
      country VARCHAR(3),
      scientific_authority VARCHAR(100),
      version SMALLINT
    );
    GRANT SELECT ON ozone_uv_92 TO reader;
    
CREATE TABLE IF NOT EXISTS oproad_gb(
      id VARCHAR(50),
      jnctn_n VARCHAR(15),
      geometry POINT
    );
    GRANT SELECT ON oproad_gb TO reader;
    
CREATE TABLE IF NOT EXISTS glwd_1(
      GLWD_ID SMALLINT,
      TYPE VARCHAR(10),
      LAKE_NAME VARCHAR(100),
      DAM_NAME VARCHAR(100),
      POLY_SRC VARCHAR(100),
      AREA_SKM INT,
      PERIM_KM INT,
      LONG_DEG DECIMAL(2, 1),
      LAT_DEG DECIMAL(2, 1),
      ELEV_M INT,
      CATCH_TSKM INT,
      INFLOW_CMS G DECIMAL(4, 1),
      VOLUME_CKM INT,
      VOL_SRC VARCHAR(100),
      COUNTRY VARCHAR(100),
      SEC_CNTRY VARCHAR(100),
      RIVER VARCHAR(100),
      NEAR_CITY VARCHAR(100),
      MGLD_TYPE VARCHAR(10),
      MGLD_AREA INT,
      LRS_AREA INT,
      LRS_AR_SRC VARCHAR(100),
      LRS_CATCH INT,
      DAM_HEIGHT INT,
      DAM_YEAR INT,
      USE_1 VARCHAR(10),
      USE_2 VARCHAR(10),
      USE_3 VARCHAR(10),
      geometry MULTIPOLYGON
    );
    GRANT SELECT ON glwd_1 TO reader;
    
CREATE TABLE IF NOT EXISTS natural_earth(
      type VARCHAR(10),
      scalerank SMALLINT,
      featurecla VARCHAR(100),
      ne_id INT(10),
      BRK_A3 BIGINT,
      geometry LINESTRING
    );
    GRANT SELECT ON natural_earth TO reader;

CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_01(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_01 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_02(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_02 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_03(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_03 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_04(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_04 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_05(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_05 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_06(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_06 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_07(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_07 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_08(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_08 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_09(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_09 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_10(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_10 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_11(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_11 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_prec_12(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      precipitation INT
    );
    GRANT SELECT ON wc2.1_30s_prec_12 TO reader;

CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_01(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_01 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_02(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_02 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_03(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_03 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_04(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_04 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_05(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_05 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_06(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_06 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_07(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_07 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_08(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_08 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_09(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_09 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_10(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_10 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_11(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_11 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_srad_12(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      solar_radiation INT
    );
    GRANT SELECT ON wc2.1_30s_srad_12 TO reader;

CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_01(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_01 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_02(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_02 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_03(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_03 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_04(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_04 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_05(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_05 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_06(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_06 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_07(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_07 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_08(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_08 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_09(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_09 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_10(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_10 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_11(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_11 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tavg_12(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      average_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tavg_12 TO reader;

CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_01(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_01 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_02(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_02 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_03(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_03 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_04(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_04 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_05(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_05 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_06(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_06 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_07(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_07 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_08(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_08 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_09(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_09 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_10(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_10 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_11(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_11 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmax_12(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      maximum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmax_12 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_01(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_01 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_02(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_02 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_03(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_03 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_04(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_04 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_05(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_05 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_06(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_06 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_07(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_07 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_08(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_08 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_09(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_09 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_10(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_10 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_11(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_11 TO reader;
CREATE TABLE IF NOT EXISTS wc2.1_30s_tmin_12(
      x DECIMAL(3, 5),
      y DECIMAL(3, 5),
      minimum_temperature INT
    );
    GRANT SELECT ON wc2.1_30s_tmin_12 TO reader;
CREATE TABLE IF NOT EXISTS earthdata_vnp46a4 (
    year INTEGER,
    composite FLOAT8,
    num INTEGER,
    quality INTEGER,
    std FLOAT8,
    snow BOOLEAN,
    angle TEXT,
    mask INTEGER,
    platform INTEGER,
    geom GEOGRAPHY(POINT, 4326)
);
GRANT SELECT ON earthdata_vnp46a4 TO reader;

"
psql -U $POSTGRES_USER -d $POSTGRES_DB -c \
"
COPY catalogue(provider, resource, descr, version, url)
FROM '/var/lib/postgresql/init_data/catalogue.csv'
DELIMITER ','
CSV HEADER;
"