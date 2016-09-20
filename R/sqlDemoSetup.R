# globally visible sql.yaml location (for R Services)
RServicesYamlLocation <- "c:/"

## R package dependencies:
# RSQLServer
# yaml
# dplyr
# dplyrXdf (for setup only; get the source from https://github.com/RevolutionAnalytics/dplyrXdf)
## other dependencies:
# 64-bit Java


# update SQL scoring scripts with login details
updateSQLScript <- function(sqlFile, RServicesYamlLocation)
{
    dbName <- names(yaml::yaml.load_file("sql.yaml")[1])
    lines <- readLines(sqlFile)
    lines[1] <- sprintf("use %s", dbName)
    RServicesYamlLocation <- normalizePath(file.path(RServicesYamlLocation, "sql.yaml"),
        winslash="/", mustWork=FALSE)
    lines <- gsub("c:/sql.yaml", RServicesYamlLocation, lines, fixed=TRUE)
    writeLines(lines, sqlFile)
}

updateSQLScript("sql/scoreProc.sql", RServicesYamlLocation)
updateSQLScript("sql/scoreProcNN.sql", RServicesYamlLocation)
updateSQLScript("sql/scoreExec.sql", RServicesYamlLocation)
updateSQLScript("sql/scoreExecNN.sql", RServicesYamlLocation)


# source data from Azure blob storage
# sample of NYC taxi ride data
if(!dir.exists("data")) dir.create(data)
if(!file.exists("data/nyctaxis_sample.csv"))
    download.file("http://getgoing.blob.core.windows.net/public/nyctaxi1pct.csv", "data/nyctaxi_sample.csv")


# convert to xdf
library(dplyrXdf)
taxiCsv <- RxTextData("data/nyctaxi_sample.csv")
taxiXdf <- taxiCsv %>%
    mutate(pickup_datetime=as.POSIXct(pickup_datetime),
           dropoff_datetime=as.POSIXct(dropoff_datetime))


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


