# Module C: Parameter Sniffing

## 🎯 Objective

Understand why the same stored procedure can be blazing fast for one user and painfully slow for another—and how to fix it.

## ❌ The Problem

**Parameter Sniffing** occurs when:

1. SQL Server compiles a stored procedure using the **first parameter value**
2. Creates an execution plan optimized for that specific value
3. **Caches and reuses** that plan for all subsequent executions
4. The plan may be **terrible** for different parameter values

### Real-World Example

In our lab, VIP customers have ~40% of all orders, while regular customers have very few orders each.

- If the procedure is first called for a **VIP customer** (many orders):
  - Plan uses **Table Scan** (good for returning thousands of rows)
  - Plan is cached
  
- Second call for a **Regular customer** (few orders):
  - Same plan is used (Table Scan)
  - But this is **slow** for returning just 3 rows!
  - Should have used **Index Seek** instead

## 📊 Expected Results

| Scenario | First Exec (VIP) | Subsequent Exec (Regular) | After Fix |
|----------|------------------|---------------------------|-----------|
| Time | Fast | Slow (10-100x worse) | Consistent |
| Plan | Table Scan | Table Scan (wrong!) | Appropriate |

## 🔬 Lab Steps

### Step 1: Set Up the Problem

We've intentionally created a **data skew** in our lab:
- VIP customers: 5% of customers, 40% of orders
- Regular customers: 70% of customers, 25% of orders

### Step 2: Observe Parameter Sniffing

Execute `01-bad-query.sql` to see:
- First execution with a VIP customer
- Second execution with a regular customer
- Watch the performance degradation

### Step 3: Analyze the Root Cause

Execute `02-analysis.sql` to understand:
- How execution plans are cached
- The impact of data distribution
- Detecting parameter sniffing issues

### Step 4: Apply Fixes

Execute `03-fix.sql` to implement:
- OPTION (RECOMPILE)
- OPTION (OPTIMIZE FOR UNKNOWN)
- Plan Guides
- Dynamic SQL approaches

## 📁 Files in This Module

| File | Description |
|------|-------------|
| `01-bad-query.sql` | Demonstrates parameter sniffing in action |
| `02-analysis.sql` | Root cause analysis and detection |
| `03-fix.sql` | Multiple solution approaches |

## 📚 Solution Comparison

| Solution | Pros | Cons | Best For |
|----------|------|------|----------|
| RECOMPILE | Always optimal plan | Compilation overhead | Low-frequency queries |
| OPTIMIZE FOR value | Predictable plan | May be wrong for other values | Known typical value |
| OPTIMIZE FOR UNKNOWN | Uses average stats | May not be optimal for anyone | Variable distributions |
| Dynamic SQL | Full control | Security concerns (injection) | Complex scenarios |
| Plan Guide | No code changes | Complex to maintain | Legacy applications |

## 🔗 Related Topics

- Query Store for plan regression detection
- Plan Forcing
- Statistics and cardinality estimation
- Memory grants
