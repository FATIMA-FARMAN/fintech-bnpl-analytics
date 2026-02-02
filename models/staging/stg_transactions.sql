{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('transactions_sample') }}
),

renamed as (
    select
        -- Primary identifiers
        transaction_id,
        order_id,
        
        -- Foreign keys
        merchant_id,
        customer_id,
        
        -- Timestamps
        cast(transaction_date as date) as transaction_date,
        cast(transaction_timestamp as timestamp) as transaction_timestamp,
        
        -- Transaction details
        lower(trim(transaction_status)) as transaction_status,
        lower(trim(payment_method)) as payment_method,
        
        -- Amounts (ensure proper decimals)
        cast(order_amount as double) as order_amount,
        cast(customer_paid_amount as double) as customer_paid_amount,
        cast(merchant_received_amount as double) as merchant_received_amount,
        cast(tabby_fee_amount as double) as tabby_fee_amount,
        
        -- Installment info (BNPL specific)
        cast(installment_plan as int64) as installment_plan,
        cast(first_installment_amount as double) as first_installment_amount,
        cast(subsequent_installment_amount as double) as subsequent_installment_amount,
        
        -- Timing metrics
        cast(authorization_to_capture_hours as double) as authorization_to_capture_hours,
        cast(capture_to_settlement_hours as double) as capture_to_settlement_hours,
        
        -- Risk attributes
        cast(risk_score as double) as risk_score,
        cast(is_fraudulent as bool) as is_fraudulent,
        
        -- Metadata
        current_timestamp as _loaded_at
        
    from source
)

select * from renamed
