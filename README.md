# 🏦 Fintech BNPL Analytics Platform

Production-grade Buy Now Pay Later (BNPL) analytics domain built with dbt, modeling Tabby's payment infrastructure. Demonstrates end-to-end data engineering from raw transactions to executive dashboards.

## 📊 Project Overview

Built a complete analytics platform processing **$9.1M GMV** across **50,000 transactions** for a BNPL fintech company, implementing:
- **12 dbt models** (staging → intermediate → marts)
- **60 data quality tests** (100% pass rate)
- **Incremental processing** with partitioning and clustering
- **Full data lineage** documentation

## 🏗️ Architecture
```
Seeds (CSV)          Staging           Intermediate              Marts
─────────────        ───────────       ──────────────           ─────────────
transactions    →    stg_transactions                      →    fct_payment_transactions
                                   ↘                             (incremental, partitioned)
merchants       →    stg_merchants  →  int_transaction_enriched
                                   ↗                         →   dim_merchant
customers       →    stg_customers  →  int_customer_behavior →   dim_customer
                                                             
repayments      →    stg_repayments →  int_merchant_metrics  →   fct_repayment_performance
                                                             →   fct_merchant_gmv_daily
```

## 📈 Key Metrics

- **Total GMV:** $9,124,346.19
- **Transactions:** 50,000
- **BNPL Adoption Rate:** 77.3%
- **On-Time Payment Rate:** 93.7%
- **Default Rate:** 0.4%
- **Merchants:** 40 (Fashion, Electronics, Home, Beauty)
- **Customers:** 5,000 (Premium, Standard, New segments)

## 🛠️ Tech Stack

- **Transformation:** dbt (Data Build Tool)
- **Database:** DuckDB (local), BigQuery-ready
- **Orchestration:** Airflow DAG (daily 2 AM UTC)
- **Testing:** dbt_utils, dbt_expectations
- **Languages:** SQL, Python, YAML
- **Version Control:** Git, GitHub

## 📁 Project Structure
```
payments_analytics/
├── models/
│   ├── staging/          # 4 models - data cleaning
│   ├── intermediate/     # 3 models - business logic
│   └── marts/            # 5 models - fact tables & dimensions
├── seeds/                # 4 CSV files (~200K rows)
├── tests/                # Custom data quality tests
├── dags/                 # Airflow orchestration
└── docs/                 # Project documentation
```

## 🎯 Models

### Staging Layer (Views)
- `stg_transactions` - Cleaned transaction data
- `stg_merchants` - Merchant master data
- `stg_customers` - Customer demographics
- `stg_repayment_schedules` - BNPL installment tracking

### Intermediate Layer (Views)
- `int_transaction_enriched` - Transactions with merchant/customer context
- `int_customer_repayment_behavior` - Payment patterns by customer
- `int_merchant_metrics` - Merchant performance aggregations

### Marts Layer (Tables)
- `fct_payment_transactions` - Core fact table (incremental, partitioned by date)
- `fct_repayment_performance` - BNPL repayment analytics
- `fct_merchant_gmv_daily` - Daily merchant performance
- `dim_merchant` - Merchant dimension with lifetime metrics
- `dim_customer` - Customer dimension with risk scores

## ✅ Data Quality

**60 automated tests ensuring:**
- Primary key uniqueness
- Not null constraints
- Referential integrity
- Value range validations
- Accepted value lists
- Custom business logic (GMV consistency, payment status flow)

**Test Results:** ✅ 100% Pass Rate

## 🚀 Quick Start

### Prerequisites
```bash
# Install dbt with DuckDB adapter
pip install dbt-duckdb

# Or for BigQuery
pip install dbt-bigquery
```

### Setup
```bash
# Clone repository
git clone https://github.com/FATIMA-FARMAN/fintech-bnpl-analytics.git
cd fintech-bnpl-analytics

# Install dbt packages
dbt deps

# Load seed data
dbt seed

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve  # Opens at localhost:8080
```

### Configuration

Create `~/.dbt/profiles.yml`:
```yaml
payments_analytics:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: payments_analytics.duckdb
      threads: 4
```

## 📸 Screenshots

### Data Lineage Graph
![Data Lineage](docs/images/lineage_graph.png)
*Full data flow from seeds to marts showing 12 models and dependencies*

### Model Documentation
![Model Details](docs/images/model_details.png)
*Detailed model page showing columns, tests, and compiled SQL*

### Test Results
![Test Results](docs/images/test_results.png)
*60 passing data quality tests ensuring data integrity*

## 🎓 Skills Demonstrated

### Analytics Engineering
- dbt best practices (staging → intermediate → marts)
- Incremental materialization strategies
- Data quality testing frameworks
- Documentation as code

### Data Modeling
- Dimensional modeling (facts & dimensions)
- Slowly changing dimensions
- Surrogate key management
- Star schema design

### SQL Mastery
- Window functions for payment tracking
- Complex aggregations for metrics
- CTEs for readable code
- Performance optimization (partitioning, clustering)

### Domain Expertise
- BNPL business model understanding
- Payment processing workflows
- Risk analytics (fraud detection, default prediction)
- Merchant performance metrics

## 🔄 Orchestration

**Airflow DAG:**
- Runs daily at 2 AM UTC
- Task groups: staging → intermediate → marts → QA
- Error handling and alerting
- Comprehensive logging

## 📊 Sample Queries

**Merchant Performance:**
```sql
SELECT 
    merchant_name,
    total_gmv,
    bnpl_rate,
    capture_rate,
    merchant_tier
FROM dim_merchant
WHERE merchant_tier = 'tier_1_elite'
ORDER BY total_gmv DESC;
```

**BNPL Repayment Health:**
```sql
SELECT 
    customer_segment,
    COUNT(*) as total_plans,
    AVG(on_time_payment_rate) as avg_on_time_rate,
    SUM(CASE WHEN payment_status = 'defaulted' THEN 1 ELSE 0 END) as defaults
FROM fct_repayment_performance
GROUP BY customer_segment;
```

## 🎯 Business Impact

This platform enables:
- **Real-time merchant performance tracking**
- **Customer risk scoring for credit decisions**
- **BNPL portfolio health monitoring**
- **Fraud detection and prevention**
- **Executive dashboards for data-driven decisions**

## 📝 Next Steps

- [ ] Build Looker Studio dashboard (3 pages)
- [ ] Add Tableau Public visualizations
- [ ] Implement predictive models (default risk)
- [ ] Add incremental refresh monitoring
- [ ] Create CI/CD pipeline with GitHub Actions

## 👤 Author

**Fatima Farman**
- LinkedIn: [linkedin.com/in/fatima-farman](https://www.linkedin.com/in/fatima-farman)
- GitHub: [@FATIMA-FARMAN](https://github.com/FATIMA-FARMAN)
- Domain: Analytics Engineering | Payments Analytics | Fintech

---

⭐ **Star this repo** if you find it useful for learning dbt or BNPL analytics!

📧 **Interested in collaboration?** Feel free to reach out!
