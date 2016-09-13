## source() this from sqlDemoSetup.R


# use weights of evidence methodology for categorical variables
# ref: http://ucanalytics.com/blogs/information-value-and-weight-of-evidencebanking-case/
Cat <- grep("^Cat", names(clm), value=TRUE)
woe_table <- sapply(Cat, function(x) {
        clm %>% group_by_(x) %>% summarise(n=n(), bad=sum(has_claim)) %>%
            as.data.frame
    }, simplify=FALSE)

# this object will be used in scoring
woe <- lapply(woe_table, function(woe_df) {
        woe <- with(woe_df, {
            N <- sum(n)
            Nbad <- sum(bad)
            Dgood <- (n - bad)/(N - Nbad)
            Dbad <- bad/Nbad
            log(Dgood/Dbad)
        })
        names(woe) <- woe_df[[1]]
        woe
    })

# put derived variables on to modelling dataset
clm_woe <- clm %>%
    mutate(.rxArgs=list(
        transformFunc=function(varlst) {
            woelst <- mapply(function(x, val) val[match(x, names(val))],
                varlst, .woe, SIMPLIFY=FALSE)
            names(woelst) <- paste("woe", names(varlst), sep="_")
            c(varlst, woelst)
        },
        transformVars=Cat,
        transformObjects=list(.woe=woe))) %>%
    persist("data/clm_woe.xdf")
