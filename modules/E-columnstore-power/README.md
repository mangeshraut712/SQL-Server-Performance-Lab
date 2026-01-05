# 📊 Module E: Analytical Powerhouse (Columnstore Indexes)

## 🎯 Objective
Demonstrate how to achieve **100x+ performance gains** on large-scale aggregation queries using Columnstore technology.

## ⚠️ The Problem: Row-Store Aggregations
Standard indexes (B-Trees) are "Row-Store." When you calculate a SUM or AVG over 500,000+ rows, the engine must read every row and every column in the index. This causes massive I/O and high CPU usage.

## 🚀 The Fix: Non-Clustered Columnstore
Columnstore stores data by *column* rather than row. It uses high-performance compression and "Batch Mode" processing, allowing it to skip unnecessary data entirely.

## 📈 Expected Results
- **Before (Row-Store):** ~45,000 logical reads, ~250ms CPU
- **After (Columnstore):** ~800 logical reads (or less), ~10ms CPU
- **Improvement:** 50x - 200x speedup ✅

## 🛠️ Lab Steps
1. Run `01-bad-query.sql` to see the slow aggregation.
2. Run `02-fix.sql` to create a Non-Clustered Columnstore Index.
3. Observe Batch Mode processing in the Execution Plan.
