call website.estat_import_dictinary('indic_in')

DROP TABLE tmpDictionary;
CREATE TEMPORARY TABLE IF NOT EXISTS tmpDictionary(id SERIAL PRIMARY KEY, result_json TEXT);
CREATE TEMPORARY TABLE IF NOT EXISTS tmpDictionary( result_json TEXT);
TRUNCATE TABLE tmpDictionary restart identity;
	
copy tmpDictionary(result_json) from program  'curl "https://dd.eionet.europa.eu/vocabulary/eurostat/indic_in/json"' WITH csv  DELIMITER E'\007' ESCAPE  E'\'' QUOTE  E'\''

select * from tmpDictionary
create temporary  table  tmpDictionary_2 as select * from tmpDictionary 
	
SELECT 
	(string_agg(result_json,''))::JSONB jj 
FROM 
	tmpDictionary ;		  

select * from tmpDictionary where lower(result_json) ilike '%world%'

      --"@value" : "Enterprises that introduced at least one "world first" product innovation"",

	  create temporary table tmpTest  (id serial primary key, tekst TEXT)

	  select * from tmpTest

	  insert into tmpTest(tekst) values ('"@value" : "Enterprises that introduced at least one \"world first\" product innovation\"",')