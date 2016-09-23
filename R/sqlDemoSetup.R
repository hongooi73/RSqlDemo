## R package dependencies:
# RSQLServer
# dplyr
# dplyrXdf (for setup only; get the source from https://github.com/RevolutionAnalytics/dplyrXdf)
## other dependencies:
# 64-bit Java


# update SQL scripts with database name
updateSQLScript <- function(sqlFile)
{
    dbName <- names(yaml::yaml.load_file("sql.yaml")[1])
    lines <- readLines(sqlFile)
    lines[1] <- sprintf("use %s", dbName)
    writeLines(lines, sqlFile)
}

updateSQLScript("sql/scoreProc.sql")
updateSQLScript("sql/scoreProcNN.sql")
updateSQLScript("sql/scoreExec.sql")
updateSQLScript("sql/scoreExecNN.sql")


# sample of NYC taxi ride data, download from Azure blob storage
if(!dir.exists("data")) dir.create(data)
if(!file.exists("data/nyctaxi_sample.csv"))
    download.file("http://getgoing.blob.core.windows.net/public/nyctaxi1pct.csv", "data/nyctaxi_sample.csv")


# import to xdf, convert datetimes from char to POSIXct
library(dplyrXdf)
taxiCsv <- RxTextData("data/nyctaxi_sample.csv")
taxiXdf <- taxiCsv %>%
    mutate(pickup_datetime=as.POSIXct(pickup_datetime),
           dropoff_datetime=as.POSIXct(dropoff_datetime)) %>%
    persist("data/nyctaxi_sample.xdf")


# upload full dataset to database
connStr <- local({
    db <- yaml::yaml.load_file("sql.yaml")
    sprintf("Driver=SQL Server;Server=%s;database=%s;Uid=%s;Pwd=%s",
            db[[1]]$server, names(db)[1], db[[1]]$user, db[[1]]$password)
})
taxiSql <- RxSqlServerData("nyctaxi_sample", connectionString=connStr)
if(!rxSqlServerTableExists("nyctaxi_sample", connStr)) rxDataStep(taxiXdf, taxiSql)

# upload first 100 rows as sample
taxiSamp <- RxSqlServerData("nyctaxi_sample100", connectionString=connStr)
if(!rxSqlServerTableExists("nyctaxi_sample100", connStr)) rxDataStep(taxiXdf, taxiSamp, numRows=100)


# create some derived variables for modelling
source("R/sqlDemoTransformData.R")

# create fitted model objects
source("R/sqlDemoFitModel.R")


