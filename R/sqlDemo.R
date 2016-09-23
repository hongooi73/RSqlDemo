### demonstrate use of open source R to access SQL
# Microsoft R Server is built on the open source platform, so all packages continue to work
library(RSQLServer)
dbName <- names(yaml::yaml.load_file("sql.yaml")[1])
db <- src_sqlserver(dbName, file="sql.yaml", database=dbName)


# sending raw T-SQL to the database, getting results back via JDBC
dbGetQuery(db$con, "select top 10 * from nyctaxi_sample")
dbGetQuery(db$con, "select count(*) as [n] from nyctaxi_sample")
dbGetQuery(db$con, "select vendor_id, count(*) as [count], sum(tipped) as [tipped]
                    from nyctaxi_sample
                    group by vendor_id")


# using dplyr: hiding the SQL
library(dplyr)
taxiSql <- tbl(db, "nyctaxi_sample")

tally(taxiSql)
taxiSql %>%
    group_by(vendor_id) %>%
    summarise(count=n(), tipped=sum(tipped)) %>%
    collect

# dplyr has the ability to leave results in the database
taxiSqlSubset <- taxiSql %>%
    filter(vendor_id == "CMT") %>%
    mutate(amount=fare_amount + tolls_amount + tip_amount) %>%
    select(medallion, hack_license, amount) %>%
    compute
print(taxiSqlSubset)


### fitting a model
tbl_vars(taxiSql)
fm <- fare_amount ~ passenger_count + trip_time_in_secs + trip_distance + passenger_count

## Not run: import the data from SQL Server, fit a model
## requires enough memory to fit the data
#taxiDf <- collect(taxiSql)
#lm(fm, data=taxiDf)

# using RevoScaleR to fit the model in database
# no data movement to the client
connStr <- local({
    db <- yaml::yaml.load_file("sql.yaml")[[dbName]]
    sprintf("Driver=SQL Server;Server=%s;database=%s;Uid=%s;Pwd=%s",
            db$server, dbName, db$user, db$password)
})

taxiRxSql <- RxSqlServerData("nyctaxi_sample", connectionString=connStr)  # data source
ccSql <- RxInSqlServer(connectionString=connStr)                          # compute context

rxSetComputeContext(ccSql)                                                # set the compute context
rxLinMod(fm, data=taxiRxSql)                                              # fit the model
rxSetComputeContext("local")                                              # reset the compute context


### save/serialise a fitted model into the database, along with associated objects for scoring
load("data/taxi_modGlm.rdata")
summary(taxi_modGlm)
print(directDistance)
print(isNightTime)

source("R/initModelTable.R")
source("R/saveModelObjects.R")
initModelTable("nyctaxi_models", connectionString=connStr)
saveModelObjects(taxi_modGlm, directDistance, isNightTime,
                 modelId="taxi_modGlm", modelTable="nyctaxi_models", connectionString=connStr)

# verify that serialisation worked
dbGetQuery(db$con, "select * from nyctaxi_models where id='taxi_modGlm'")


### scoring will be done in SQL ###
# run scoreProc.sql and scoreExec.sql


# the same, but with a complicated model fitted using open source R
# ensemble of 20 single-layer neural networks with 5 hidden nodes each
library(nnet)
load("data/clm_modNN.rdata")
print(clm_modNN)

saveModelObjects(taxi_modNN, directDistance, isNightTime,
                 modelId="taxi_modNN", modelTable="nyctaxi_models", connectionString=connStr)


# run scoreProcNN.sql and scoreExecNN.sql
