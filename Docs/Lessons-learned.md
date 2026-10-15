This section documents the challenges encountered during the project and the new concepts and technologies explored throughout the implementation.

### 1. Azure Storage Account Deployment Challenges

**Issue:** The Azure Storage Account deployment did not complete successfully in the initially selected region.

**Possible Cause:** The failure may have been related to temporary regional capacity constraints or service availability. However, the exact cause was not confirmed.

**Resolution:** Reviewed the deployment issue and proceeded with an alternative region where the required resources could be created successfully.

**Lesson Learned:** Azure resource deployment can be affected by regional capacity and service availability. When a deployment fails, review the deployment error details before identifying the root cause, and consider an alternative region if appropriate. Also, verify service availability, pricing, and resource requirements before deploying.

### 2. Dynamic File Name and Primary Key Mapping

**Challenge:** Dynamically determining the primary key column name for different CSV files during data processing.

**Approach 1 – Dynamic Expression:**  
Used the **Get Metadata**, **ForEach**, and **Set Variable** activities in Azure Synapse Pipelines.

- Configured Get Metadata to retrieve the file list from the source folder.
- Used ForEach to iterate through the returned file metadata.
- Created a pipeline-level variable named `pk` to store the derived primary key column name.
- Used a dynamic expression to generate the primary key name from each file name. For example, `customers.csv` was converted to `customer_id`.

**Approach 2 – Configuration-Based Mapping:**  
Explored a more maintainable approach by storing file names and their corresponding primary key column names in a configuration file in the Bronze container.

**Lesson Learned:**  
Although primary key names can be derived dynamically from file names, naming conventions may vary across datasets. A configuration-driven approach provides greater flexibility, improves maintainability, and allows file-specific mappings to be managed without modifying pipeline expressions.

**Outcome:** Adopted the configuration-based approach to manage file-to-primary-key mappings.

![Dynamic File Name and Primary Key Mapping](Screenshots/Dynamic File Name.png)

### 3. Cleaning the Data Challanges

| Issue | Cause | Fix / lesson |
|---|---|---|
| `customers.csv` not accepted as debug value | Parameter values are expressions | Use quotes: `'customers.csv'` |
| "Allow schema drift" option missing | Only exists for Integration datasets | Inline sources already accept any columns |
| "Type mismatch" in casttypes | Expression put in the column-name box; column types unknown at design time | Name box = `$$`; wrap values in `toString($$)` |
| Dates came out null | Format letters are case-sensitive (`YYYY`/`DD` ≠ `yyyy`/`dd`) | Use `yyyy-MM-dd`; `MM` = month, `mm` = minutes |
| Dates looked like `14-01-2024` | Excel re-displays dates in the PC's local format | Inspect raw data in Notepad or ADF Data preview, never Excel |
| Warning on `byName` in validate | Return type unknown at design time | `toString(byName($pkvalue))` |
| Silver-layer data stored as a Delta table instead of a single file | Delta format stores data in a folder containing multiple Parquet files and a transaction log. Spark writes data in parallel across multiple files. | Use Delta format, Remember that a Delta table is a folder, not a single file. |

### Business Needs :

| Issue | Cause | Fix / lesson |
|---|---|---|
| "Column not found" in gold flows | No schema imported on the source | Click **Import schema** in table-specific flows (the generic silver flow is the only one without it) |
| Helper `pk` column showed up in silver tables | Fixed mapping in a generic Select can't drop a drifted column | Rule-based mapping `name != 'pk'` in silver; deleted the old silver folders and reran p2 |
| Import schema showed no data | Dims hadn't been run yet | Debug-run upstream flows first |
| Totals 3× too high (planned joins) | **Fan-out:** joining a customer to 2 accounts and 3 loans gives 2 × 3 = 6 rows | Aggregate each table to one row per customer, then join |
| Customers missing from 360 | First join was accounts ↔ loans | Always start from `dim_customer` and chain left joins |
| `count(total_balance >= 10000)` counted everyone | `count()` counts non-null values, and `false` isn't null | `countIf(...)`, or group by segment with `count()` |
| Column not visible inside the same Derived column | A Derived column can't use a column created in itself | Put helper columns (`monthly_rate`) in an earlier Derived column |
| EMI null for 0% loans | Formula becomes 0 / 0 | `iif(monthly_rate == 0, loan_amount / loan_term, ...)` |
| Outstanding came out negative | Subtraction in the wrong order | `total_payable - total_paid` |
| Every loan would show Overdue | Comparing 2024 dates with today | As-of-date parameter |
| `lag(x, 1, 0)` made month-on-month % wrong | Default 0 claims "last month was zero" and divides by zero | `lag(x, 1)` (null) and guard with `iif` |
| `'tnx_sum*100'` returned text | Quotes make a string, not a calculation | No quotes around expressions |
| Considered the Wait activity for ordering | Wait just sleeps for N seconds | Use On success dependency arrows |


## Data quality finding: orphan loans and accounts
The source data has **87 customers**, but loans and accounts reference **more customer_ids** than that. With foreign keys on the SQL tables, inserts failed (FK conflict).

Found with an **Exists** transformation (*Doesn't exist*): gold dim_loan vs gold dim_customer on `customer_id`. Exists works like `WHERE NOT EXISTS` in SQL: it filters, it doesn't add columns.

| Option | Result | Chosen? |
|---|---|---|
| Drop the FK constraints | Everything loads; relationships are no longer enforced by SQL | ✅ Now (common in data warehouses) |
| Inferred ("Unknown") customer rows for missing ids | FKs stay; real customer overwrites the placeholder later via SCD-1 | 🔜 Enhancement |
| Reject orphans to quarantine | Real loans disappear from reports | ❌ Not for a bank |

```sql
ALTER TABLE dbo.dim_loans DROP CONSTRAINT <fk_name>;
SELECT name FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('dbo.dim_accounts');
```

---

## 9. Pipeline 4
| Issue | Cause | Fix / lesson |
|---|---|---|
| "Allowing delete, upsert, or update requires an Alter Row transformation" | Alter Row removed from the update branch | Update/upsert/delete sinks always need an Alter Row before them |
| Pipeline run failed on a data flow parameter | Parameter had no value in debug | Give data flow parameters a default (e.g. `'debug_run'`) |
| Can't use `$` parameter in the dataset | Datasets only see **dataset** parameters | `@dataset().tablename`, value supplied by the pipeline / debug settings |
| *Schema "dbo." does not exist* | Typed `dbo.` in the schema box | Schema = `dbo`; ADF adds the dot itself |
| FK conflict inserting loans/accounts | Orphan customer_ids in the source data | Investigated with Exists; dropped FKs, documented the issue |
| Rows with a missing hash never updated | `null != value` isn't `true` | Null-safe condition with `isNull(tgt_hash_col) \|\|` |
| Considered including the key/audit columns in the hash | Audit columns change every run | Hash only business columns (+ FKs), never PK or audit columns |
| Hash and audit columns NULL in SQL for loans/accounts, no error | Sink output name `src_hash_col` (and audit names) didn't match the SQL column names; the sink silently drops columns the target table doesn't have | Output names in the sink Mapping must match SQL exactly. Found via Monitor → data flow details: sink showed 5 columns kept, 7 dropped |
| created_by showed `debug_run` in Data preview | Data preview always runs in data flow debug, which uses the parameter's default | Check the real value after a pipeline run; the activity passes `@pipeline().Pipeline` |
| Upsert vs Update + Insert | Upsert can't keep `created_date` untouched on updates | Separate insert and update branches |

---
