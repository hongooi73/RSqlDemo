use sqlDemoLocal
go

drop table if exists nyctaxi_predNN;
create table nyctaxi_predNN (
    tipped_Pred double precision
);

exec nyctaxi_scoreNN;
select * from nyctaxi_predNN;

