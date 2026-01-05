# 🚀 Quick Start Guide - SQL Server Performance Lab

## Step-by-Step: From Zero to Running

This guide walks you through **everything** from installing SQL Server to seeing your first 560x performance improvement.

**Time Required:** ~30 minutes for full setup

---

## 📋 Prerequisites Checklist

Before you start, you need:

- [ ] **Windows, macOS, or Linux** computer
- [ ] **4GB+ free RAM** (8GB recommended)
- [ ] **2GB free disk space**
- [ ] **Internet connection** (for initial SQL Server download)
- [ ] **Basic SQL knowledge** (SELECT, WHERE, JOIN)

---

## Part 1️⃣: Install SQL Server (15 minutes)

### Option A: Windows - SQL Server Express (FREE)

1. **Download SQL Server Express**
   - Go to: https://www.microsoft.com/sql-server/sql-server-downloads
   - Click "Download now" under "Express" (it's FREE)
   - Run the installer: `SQL2022-SSEI-Expr.exe`

2. **Choose Installation Type**
   - Select **"Basic"** installation
   - Accept license terms
   - Choose install location (default is fine)
   - Wait for download and install (~10 minutes)

3. **Note Your Connection String**
   - After installation, you'll see: `Server=localhost\SQLEXPRESS`
   - Write this down! You'll need it.

### Option B: macOS/Linux - Docker (Easier!)

```bash
# Pull SQL Server 2022 container
docker pull mcr.microsoft.com/mssql/server:2022-latest

# Run SQL Server container
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Password123" \
   -p 1433:1433 --name sqlserver2022 \
   -d mcr.microsoft.com/mssql/server:2022-latest

# Verify it's running
docker ps
```

**Connection Details:**
- Server: `localhost` or `127.0.0.1`
- Port: `1433`
- Username: `sa`
- Password: `YourStrong@Password123` (or whatever you set)

### Option C: Azure SQL Database (Cloud)

1. Go to: https://portal.azure.com
2. Create new SQL Database (free tier available)
3. Note connection string from portal

---

## Part 2️⃣: Install SQL Management Tool (5 minutes)

You need a tool to run SQL queries. Choose ONE:

### Option A: SSMS (Windows Only - Recommended)

1. **Download SSMS**
   - Go to: https://aka.ms/ssmsfullsetup
   - Run installer: `SSMS-Setup-ENU.exe`
   - Install with default options (~5 min)

2. **Launch SSMS**
   - Open "Microsoft SQL Server Management Studio 19"
   - You'll see a "Connect to Server" dialog

3. **Connect to Your Server**
   - Server type: `Database Engine`
   - Server name: `localhost\SQLEXPRESS` (or your Docker/Azure connection)
   - Authentication: `Windows Authentication` (or SQL Server Auth for Docker)
   - Click **Connect**

### Option B: Azure Data Studio (Cross-Platform)

1. **Download Azure Data Studio**
   - Go to: https://aka.ms/azuredatastudio
   - Download for macOS/Windows/Linux
   - Install (drag to Applications on macOS)

2. **Launch and Connect**
   - Open Azure Data Studio
   - Click "New Connection"
   - Server: `localhost` or `localhost\SQLEXPRESS`
   - Authentication: Choose appropriate type
   - Click **Connect**

---

## Part 3️⃣: Create the Performance Lab Database (10 minutes)

Now the fun begins! You'll create the database with 750K+ rows.

### Step 1: Download or Navigate to Scripts

If you cloned from GitHub:
```bash
cd sqlserver-performance-lab
```

If you're viewing files locally, just note the location:
```
/Users/mangeshraut/Downloads/sqlserver-performance-lab/
```

### Step 2: Run Schema Script (30 seconds)

**In SSMS:**
1. Click **File** → **Open** → **File**
2. Navigate to: `db/01-schema.sql`
3. Click **Open**
4. Press **F5** or click **Execute** button
5. Wait for "Schema creation complete!" message

**In Azure Data Studio:**
1. Click **File** → **Open File**
2. Select `db/01-schema.sql`
3. Click **Run** button (or press F5)
4. Check output pane for success message

**Expected Output:**
```
Creating schema...
  - dbo.Customers
  - dbo.Products
  - dbo.Orders
  - dbo.OrderDetails
  - dbo.Inventory
  - dbo.AuditLog
  - dbo.QueryBenchmarks

Schema creation complete!
```

### Step 3: Generate Test Data (2 minutes)

This is where we create 750K+ rows of realistic data.

1. **Open** `db/02-seed-data.sql`
2. **Execute** (F5)
3. **Wait** ~1-2 minutes (you'll see progress messages)

**What's Happening:**
```
Generating 1,000 products...
  Products created: 1000

Generating 50,000 customers...
  Customers created: 50000

Generating 200,000 orders (with data skew)...
  Orders created: 200000

Generating 500,000+ order details...
  OrderDetails created: 526841

Updating order totals...
  Order totals updated: 200000

Data generation complete!
```

**Verify It Worked:**
```sql
USE PerformanceLab;
GO

SELECT 'Customers' AS TableName, COUNT(*) AS RowCount FROM dbo.Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL
SELECT 'OrderDetails', COUNT(*) FROM dbo.OrderDetails
UNION ALL
SELECT 'Products', COUNT(*) FROM dbo.Products;
```

**Expected Output:**
```
TableName      RowCount
--------------------------
Customers      50000
Orders         200000
OrderDetails   500000+
Products       1000
```

✅ **You now have 750K+ rows of test data!**

### Step 4: Create Indexes (10 seconds)

1. **Open** `db/03-indexes.sql`
2. **Execute** (F5)
3. Wait for "Index creation complete!" message

### Step 5: Create Stored Procedures (10 seconds)

1. **Open** `db/04-stored-procedures.sql`
2. **Execute** (F5)
3. Wait for "Stored procedure creation complete!" message

---

## Part 4️⃣: Test Module A - See 560x Improvement! (5 minutes)

Let's run your first optimization and see REAL results.

### Step 1: Enable Measurement Tools

```sql
USE PerformanceLab;
GO

-- Turn on statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Enable execution plan (CTRL+M in SSMS or click "Explain" in Azure Data Studio)
```

**In SSMS:** Press `Ctrl+M` (or **Query** → **Include Actual Execution Plan**)  
**In Azure Data Studio:** Click the **Explain** button

### Step 2: Run the BAD Query

```sql
-- Clear cache for accurate measurement
EXEC dbo.usp_ClearCache;
GO

-- BAD: Leading wildcard search
SELECT CustomerID, FirstName, LastName, Email
FROM dbo.Customers
WHERE LastName LIKE '%smith%';
GO
```

**Look at the Messages Tab:**
```
BEFORE:
Table 'Customers'. Scan count 1, logical reads 2847, physical reads 0
CPU time = 125 ms, elapsed time = 342 ms.
```

**Look at the Execution Plan:**
- You'll see an **Index Scan** or **Clustered Index Scan**
- Cost should be ~100%
- No warnings (yet - this is just slow)

📝 **Write down:** Logical reads = ________ (should be ~2,800)

### Step 3: Run the GOOD Query

```sql
-- Clear cache again
EXEC dbo.usp_ClearCache;
GO

-- GOOD: Trailing wildcard (index-friendly)
SELECT CustomerID, FirstName, LastName, Email
FROM dbo.Customers
WHERE LastName LIKE 'Smith%';
GO
```

**Look at the Messages Tab:**
```
AFTER:
Table 'Customers'. Scan count 1, logical reads 5, physical reads 0
CPU time = 1 ms, elapsed time = 15 ms.
```

**Look at the Execution Plan:**
- You'll see an **Index Seek** (green icon)
- Much lower cost
- Minimal data flow

📝 **Write down:** Logical reads = ________ (should be ~5)

### Step 4: Calculate Your Improvement

```
Improvement = Before / After
            = 2847 / 5
            = 569x faster!
```

🎉 **You just achieved a 560x performance improvement!**

### Step 5: See the Full Module

For more examples, work through:
- `modules/A-slow-search/01-bad-query.sql` - 5 bad patterns
- `modules/A-slow-search/02-analysis.sql` - Why they're slow
- `modules/A-slow-search/03-fix.sql` - All the fixes

---

## Part 5️⃣: Test Module B - Key Lookup Elimination

### Quick Test: Covering Index

```sql
USE PerformanceLab;
SET STATISTICS IO ON;
GO

-- Find a VIP customer (they have many orders)
DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID 
FROM dbo.Customers WHERE CustomerType = 'V';

PRINT 'Testing customer: ' + CAST(@CustomerID AS VARCHAR);
GO

-- BEFORE: This will show Key Lookups
DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID 
FROM dbo.Customers WHERE CustomerType = 'V';

SELECT o.OrderID, o.OrderDate, o.Status, o.TotalAmount
FROM dbo.Orders o
WHERE o.CustomerID = @CustomerID;
GO
```

**Check the Execution Plan:**
- Look for **Key Lookup** operator (appears after Index Seek)
- See the thick arrow showing data flow
- Note the cost percentage split

📝 **Logical reads:** ________

**Now create the covering index:**

```sql
-- Create covering index
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID_Covering
ON dbo.Orders (CustomerID)
INCLUDE (OrderDate, Status, TotalAmount);
GO

-- AFTER: No more Key Lookups!
DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID 
FROM dbo.Customers WHERE CustomerType = 'V';

SELECT o.OrderID, o.OrderDate, o.Status, o.TotalAmount
FROM dbo.Orders o
WHERE o.CustomerID = @CustomerID;
GO
```

**Check the NEW Execution Plan:**
- No Key Lookup operator!
- Just Index Seek
- Much lower logical reads

📝 **Logical reads:** ________ (should be ~10x-50x better)

---

## Part 6️⃣: Test Module C - Parameter Sniffing

This is the "same query, different performance" problem.

### Quick Test:

```sql
USE PerformanceLab;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Clear cache to start fresh
EXEC dbo.usp_ClearCache;
GO

-- First execution with VIP customer (many orders)
PRINT '=== Execution 1: VIP Customer (compiles plan) ===';
EXEC dbo.usp_GetOrdersByCustomer @CustomerID = 1;
GO

-- Second execution with Regular customer (reuses VIP plan - BAD!)
PRINT '=== Execution 2: Regular Customer (reuses plan) ===';
DECLARE @RegularCustomer INT;
SELECT TOP 1 @RegularCustomer = c.CustomerID
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerType = 'R'
GROUP BY c.CustomerID
HAVING COUNT(*) <= 3;

EXEC dbo.usp_GetOrdersByCustomer @CustomerID = @RegularCustomer;
GO
```

**Compare the metrics:**
- Execution 1 vs Execution 2
- Should have similar logical reads (even though row counts differ!)
- This is parameter sniffing in action

**Test the fix:**

```sql
-- Clear cache
EXEC dbo.usp_ClearCache;
GO

-- Use the RECOMPILE version
EXEC dbo.usp_GetOrdersByCustomer_Recompile @CustomerID = @RegularCustomer;
GO
```

Now it should be optimized for the actual row count!

---

## Part 7️⃣: Test Module D - Deadlock Demo

This requires **TWO query windows** running at the same time.

### Setup:

1. **Run setup script:**
   ```sql
   -- In ONE window, run:
   USE PerformanceLab;
   EXEC modules/D-deadlock-demo/01-setup.sql;
   ```

2. **Open TWO separate query windows in SSMS/Azure Data Studio**

### Create a Deadlock:

**Window 1:**
```sql
-- Copy entire contents of modules/D-deadlock-demo/02-session-a.sql
-- Run it (F5)
-- It will say "Waiting 5 seconds..."
```

**Window 2 (IMMEDIATELY after Window 1):**
```sql
-- Copy entire contents of modules/D-deadlock-demo/03-session-b.sql
-- Run it (F5)
```

**What Happens:**
- Both sessions start
- Both acquire their first lock
- Both wait 5 seconds
- Both try to get the second lock
- **DEADLOCK!** One session will get error 1205
- The other completes successfully

**Expected Error in One Window:**
```
Msg 1205, Level 13, State 51
Transaction (Process ID XX) was deadlocked on lock resources 
with another process and has been chosen as the deadlock victim. 
Rerun the transaction.
```

✅ **You just created a real deadlock!**

### See the Deadlock Graph:

```sql
-- View captured deadlocks
SELECT TOP 1
    CAST(e.event_data AS XML).value('(event/data[@name="xml_report"]/value)[1]', 'nvarchar(max)') AS DeadlockGraph
FROM sys.fn_xe_file_target_read_file('DeadlockCapture*.xel', NULL, NULL, NULL) e
WHERE e.object_name = 'xml_deadlock_report'
ORDER BY e.timestamp DESC;
```

Click the XML output to see the deadlock graph visualization!

---

## 🎯 Quick Verification Checklist

After setup, verify everything works:

```sql
USE PerformanceLab;
GO

-- ✅ Check row counts
SELECT 
    'Customers' AS TableName, 
    COUNT(*) AS Rows, 
    CASE WHEN COUNT(*) >= 50000 THEN '✅' ELSE '❌' END AS Status
FROM dbo.Customers
UNION ALL
SELECT 'Orders', COUNT(*), CASE WHEN COUNT(*) >= 200000 THEN '✅' ELSE '❌' END FROM dbo.Orders
UNION ALL
SELECT 'OrderDetails', COUNT(*), CASE WHEN COUNT(*) >= 500000 THEN '✅' ELSE '❌' END FROM dbo.OrderDetails;
GO

-- ✅ Check indexes
EXEC dbo.usp_IndexUsageStats;
GO

-- ✅ Check stored procedures
SELECT name FROM sys.procedures WHERE is_ms_shipped = 0 ORDER BY name;
GO

-- ✅ Test utility procedure
EXEC dbo.usp_MissingIndexes;
GO
```

---

## 📊 Full Module Walkthrough Order

Work through modules in this order:

### 1️⃣ **Module A** (30 minutes)
- `modules/A-slow-search/README.md` - Read overview
- `modules/A-slow-search/01-bad-query.sql` - Run bad examples
- `modules/A-slow-search/02-analysis.sql` - Understand why
- `modules/A-slow-search/03-fix.sql` - Implement fixes

**Goal:** Achieve 560x improvement

### 2️⃣ **Module B** (30 minutes)
- `modules/B-covering-index/README.md`
- `modules/B-covering-index/01-bad-query.sql`
- `modules/B-covering-index/02-analysis.sql`
- `modules/B-covering-index/03-fix.sql`

**Goal:** Eliminate Key Lookups, 50x improvement

### 3️⃣ **Module C** (30 minutes)
- `modules/C-parameter-sniffing/README.md`
- `modules/C-parameter-sniffing/01-bad-query.sql`
- `modules/C-parameter-sniffing/02-analysis.sql`
- `modules/C-parameter-sniffing/03-fix.sql`

**Goal:** Consistent performance

### 4️⃣ **Module D** (20 minutes)
- `modules/D-deadlock-demo/README.md`
- `modules/D-deadlock-demo/01-setup.sql`
- Run 02 and 03 in parallel
- `modules/D-deadlock-demo/04-fix.sql`

**Goal:** Understand and prevent deadlocks

---

## 🐛 Troubleshooting

### "Cannot connect to server"

**SQL Express:**
```
Server name should be: localhost\SQLEXPRESS
If that fails, try: .\SQLEXPRESS or (localdb)\MSSQLLocalDB
```

**Docker:**
```bash
# Check if container is running
docker ps

# Check logs
docker logs sqlserver2022

# Restart container
docker restart sqlserver2022
```

### "Database 'PerformanceLab' does not exist"

You need to run the setup scripts first:
```sql
-- Run in order:
db/01-schema.sql
db/02-seed-data.sql
db/03-indexes.sql
db/04-stored-procedures.sql
```

### "Procedure dbo.usp_ClearCache not found"

Run: `db/04-stored-procedures.sql`

### "Out of memory" during seed data

Reduce row counts in `02-seed-data.sql`:
- Line with `SELECT TOP 50000` → change to `TOP 10000`
- Line with `SELECT TOP 200000` → change to `TOP 50000`

### Execution plans not showing

**SSMS:** Press `Ctrl+M` before running query  
**Azure Data Studio:** Click **Explain** button

---

## 💡 Pro Tips

### Save Your Results

Create a results folder:
```sql
-- Record your measurements
INSERT INTO dbo.QueryBenchmarks (TestName, QueryType, LogicalReads, CPUTimeMs, Notes)
VALUES 
    ('My Test - Module A', 'BAD', 2847, 125, 'Leading wildcard'),
    ('My Test - Module A', 'OPTIMIZED', 5, 1, 'Trailing wildcard with index');
GO

-- View your results
SELECT * FROM dbo.QueryBenchmarks ORDER BY TestDate DESC;
```

### Clear Cache Responsibly

```sql
-- ⚠️ ONLY IN DEVELOPMENT!
-- This clears ALL cached data and plans
EXEC dbo.usp_ClearCache;

-- In production, use:
DBCC FREEPROCCACHE WITH NO_INFOMSGS;  -- Just clear one plan
```

### Monitor Real-Time

```sql
-- See what SQL Server is doing RIGHT NOW
SELECT 
    session_id,
    status,
    command,
    wait_type,
    wait_time,
    cpu_time,
    logical_reads,
    text
FROM sys.dm_exec_requests
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
WHERE session_id > 50;
```

---

## ✅ Success Criteria

You'll know it's working when:

- ✅ Database has 750K+ rows
- ✅ Module A shows ~560x improvement
- ✅ Module B eliminates Key Lookups
- ✅ Module C shows consistent times with RECOMPILE
- ✅ Module D creates a deadlock (then fixes it)
- ✅ Execution plans show before/after differences
- ✅ STATISTICS IO shows reduced logical reads

---

## 🎓 Next Steps

Once you've run everything:

1. **Document your results** - Screenshot execution plans
2. **Create a blog post** - Write about one module
3. **Add to portfolio** - Push to GitHub
4. **Practice explaining** - Use for interview prep

---

## 📞 Getting Help

If stuck, check:

1. **Error messages** in Messages pane
2. **Module README files** for specific guidance
3. **Code comments** in SQL scripts
4. **SQL Server error log** for system issues

Common issues are usually:
- Connection string wrong
- Scripts run out of order
- SQL Server version too old (need 2016+)

---

**You're ready! Start with Part 1 and work your way through. In 30 minutes, you'll have a working performance lab with measurable results.** 🚀
