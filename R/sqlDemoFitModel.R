## source() this from sqlDemoSetup.R


# model fitting offline: logistic regression
# can also include this in live demo if your machine is powerful enough
Var <- grep("^Var", names(clm_woe), value=TRUE)
Woe <- grep("^woe", names(clm_woe), value=TRUE)
fm <- formula(paste("has_claim ~", paste(c(Var, Woe), collapse="+")))
clm_modGlm <- rxGlm(fm, data=clm_woe, family=binomial)

# need this hack to shrink saved model object to a more reasonable size
# by default, parent of stored env includes copies of RevoScaleR, utils, stats, methods, base packages (!)
parent.env(clm_modGlm$params$env) <- new.env()
save(clm_modGlm, woe, file="data/clm_modGlm.rdata")


# model fitting offline: neural network ensemble
# use a stratified subset of the data for open source R
clmdf <- clm_woe %>% filter(ifelse(has_claim, TRUE, runif(.rxNumRows) < 0.01)) %>%
    as.data.frame
save(clmdf, file="data/clmdf.rdata")

# fit ensemble in parallel
rxSetComputeContext("localpar")
clm_modNN <- rxExec(function(x, .formula, .data) {
        obj <- nnet(.formula, .data, size=5, entropy=TRUE, skip=TRUE, maxit=500,
            reltol=1e-6)
        obj$residuals <- obj$fitted.values <- NULL
        environment(obj$terms) <- globalenv()
        obj
    }, x=rxElemArg(1:20), .formula=fm, .data=clmdf,
    packagesToLoad="nnet")
rxSetComputeContext("local")
save(clm_modNN, woe, file="data/clm_modNN.rdata")
