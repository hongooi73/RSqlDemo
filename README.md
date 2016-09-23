## Summary

This is a short (15-20 minute) presentation focused specifically on how Microsoft R Server and SQL Server can be used together. It's based on a demo given originally at the Melbourne SQL Server launch event in September 2016\. It's meant for an audience of mainly R and SQL professionals, so it doesn't mention of Streaming Analytics, HDInsight, AzureML, or any other bits not relevant to the subject at hand. There are minimal dependencies (except for Java); it should be possible to run this on both Windows and Linux. It doesn’t need access to commandline tools like bash, PowerShell or sqlcmd.


## Demo outline

1. Use RSQLServer to access the database. This is to show that all the usual open source packages will still work with Microsoft R. RSQLServer is used instead of RODBC because it includes a dplyr backend, which is coming up next.

2. Because R users are often afraid of SQL, use dplyr to hide the raw queries. Also show how dplyr can keep the results in the database, rather than importing it into the local environment (like with RODBC or base RSQLServer).

3. While using dplyr for ETL or simple analyses is fine, it can’t be used for in-database model fitting. Similarly, importing very large tables into memory has its own problems. Fit a (simple) model in-database using RevoScaleR.

4. Load some more complex model objects (which were fitted offline) and serialise them, along with associated objects needed for scoring. Upload the models to the database.

5. Define and call R in a stored proc to score a table on the server. Do this with both a RevoScaleR and an open source R model (a 20-net neural network ensemble), to show that the approach is broadly applicable.


## Demo Instructions

To setup the demo, see `setup.md`.

The main script file is `R/sqlDemo.R`. Running lines 1 to 70 will demonstrate points 1 to 4 above.

Scoring the RevoScaleR model is done via the files `sql/scoreProc.sql` and `scoreExec.sql`. Run `scoreProc.sql` first to define the stored proc, and then run `scoreExec.sql` to execute it against a 100-row sample.

Similarly, scoring the open source R model is done via the files `sql/scoreProcNN.sql` and `scoreExecNN.sql`. Run lines 79-83 in `sqlDemo.R`, then run `scoreProcNN.sql`, and then `scoreExecNN.sql`.

