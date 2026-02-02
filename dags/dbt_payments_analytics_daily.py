"""
Airflow DAG for Payments Analytics Domain
Orchestrates daily dbt runs for BNPL analytics pipeline
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator
from airflow.utils.task_group import TaskGroup

# Default arguments
default_args = {
    'owner': 'analytics-engineering',
    'depends_on_past': False,
    'email': ['analytics@payease.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(hours=1),
}

# DAG definition
dag = DAG(
    'dbt_payments_analytics_daily',
    default_args=default_args,
    description='Daily BNPL analytics pipeline - transactions, merchants, repayments',
    schedule_interval='0 2 * * *',  # Daily at 2 AM UTC
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['dbt', 'payments', 'bnpl', 'analytics'],
)

# DBT project path
DBT_PROJECT_DIR = '/path/to/analytics-domain-ownership/domains/payments_analytics'
DBT_PROFILES_DIR = '/path/to/.dbt'

# Task: Start pipeline
start = DummyOperator(
    task_id='start_pipeline',
    dag=dag,
)

# Task Group: Staging layer
with TaskGroup('staging_models', dag=dag) as staging:
    run_stg_transactions = BashOperator(
        task_id='run_stg_transactions',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select stg_transactions --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    run_stg_merchants = BashOperator(
        task_id='run_stg_merchants',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select stg_merchants --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    run_stg_customers = BashOperator(
        task_id='run_stg_customers',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select stg_customers --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    run_stg_repayments = BashOperator(
        task_id='run_stg_repayment_schedules',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select stg_repayment_schedules --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    test_staging = BashOperator(
        task_id='test_staging_models',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt test --select staging --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    [run_stg_transactions, run_stg_merchants, run_stg_customers, run_stg_repayments] >> test_staging

# Task Group: Intermediate layer
with TaskGroup('intermediate_models', dag=dag) as intermediate:
    run_int_transactions = BashOperator(
        task_id='run_int_transaction_enriched',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select int_transaction_enriched --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    run_int_merchants = BashOperator(
        task_id='run_int_merchant_metrics',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select int_merchant_metrics --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    run_int_repayments = BashOperator(
        task_id='run_int_customer_repayment_behavior',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select int_customer_repayment_behavior --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    test_intermediate = BashOperator(
        task_id='test_intermediate_models',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt test --select intermediate --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    [run_int_transactions, run_int_merchants, run_int_repayments] >> test_intermediate

# Task Group: Marts layer (Fact Tables)
with TaskGroup('marts_facts', dag=dag) as marts_facts:
    # Incremental load of main fact table
    run_fct_transactions = BashOperator(
        task_id='run_fct_payment_transactions',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select fct_payment_transactions --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    # Full refresh of aggregated tables
    run_fct_merchant_gmv = BashOperator(
        task_id='run_fct_merchant_gmv_daily',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select fct_merchant_gmv_daily --full-refresh --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    run_fct_repayments = BashOperator(
        task_id='run_fct_repayment_performance',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select fct_repayment_performance --full-refresh --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    test_facts = BashOperator(
        task_id='test_fact_tables',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt test --select fct_payment_transactions fct_merchant_gmv_daily fct_repayment_performance --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    run_fct_transactions >> [run_fct_merchant_gmv, run_fct_repayments] >> test_facts

# Task Group: Marts layer (Dimension Tables)
with TaskGroup('marts_dimensions', dag=dag) as marts_dimensions:
    run_dim_merchant = BashOperator(
        task_id='run_dim_merchant',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select dim_merchant --full-refresh --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    run_dim_customer = BashOperator(
        task_id='run_dim_customer',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --select dim_customer --full-refresh --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    test_dimensions = BashOperator(
        task_id='test_dimension_tables',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt test --select dim_merchant dim_customer --profiles-dir {DBT_PROFILES_DIR}',
    )
    
    [run_dim_merchant, run_dim_customer] >> test_dimensions

# Task: Generate dbt documentation
generate_docs = BashOperator(
    task_id='generate_dbt_docs',
    bash_command=f'cd {DBT_PROJECT_DIR} && dbt docs generate --profiles-dir {DBT_PROFILES_DIR}',
    dag=dag,
)

# Task: Data quality report
data_quality_report = BashOperator(
    task_id='generate_qa_report',
    bash_command=f'cd {DBT_PROJECT_DIR} && python qa/generate_report.py',
    dag=dag,
)

# Task: End pipeline
end = DummyOperator(
    task_id='end_pipeline',
    dag=dag,
)

# Task: Send success notification
send_success_notification = BashOperator(
    task_id='send_success_notification',
    bash_command='echo "✅ Payments Analytics Pipeline completed successfully" | mail -s "Airflow Success" analytics@payease.com',
    dag=dag,
)

# Define task dependencies (linear flow with task groups)
start >> staging >> intermediate >> marts_facts >> marts_dimensions >> generate_docs >> data_quality_report >> send_success_notification >> end

# Optional: Separate branch for dimension refresh (weekly on Sunday)
# This can be configured with a separate DAG or conditional logic
