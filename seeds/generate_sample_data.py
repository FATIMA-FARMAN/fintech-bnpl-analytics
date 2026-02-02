"""
Generate realistic BNPL (Buy Now Pay Later) sample data for PayEase Analytics
Inspired by Tabby's business model in MENA region
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Set seed for reproducibility
np.random.seed(42)
random.seed(42)

print("🎲 Generating BNPL Sample Data...")

# ============================================================================
# 1. MERCHANTS SEED (40 merchants across different categories)
# ============================================================================
print("\n1️⃣ Generating merchants data...")

merchant_names = [
    # Fashion (15)
    'Zara MENA', 'H&M Middle East', 'Mango Fashion', 'Centrepoint', 'Massimo Dutti',
    'Pull&Bear UAE', 'Stradivarius', 'Brands for Less', 'Splash Fashion', 'Ounass',
    'The Giving Movement', 'Namshi', 'Level Shoes', 'Sun & Sand Sports', 'Bloomingdale\'s',
    
    # Electronics (10)
    'Noon Electronics', 'Jumbo Electronics', 'Sharaf DG', 'Emax', 'Virgin Megastore',
    'Axiom Telecom', 'iStyle Apple', 'Samsung Gulf', 'Carrefour Electronics', 'Lulu Electronics',
    
    # Home & Furniture (8)
    'IKEA UAE', 'Home Centre', 'The One', 'Pottery Barn', 'West Elm',
    'Danube Home', 'Pan Emirates', '2XL Furniture',
    
    # Beauty & Health (7)
    'Sephora Middle East', 'Boots Pharmacy', 'Paris Gallery', 'Faces',
    'The Body Shop', 'MAC Cosmetics', 'Nykaa Fashion'
]

merchants = pd.DataFrame({
    'merchant_id': [f'MERCH_{i:04d}' for i in range(1, 41)],
    'merchant_name': merchant_names,
    'merchant_category': (
        ['fashion'] * 15 + 
        ['electronics'] * 10 + 
        ['home'] * 8 + 
        ['beauty'] * 7
    ),
    'onboarding_date': pd.date_range('2022-01-01', periods=40, freq='2W'),
    'country': np.random.choice(['UAE', 'KSA', 'Egypt', 'Kuwait'], 40, p=[0.5, 0.3, 0.15, 0.05]),
    'merchant_status': ['active'] * 40,
    'commission_rate': np.round(np.random.uniform(0.02, 0.05, 40), 4)
})

print(f"   ✅ Generated {len(merchants)} merchants")

# ============================================================================
# 2. CUSTOMERS SEED (5,000 customers with realistic segments)
# ============================================================================
print("\n2️⃣ Generating customers data...")

customers = pd.DataFrame({
    'customer_id': [f'CUST_{i:06d}' for i in range(1, 5001)],
    'customer_segment': np.random.choice(
        ['premium', 'standard', 'new'], 
        5000, 
        p=[0.15, 0.55, 0.30]  # 15% premium, 55% standard, 30% new
    ),
    'signup_date': pd.date_range('2023-01-01', periods=5000, freq='2H'),
    'country': np.random.choice(['UAE', 'KSA', 'Egypt', 'Kuwait'], 5000, p=[0.5, 0.3, 0.15, 0.05]),
    'age_group': np.random.choice(['18-24', '25-34', '35-44', '45+'], 5000, p=[0.2, 0.5, 0.2, 0.1]),
    'is_verified': np.random.choice([True, False], 5000, p=[0.85, 0.15]),
    'credit_limit': np.random.choice([3000, 5000, 10000, 20000], 5000, p=[0.3, 0.4, 0.2, 0.1])
})

print(f"   ✅ Generated {len(customers)} customers")

# ============================================================================
# 3. TRANSACTIONS SEED (50,000 transactions over 6 months)
# ============================================================================
print("\n3️⃣ Generating transactions data...")

transactions = []
start_date = datetime(2024, 1, 1)
end_date = datetime(2024, 6, 30)
date_range_days = (end_date - start_date).days

for i in range(50000):
    # Random date weighted towards recent months
    days_offset = int(np.random.beta(2, 2) * date_range_days)
    transaction_date = start_date + timedelta(days=days_offset)
    transaction_timestamp = transaction_date + timedelta(
        hours=random.randint(8, 22),
        minutes=random.randint(0, 59),
        seconds=random.randint(0, 59)
    )
    
    # Select merchant and customer
    merchant_id = random.choice(merchants['merchant_id'].tolist())
    customer_id = random.choice(customers['customer_id'].tolist())
    
    # Get customer segment for realistic behavior
    customer_segment = customers[customers['customer_id'] == customer_id]['customer_segment'].iloc[0]
    
    # Payment method (BNPL vs Card) - varies by segment
    if customer_segment == 'premium':
        payment_method = np.random.choice(
            ['bnpl_4installments', 'bnpl_3installments', 'card'], 
            p=[0.4, 0.2, 0.4]
        )
    elif customer_segment == 'standard':
        payment_method = np.random.choice(
            ['bnpl_4installments', 'bnpl_3installments', 'card'], 
            p=[0.5, 0.3, 0.2]
        )
    else:  # new customers
        payment_method = np.random.choice(
            ['bnpl_4installments', 'bnpl_3installments', 'card'], 
            p=[0.6, 0.2, 0.2]
        )
    
    # Order amount - log-normal distribution (realistic e-commerce)
    # Premium customers spend more
    if customer_segment == 'premium':
        order_amount = round(np.random.lognormal(5.5, 0.8), 2)
    elif customer_segment == 'standard':
        order_amount = round(np.random.lognormal(5.0, 0.9), 2)
    else:
        order_amount = round(np.random.lognormal(4.5, 1.0), 2)
    
    # Cap at realistic maximums
    order_amount = min(order_amount, 10000)
    order_amount = max(order_amount, 50)  # Minimum order
    
    # Transaction status - realistic funnel
    # Premium customers have better success rates
    if customer_segment == 'premium':
        status = np.random.choice(
            ['authorized', 'captured', 'settled', 'failed', 'refunded'],
            p=[0.02, 0.03, 0.90, 0.04, 0.01]
        )
    else:
        status = np.random.choice(
            ['authorized', 'captured', 'settled', 'failed', 'refunded'],
            p=[0.05, 0.05, 0.80, 0.08, 0.02]
        )
    
    # Risk scoring
    base_risk = 0.1 if customer_segment == 'premium' else 0.3 if customer_segment == 'standard' else 0.5
    risk_score = round(min(1.0, max(0.0, np.random.normal(base_risk, 0.15))), 3)
    
    # Fraud flag (very rare, higher for high-risk customers)
    fraud_probability = 0.005 if customer_segment == 'premium' else 0.01 if customer_segment == 'standard' else 0.02
    is_fraudulent = np.random.choice([True, False], p=[fraud_probability, 1-fraud_probability])
    
    # Commission calculation (merchant pays Tabby)
    merchant_commission_rate = merchants[merchants['merchant_id'] == merchant_id]['commission_rate'].iloc[0]
    tabby_fee = round(order_amount * merchant_commission_rate, 2)
    
    # Customer and merchant amounts
    customer_paid_amount = order_amount
    merchant_received_amount = round(order_amount - tabby_fee, 2)
    
    # Installment details for BNPL
    if 'bnpl' in payment_method:
        installment_plan = 4 if payment_method == 'bnpl_4installments' else 3
        first_installment_amount = round(order_amount / installment_plan, 2)
        subsequent_installment_amount = round(order_amount / installment_plan, 2)
    else:
        installment_plan = None
        first_installment_amount = None
        subsequent_installment_amount = None
    
    # Timing metrics
    auth_to_capture_hours = round(np.random.uniform(0.1, 2.0), 2) if status in ['captured', 'settled'] else None
    capture_to_settlement_hours = round(np.random.uniform(1.0, 48.0), 2) if status == 'settled' else None
    
    transactions.append({
        'transaction_id': f'TXN_{i:08d}',
        'order_id': f'ORD_{i:08d}',
        'merchant_id': merchant_id,
        'customer_id': customer_id,
        'transaction_date': transaction_date.date(),
        'transaction_timestamp': transaction_timestamp,
        'transaction_status': status,
        'payment_method': payment_method,
        'order_amount': order_amount,
        'customer_paid_amount': customer_paid_amount,
        'merchant_received_amount': merchant_received_amount,
        'tabby_fee_amount': tabby_fee,
        'installment_plan': installment_plan,
        'first_installment_amount': first_installment_amount,
        'subsequent_installment_amount': subsequent_installment_amount,
        'authorization_to_capture_hours': auth_to_capture_hours,
        'capture_to_settlement_hours': capture_to_settlement_hours,
        'risk_score': risk_score,
        'is_fraudulent': is_fraudulent,
    })

transactions_df = pd.DataFrame(transactions)

print(f"   ✅ Generated {len(transactions_df)} transactions")
print(f"      - Settlement rate: {(transactions_df['transaction_status'] == 'settled').mean():.1%}")
print(f"      - BNPL transactions: {(transactions_df['payment_method'].str.contains('bnpl')).mean():.1%}")
print(f"      - Average order value: ${transactions_df['order_amount'].mean():.2f}")

# ============================================================================
# 4. REPAYMENT SCHEDULES SEED (for BNPL transactions only)
# ============================================================================
print("\n4️⃣ Generating repayment schedules data...")

repayments = []
repayment_id = 1

# Only for BNPL transactions
bnpl_transactions = transactions_df[transactions_df['payment_method'].str.contains('bnpl')].copy()

for _, txn in bnpl_transactions.iterrows():
    num_installments = int(txn['installment_plan'])
    installment_amount = round(txn['order_amount'] / num_installments, 2)
    
    # Get customer segment for realistic payment behavior
    customer_segment = customers[customers['customer_id'] == txn['customer_id']]['customer_segment'].iloc[0]
    
    for installment_num in range(1, num_installments + 1):
        # Due date: first installment due at purchase, rest every 30 days
        due_date = txn['transaction_date'] + timedelta(days=(installment_num - 1) * 30)
        
        # Payment behavior based on customer segment
        if customer_segment == 'premium':
            payment_status_probs = [0.95, 0.03, 0.02]  # on_time, late, missed
        elif customer_segment == 'standard':
            payment_status_probs = [0.85, 0.10, 0.05]
        else:  # new
            payment_status_probs = [0.75, 0.15, 0.10]
        
        payment_outcome = np.random.choice(['on_time', 'late', 'missed'], p=payment_status_probs)
        
        # Actual payment date
        if payment_outcome == 'on_time':
            days_offset = random.randint(-2, 0)  # Sometimes pays early
            actual_payment_date = due_date + timedelta(days=days_offset)
            actual_payment_amount = installment_amount
        elif payment_outcome == 'late':
            days_offset = random.randint(1, 15)
            actual_payment_date = due_date + timedelta(days=days_offset)
            # Late fee
            actual_payment_amount = round(installment_amount * 1.05, 2)
        else:  # missed
            actual_payment_date = None
            actual_payment_amount = None
        
        repayments.append({
            'repayment_id': f'RPY_{repayment_id:08d}',
            'transaction_id': txn['transaction_id'],
            'customer_id': txn['customer_id'],
            'installment_number': installment_num,
            'installment_due_date': due_date,
            'installment_amount': installment_amount,
            'actual_payment_date': actual_payment_date,
            'actual_payment_amount': actual_payment_amount,
        })
        
        repayment_id += 1

repayments_df = pd.DataFrame(repayments)

print(f"   ✅ Generated {len(repayments_df)} repayment records")
print(f"      - On-time payment rate: {(repayments_df['actual_payment_date'].notna()).mean():.1%}")

# ============================================================================
# SAVE ALL SEED FILES
# ============================================================================
print("\n💾 Saving seed files...")

merchants.to_csv('merchants_sample.csv', index=False)
print("   ✅ merchants_sample.csv")

customers.to_csv('customers_sample.csv', index=False)
print("   ✅ customers_sample.csv")

transactions_df.to_csv('transactions_sample.csv', index=False)
print("   ✅ transactions_sample.csv")

repayments_df.to_csv('repayment_schedules_sample.csv', index=False)
print("   ✅ repayment_schedules_sample.csv")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================
print("\n" + "="*60)
print("📊 SUMMARY STATISTICS")
print("="*60)

print("\n🏪 MERCHANTS:")
print(f"   Total merchants: {len(merchants)}")
print(f"   By category:")
for cat in merchants['merchant_category'].value_counts().items():
    print(f"      - {cat[0]}: {cat[1]}")

print("\n👥 CUSTOMERS:")
print(f"   Total customers: {len(customers)}")
print(f"   By segment:")
for seg in customers['customer_segment'].value_counts().items():
    print(f"      - {seg[0]}: {seg[1]}")

print("\n💳 TRANSACTIONS:")
print(f"   Total transactions: {len(transactions_df)}")
print(f"   Date range: {transactions_df['transaction_date'].min()} to {transactions_df['transaction_date'].max()}")
print(f"   Total GMV: ${transactions_df[transactions_df['transaction_status']=='settled']['order_amount'].sum():,.2f}")
print(f"   Payment methods:")
for method in transactions_df['payment_method'].value_counts().items():
    print(f"      - {method[0]}: {method[1]}")

print("\n📅 REPAYMENTS:")
print(f"   Total repayment records: {len(repayments_df)}")
print(f"   Paid on time: {(repayments_df['actual_payment_date'].notna()).sum()}")
print(f"   Missed payments: {(repayments_df['actual_payment_date'].isna()).sum()}")

print("\n✨ Data generation complete!")
print("="*60)
