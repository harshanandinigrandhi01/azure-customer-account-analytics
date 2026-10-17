use database22;

create table dim_customers(
customer_id varchar(10) not null primary key,
first_name varchar(50),
last_name varchar(50),
full_name varchar(101),
address varchar(100),
city varchar(50),
state varchar(20),
zip varchar(10),
hash_col varchar(64),
Created_by varchar(100),
Created_date DATETIME2,
Updated_by varchar(100),
Updated_date DATETIME2
);


create table dim_accounts(
account_id varchar(10) not null primary key,
customer_id	varchar(10),
account_type varchar(20),
balance decimal(18,2),
hash_col varchar(64),
Created_by varchar(100),
Created_date DATETIME2,
Updated_by varchar(100),
Updated_date DATETIME2,
foreign key (customer_id) references dim_customers(customer_id)
);

create table dim_loans(
loan_id varchar(10) not null primary key,
customer_id varchar(10),
loan_amount decimal(18,2),
interest_rate  decimal(5,2),
loan_term  int,
hash_col varchar(64),
Created_by varchar(100),
Created_date DATETIME2,
Updated_by varchar(100),
Updated_date DATETIME2,
foreign key (customer_id) references dim_customers(customer_id)
);

select * from dbo.dim_customers;
select * from dbo.dim_accounts;
select * from dbo.dim_loans;


select customer_id as tgt_customer_id, hash_col as tgt_hash_col from dbo.dim_customers;


SELECT COUNT(*), MIN(created_date) FROM dbo.dim_customers;


truncate table dbo.dim_customers;
truncate table dbo.dim_accounts;
truncate table dbo.dim_loans;


SELECT COUNT(*) AS total_rows, COUNT(DISTINCT loan_id) AS unique_loans FROM dbo.dim_loans;

SELECT MIN(Created_date) AS first_created, MAX(Created_date) AS last_created
FROM dbo.dim_loans;


SELECT MIN(Created_date) AS first_created, MAX(Created_date) AS last_created
FROM dbo.dim_customers;

SELECT COUNT(*) FROM dbo.dim_customers WHERE Updated_date > Created_date;

create table mart_customer_360(
customer_id varchar(10) not null primary key,
first_name varchar(50),
last_name varchar(50),
full_name varchar(101),
address varchar(100),
city varchar(50),
state varchar(20),
zip varchar(10),
num_accounts int,
total_balance decimal(18,2),
num_loans int,
total_loan_amount decimal(18,2),
total_transaction_amount decimal(18,2),
latest_transaction_date date,
total_payment_amount decimal(18,2),
latest_payment_date date,
outstanding_loan decimal(18,2),
customer_segment varchar(20),
loaded_by varchar(100),
loaded_date datetime2

);



create table mart_loan_summary(
loan_id varchar(10) not null primary key,
customer_id varchar(10),
loan_amount decimal(18,2),
interest_rate  decimal(5,2),
loan_term  int,
num_payments_made int,
total_payment_amount_paid decimal(18,2),
latest_payment_date date,
monthly_rate decimal(10,6),
monthly_emi decimal(18,2),
total_payable decimal(18,2),
outstanding_amount decimal(18,2),
days_since_last_payment int,
as_of_date date,
risk_flag varchar(20),
loaded_by varchar(100),
loaded_date DATETIME2
);

create table mart_monthly_transactions(
transaction_year int NOT NULL,
transaction_month int NOT NULL,
transaction_type  varchar(20) NOT NULL,
tnx_count  int,
tnx_sum  decimal(18,2),
tnx_avg  decimal(18,2),
previous_month_total DECIMAL(18,2),
mom_change_pct DECIMAL(10,2),
loaded_by varchar(100),
loaded_date DATETIME2,
constraint pk_mart_monthly primary key (transaction_year,transaction_month,transaction_type)
);


select * from dbo.mart_customer_360;
select * from dbo.mart_loan_summary;
select * from dbo.mart_monthly_transactions;