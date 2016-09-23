## source() this from sqlDemoSetup.R


# model fitting offline: logistic regression
# can also include this in live demo if your machine is powerful enough
xvars <- grep("tip", tbl_vars(taxiFeaturesXdf), invert=TRUE, value=TRUE)
fm <- formula(paste("tipped ~", paste(xvars, collapse="+")))
taxi_modGlm <- rxGlm(fm, data=taxiFeaturesXdf, family=binomial)

# need this hack to shrink saved model object to a more reasonable size
# by default, parent of stored env includes copies of RevoScaleR, utils, stats, methods, base packages (!)
parent.env(taxi_modGlm$params$env) <- new.env()
save(taxi_modGlm, directDistance, isNightTime, file="data/taxi_modGlm.rdata")


# model fitting offline: neural network ensemble
# use a 10% subset of the data for open source R
taxiDf <- taxiFeaturesXdf %>% filter(runif(.rxNumRows) < 0.1) %>% as.data.frame
save(taxiDf, file="data/taxiDf.rdata")

# fit ensemble in parallel
rxSetComputeContext("localpar")
taxi_modNN <- rxExec(function(x, .formula, .data) {
        obj <- nnet(.formula, .data, size=5, entropy=TRUE, skip=TRUE, maxit=500,
            reltol=1e-6)
        obj$residuals <- obj$fitted.values <- NULL
        environment(obj$terms) <- globalenv()
        obj
    }, x=rxElemArg(1:20), .formula=fm, .data=taxiDf,
    packagesToLoad="nnet")
rxSetComputeContext("local")
save(taxi_modNN, directDistance, isNightTime, file="data/taxi_modNN.rdata")
