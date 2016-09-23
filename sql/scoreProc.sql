use sqlDemoLocal
go

drop procedure if exists dbo.nyctaxi_scoreGlm
go

create procedure dbo.nyctaxi_scoreGlm
    @modelId nvarchar(50) = '',
    @scoreData nvarchar(50) = ''
as begin
    declare @inquery nvarchar(max)=N'
        select * from ' + quotename(@scoreData);

    declare @rdatabinary varbinary(max)=(
        select top 1
            rdata
        from nyctaxi_models
        where id=@modelId
    )

    insert into nyctaxi_predGlm
    exec sp_execute_external_script @language=N'R', @script=N'
        # unserialise model objects
        rawCont <- memDecompress(as.raw(model), "gzip")
        rc <- rawConnection(rawCont, "rb")
        load(rc)
        close(rc)

        InputDataSet <- within(InputDataSet, {
            direct_distance <- directDistance(pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude)
            is_nighttime_pickup <- isNightTime(pickup_datetime, origin="1970-01-01")
        })

        OutputDataSet <- rxPredict(taxi_modGlm, InputDataSet)
    ',
    @input_data_1=@inquery,
    @params=N'@model varbinary(max)',
    @model=@rdatabinary
end
