{{
    config(
        materialized='view'
    )
}}

with repayments as (
    select * from {{ ref('stg_repayment_schedules') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

enriched_repayments as (
    select
        r.repayment_id,
        r.transaction_id,
        r.customer_id,
        r.installment_number,
        r.installment_due_date,
        r.installment_amount,
        r.actual_payment_date,
        r.actual_payment_amount,
        
        -- Customer context
        c.customer_segment,
        c.country as customer_country,
        c.age_group,
        
        -- Payment status logic
        case 
            when r.actual_payment_date is null 
                 and r.installment_due_date < current_date() 
            then 'missed'
            when r.actual_payment_date is null 
            then 'upcoming'
            when r.actual_payment_date <= r.installment_due_date 
            then 'on_time'
            when r.actual_payment_date > r.installment_due_date 
            then 'late'
        end as payment_status,
        
        -- Days late calculation
        case 
            when r.actual_payment_date is not null and r.actual_payment_date > r.installment_due_date
            then date_diff('day', r.installment_due_date, r.actual_payment_date)
            when r.actual_payment_date is null and r.installment_due_date < current_date()
            then date_diff('day', r.installment_due_date, current_date())
            else 0
        end as days_late,
        
        -- Default flag (missed payment > 30 days)
        case 
            when r.actual_payment_date is null 
                 and date_diff('day', r.installment_due_date, current_date()) > 30 
            then true 
            else false 
        end as is_defaulted,
        
        -- Late fee calculation
        case
            when r.actual_payment_date is not null 
                 and r.actual_payment_date > r.installment_due_date
            then round(r.actual_payment_amount - r.installment_amount, 2)
            else 0.0
        end as late_fee_amount,
        
        current_timestamp as _processed_at
        
    from repayments r
    left join customers c on r.customer_id = c.customer_id
)

select * from enriched_repayments
