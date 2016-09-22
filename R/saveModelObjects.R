saveModelObjects <- function(..., id, connectionString=NULL)
{
    objnames <- as.character(substitute(list(...)))[-1]

    rc <- rawConnection(raw(0), open="wb")
    save(list=objnames, file=rc, envir=parent.frame(2))
    rdata <- paste(memCompress(rawConnectionValue(rc)), collapse="")
    close(rc)

    dest <- RxOdbcData(sqlQuery="select 1", connectionString=connectionString)
    rxOpen(dest, mode="r")
    rxExecuteSQLDDL(dest, sSQLString=sprintf("exec RSqlSaveModel @id='%s' @model='%s'", id, rdata))
    rxClose(dest)
}

#m <- lm(mpg ~ ., mtcars)
#rc <- memCompress(serialize(m, connection=NULL))
#ch <- paste(rc, collapse="")

