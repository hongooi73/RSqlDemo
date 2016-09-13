## Summary

This is a short (15-20 minute) presentation focused specifically on how Microsoft R Server and SQL Server can be used together. It was given originally at the Melbourne SQL Server launch event in September 2016\. It's meant for an audience of mainly SQL professionals, so it doesn't mention of Streaming Analytics, HDInsight, AzureML, or any other bits not relevant to the subject at hand. There are minimal dependencies (except for Java); it should be possible to run this on both Windows and Linux. It doesn’t need access to commandline tools like bash, PowerShell or sqlcmd.


## Demo outline

1. Use RSQLServer to access the database. This is to show that all the usual open source packages will still work with Microsoft R. RSQLServer is used instead of RODBC because it includes a dplyr backend, which is coming up next.

2. Because R users are often afraid of SQL, use dplyr to hide the raw queries. Also show how dplyr can keep the results in the database, rather than importing it into the local environment (like with RODBC or base RSQLServer).

3. While using dplyr for ETL or simple analyses is fine, it can’t be used for in-database model fitting. Similarly, importing very large tables into memory has its own problems. Fit a (simple) model in-database using RevoScaleR.

4. Load some more complex model objects (which were fitted offline) and serialise them, along with associated objects needed for scoring. Upload the models to the database.

5. Define and call R in a stored proc to score a table on the server. Do this with both a RevoScaleR and an open source R model (a 20-net neural network ensemble), to show that the approach is broadly applicable.


## Demo Instructions

The main script file is `R/sqlDemo.R`. Running lines 1 to 70 will demonstrate points 1 to 4 above.

Scoring the RevoScaleR model is done via the files `sql/scoreProc.sql` and `scoreExec.sql`. Run `scoreProc.sql` first to define the stored proc, and then run `scoreExec.sql` to execute it against a 100-row sample.

Similarly, scoring the open source R model is done via the files `sql/scoreProcNN.sql` and `scoreExecNN.sql`. Run lines 79-83 in `sqlDemo.R`, then run `scoreProcNN.sql`, and then `scoreExecNN.sql`.


## Demo files

In the root:
- `sql.yaml`: file containing server credentials

In `R`:
- `sqlDemo.R`: main demo script
- `saveModelObjects.R`: serialisation code, called by `sqlDemo.R`
- `sqlDemoSetup.R`: setup script
- `sqlDemoFitModel.R`: fit models, called by `sqlDemoSetup.R`
- `sqlDemoTransformData.R`: create some derived variables for modelling, called by `sqlDemoSetup.R`

In `sql`:
- `scoreProc.sql`: define a stored procedure for scoring a logistic regression model
- `scoreExec.sql`: execute stored proc defined in `scoreProc.sql`
- `scoreProcNN.sql`: define a stored proc for scoring a neural network ensemble
- `scoreExecNN.sql`: execute stored proc defined in `scoreProcNN.sql`


## Setup instructions

The demo has the following R package dependencies:
- RSQLServer
- dplyr
- yaml
- dplyrXdf (only for setup)
The first 3 are available from CRAN. dplyrXdf is available as source from https://github.com/RevolutionAnalytics/dplyrXdf; you can get it via `devtools::install_github`.

Note that the packages above will have their own dependencies but in general running `install.packages()` should be enough. A wart is that RSQLServer works with dplyr 0.4.3 only, and the current dplyr version is 0.5\. The Windows binary for 0.4.3 is [available from CRAN](https://cran.r-project.org/bin/windows/contrib/3.1/dplyr_0.4.3.zip), as is [the source](https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.4.3.tar.gz).

RSQLServer also requires 64-bit Java. The default download from the Oracle website is the 32-bit version; you can get the 64-bit files [here](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html).

To setup the demo:

1. Download and install the dependencies listed above.
2. I assume you already have a SQL Server instance available, with R Services installed. If R Services isn’t setup to use the same R library folder as R Server (which is the default), install the yaml package into your R Services library folder as well.
3. Edit the file `sql.yaml` to contain the server details and credentials for your database. It should be in the following format:
<pre>
    &lt;databaseName&gt;:
        server: &lt;address&gt;
        type: sqlserver
        user: &lt;loginname&gt;
        password: &lt;password&gt;
        port: 1433
</pre>
4. Copy `sql.yaml` to a location where R Services can see it when run from SQL (_not_ into anywhere under your user directory tree, for instance).
5. Open the file `R/sqlDemoSetup.R`; in line 2, change `"c:/"` to the location where you copied `sql.yaml`.
6. Run `sqlDemoSetup.R`. This will download the claims dataset from packages.revolutionanalytics.com, do some transforms, upload it to SQL, fit the models, and update the SQL scripts with the correct login details. All up, it should take about 30 minutes to a couple of hours.


## Comments

The data transforms and model fitting are done offline to save time (the dataset is 13 million rows, ~3GB uncompressed). If you have a big enough time slot and a meaty machine, you can include them in the live demo.

The object serialisation/deserialisation functions are some hacks I ([Hong](mailto:hongooi@microsoft.com)) wrote a while back. I’m not sure where we’re at with recommended code for this. In any case, changing the code shouldn’t be too difficult.

