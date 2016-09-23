initModelTable <- function(modelTable, connectionString=NULL)
{
    dest <- RxOdbcData(sqlQuery="select 1", connectionString=connectionString)
    rxOpen(dest, mode="r")
    rxExecuteSQLDDL(dest, sSQLString=sprintf("drop table if exists %s", modelTable))
    rxExecuteSQLDDL(dest, sSQLString=sprintf("create table %s (id nvarchar(50), rdata varbinary(max))",
        modelTable))
    rxClose(dest)
}
