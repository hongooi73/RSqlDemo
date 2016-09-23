## Demo files

In the root:
- `sql.yaml`: file containing server credentials

In `R`:
- `sqlDemo.R`: main demo script
- `initModelTable.R`: serialisation code, called by `sqlDemo.R`
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
- dplyrXdf (only for setup)
The first two are available from CRAN. dplyrXdf is available as source from https://github.com/RevolutionAnalytics/dplyrXdf; you can get it via `devtools::install_github`.

Note that the packages above will have their own dependencies but in general running `install.packages()` should be enough. A wart is that RSQLServer works with dplyr 0.4.3 only, and the current dplyr version is 0.5\. The Windows binary for 0.4.3 is [available from CRAN](https://cran.r-project.org/bin/windows/contrib/3.1/dplyr_0.4.3.zip), as is [the source](https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.4.3.tar.gz).

RSQLServer also requires 64-bit Java. The default download from the Oracle website is the 32-bit version; you can get the 64-bit files [here](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html).

To setup the demo:

1. I assume you already have a SQL Server instance available, with R Services installed.
2. Download and install the dependencies listed above.
3. Edit the file `sql.yaml` to contain the server details and credentials for your database. It should be in the following format:
<pre>
    &lt;databaseName&gt;:
        server: &lt;address&gt;
        type: sqlserver
        user: &lt;loginname&gt;
        password: &lt;password&gt;
        port: 1433
</pre>
4. Run `sqlDemoSetup.R`. This will download the NYC taxis sample dataset from Azure blob storage, do some transforms, upload it to SQL, fit the models, and update the SQL scripts with the correct database name. All up, it should take about 20-30 minutes.


## Comments

The data transforms and model fitting are done offline to save time. If you have a big enough time slot and a meaty machine, you can include them in the live demo.


