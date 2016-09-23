use sqlDemoLocal
go

drop table if exists nyctaxi_predGlm;
create table nyctaxi_predGlm (
    tipped_Pred double precision
);

exec nyctaxi_scoreGlm @modelId=N'taxi_modGlm', @scoreData=N'nyctaxi_sample100';
select * from nyctaxi_predGlm;

