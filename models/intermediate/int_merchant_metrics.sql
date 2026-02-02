{{
    config(
        materialized='view'
    )
}}

with transactions as (
    select * from {{ ref('int_transaction_enriched') }}
),

merchant_metrics as (
    select
        merchant_id,
        merchant_name,
        merchant_category,
        merchant_country,
        
        count(*) as total_transactions,
        count(distinct customer_id) as unique_customers,
        count(distinct transaction_date) as active_days,
        
        count(case when transaction_status = 'authorized' then 1 end) as authorized_transactions,
        count(case when transaction_status = 'captured' then 1 end) as captured_transactions,
        count(case when transaction_status = 'settled' then 1 end) as settled_transactions,
        count(case when transaction_status = 'failed' then 1 end) as failed_transactions,
        count(case when transaction_status = 'refunded' then 1 end) as refunded_transactions,
        
        sum(case when transaction_status = 'settled' then order_amount else 0 end) as total_gmv,
        sum(tabby_fee_amount) as total_tabby_revenue,
        avg(case when transaction_status = 'settled' then order_amount end) as avg_order_value,
        
        count(case when is_bnpl_transaction then 1 end) as bnpl_transactions,
        count(case when payment_method = 'card' then 1 end) as card_transactions,
        
        count(case when is_fraudulent then 1 end) as fraud_transactions,
        avg(risk_score) as avg_risk_score,
        
        count(distinct case when is_first_transaction then customer_id end) as new_customers_acquired,
        
        min(transaction_date) as first_transaction_date,
        max(transaction_date) as last_transaction_date,
        
        cast(count(case when transaction_status = 'settled' then 1 end) as double) / nullif(cast(count(case when transaction_status = 'authorized' then 1 end) as double), 0) as capture_rate,
        
        cast(count(case when is_fraudulent then 1 end) as double) / nullif(cast(count(*) as double), 0) as fraud_rate,
        
        cast(count(case when is_bnpl_transaction then 1 end) as double) / nullif(cast(count(*) as double), 0) as bnpl_rate
        
    from transactions
    group by 1, 2, 3, 4
)

select * from merchant_metrics
