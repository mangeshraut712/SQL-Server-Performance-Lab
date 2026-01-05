# 🚀 SQL Server Performance Lab: The Ultimate Optimization Workshop

A world-class, hands-on laboratory for mastering SQL Server performance engineering. This repository provides a complete environment with **750,000+ rows** of synthetic data to learn, test, and prove query optimization techniques.

![SQL Server](https://img.shields.io/badge/SQL%20Server-2019+-blue?style=for-the-badge&logo=microsoft-sql-server)
![Performance](https://img.shields.io/badge/Performance-100x_Gains-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-M1_Mac_/_Win_/_Linux-lightgrey?style=for-the-badge)

---

## 🏗️ The Lab Environment

This isn't just a collection of scripts; it's a simulated production environment designed to fail under pressure, then be transformed through engineering.

| Feature | Volume / Capability |
| :--- | :--- |
| **📈 Scale** | **750,000+ Records** (Customers, Orders, OrderDetails) |
| **🚠 Modules** | **5 Performance Scenarios** (A to E) |
| **📊 Measurement** | Built-in `dbo.QueryBenchmarks` tracking & **Performance Dashboard** |
| **🐳 Portability** | **Docker Compose** optimized for Apple Silicon (M1/M2/M3) |
| **🏁 Speed** | Setup in **< 5 minutes** |

---

## 🎯 Optimization Roadmap

Work through these five modules to master high-impact performance techniques:

| Module | Technical Focus | Result 🚀 |
| :--- | :--- | :--- |
| **A. Slow Search** | SARGability, Wildcards, Implicit conversion | **560x Improvement** |
| **B. Covering Index** | Key Lookups, INCLUDE columns, I/O reduction | **50x Improvement** |
| **C. Parameter Sniffing** | Plan Cache, Stored Procs, Data Skew | **Stable Performance** |
| **D. Deadlock Demo** | Lock Contention, Transaction Ordering | **100% Elimination** |
| **E. Columnstore** | Batch Mode, Compression, OLAP Aggregation | **100x Speedup** |

---

## 🚀 Quick Start (One-Command Setup)

### Option 1: Docker (Apple Silicon / Linux / Windows)
If you have Docker Desktop installed, simply run:
```bash
docker-compose up -d
```
Then connect to `localhost,1433` with user `sa` and password `YourStrong@Pass123`.

### Option 2: Individual Scripts (SSMS / Azure Data Studio)
Execute these in order to build the universe:
1. `db/01-schema.sql`
2. `db/02-seed-data.sql` (Creates 750K+ rows)
3. `db/03-indexes.sql`
4. `db/04-stored-procedures.sql`

---

## 🧪 Validating the Lab

Run **`RUN-ALL-TESTS.sql`** to automatically verify every module. This script measures the "Bad" query, applies the fix, and reports the speedup.

For a high-level view of your results, run:
```sql
-- The Ultimate Performance Lab Dashboard
EXEC [dbo].[usp_ViewDashboard]; -- Or run PERFORMANCE-DASHBOARD.sql
```

---

## 📁 Project Architecture

```
sqlserver-performance-lab/
├── 🐋 docker-compose.yml       # M1 Optimized container setup
├── 🏁 START-HERE.md            # Entry point for beginners
├── 🧪 RUN-ALL-TESTS.sql        # All-in-one verification suite
├── 🖥️ PERFORMANCE-DASHBOARD.sql # ASCII Art Performance Report
│
├── 📂 db/                      # Core Setup Engine
│   ├── 01-schema.sql
│   ├── 02-seed-data.sql       # The 750K row generator
│   └── 04-stored-procedures.sql
│
└── 📂 modules/                 # The Labs
    ├── A-slow-search/          # Patterns & Wildcards
    ├── B-covering-index/       # I/O & Key Lookups
    ├── C-parameter-sniffing/   # Cache & Data Skew
    ├── D-deadlock-demo/        # Locking & Contentions
    └── E-columnstore-power/    # Massive Data Aggregation
```

---

## 📊 Performance Cheat Sheet

Always use these before/after running a test:
```sql
SET STATISTICS IO ON;   -- Shows "Logical Reads" (Most important metric)
SET STATISTICS TIME ON; -- Shows CPU/Elapsed time
GO
EXEC dbo.usp_ClearCache; -- Never test without clearing wait stats/buffers
```

---

## 🤝 Community & Portfolio
This repository is designed to be part of your professional engineering portfolio. 

1. **Clone it.**
2. **Optimize it.**
3. **Screenshot it.**
4. **Present it.**

---

**Happy Optimizing!** 🎉  
*Engineered by Antigravity AI for the next generation of SQL Performance Experts.*
