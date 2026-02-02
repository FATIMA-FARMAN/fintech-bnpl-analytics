{{
    config(
        materialized='table',
        cluster_by=['customer_id', 'payment_status']
    )
}}

with repayments as (
    select
        repayment_id,
        transaction_id,
        customer_id,
        customer_segment,
        customer_country,
        age_group,
        
        installment_number,
        installment_due_date,
        installment_amount,
        
        actual_payment_date,
        actual_payment_amount,
        
        payment_status,
        days_late,
        is_defaulted,
        late_fee_amount
        
    from {{ ref('int_customer_repayment_behavior') }}
)

select
    *,
    
    -- Risk scoring based on payment behavior
    case
        when is_defaulted then 'high_risk'
        when payment_status = 'late' and days_late > 7 then 'medium_risk'
        when payment_status = 'missed' then 'high_risk'
        when payment_status = 'late' and days_late <= 7 then 'low_risk'
        when payment_status = 'on_time' then 'no_risk'
        else 'pending'
    end as customer_risk_category,
    
    -- Financial impact
    case
        when is_defaulted then installment_amount
        else 0
    end as defaulted_amount,
    
    case
        when payment_status = 'on_time' then 1
        else 0
    end as on_time_payment_flag,
    
    case
        when payment_status = 'late' then 1
        else 0
    end as late_payment_flag,
    
    case
        when payment_status = 'missed' then 1
        else 0
    end as missed_payment_flag,
    
    -- Date parts for cohort analysis
    extract(year from installment_due_date) as due_year,
    extract(month from installment_due_date) as due_month,
    strftime(installment_due_date, '%Y-%m') as due_year_month,
    
    -- Metadata
    current_timestamp as _mart_loaded_at

from repayments
