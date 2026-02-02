{{
    config(
        materialized='table'
    )
}}

with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_transactions as (
    select
        customer_id,
        count(*) as lifetime_transactions,
        count(distinct merchant_id) as unique_merchants_used,
        sum(gmv) as lifetime_gmv,
        avg(order_amount) as avg_order_value,
        min(transaction_date) as first_transaction_date,
        max(transaction_date) as last_transaction_date,
        count(case when is_bnpl_transaction then 1 end) as bnpl_transactions,
        avg(risk_score) as avg_risk_score
    from {{ ref('fct_payment_transactions') }}
    where transaction_status = 'settled'
    group by 1
),

customer_repayments as (
    select
        customer_id,
        count(*) as total_installments,
        count(case when payment_status = 'on_time' then 1 end) as on_time_payments,
        count(case when payment_status = 'late' then 1 end) as late_payments,
        count(case when payment_status = 'missed' then 1 end) as missed_payments,
        count(case when is_defaulted then 1 end) as defaulted_payments,
        avg(days_late) as avg_days_late
    from {{ ref('fct_repayment_performance') }}
    group by 1
)

select
    -- Primary key
    c.customer_id,
    
    -- Customer attributes
    c.customer_segment,
    c.signup_date,
    c.country,
    c.age_group,
    c.is_verified,
    c.credit_limit,
    c.days_since_signup,
    
    -- Transaction lifetime metrics
    coalesce(ct.lifetime_transactions, 0) as lifetime_transactions,
    coalesce(ct.unique_merchants_used, 0) as unique_merchants_used,
    coalesce(ct.lifetime_gmv, 0) as lifetime_gmv,
    coalesce(ct.avg_order_value, 0) as avg_order_value,
    ct.first_transaction_date,
    ct.last_transaction_date,
    coalesce(ct.bnpl_transactions, 0) as bnpl_transactions,
    coalesce(ct.avg_risk_score, 0) as avg_risk_score,
    
    -- Repayment behavior metrics
    coalesce(cr.total_installments, 0) as total_installments,
    coalesce(cr.on_time_payments, 0) as on_time_payments,
    coalesce(cr.late_payments, 0) as late_payments,
    coalesce(cr.missed_payments, 0) as missed_payments,
    coalesce(cr.defaulted_payments, 0) as defaulted_payments,
    coalesce(cr.avg_days_late, 0) as avg_days_late,
    
    -- Calculated repayment rate
    cast(cr.on_time_payments as double) / nullif(cast(cr.total_installments as double), 0) as on_time_payment_rate,
    
    -- Customer value tier based on lifetime GMV
    case
        when ct.lifetime_gmv >= 5000 then 'vip'
        when ct.lifetime_gmv >= 2000 then 'high_value'
        when ct.lifetime_gmv >= 500 then 'medium_value'
        when ct.lifetime_gmv > 0 then 'low_value'
        else 'no_purchases'
    end as customer_value_tier,
    
    -- Risk tier based on payment behavior
    case
        when cr.defaulted_payments > 0 then 'high_risk'
        when cast(cr.late_payments + cr.missed_payments as double) / nullif(cast(cr.total_installments as double), 0) > 0.2 then 'medium_risk'
        when cast(cr.on_time_payments as double) / nullif(cast(cr.total_installments as double), 0) >= 0.95 then 'low_risk'
        when cr.total_installments = 0 then 'no_bnpl_history'
        else 'medium_risk'
    end as repayment_risk_tier,
    
    -- Days since last activity
    date_diff('day', ct.last_transaction_date, current_date()) as days_since_last_transaction,
    
    -- Metadata
    current_timestamp as _dimension_loaded_at

from customers c
left join customer_transactions ct on c.customer_id = ct.customer_id
left join customer_repayments cr on c.customer_id = cr.customer_id
