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

![Dynamic File Name and Primary Key Mapping](Dynamic File Name.png)

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

