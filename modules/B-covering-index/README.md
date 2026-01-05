# Module B: Covering Indexes & Query Rewrites

## 🎯 Objective

Learn how to eliminate expensive **Key Lookups** using covering indexes and how to optimize JOIN queries for maximum performance.

## ❌ The Problem

Even when SQL Server uses an index seek, it may still need to:

1. **Key Lookup**: Go back to the clustered index to fetch additional columns
2. **Nested Loop with expensive lookups**: For each row, perform a separate disk read
3. **Wide result sets**: Returning more columns than the index contains

A Key Lookup happens when your query SELECTs columns that aren't in the index being used.

## 📊 Expected Results

| Metric | Without Covering Index | With Covering Index | Improvement |
|--------|------------------------|---------------------|-------------|
| Logical Reads | 5,000+ | 100-500 | 10-50x |
| Key Lookups | Yes | No | ✓ |
| Query Cost | High | Low | ✓ |

## 🔬 Lab Steps

### Step 1: Understand Key Lookups

A Key Lookup happens when:
1. SQL Server finds qualifying rows using a nonclustered index
2. But needs to fetch additional columns from the base table
3. This requires a separate I/O for each row found

### Step 2: Run the Bad Query

Execute `01-bad-query.sql` and look for:
- "Key Lookup" operator in the execution plan
- High logical reads despite using an index
- Thick arrow between Index Seek and Key Lookup

### Step 3: Analyze the Problem

Execute `02-analysis.sql` to understand:
- Which columns are causing the key lookups
- The cost difference between seek and lookup
- How to identify covering index opportunities

### Step 4: Apply the Fix

Execute `03-fix.sql` to:
- Create covering indexes with INCLUDE columns
- See the dramatic performance improvement
- Learn query rewrite techniques

## 📁 Files in This Module

| File | Description |
|------|-------------|
| `01-bad-query.sql` | Queries that cause expensive key lookups |
| `02-analysis.sql` | Identify and understand key lookup costs |
| `03-fix.sql` | Covering indexes and query rewrites |

## 📚 Key Concepts

### Covering Index
An index that "covers" a query by including all the columns the query needs:

```sql
-- Original index (not covering)
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);

-- Covering index
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID)
INCLUDE (OrderDate, Status, TotalAmount);
```

### INCLUDE Columns
- Not part of the index key (not sorted)
- Stored at the leaf level of the index
- Reduce storage compared to adding to key
- Perfect for frequently-selected columns

### When to Use Covering Indexes
✅ Frequently-run queries with specific column patterns
✅ Queries returning small result sets
✅ When Key Lookups show high cost in plans

❌ Wide tables with many columns
❌ Infrequent queries
❌ When too many indexes slow down writes

## 🔗 Related Topics

- Index key vs included columns
- Filtered indexes
- Index intersection
- Index consolidation strategies
