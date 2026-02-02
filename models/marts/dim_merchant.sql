{{
    config(
        materialized='table'
    )
}}

with merchants as (
    select * from {{ ref('stg_merchants') }}
),

merchant_summary as (
    select
        merchant_id,
        total_transactions,
        unique_customers,
        total_gmv,
        total_tabby_revenue,
        avg_order_value,
        capture_rate,
        fraud_rate,
        bnpl_rate,
        first_transaction_date,
        last_transaction_date
    from {{ ref('int_merchant_metrics') }}
)

select
    m.merchant_id,
    m.merchant_name,
    m.merchant_category,
    m.onboarding_date,
    m.country,
    m.merchant_status,
    m.commission_rate,
    m.days_since_onboarding,
    coalesce(ms.total_transactions, 0) as total_transactions,
    coalesce(ms.unique_customers, 0) as unique_customers,
    coalesce(ms.total_gmv, 0) as total_gmv,
    coalesce(ms.total_tabby_revenue, 0) as total_tabby_revenue,
    coalesce(ms.avg_order_value, 0) as avg_order_value,
    coalesce(ms.capture_rate, 0) as capture_rate,
    coalesce(ms.fraud_rate, 0) as fraud_rate,
    coalesce(ms.bnpl_rate, 0) as bnpl_rate,
    ms.first_transaction_date,
    ms.last_transaction_date,
    case
        when coalesce(ms.total_gmv, 0) >= 100000 then 'tier_1_elite'
        when coalesce(ms.total_gmv, 0) >= 50000 then 'tier_2_high'
        when coalesce(ms.total_gmv, 0) >= 10000 then 'tier_3_medium'
        else 'tier_4_low'
    end as merchant_tier,
    current_timestamp as _dimension_loaded_at
from merchants m
left join merchant_summary ms on m.merchant_id = ms.merchant_id
