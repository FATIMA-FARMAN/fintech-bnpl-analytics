{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('merchants_sample') }}
),

renamed as (
    select
        -- Primary identifier
        merchant_id,
        
        -- Merchant details
        trim(merchant_name) as merchant_name,
        lower(trim(merchant_category)) as merchant_category,
        cast(onboarding_date as date) as onboarding_date,
        upper(trim(country)) as country,
        lower(trim(merchant_status)) as merchant_status,
        
        -- Financial
        cast(commission_rate as double) as commission_rate,
        
        -- Derived fields
        date_diff('day', cast(onboarding_date as date), current_date()) as days_since_onboarding,
        
        -- Metadata
        current_timestamp as _loaded_at
        
    from source
)

select * from renamed
