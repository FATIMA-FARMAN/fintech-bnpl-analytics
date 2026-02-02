{{
    config(
        materialized='incremental',
        unique_key='transaction_id',
        on_schema_change='append_new_columns',
        partition_by={
          "field": "transaction_date",
          "data_type": "date",
          "granularity": "day"
        },
        cluster_by=['merchant_id', 'transaction_status']
    )
}}
with transactions as (
    select * from {{ ref('int_transaction_enriched') }}
    {% if is_incremental() %}
    where transaction_timestamp >= (select max(transaction_timestamp) from {{ this }})
    {% endif %}
)

select
    -- Transaction identifiers
    transaction_id,
    order_id,
    
    -- Dimensions (foreign keys)
    customer_id,
    merchant_id,
    
    -- Transaction details
    transaction_date,
    transaction_timestamp,
    transaction_status,
    payment_method,
    
    -- Merchant context
    merchant_name,
    merchant_category,
    merchant_country,
    
    -- Customer context
    customer_segment,
    customer_country,
    age_group,
    customer_is_verified,
    
    -- Amounts
    order_amount,
    customer_paid_amount,
    merchant_received_amount,
    tabby_fee_amount,
    
    -- Installment info (BNPL specific)
    installment_plan,
    first_installment_amount,
    subsequent_installment_amount,
    
    -- Timing metrics
    authorization_to_capture_hours,
    capture_to_settlement_hours,
    
    -- Risk flags
    is_first_transaction,
    is_bnpl_transaction,
    risk_score,
    is_fraudulent,
    
    -- Business metrics (pre-calculated for BI)
    gmv,
    successful_transaction_flag,
    effective_commission_rate_pct,
    
    -- Date dimensions
    transaction_year,
    transaction_month,
    transaction_day,
    transaction_day_of_week,
    transaction_day_name,
    
    -- Metadata
    current_timestamp as _mart_loaded_at

from transactions
