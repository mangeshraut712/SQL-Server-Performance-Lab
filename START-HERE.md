# 🚀 START HERE - SQL Server Performance Lab

## Welcome! Here's How to Get Started

You have **two main documents** to guide you:

---

## 📖 **1. QUICKSTART-GUIDE.md** - Installation & Setup

**👉 START WITH THIS if you need to:**
- Install SQL Server
- Install SSMS or Azure Data Studio
- Create the database
- Generate 750K+ rows of test data
- Verify everything works

**Time:** ~30 minutes to complete setup

**Read:** [QUICKSTART-GUIDE.md](QUICKSTART-GUIDE.md)

---

## 🎯 **2. TESTING-WORKFLOW.md** - Running the Modules

**👉 GO HERE AFTER SETUP to:**
- Run Module A: Slow Search (560x improvement)
- Run Module B: Covering Index (50x improvement)
- Run Module C: Parameter Sniffing (consistent performance)
- Run Module D: Deadlock Demo (elimination)
- Record your results
- Capture execution plans

**Time:** ~2 hours total (30 min per module)

**Read:** [TESTING-WORKFLOW.md](TESTING-WORKFLOW.md)

---

## ⚡ Quick Start Path

```
┌─────────────────────────────────────────────┐
│  Haven't installed SQL Server yet?          │
│  👉 Read QUICKSTART-GUIDE.md Part 1         │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│  Need to install SSMS/Azure Data Studio?    │
│  👉 Read QUICKSTART-GUIDE.md Part 2         │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│  Ready to create the database?              │
│  👉 Follow QUICKSTART-GUIDE.md Part 3       │
│     Run scripts in order:                   │
│     1. db/01-schema.sql                     │
│     2. db/02-seed-data.sql                  │
│     3. db/03-indexes.sql                    │
│     4. db/04-stored-procedures.sql          │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│  Database setup complete?                   │
│  👉 Go to TESTING-WORKFLOW.md               │
│     Work through modules A → B → C → D     │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│  🎉 You're done! You have:                  │
│     ✅ 560x search optimization             │
│     ✅ 50x covering index improvement       │
│     ✅ Consistent parameter performance     │
│     ✅ Zero deadlocks                       │
└─────────────────────────────────────────────┘
```

---

## 🆘 "I'm Completely New to SQL Server"

**Follow this exact path:**

1. **Day 1 (30 min):** Read QUICKSTART-GUIDE.md Parts 1-3
   - Install SQL Server
   - Install SSMS
   - Create database
   - Generate data (wait for completion)

2. **Day 1 (15 min):** Verify everything works
   - Run verification queries from QUICKSTART-GUIDE.md Part 3
   - Check that you have 750K+ rows
   - Test a simple SELECT query

3. **Day 2 (30 min):** Module A
   - Read TESTING-WORKFLOW.md Module A section
   - Run bad query, see ~2,800 reads
   - Run good query, see ~5 reads
   - Calculate improvement: 560x! 🎉

4. **Day 3 (30 min):** Module B
   - Work through covering index examples
   - See Key Lookups eliminated
   - Achieve 50x improvement

5. **Day 4 (30 min):** Module C
   - Demonstrate parameter sniffing
   - See inconsistent performance
   - Apply fixes, achieve consistency

6. **Day 5 (20 min):** Module D
   - Create a real deadlock
   - View deadlock graph
   - Fix with consistent locking

---

## 💻 "I Already Have SQL Server Installed"

**Skip to:**

1. **QUICKSTART-GUIDE.md Part 3** - Create the database
2. **TESTING-WORKFLOW.md** - Start running modules

**Quick setup (copy/paste this):**

```sql
-- Run these 4 scripts in order:
-- 1. Open db/01-schema.sql → Execute
-- 2. Open db/02-seed-data.sql → Execute (wait ~2 min)
-- 3. Open db/03-indexes.sql → Execute
-- 4. Open db/04-stored-procedures.sql → Execute

-- Verify it worked:
USE PerformanceLab;
SELECT 'Customers', COUNT(*) FROM dbo.Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL  
SELECT'OrderDetails', COUNT(*) FROM dbo.OrderDetails;

-- Should see:
-- Customers: 50,000
-- Orders: 200,000
-- OrderDetails: 500,000+
```

Then go to **TESTING-WORKFLOW.md** and start with Module A.

---

## 🎓 "I Want to Understand the Concepts First"

**Read the module READMEs:**

1. `modules/A-slow-search/README.md` - Why search patterns matter
2. `modules/B-covering-index/README.md` - Key Lookups explained
3. `modules/C-parameter-sniffing/README.md` - Plan cache issues
4. `modules/D-deadlock-demo/README.md` - Lock contention

**Then follow TESTING-WORKFLOW.md** to see the concepts in action.

---

## 📊 "I Just Want to See Results Fast"

**If you have SQL Server + SSMS ready**, do this:

```sql
-- Setup (5 minutes)
-- Run: db/01-schema.sql
-- Run: db/02-seed-data.sql (wait)
-- Run: db/03-indexes.sql
-- Run: db/04-stored-procedures.sql

-- Quick test (2 minutes)
USE PerformanceLab;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- BAD
EXEC dbo.usp_ClearCache;
SELECT CustomerID, LastName FROM dbo.Customers WHERE LastName LIKE '%smith%';
-- Note the logical reads: ~2,800

-- GOOD  
EXEC dbo.usp_ClearCache;
SELECT CustomerID, LastName FROM dbo.Customers WHERE LastName LIKE 'Smith%';
-- Note the logical reads: ~5

-- Calculate: 2800 / 5 = 560x faster!
```

---

## 🔧 Troubleshooting Guide

### "I can't connect to SQL Server"

**See:** QUICKSTART-GUIDE.md → Troubleshooting section

Common fixes:
- Server name: `localhost\SQLEXPRESS`
- Or try: `.\SQLEXPRESS` or `(localdb)\MSSQLLocalDB`
- For Docker: `localhost,1433`

### "Script is taking too long"

**Normal timing:**
- 01-schema.sql: ~30 seconds
- 02-seed-data.sql: ~1-2 minutes ⏳ (this is expected!)
- 03-indexes.sql: ~10 seconds
- 04-stored-procedures.sql: ~10 seconds

If longer, check:
- Your computer's available RAM
- SQL Server isn't busy with other tasks
- Antivirus isn't scanning SQL files

### "I don't see any improvement"

Check that you:
1. Cleared cache before EACH test: `EXEC dbo.usp_ClearCache;`
2. Ran scripts in correct order (01 → 02 → 03 → 04)
3. Enabled STATISTICS IO: `SET STATISTICS IO ON;`
4. Are looking at logical reads in Messages tab, not Results tab

---

## 📚 Document Reference

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **README.md** | Project overview | First-time visitors |
| **QUICKSTART-GUIDE.md** | Installation & setup | Before running anything |
| **TESTING-WORKFLOW.md** | Module execution | After database is created |
| **Module READMEs** | Concept explanation | Understanding theory |
| **01-bad-query.sql** | See the problem | Running each module |
| **02-analysis.sql** | Understand why | Learning root cause |
| **03-fix.sql** | Apply solution | Seeing improvement |

---

## ✅ Success Checklist

Use this to track your progress:

### Setup Phase
- [ ] SQL Server installed
- [ ] SSMS or Azure Data Studio installed
- [ ] Connected to server successfully
- [ ] Ran db/01-schema.sql (database created)
- [ ] Ran db/02-seed-data.sql (750K+ rows created)
- [ ] Ran db/03-indexes.sql (14 indexes created)
- [ ] Ran db/04-stored-procedures.sql (12 procedures created)
- [ ] Verified row counts are correct

### Module A: Slow Search
- [ ] Ran bad query (LIKE '%smith%')
- [ ] Saw ~2,800 logical reads
- [ ] Ran good query (LIKE 'Smith%')
- [ ] Saw ~5 logical reads
- [ ] Calculated 560x improvement
- [ ] Captured execution plans

### Module B: Covering Index
- [ ] Ran query with Key Lookups
- [ ] Saw ~5,000+ logical reads
- [ ] Created covering index
- [ ] Re-ran query (no Key Lookups)
- [ ] Saw ~100 logical reads
- [ ] Calculated 50x improvement

### Module C: Parameter Sniffing
- [ ] Ran procedure for VIP customer
- [ ] Ran same procedure for Regular customer
- [ ] Observed inconsistent performance
- [ ] Applied RECOMPILE fix
- [ ] Confirmed consistent performance

### Module D: Deadlock Demo
- [ ] Set up Extended Events
- [ ] Opened two query windows
- [ ] Created a deadlock
- [ ] Saw error 1205 in one window
- [ ] Viewed deadlock graph
- [ ] Applied consistent locking fix

---

## 🎯 Next Steps After Completion

1. **Screenshot your results** - Execution plans + statistics
2. **Document improvements** - Create a summary table
3. **Blog about it** - Write up one module
4. **Add to portfolio** - Push to GitHub
5. **Practice explaining** - Prepare for interviews

---

## 📞 Need Help?

1. **Check QUICKSTART-GUIDE.md** - Detailed troubleshooting section
2. **Review module README** - Each module has specific guidance
3. **Check SQL comments** - Scripts have inline explanations
4. **Examine error messages** - Often point to the specific issue

---

## 🏁 Where You Are Now

You're at: **START HERE**

Your first action: **Open QUICKSTART-GUIDE.md**

Your goal: Run all 4 modules and achieve measurable improvements

Your reward: Portfolio-ready SQL Server optimization proof

**Let's begin! Open QUICKSTART-GUIDE.md and start with Part 1.** 🚀

---

*Created for SQL Server performance engineers who want hands-on experience with real optimization scenarios.*
