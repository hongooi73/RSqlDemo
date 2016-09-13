use sqlDemoLocal
go

drop procedure if exists dbo.clm_scoreGlm
go

create procedure dbo.clm_scoreGlm as
begin
    declare @inquery nvarchar(max)=N'
        select * from clm_modGlm
    '
    insert into claimsSamp_predGlm
    exec sp_execute_external_script @language=N'R', @script=N'
        # unserialise the model
        rdata <- strsplit(as.character(InputDataSet$rdata), "")[[1]]
        rdata <- paste0(rdata[c(TRUE, FALSE)], rdata[c(FALSE, TRUE)])
        rawCont <- memDecompress(as.raw(strtoi(rdata, 16)), "gzip")
        rc <- rawConnection(rawCont, "rb")
        load(rc)
        close(rc)

		connStr <- local({
            db <- yaml::yaml.load_file("c:/sql.yaml")
			sprintf("Driver=SQL Server;Server=%s;database=%s;Uid=%s;Pwd=%s",
					db[[1]]$server, names(db)[1], db[[1]]$user, db[[1]]$password)
		})

        clm <- rxDataStep(RxSqlServerData("claimsSamp", connectionString=connStr))

        Cat <- grep("^Cat", names(clm), value=TRUE)
        woedf <- mapply(function(x, val) val[match(x, names(val))],
            clm[Cat], woe, SIMPLIFY=FALSE)
        names(woedf) <- paste("woe", Cat, sep="_")
        woedf <- cbind(clm, woedf)
        OutputDataSet <- rxPredict(clm_modGlm, woedf)
    ',
    @input_data_1=@inquery
end
