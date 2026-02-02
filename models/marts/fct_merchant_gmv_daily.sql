{{
    config(
        materialized='table',
        partition_by={
          "field": "metric_date",
          "data_type": "date",
          "granularity": "day"
        },
        cluster_by=['merchant_id']
    )
}}

with daily_metrics as (
    select
        merchant_id,
        merchant_name,
        merchant_category,
        merchant_country,
        transaction_date as metric_date,
        
        -- Volume metrics
        count(*) as total_transactions,
        count(case when transaction_status = 'settled' then 1 end) as settled_transactions,
        count(case when transaction_status = 'failed' then 1 end) as failed_transactions,
        count(case when transaction_status = 'refunded' then 1 end) as refunded_transactions,
        
        -- GMV metrics
        sum(case when transaction_status = 'settled' then order_amount else 0 end) as gmv,
        sum(case when transaction_status = 'settled' then tabby_fee_amount else 0 end) as tabby_revenue,
        avg(case when transaction_status = 'settled' then order_amount end) as avg_order_value,
        
        -- Conversion metrics
        count(case when transaction_status = 'authorized' then 1 end) as authorized_count,
        count(case when transaction_status = 'settled' then 1 end) as settled_count,
        
        -- Risk metrics
        count(case when is_fraudulent then 1 end) as fraud_transactions,
        avg(risk_score) as avg_risk_score,
        
        -- Customer metrics
        count(distinct customer_id) as unique_customers,
        count(distinct case when is_first_transaction then customer_id end) as new_customers,
        
        -- BNPL metrics
        count(case when is_bnpl_transaction then 1 end) as bnpl_transactions,
        sum(case when is_bnpl_transaction and transaction_status = 'settled' then order_amount else 0 end) as bnpl_gmv

    from {{ ref('fct_payment_transactions') }}
    group by 1, 2, 3, 4, 5
)

select
    *,
    
    -- Calculated rates
    cast(settled_count as double) / nullif(cast(authorized_count as double), 0) as capture_rate,
    cast(fraud_transactions as double) / nullif(cast(total_transactions as double), 0) as fraud_rate,
    cast(bnpl_transactions as double) / nullif(cast(total_transactions as double), 0) as bnpl_rate,
    cast(tabby_revenue as double) / nullif(cast(gmv as double), 0) as revenue_take_rate,
    
    -- Window functions for trends (7-day moving average)
    gmv - lag(gmv) over (partition by merchant_id order by metric_date) as gmv_day_over_day_change,
    
    avg(gmv) over (
        partition by merchant_id 
        order by metric_date 
        rows between 6 preceding and current row
    ) as gmv_7day_avg,
    
    avg(unique_customers) over (
        partition by merchant_id 
        order by metric_date 
        rows between 6 preceding and current row
    ) as customers_7day_avg,
    
    -- Metadata
    current_timestamp as _mart_loaded_at

from daily_metrics
