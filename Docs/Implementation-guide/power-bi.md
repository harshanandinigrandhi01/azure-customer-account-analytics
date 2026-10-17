# Power BI

## Summary
- A two-page Power BI report, **Bank Customer & Loan Overview** and **Monthly Transaction Trends**, built on the three SQL marts in Azure SQL Database (`database22`).
- **Import mode** with one relationship (`customer_id`, 1 → \*) lets a single segment slicer filter the cards, the top-10 chart and the loan risk chart together.
- Building the report surfaced real data issues: orphan loans showing as **(Blank)**, a **segment label typo**, and a **partial last month**. BI is where data bugs become visible.

---

## 1. Where it fits
```
Source CSV → Bronze → Silver → Gold (Delta) → Azure SQL DB (SCD-1 dims + marts) → Power BI
```
Power BI reads only the **marts**, which are pre-aggregated in gold. The report needs no heavy DAX: the business logic lives in the pipeline, and Power BI only displays it.

---

## 2. Connection
| Setting | Value | Why |
|---|---|---|
| Source | Azure SQL Database `database22` | The serving layer from Step 6 |
| Mode | **Import** | Small data, fastest visuals, works offline; refresh after each pipeline run |
| Tables | `mart_customer_360`, `mart_loan_summary`, `mart_monthly_transactions` | One mart per business question |
| Auth | SQL login | The password is **not** stored in the .pbix |
| Network | Client IP added to the SQL server firewall | Needed for the desktop to reach Azure SQL (error 40615 otherwise) |

**Import vs DirectQuery:** Import copies the data into the report, so it's fast but only as fresh as the last refresh. DirectQuery queries SQL on every click, so it's always live but slower and dependent on the database. For a daily batch pipeline, Import is the right fit.

---

## 3. Data model
| From | To | Cardinality | Filter direction |
|---|---|---|---|
| `mart_customer_360[customer_id]` | `mart_loan_summary[customer_id]` | 1 → \* (one customer, many loans) | Single |

- `mart_monthly_transactions` stands alone. It's aggregated by year, month and type, so it has no customer key.
- `dim_customers` was not needed, because `mart_customer_360` already has one row per customer.

**Calculated column** (for a real time axis):
```DAX
Month = DATE(mart_monthly_transactions[transaction_year], mart_monthly_transactions[transaction_month], 1)
```
Formatted as `mmm yyyy`. On the axis it is set to **Month**, not Date Hierarchy, otherwise everything collapses into one "2024" point.

---

## 4. Report pages

### Page 1: Bank Customer & Loan Overview
| Visual | Type | Fields | Business question |
|---|---|---|---|
| KPI cards | Card ×4 | Customers (distinct count of `customer_id`), Total Balance, Total Loans, Outstanding Loans | What is the size of the book? |
| Customer Segment | Slicer (tiles) | `customer_segment` | Filter everything by segment |
| Loan Amount and Count by Risk | Line and clustered column (two axes) | `risk_flag`; Sum `loan_amount` (columns); Count `loan_id` (markers) | Where is the loan risk, in money and in number of loans? Overdue highlighted |
| Top 10 Customers by Outstanding Loan | Clustered bar + Top N filter | `full_name`, `outstanding_loan` | Who owes the most? |
| Balance vs Loans by Segment | Clustered bar | `customer_segment`; `total_balance`, `total_loan_amount` | Which segment holds the most balance and loans? |

### Page 2: Monthly Transaction Trends
| Visual | Type | Fields | Business question |
|---|---|---|---|
| Transaction Type | Slicer (tiles) | `transaction_type` | Deposits vs withdrawals |
| Monthly Transaction Value by Type | Line chart | `Month`; Sum `tnx_sum`; legend `transaction_type` | Is activity growing or falling? |
| Month-over-Month Change | Table + conditional formatting | `Month`, `transaction_type`, `tnx_sum`, `previous_month_total`, `mom_change_pct` (red < 0, green ≥ 0) | How much did each month change? |

**Why two pages?** The segment slicer can't filter the transactions mart, which has no customer key. Keeping the trend visuals on their own page avoids a slicer that silently does nothing.

---

## 5. Key insights
| Insight | Evidence |
|---|---|
| **Standard** customers hold the lowest balances but the highest loan amount | Segment chart: Standard has 0.02M balance vs 0.76M loans |
| Most loan money sits in the **Watch** risk group, and **Overdue** is the second-largest exposure | Risk chart: Watch 1.43M across 60 loans; Overdue 0.70M across 29 loans |
| Outstanding loans are about **87%** of total loans | Cards: 1.83M outstanding of 2.10M |
| The last month (April) drops around 70% for both types | MoM table: -70.79% deposits, -66.67% withdrawals. Most likely a **partial month** in the source data, not a real business drop, so worth checking before drawing conclusions |

---
