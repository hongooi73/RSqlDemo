use sqlDemoLocal
go

drop table if exists nyctaxi_predNN;
create table nyctaxi_predNN (
    tipped_Pred double precision
);

exec nyctaxi_scoreNN @modelId=N'taxi_modNN', @scoreData=N'nyctaxi_sample100';;
select * from nyctaxi_predNN;

