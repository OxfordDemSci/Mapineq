select * from "BD_SIZE_R3" limit 100;

select count(*) from "BD_SIZE_R3";

select distinct "obsTime" FROm "BD_SIZE_R3";

select * from catalogue where resource ='BD_SIZE_R3';

https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/BD_SIZE_R3

https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/bd_size_r3?format=SDMX-CSV&compressed=false

select * FROM load_csv_file_curl('ronnie','BD_SIZE_R3','https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/bd_size_r3?format=SDMX-CSV', ','::TEXT,bHeaderRow := TRUE,bAllText := FALSE);
select * FROM load_csv_file_curl('ronnie','BD_SIZE_R3','file:///c:/projects/mapineq/eurostat_data/test.csv', ','::TEXT,bHeaderRow := FALSE,bAllText := FALSE);

select * from ronnie."bd_size_r3"

drop table ronnie.bd_size_r3

select * from postgisftw.get_all_sources()

curl --range 0-99 https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/bd_size_r3?format=SDMX-CSV

select * from tmpHeaderRow limit 1

DATAFLOW,LAST UPDATE,freq,indic_sb,sizeclas,nace_r2,geo,TIME_PERIOD,OBS_VALUE,OBS_FLAG