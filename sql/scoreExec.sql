use claimsDemoLocal
go

drop table if exists claimsSamp_predGlm;
create table claimsSamp_predGlm (
    has_claim_Pred double precision
);

exec clm_scoreGlm;
select * from claimsSamp_predGlm;

