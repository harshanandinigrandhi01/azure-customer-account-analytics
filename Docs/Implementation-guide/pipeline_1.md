# Source-to-Bronze Data Ingestion
- Created a pipeline named `pl_source_to_bronze` in Azure Synapse Analytics.
- Added a **Copy Data activity** to ingest CSV files from the `source` container into the `bronze` container.
- Configured the source dataset with the `*.csv` wildcard pattern to select all matching CSV files.
- Configured the sink dataset to write the copied files to the `bronze` layer.
- Executed the pipeline and verified that all five CSV files were successfully copied from `source` to `bronze`.

![Source-to-Bronze Data Ingestion](Screenshots/Copy_activity.png)