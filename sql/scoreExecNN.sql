use claimsDemoLocal
go

drop table if exists claimsSamp_predNN;
create table claimsSamp_predNN (
    has_claim_Pred double precision
);

exec clm_scoreNN;
select * from claimsSamp_predNN;

