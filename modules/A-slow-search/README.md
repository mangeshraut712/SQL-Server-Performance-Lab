# Module A: Slow Search Patterns

## 🎯 Objective

Learn why certain search patterns make SQL Server unable to use indexes efficiently, and how to rewrite queries for better performance.

## ❌ The Problem

Common search anti-patterns include:

1. **Leading wildcard LIKE**: `WHERE LastName LIKE '%smith%'`
2. **Function wrapping columns**: `WHERE UPPER(LastName) = 'SMITH'`
3. **Implicit conversions**: Comparing mismatched data types
4. **OR conditions across columns**: `WHERE LastName = 'X' OR Email = 'Y'`

These patterns force **table scans** or **index scans** instead of efficient **index seeks**.

## 📊 Expected Results

| Metric | Bad Query | Optimized Query | Improvement |
|--------|-----------|-----------------|-------------|
| Logical Reads | 2,800+ | 10-50 | 50-280x |
| CPU Time | 100+ ms | 1-5 ms | 20-100x |
| Index Operation | Scan | Seek | ✓ |

## 🔬 Lab Steps

### Step 1: Set Up Measurement

```sql
USE PerformanceLab;
GO

-- Enable statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Clear cache for accurate measurements
EXEC dbo.usp_ClearCache;
GO
```

### Step 2: Run the Bad Query

Execute `01-bad-query.sql` and note:
- Logical reads (should be ~2,800)
- CPU time (should be 50-200ms)
- Execution plan shows **Index Scan** or **Table Scan**

### Step 3: Analyze the Problem

Execute `02-analysis.sql` to understand:
- Why indexes can't be used
- What the query optimizer is doing
- Missing index suggestions

### Step 4: Apply the Fix

Execute `03-fix.sql` to see:
- Optimized query patterns
- New covering index creation
- Performance comparison

## 📁 Files in This Module

| File | Description |
|------|-------------|
| `01-bad-query.sql` | Demonstrates slow search patterns |
| `02-analysis.sql` | Explains why the queries are slow |
| `03-fix.sql` | Shows optimized solutions |

## 📚 Key Takeaways

1. **Never use leading wildcards** if you can avoid them
2. **Don't wrap columns in functions** - wrap the parameter instead
3. **Use COLLATE** for case-insensitive searches on indexed columns
4. **Consider full-text search** for complex text searching needs
5. **Create computed columns** for frequently-used expressions

## 🔗 Related Topics

- Full-Text Search indexing
- Computed columns with indexes
- Query Store for tracking regressions
