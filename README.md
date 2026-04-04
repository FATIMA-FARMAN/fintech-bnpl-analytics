# FinTech BNPL Analytics Platform — Checkout & Payment Intelligence

> Built to mirror the analytics domain for a production BNPL platform — modelling the **core BNPL purchase flow**, checkout performance, merchant health, and customer risk scoring across $9.1M GMV and 50K transactions.

![dbt](https://img.shields.io/badge/dbt-FF694B?style=flat-square&logo=dbt&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=flat-square&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)
![Airflow](https://img.shields.io/badge/Airflow-017CEE?style=flat-square&logo=apache-airflow&logoColor=white)
![DuckDB](https://img.shields.io/badge/DuckDB-FFF000?style=flat-square&logo=duckdb&logoColor=black)

---

## Business Context

BNPL platforms live or die on **checkout completion**. A 1% drop in conversion at any stage of the purchase flow translates directly to lost GMV. This project builds the full analytics layer to monitor, diagnose, and improve checkout performance — the same problem a Senior Product Analyst on a Checkout Core team owns day-to-day.

---

## What This Solves

| Business Problem | Analytics Solution Built |
|---|---|
| Why are checkouts failing? | Checkout funnel: stage-by-stage conversion + drop-off root cause |
| Which merchants underperform? | Merchant tier scorecards: GMV, approval rate, default rate |
| Which customers are high risk? | Risk scoring model based on repayment behaviour |
| Is our portfolio healthy? | Installment-level delinquency tracking + early warning signals |
| What drives successful checkout? | A/B test framework for purchase flow experiments |
| Can non-analysts self-serve? | Looker Studio dashboard — no SQL required |

---

## Checkout Funnel Analysis

The core product metric — tracking every step of the BNPL purchase flow from initiation to successful completion:

```
Checkout Initiated → Risk Check → Approval → Payment Plan Selected → Order Confirmed
      100%             87.3%        79.1%           76.4%                 72.8%
```

Key metrics tracked:
- Checkout completion rate (overall + by merchant, device, product category)
- Stage drop-off rate with root cause segmentation
- Approval rate by customer risk tier
- Payment plan selection rate (3-month vs 6-month vs 12-month split)

```sql
SELECT
    funnel_stage,
    stage_order,
    COUNT(*)                                                             AS sessions,
    ROUND(COUNT(*) * 100.0 / FIRST_VALUE(COUNT(*)) OVER (
        ORDER BY stage_order
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 1)   AS completion_rate,
    ROUND(100.0 - COUNT(*) * 100.0 / LAG(COUNT(*)) OVER (
        ORDER BY stage_order), 1)                                        AS stage_dropoff_rate
FROM checkout_events
GROUP BY funnel_stage, stage_order
ORDER BY stage_order;
```

---

## A/B Testing Framework

Built to support hypothesis-driven product decisions on the checkout flow:

**Example: Simplified payment plan selection screen**
- **Hypothesis:** Reducing plan options at checkout increases completion rate
- **Primary metric:** Checkout completion rate
- **Guardrail metric:** Average order value (AOV)
- **Method:** Two-proportion z-test · 95% confidence · MDE = 2%

```python
import numpy as np
from scipy import stats

def checkout_ab_test(control_conv, control_n, treatment_conv, treatment_n):
    p_c = control_conv / control_n
    p_t = treatment_conv / treatment_n
    p_pool = (control_conv + treatment_conv) / (control_n + treatment_n)
    se = np.sqrt(p_pool * (1 - p_pool) * (1/control_n + 1/treatment_n))
    z  = (p_t - p_c) / se
    p  = 2 * (1 - stats.norm.cdf(abs(z)))
    return {"control": round(p_c*100,2), "treatment": round(p_t*100,2),
            "lift": round((p_t-p_c)*100,2), "p_value": round(p,4),
            "significant": p < 0.05}
```

---

## Data Architecture

```
Sources
  stg_transactions      — typed, cleaned payment events
  stg_merchants         — merchant profiles + tier classification
  stg_customers         — customer identity + risk attributes
  stg_installments      — installment schedules + payment status

Intermediate
  int_checkout_funnel   — stage-by-stage funnel reconstruction
  int_customer_risk     — risk scoring: repayment history + behaviour
  int_merchant_health   — GMV, approval rate, default rate per merchant

Marts (self-serve, BI-ready)
  fct_checkout_events   — grain: one row per checkout attempt
  fct_installments      — grain: one row per installment
  dim_customers         — customer segments + risk tiers
  dim_merchants         — merchant tiers + partner performance
  mart_checkout_funnel  — pre-aggregated funnel KPIs for dashboards
  mart_portfolio_health — delinquency, default rate, GMV at risk
```

**60 automated dbt tests** — primary keys, referential integrity, accepted values, custom business rules.

---

## Merchant & Partner Analytics

Supports BD and partner discussions with structured merchant scorecards:

| Metric | Description |
|---|---|
| GMV by merchant tier | Revenue contribution: Premium / Standard / New |
| Approval rate | % of checkout attempts approved per merchant category |
| Default rate | % of orders with missed installments |
| Fraud indicator rate | Flagged transactions as % of total volume |
| Customer LTV by merchant | Repeat purchase rate and basket size trends |

---

## Self-Serve Dashboard (Looker Studio)

Built for product and business stakeholders — no SQL required:

- **Checkout Health**: completion rate, drop-off by stage, daily trend
- **Merchant Scorecard**: GMV, approval rate, default rate by tier
- **Portfolio Risk**: delinquency rate, 30/60/90 day buckets
- **Customer Segments**: Premium / Standard / New with behaviour profiles

Daily refresh via Airflow DAG (`dbt deps → dbt run → dbt test`, 2AM UTC).

---

## Key Results

| Metric | Value |
|---|---|
| Total GMV analysed | $9,124,346 |
| Transactions | 50,000 |
| Checkout completion rate | 72.8% |
| BNPL adoption rate | 77.3% |
| On-time payment rate | 93.7% |
| Default rate | 0.4% |
| Active merchants | 40 (Fashion, Electronics, Home, Beauty) |
| Automated dbt tests | 60 (100% pass rate) |

---

## Tech Stack

| Layer | Tool |
|---|---|
| Transformation | dbt (staging → intermediate → marts) |
| Warehouse | DuckDB (local) · BigQuery (production-compatible) |
| Orchestration | Apache Airflow — daily DAG |
| BI / Self-serve | Looker Studio |
| Event Analytics | Compatible with Amplitude event schema |
| Language | SQL (91%) · Python (9%) |
| Testing | dbt-utils · dbt-expectations |

---

## How to Run

```bash
pip install -r requirements.txt
dbt debug
dbt seed
dbt run
dbt test
# Trigger Airflow DAG: bnpl_analytics_daily
```
