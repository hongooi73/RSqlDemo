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


# source data from packages.revo
# synthetic dataset (?) of insurance claims
if(!dir.exists("data")) dir.create(data)
download.file("http://packages.revolutionanalytics.com/datasets/claims.xdf", "data/claims.xdf", mode="wb")


# add a has_claim indicator
library(dplyrXdf)
clm <- RxXdfData("data/claims.xdf")
rxDataStep(clm, clm, transforms=list(has_claim=Claim_Amount > 0), overwrite=TRUE)


# upload full dataset to database
connStr <- local({
	db <- yaml::yaml.load_file("sql.yaml")
	sprintf("Driver=SQL Server;Server=%s;database=%s;Uid=%s;Pwd=%s",
			db[[1]]$server, names(db)[1], db[[1]]$user, db[[1]]$password)
})
clmSql <- RxSqlServerData("claims", connectionString=connStr)
if(!rxSqlServerTableExists("claims", connStr)) rxDataStep(clm, clmSql)

# upload first 100 rows as sample
clmSqlSamp <- RxSqlServerData("claimsSamp", connectionString=connStr)
if(!rxSqlServerTableExists("claimsSamp", connStr)) rxDataStep(clm, clmSqlSamp, numRows=100)


# create some derived variables for modelling
source("R/sqlDemoTransformData.R")

# create fitted model objects
source("R/sqlDemoFitModel.R")


