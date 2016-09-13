### demonstrate use of open source R to access SQL
# Microsoft R Server is built on the open source platform, so all packages continue to work
library(RSQLServer)
dbName <- names(yaml::yaml.load_file("sql.yaml")[1])
db <- src_sqlserver(dbName, file="sql.yaml", database=dbName)


# sending raw T-SQL to the database, getting results back via JDBC
dbGetQuery(db$con, "select top 10 * from claims")
dbGetQuery(db$con, "select count(*) as [n] from claims")
dbGetQuery(db$con, "select Cat1, count(*) as [count], sum(cast(has_claim as int)) as [has_claim]
                    from claims
                    group by Cat1")


# using dplyr: hiding the SQL
library(dplyr)
clmSql <- tbl(db, "claims")

tally(clmSql)
clmSql %>%
    group_by(Cat1) %>%
    summarise(count=n(), has_claim=sum(as.integer(has_claim))) %>%
    collect

# dplyr has the ability to leave results in the database
clmSqlSubset <- clmSql %>%
    filter(Calendar_Year == 2005) %>%
    mutate(newVar=Var1 + Var2) %>%
    select(Row_ID, Household_ID, newVar) %>%
    compute
print(clmSqlSubset)


### fitting a model
tbl_vars(clmSql)
Var <- grep("^Var", tbl_vars(clmSql), value=TRUE)
fm <- formula(paste("has_claim ~", paste(Var, collapse="+")))

## Not run: import the data into memory, fit a model
# this will break the JDBC layer
#clmDf <- collect(clmSql)
#lm(fm, data=clmDf)

# using RevoScaleR to fit the model in database
# no data movement to the client
connStr <- local({
    db <- yaml::yaml.load_file("sql.yaml")[[dbName]]
    sprintf("Driver=SQL Server;Server=%s;database=%s;Uid=%s;Pwd=%s",
            db$server, dbName, db$user, db$password)
})

clmRx <- RxSqlServerData("claims", connectionString=connStr)  # data source
ccSql <- RxInSqlServer(connectionString=connStr)              # compute context

rxSetComputeContext(ccSql)                                    # set the compute context
rxLinMod(fm, data=clmRx)                                      # fit the model
rxSetComputeContext("local")                                  # reset the compute context


### save/serialise a fitted model into the database, along with associated objects for scoring
load("data/clm_modGlm.rdata")
summary(clm_modGlm)
print(woe)

source("R/saveModelObjects.R")
saveModelObjects(clm_modGlm, woe, destTable="clm_modGlm", connectionString=connStr)

# verify that serialisation worked
dbGetQuery(db$con, "select * from clm_modGlm")


### scoring will be done in SQL ###
# run scoreProc.sql and scoreExec.sql


# the same, but with a complicated model fitted using open source R
# ensemble of 20 single-layer neural networks with 5 hidden nodes each
library(nnet)
load("clm_modNN.rdata")
print(clm_modNN)

saveModelObjects(clm_modNN, woe, destTable="clm_modNN", connectionString=connStr)


# run scoreProcNN.sql and scoreExecNN.sql
