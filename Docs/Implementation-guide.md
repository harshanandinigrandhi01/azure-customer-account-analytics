# Implementation Guide

## 1. Azure Storage Account Setup
- Created an Azure Storage Account named `customer_analytics` with **Hierarchical Namespace enabled** to support Azure Data Lake Storage Gen2 capabilities.
- Created separate containers to organize source files and data processing layers: `source`, `bronze`, `silver`, and `gold`.
- Uploaded below five source CSV files into the `source` container. Source Files - `accounts.csv`, `customers.csv`, `loans.csv`, `loan_payments.csv`, `transactions.csv`

## 2. Azure Synapse Analytics Setup
- Created an Azure Synapse Analytics workspace to build and manage the data integration pipeline.
- Configured the required connectivity between Azure Storage and Synapse using linked services and datasets.

## 3. Source-to-Bronze Data Ingestion
- Created a pipeline named `pl_source_to_bronze` in Azure Synapse Analytics.
- Added a **Copy Data activity** to ingest CSV files from the `source` container into the `bronze` container.
- Configured the source dataset with the `*.csv` wildcard pattern to select all matching CSV files.
- Configured the sink dataset to write the copied files to the `bronze` layer.
- Executed the pipeline and verified that all five CSV files were successfully copied from `source` to `bronze`.

![Source-to-Bronze Data Ingestion](Screenshots/Copy_activity.png)

