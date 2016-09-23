use sqlDemoLocal
go

drop table if exists nyctaxi_predGlm;
create table nyctaxi_predGlm (
    tipped_Pred double precision
);

exec nyctaxi_scoreGlm;
select * from nyctaxi_predGlm;

