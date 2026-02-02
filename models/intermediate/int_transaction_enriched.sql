{{
    config(
        materialized='view'
    )
}}

with transactions as (
    select * from {{ ref('stg_transactions') }}
),

merchants as (
    select * from {{ ref('stg_merchants') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

-- Determine if this is customer's first transaction
customer_first_transaction as (
    select
        customer_id,
        min(transaction_timestamp) as first_transaction_timestamp
    from transactions
    group by 1
),

enriched as (
    select
        -- Transaction core
        t.transaction_id,
        t.order_id,
        t.transaction_date,
        t.transaction_timestamp,
        t.transaction_status,
        t.payment_method,
        
        -- Foreign keys
        t.merchant_id,
        t.customer_id,
        
        -- Merchant context
        m.merchant_name,
        m.merchant_category,
        m.country as merchant_country,
        m.merchant_status,
        m.days_since_onboarding as merchant_days_since_onboarding,
        
        -- Customer context
        c.customer_segment,
        c.country as customer_country,
        c.age_group,
        c.is_verified as customer_is_verified,
        c.credit_limit,
        c.days_since_signup as customer_days_since_signup,
        
        -- Amounts
        t.order_amount,
        t.customer_paid_amount,
        t.merchant_received_amount,
        t.tabby_fee_amount,
        
        -- Installment info
        t.installment_plan,
        t.first_installment_amount,
        t.subsequent_installment_amount,
        
        -- Timing metrics
        t.authorization_to_capture_hours,
        t.capture_to_settlement_hours,
        
        -- Risk
        t.risk_score,
        t.is_fraudulent,
        
        -- Derived business flags
        case 
            when t.transaction_timestamp = cft.first_transaction_timestamp 
            then true 
            else false 
        end as is_first_transaction,
        
        case 
            when t.payment_method like 'bnpl%' then true 
            else false 
        end as is_bnpl_transaction,
        
        case 
            when t.transaction_status = 'settled' then t.order_amount 
            else 0 
        end as gmv,
        
        case 
            when t.transaction_status in ('authorized', 'captured', 'settled') 
            then 1 
            else 0 
        end as successful_transaction_flag,
        
        -- Derived metrics
        case 
            when t.merchant_received_amount > 0 
            then round((t.tabby_fee_amount / t.order_amount) * 100, 2)
            else null 
        end as effective_commission_rate_pct,
        
        -- Date parts for analysis
        extract(year from t.transaction_date) as transaction_year,
        extract(month from t.transaction_date) as transaction_month,
        extract(day from t.transaction_date) as transaction_day,
        extract(dayofweek from t.transaction_date) as transaction_day_of_week,
        strftime(t.transaction_date, '%A') as transaction_day_name,
        
        -- Load timestamp
        current_timestamp as _enriched_at
        
    from transactions t
    left join merchants m on t.merchant_id = m.merchant_id
    left join customers c on t.customer_id = c.customer_id
    left join customer_first_transaction cft on t.customer_id = cft.customer_id
)

select * from enriched
