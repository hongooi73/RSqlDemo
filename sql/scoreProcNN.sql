use sqlDemoLocal
go

drop procedure if exists dbo.nyctaxi_scoreNN
go

create procedure dbo.nyctaxi_scoreNN
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

    insert into nyctaxi_predNN
    exec sp_execute_external_script @language=N'R', @script=N'
        predict_modNN <- function(obj, data)
        {
            require(nnet)
            preds <- sapply(obj, predict, data)
            data.frame(tipped_pred=rowMeans(preds))
        }

        # unserialise the model
        rawCont <- memDecompress(as.raw(model), "gzip")
        rc <- rawConnection(rawCont, "rb")
        load(rc)
        close(rc)

        InputDataSet <- within(InputDataSet, {
            direct_distance <- directDistance(pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude)
            is_nighttime_pickup <- isNightTime(pickup_datetime, origin="1970-01-01")
        })

        OutputDataSet <- predict_modNN(taxi_modNN, InputDataSet)
    ',
    @input_data_1=@inquery,
    @params=N'@model varbinary(max)',
    @model=@rdatabinary
end



