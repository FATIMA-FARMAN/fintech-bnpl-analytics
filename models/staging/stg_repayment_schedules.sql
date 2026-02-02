{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('repayment_schedules_sample') }}
),

renamed as (
    select
        -- Primary identifier
        repayment_id,
        
        -- Foreign keys
        transaction_id,
        customer_id,
        
        -- Installment details
        cast(installment_number as integer) as installment_number,
        cast(installment_due_date as date) as installment_due_date,
        cast(installment_amount as double) as installment_amount,
        
        -- Payment details
        cast(actual_payment_date as date) as actual_payment_date,
        cast(actual_payment_amount as double) as actual_payment_amount,
        
        -- Metadata
        current_timestamp as _loaded_at
        
    from source
)

select * from renamed
