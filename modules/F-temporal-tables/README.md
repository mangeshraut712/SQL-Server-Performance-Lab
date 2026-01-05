# 🕐 Module F: Temporal Tables (System-Versioned Tables)

## 🎯 Objective
Demonstrate SQL Server 2022's **Temporal Tables** feature for automatic historical data tracking and point-in-time analysis.

## ⚠️ The Problem: Manual Audit Trails
Traditional audit logging requires complex triggers, separate audit tables, and manual timestamp management. This adds overhead and is error-prone.

## 🚀 The Fix: System-Versioned Temporal Tables
SQL Server automatically maintains a complete history of all changes without triggers or application logic. You can query data "as it was" at any point in time.

## 📈 Expected Results
- **Zero Application Code**: No triggers needed
- **Automatic History**: Every UPDATE/DELETE tracked automatically
- **Time-Travel Queries**: Query data as of any timestamp
- **Audit Compliance**: Built-in change tracking for regulations

## 🛠️ Lab Steps
1. Run `01-setup.sql` to create a temporal table
2. Run `02-demo.sql` to modify data and query history
3. Run `03-analysis.sql` to see time-travel queries in action

## 💡 Use Cases
- Regulatory compliance (SOX, GDPR)
- Data recovery and rollback
- Trend analysis and reporting
- Debugging data changes
