# 💳 Payments Analytics Domain - BNPL Platform

## 🎯 Overview

**PayEase BNPL Analytics** is a production-grade analytics domain built to mirror Tabby's Buy Now Pay Later business model. This domain demonstrates advanced analytics engineering capabilities including incremental loading, data quality testing, dimensional modeling, and BNPL-specific risk analytics.

---

## 🏗️ Architecture

### **Three-Layer Medallion Architecture**

```
┌─────────────┐
│   SEEDS     │  ← Raw CSV data (merchants, customers, transactions, repayments)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  STAGING    │  ← Data cleaning & type casting
└──────┬──────┘
       │
       ▼
┌─────────────┐
│INTERMEDIATE │  ← Business logic & enrichment
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   MARTS     │  ← Production fact & dimension tables
└─────────────┘
```

---

## 📊 Data Model

### **Fact Tables**

#### 1. `fct_payment_transactions`
**Grain:** One row per payment transaction  
**Purpose:** Core transaction fact table with full lifecycle tracking

**Key Metrics:**
- GMV (Gross Merchandise Value)
- Transaction success rates
- Payment method distribution
- Risk scores and fraud detection

**Business Questions:**
- What's our daily/monthly GMV?
- Which merchants drive the most revenue?
- What's the authorization → settlement conversion rate?
- What's the fraud rate by merchant/customer segment?

#### 2. `fct_merchant_gmv_daily`
**Grain:** One row per merchant per day  
**Purpose:** Daily aggregated merchant performance metrics

**Key Metrics:**
- Daily GMV and trends (7-day moving average)
- Transaction volumes
- Capture rates and fraud rates
- New customer acquisition
- BNPL vs card payment split

**Business Questions:**
- Which merchants are growing/declining?
- What's the merchant cohort retention?
- Which categories perform best?
- What's the average order value by merchant?

#### 3. `fct_repayment_performance`
**Grain:** One row per BNPL installment  
**Purpose:** BNPL repayment behavior and default risk analysis

**Key Metrics:**
- On-time payment rate
- Default rate by segment
- Average days late
- Late fee revenue
- Customer risk categorization

**Business Questions:**
- What's our overall repayment performance?
- Which customer segments have highest default risk?
- What's the correlation between first installment payment and full repayment?
- How do late fees impact revenue?

### **Dimension Tables**

#### 1. `dim_merchant`
**Purpose:** Merchant master data with lifetime performance metrics

**Attributes:**
- Merchant profile (name, category, country)
- Onboarding date and tenure
- Lifetime GMV and revenue
- Merchant tier classification (elite/high/medium/low)
- Capture rates and fraud rates

#### 2. `dim_customer`
**Purpose:** Customer master data with value and risk profiling

**Attributes:**
- Customer profile (segment, age, country)
- Lifetime transaction and GMV metrics
- Repayment behavior (on-time rate, defaults)
- Customer value tier (VIP/high/medium/low)
- Repayment risk tier (low/medium/high risk)

---

## 🚀 Getting Started

### **Prerequisites**
- Python 3.8+
- dbt-core 1.6+
- BigQuery project (or any SQL warehouse)

### **Setup**

1. **Generate sample data:**
```bash
cd seeds
python generate_sample_data.py
```

2. **Install dbt dependencies:**
```bash
dbt deps
```

3. **Load seed data:**
```bash
dbt seed
```

4. **Run models:**
```bash
# Full refresh
dbt run

# Run specific layers
dbt run --select staging
dbt run --select intermediate
dbt run --select marts

# Incremental run (production)
dbt run --select fct_payment_transactions
```

5. **Run tests:**
```bash
# All tests
dbt test

# Specific model tests
dbt test --select fct_payment_transactions
```

---

## 📈 Key Metrics & KPIs

### **Transaction Performance**
- **GMV (Gross Merchandise Value):** Total value of settled transactions
- **Authorization Rate:** % of transactions authorized
- **Capture Rate:** % of authorized transactions that settle
- **Average Order Value (AOV):** Mean transaction amount

### **BNPL Specific**
- **BNPL Adoption Rate:** % of transactions using BNPL
- **On-Time Payment Rate:** % of installments paid on/before due date
- **Default Rate:** % of installments missed >30 days
- **Late Fee Revenue:** Additional revenue from late payments

### **Risk Metrics**
- **Fraud Rate:** % of fraudulent transactions
- **Average Risk Score:** Mean risk score across transactions
- **High-Risk Customer %:** % of customers in high-risk tier

### **Merchant Metrics**
- **Merchant Retention:** % of merchants active month-over-month
- **GMV Growth Rate:** Month-over-month GMV change
- **New Customer Acquisition:** New customers per merchant per day

---

## 🔍 Sample Queries

### **Daily GMV Trend**
```sql
SELECT
  metric_date,
  SUM(gmv) as total_gmv,
  SUM(gmv_7day_avg) / COUNT(DISTINCT merchant_id) as avg_merchant_gmv_7d
FROM marts.fct_merchant_gmv_daily
WHERE metric_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1
ORDER BY 1 DESC
```

### **Top Performing Merchants**
```sql
SELECT
  merchant_name,
  merchant_category,
  total_gmv,
  avg_order_value,
  capture_rate,
  merchant_tier
FROM marts.dim_merchant
ORDER BY total_gmv DESC
LIMIT 10
```

### **Repayment Performance by Segment**
```sql
SELECT
  customer_segment,
  COUNT(*) as total_installments,
  SUM(on_time_payment_flag) as on_time_payments,
  SUM(on_time_payment_flag) / COUNT(*) as on_time_rate,
  SUM(defaulted_amount) as total_defaulted_amount
FROM marts.fct_repayment_performance
GROUP BY 1
ORDER BY on_time_rate DESC
```

### **BNPL vs Card Performance**
```sql
SELECT
  CASE
    WHEN is_bnpl_transaction THEN 'BNPL'
    ELSE 'Card'
  END as payment_type,
  COUNT(*) as transactions,
  SUM(gmv) as total_gmv,
  AVG(order_amount) as avg_order_value,
  SUM(CASE WHEN transaction_status = 'settled' THEN 1 ELSE 0 END) / COUNT(*) as success_rate
FROM marts.fct_payment_transactions
GROUP BY 1
```

---

## 🧪 Data Quality & Testing

### **Test Coverage**
- ✅ **Uniqueness:** Primary key uniqueness on all fact and dimension tables
- ✅ **Not Null:** Critical fields cannot be null
- ✅ **Referential Integrity:** Foreign key relationships validated
- ✅ **Value Range:** Numeric fields within expected bounds
- ✅ **Accepted Values:** Enum fields match expected values
- ✅ **Custom Business Logic:** GMV consistency across aggregations

### **Test Execution**
```bash
# Run all tests
dbt test

# Test results show in terminal with PASS/FAIL status
# Example output:
# 16:23:45  1 of 45 START test not_null_fct_payment_transactions_transaction_id .... [RUN]
# 16:23:45  1 of 45 PASS not_null_fct_payment_transactions_transaction_id .......... [PASS in 0.12s]
```

---

## 🔄 Data Pipeline

### **Orchestration**
Airflow DAG (`dags/dbt_payments_analytics_daily.py`) orchestrates:
1. **Daily at 2 AM UTC:** Incremental load of `fct_payment_transactions`
2. **Daily at 3 AM UTC:** Rebuild `fct_merchant_gmv_daily`
3. **Daily at 4 AM UTC:** Rebuild `fct_repayment_performance`
4. **Weekly on Sunday:** Full refresh of dimension tables

### **Incremental Strategy**
`fct_payment_transactions` uses incremental materialization:
- Loads only new transactions since last run
- Partitioned by `transaction_date` for efficient queries
- Clustered by `merchant_id` and `transaction_status`

---

## 📊 Business Context: BNPL Model

### **How BNPL Works (Tabby Model)**

1. **Customer** makes a purchase at a merchant
2. **Tabby** pays the merchant upfront (minus commission)
3. **Customer** repays Tabby in 3-4 interest-free installments
4. **Revenue:** Commission from merchant + late fees from customers

### **Key Stakeholders**
- **Merchants:** Want higher conversion, lower cart abandonment
- **Customers:** Want flexible payment options, credit access
- **Tabby:** Balances merchant growth with credit risk management

### **Risk Management**
Critical to prevent defaults while enabling credit access:
- Real-time fraud detection
- Customer credit scoring
- Installment repayment monitoring
- Early warning systems for late payments

---

## 🎯 Use Cases Demonstrated

This domain showcases:

✅ **Incremental Loading:** Efficient processing of large transaction volumes  
✅ **Dimensional Modeling:** Star schema with fact/dimension separation  
✅ **Business Logic:** BNPL-specific metrics and risk calculations  
✅ **Data Quality:** Comprehensive testing with dbt contracts  
✅ **Window Functions:** 7-day moving averages, day-over-day changes  
✅ **Risk Analytics:** Payment behavior, default prediction, customer scoring  
✅ **Cohort Analysis:** Merchant retention, customer lifetime value  

---

## 📁 Project Structure

```
payments_analytics/
├── models/
│   ├── staging/           # Raw data cleaning
│   │   ├── stg_transactions.sql
│   │   ├── stg_merchants.sql
│   │   ├── stg_customers.sql
│   │   └── stg_repayment_schedules.sql
│   ├── intermediate/      # Business logic
│   │   ├── int_transaction_enriched.sql
│   │   ├── int_merchant_metrics.sql
│   │   └── int_customer_repayment_behavior.sql
│   └── marts/             # Production tables
│       ├── fct_payment_transactions.sql
│       ├── fct_merchant_gmv_daily.sql
│       ├── fct_repayment_performance.sql
│       ├── dim_merchant.sql
│       └── dim_customer.sql
├── seeds/                 # Sample data CSVs
├── tests/                 # Custom dbt tests
├── dags/                  # Airflow orchestration
├── docs/                  # Documentation
└── dbt_project.yml        # dbt configuration
```

---

## 🏆 Skills Demonstrated

- **Analytics Engineering:** dbt best practices, modular SQL
- **Data Modeling:** Star schema, fact/dimension tables, SCD Type 1
- **BNPL Domain:** Payment lifecycle, installment tracking, risk scoring
- **Data Quality:** Comprehensive testing, data contracts
- **Performance:** Incremental loading, partitioning, clustering
- **Documentation:** Self-service analytics, metric definitions

---

## 📞 Contact

Built by **[Your Name]**  
Analytics Engineer | Payments & Risk Analytics Specialist  
[LinkedIn Profile] | [Portfolio Website]

---

## 📝 License

This is a portfolio project demonstrating analytics engineering capabilities.  
Sample data is synthetic and does not represent any real company.
