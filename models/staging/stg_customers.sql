{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('customers_sample') }}
),

renamed as (
    select
        -- Primary identifier
        customer_id,
        
        -- Customer details
        lower(trim(customer_segment)) as customer_segment,
        cast(signup_date as timestamp) as signup_date,
        upper(trim(country)) as country,
        trim(age_group) as age_group,
        cast(is_verified as bool) as is_verified,
        cast(credit_limit as double) as credit_limit,
        
        -- Derived fields
        date_diff('day', cast(signup_date as date), current_date()) as days_since_signup,        
        -- Metadata
        current_timestamp as _loaded_at
        
    from source
)

select * from renamed
