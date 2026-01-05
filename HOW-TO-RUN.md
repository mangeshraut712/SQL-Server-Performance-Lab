# 🧪 How to Run and Test the Project

## Quick Start: Run Everything

Follow these steps **in order**:

---

## Step 1️⃣: Install SQL Server (If Not Already Installed)

### Windows:
1. Download: https://www.microsoft.com/sql-server/sql-server-downloads
2. Choose **Express** (free version)
3. Run installer, choose **Basic** installation
4. Note the connection string shown at the end

### macOS/Linux (Docker):
```bash
docker pull mcr.microsoft.com/mssql/server:2022-latest

docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Pass123" \
   -p 1433:1433 --name sqlserver \
   -d mcr.microsoft.com/mssql/server:2022-latest
```

---

## Step 2️⃣: Install SQL Management Tool

### Windows - SSMS (Recommended):
1. Download: https://aka.ms/ssmsfullsetup
2. Install with default options
3. Launch SSMS
4. Connect to: `localhost\SQLEXPRESS`

### macOS/Linux - Azure Data Studio:
1. Download: https://aka.ms/azuredatastudio
2. Install and launch
3. Connect to: `localhost` (or `localhost,1433` for Docker)

---

## Step 3️⃣: Create the Database

**Run these scripts IN ORDER:**

### In SSMS:
1. **File** → **Open** → **File**
2. Navigate to: `db/01-schema.sql`
3. Press **F5** (Execute)
4. Wait for "Schema creation complete!" message

### Repeat for:
- `db/02-seed-data.sql` ⏳ **(Wait ~2 minutes - this creates 750K+ rows)**
- `db/03-indexes.sql`
- `db/04-stored-procedures.sql`

---

## Step 4️⃣: Verify Setup

Run this verification query:

```sql
USE PerformanceLab;

SELECT 'Customers' AS TableName, COUNT(*) AS Rows FROM dbo.Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL
SELECT 'OrderDetails', COUNT(*) FROM dbo.OrderDetails
UNION ALL
SELECT 'Products', COUNT(*) FROM dbo.Products;
```

**Expected Output:**
```
TableName       Rows
--------------------------
Customers       50000
Orders          200000
OrderDetails    500000+
Products        1000
```

✅ **If you see these numbers, setup is complete!**

---

## Step 5️⃣: Run the Complete Test Suite

### Automated Testing (Recommended First):

1. **Open** `RUN-ALL-TESTS.sql` in SSMS/Azure Data Studio
2. **Press F5** (Execute)
3. **Watch the results** - it will test all 4 modules automatically
4. **Review** the summary table at the end

**Expected Time:** ~5 minutes

**What It Tests:**
- ✅ Module A: Slow Search → 560x improvement
- ✅ Module B: Covering Index → 50x improvement
- ✅ Module C: Parameter Sniffing → Consistent performance
- ✅ Module D: Deadlock Prevention → Elimination verified

**Expected Output:**
```
╔══════════════════════════════════════════════════════════════════╗
║  TEST SUITE COMPLETE!                                            ║
╚══════════════════════════════════════════════════════════════════╝

TestNumber  Module                          ExpectedImprovement       Status
---------------------------------------------------------------------------
1           Module A: Slow Search           560x faster              ✅ PASS
2           Module B: Covering Index        50x faster               ✅ PASS
3           Module C: Parameter Sniffing    Consistent performance   ✅ PASS
4           Module D: Deadlock Prevention   100% elimination         ✅ PASS
```

---

## Step 6️⃣: Test Individual Modules (Detailed)

### 📊 Module A: Slow Search (560x Improvement)

1. **Enable statistics:**
   ```sql
   SET STATISTICS IO ON;
   SET STATISTICS TIME ON;
   ```

2. **Enable execution plan:**
   - SSMS: Press `Ctrl+M`
   - Azure Data Studio: Click **Explain** button

3. **Open and run:**
   - `modules/A-slow-search/01-bad-query.sql`
   - Look for ~2,800 logical reads

4. **Run the fix:**
   - `modules/A-slow-search/03-fix.sql`
   - Look for ~5 logical reads

5. **Calculate:** 2,800 / 5 = **560x faster!** ✅

---

### 📊 Module B: Covering Index (50x Improvement)

1. **Enable statistics and execution plan**

2. **Open and run:**
   - `modules/B-covering-index/01-bad-query.sql`
   - Look for **Key Lookup** operator in execution plan
   - Note ~5,000+ logical reads

3. **Run the fix:**
   - `modules/B-covering-index/03-fix.sql`
   - No more Key Lookup!
   - Note ~100 logical reads

4. **Calculate:** 5,000 / 100 = **50x faster!** ✅

---

### 📊 Module C: Parameter Sniffing (Consistency)

1. **Open and run all steps:**
   - `modules/C-parameter-sniffing/01-bad-query.sql`
   - Follow the instructions to run VIP customer first, then Regular
   - Observe different performance for same query

2. **Apply fix:**
   - `modules/C-parameter-sniffing/03-fix.sql`
   - Test with RECOMPILE version
   - Observe consistent performance ✅

---

### 📊 Module D: Deadlock Demo (Elimination)

**⚠️ Requires TWO query windows!**

1. **Run setup:**
   - `modules/D-deadlock-demo/01-setup.sql`

2. **Open TWO separate query windows**

3. **Window 1:**
   - Load `modules/D-deadlock-demo/02-session-a.sql`
   - Press F5

4. **Window 2 (IMMEDIATELY):**
   - Load `modules/D-deadlock-demo/03-session-b.sql`
   - Press F5

5. **Result:**
   - One window will show **Msg 1205** (deadlock victim) ⚠️
   - Other window completes successfully
   - You just created a real deadlock!

6. **Test the fix:**
   - `modules/D-deadlock-demo/04-fix.sql`
   - Run with consistent locking
   - No deadlock! ✅

---

## 🎯 Quick Test Checklist

Use this to verify everything:

```
Setup Phase:
□ SQL Server installed and running
□ SSMS or Azure Data Studio installed
□ Connected to server successfully
□ Ran db/01-schema.sql
□ Ran db/02-seed-data.sql (waited for completion)
□ Ran db/03-indexes.sql
□ Ran db/04-stored-procedures.sql
□ Verified row counts (750K+ total)

Testing Phase:
□ Ran RUN-ALL-TESTS.sql successfully
□ All 4 modules show ✅ PASS

Detailed Testing (Optional):
□ Module A: Saw 560x improvement
□ Module B: Eliminated Key Lookups
□ Module C: Achieved consistency
□ Module D: Created and fixed deadlock
```

---

## 📸 Capture Evidence for Portfolio

For each module:

1. **Before running query:**
   - Press `Ctrl+M` (SSMS) or click **Explain** (Azure Data Studio)

2. **After running:**
   - **Execution Plan tab:** Right-click → Save As → `module-X-before.sqlplan`
   - **Messages tab:** Screenshot showing STATISTICS IO output
   - **Results tab:** Screenshot of output

3. **After fix:**
   - Repeat above
   - Save as `module-X-after.sqlplan`

**Create folder structure:**
```
portfolio/
  module-a-slow-search/
    before-plan.sqlplan
    before-stats.png
    after-plan.sqlplan
    after-stats.png
  module-b-covering-index/
    ...
```

---

## 🐛 Troubleshooting

### "Cannot connect to server"
```
Try these connection strings:
- localhost\SQLEXPRESS
- .\SQLEXPRESS
- (localdb)\MSSQLLocalDB
- localhost,1433 (Docker)
```

### "Database does not exist"
```sql
-- Run in order:
db/01-schema.sql
db/02-seed-data.sql
db/03-indexes.sql
db/04-stored-procedures.sql
```

### "Not seeing improvement"
```
1. Make sure you clear cache: EXEC dbo.usp_ClearCache;
2. Enable STATISTICS IO: SET STATISTICS IO ON;
3. Look at Messages tab (not Results tab)
4. Compare "logical reads" values
```

### "02-seed-data.sql taking too long"
```
Expected time: 1-2 minutes
If longer than 5 minutes:
- Check available RAM (needs ~2GB free)
- Close other applications
- Check SQL Server isn't busy
```

---

## ✅ Success Criteria

You know it's working when:

| Module | Success Indicator |
|--------|-------------------|
| **A** | ~2,800 reads → ~5 reads (560x) |
| **B** | Key Lookup gone, ~5,000 → ~100 reads (50x) |
| **C** | Consistent execution times with RECOMPILE |
| **D** | Deadlock created, then eliminated with fix |

---

## 🎓 Next Steps After Testing

1. ✅ All tests pass → **Capture screenshots**
2. ✅ Screenshots captured → **Document results**
3. ✅ Results documented → **Add to portfolio**
4. ✅ Portfolio ready → **Practice explaining to others**
5. ✅ Can explain clearly → **Ready for interviews!**

---

## 📞 Quick Command Reference

```sql
-- Always run before each test
EXEC dbo.usp_ClearCache;

-- Enable measurement
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Verify row counts
SELECT 'Customers', COUNT(*) FROM dbo.Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders;

-- View all indexes
EXEC dbo.usp_IndexUsageStats;

-- Find missing indexes
EXEC dbo.usp_MissingIndexes;
```

---

**🚀 Ready to test? Start with Step 1 and work your way through. In 30 minutes, you'll have measurable results proving 560x SQL optimization!**
