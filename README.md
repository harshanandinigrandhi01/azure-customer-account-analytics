# Data Pipeline for Customer Account Analysis

## Project Overview
This project implements an end-to-end data pipeline to process customer account data using Microsoft Azure services.

## Objectives
- Ingest source CSV files into Azure Data Lake Storage (Bronze layer).
- Clean and transform data using Azure Data Factory.
- Prepare curated and business-ready data in Silver and Gold layers.
- Load data into Azure SQL Database using SCD Type 1 upsert logic.
- Build a Power BI dashboard for customer account analysis.
- Secure credentials using Azure Key Vault.

## Technologies Used
- Azure Data Factory (ADF)
- Azure Data Lake Storage Gen2 (ADLS Gen2)
- Azure SQL Database
- Azure Key Vault
- Power BI
- Git and GitHub

## Source Files
- accounts.csv
- customers.csv
- loans.csv
- loan_payments.csv
- transactions.csv

## Pipeline Architecture
Source CSV Files → Bronze (Raw) → Silver (Cleaned) → Gold (Business-Ready) → Azure SQL Database → Power BI

## Implementation Steps
1. Data ingestion from source storage into Bronze.
2. Data cleaning and validation in Silver.
3. Data transformation and Gold layer preparation.
4. SCD Type 1 upsert into Azure SQL Database.
5. Data validation and testing.
6. Power BI dashboard creation.

## Project Status
In Progress

## Key Learnings
To be updated as the project progresses.