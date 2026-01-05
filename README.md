# 🚀 SQL Server Performance Lab

A hands-on laboratory for learning SQL Server query optimization with **measurable before/after results**. This repository contains real-world performance scenarios with 500K+ rows of synthetic data.

![SQL Server](https://img.shields.io/badge/SQL%20Server-2019+-blue?style=flat-square&logo=microsoft-sql-server)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Modules](#modules)
- [How to Measure Performance](#how-to-measure-performance)
- [Capturing Execution Plans](#capturing-execution-plans)
- [Project Structure](#project-structure)
- [Contributing](#contributing)

## 🎯 Overview

This lab demonstrates four critical SQL Server performance scenarios:

| Module | Description | Typical Improvement |
|--------|-------------|---------------------|
| **A. Slow Search** | LIKE patterns and function-wrapped columns | 10-100x faster |
| **B. Covering Index** | Eliminating key lookups | 5-20x faster |
| **C. Parameter Sniffing** | Plan cache issues with variable data | 2-50x faster |
| **D. Deadlock Demo** | Lock contention patterns | Eliminates deadlocks |

## 🔧 Prerequisites

- **SQL Server 2019+** (or Azure SQL Database)
- **SSMS** (SQL Server Management Studio) or **Azure Data Studio**
- ~500MB free disk space for the test database

## 🚀 Quick Start

### Step 1: Create the Database and Schema

Open SSMS or Azure Data Studio and execute:

```sql
-- Execute in order:
-- 1. db/01-schema.sql
-- 2. db/02-seed-data.sql (takes 1-2 minutes for 500K+ rows)
-- 3. db/03-indexes.sql
-- 4. db/04-stored-procedures.sql
```

### Step 2: Verify Setup

```sql
USE PerformanceLab;
GO

-- Check row counts
SELECT 'Customers' AS TableName, COUNT(*) AS RowCount FROM dbo.Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL
SELECT 'OrderDetails', COUNT(*) FROM dbo.OrderDetails
UNION ALL
SELECT 'Products', COUNT(*) FROM dbo.Products;
```

Expected output:
- Customers: ~50,000 rows
- Orders: ~200,000 rows
- OrderDetails: ~500,000 rows
- Products: ~1,000 rows

### Step 3: Run the Modules

Navigate to the `/modules` folder and work through each scenario:

```
modules/
├── A-slow-search/
├── B-covering-index/
├── C-parameter-sniffing/
└── D-deadlock-demo/
```

## 📚 Modules

### Module A: Slow Search Patterns
**Location:** `modules/A-slow-search/`

Learn why `LIKE '%search%'` and `UPPER(column)` kill performance, and how to fix them.

### Module B: Covering Indexes
**Location:** `modules/B-covering-index/`

Understand key lookups and how INCLUDE columns can dramatically reduce I/O.

### Module C: Parameter Sniffing
**Location:** `modules/C-parameter-sniffing/`

Discover why the same query runs fast for one user and slow for another.

### Module D: Deadlock Demo
**Location:** `modules/D-deadlock-demo/`

Create, capture, and resolve deadlocks with proper transaction design.

## 📊 How to Measure Performance

### Enable Statistics

Before running any query, enable these settings:

```sql
-- Show I/O statistics (logical reads, physical reads)
SET STATISTICS IO ON;

-- Show execution time
SET STATISTICS TIME ON;

-- Optional: Show actual execution plan
-- Click "Include Actual Execution Plan" (Ctrl+M) in SSMS
```

### Understanding the Output

```
-- STATISTICS IO Output:
Table 'Customers'. Scan count 1, logical reads 2847, physical reads 0

-- STATISTICS TIME Output:
SQL Server Execution Times:
   CPU time = 125 ms, elapsed time = 342 ms.
```

**Key Metrics:**
- **Logical Reads**: Pages read from memory (lower is better)
- **Physical Reads**: Pages read from disk (should be 0 after first run)
- **CPU Time**: Processing time
- **Elapsed Time**: Total wall-clock time

### Quick Comparison Template

```sql
-- Clear cache between tests (DEV ONLY - never in production!)
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Run BAD query
-- Record: Logical Reads: ___, CPU: ___ ms, Elapsed: ___ ms

-- Run FIXED query  
-- Record: Logical Reads: ___, CPU: ___ ms, Elapsed: ___ ms

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
```

## 🔍 Capturing Execution Plans

### Method 1: Actual Execution Plan (SSMS)

1. Open your query in SSMS
2. Press `Ctrl+M` or click **Query → Include Actual Execution Plan**
3. Execute the query
4. Click the **Execution Plan** tab at the bottom

### Method 2: Estimated Execution Plan

1. Highlight your query
2. Press `Ctrl+L` or click **Query → Display Estimated Execution Plan**
3. Plan appears without executing the query

### Method 3: XML Plan (Programmatic)

```sql
SET SHOWPLAN_XML ON;
GO

-- Your query here
SELECT * FROM dbo.Customers WHERE LastName = 'Smith';
GO

SET SHOWPLAN_XML OFF;
GO
```

### Method 4: Query Store (Recommended for Production)

```sql
-- Enable Query Store (one-time setup)
ALTER DATABASE PerformanceLab 
SET QUERY_STORE = ON;

-- View top resource-consuming queries
SELECT TOP 10
    qt.query_sql_text,
    rs.avg_duration / 1000.0 AS avg_duration_ms,
    rs.avg_logical_io_reads,
    rs.count_executions
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
ORDER BY rs.avg_duration DESC;
```

### Reading Execution Plans

Look for these warning signs:
- ⚠️ **Yellow warning triangles**: Missing indexes, implicit conversions
- 🔄 **Table Scan / Index Scan**: Full scans (usually bad for large tables)
- 🔗 **Key Lookup**: Extra I/O to fetch columns not in the index
- ➡️ **Thick arrows**: Large data flows between operators
- 📊 **Actual vs Estimated rows**: Large differences indicate stale statistics

## 📁 Project Structure

```
sqlserver-performance-lab/
│
├── README.md                    # This file
├── LICENSE                      # MIT License
├── .gitignore
│
├── db/                          # Database setup scripts
│   ├── 01-schema.sql           # Tables and constraints
│   ├── 02-seed-data.sql        # 500K+ rows of synthetic data
│   ├── 03-indexes.sql          # Index definitions
│   └── 04-stored-procedures.sql # Reusable procedures
│
└── modules/                     # Performance scenarios
    │
    ├── A-slow-search/
    │   ├── README.md
    │   ├── 01-bad-query.sql
    │   ├── 02-analysis.sql
    │   └── 03-fix.sql
    │
    ├── B-covering-index/
    │   ├── README.md
    │   ├── 01-bad-query.sql
    │   ├── 02-analysis.sql
    │   └── 03-fix.sql
    │
    ├── C-parameter-sniffing/
    │   ├── README.md
    │   ├── 01-bad-query.sql
    │   ├── 02-analysis.sql
    │   └── 03-fix.sql
    │
    └── D-deadlock-demo/
        ├── README.md
        ├── 01-setup.sql
        ├── 02-session-a.sql
        ├── 03-session-b.sql
        └── 04-fix.sql
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Happy Optimizing!** 🎉

*Created for SQL Server performance engineers who want hands-on experience with real optimization scenarios.*
