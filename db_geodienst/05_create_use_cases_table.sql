CREATE TABLE website.use_cases
(
	id				SERIAL,
	use_case		INTEGER,
	short_descr		TEXT,
	long_descr		TEXT,
	parameters		JSONB,
    case_options 	JSONB,
    CONSTRAINT pk_use_cases PRIMARY KEY (id)
);

