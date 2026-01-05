# 🎯 Testing Workflow - At a Glance

## Quick Reference: How to Run Each Module

```
┌─────────────────────────────────────────────────────────┐
│  ONE-TIME SETUP (Do This First!)                        │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  1. Install SQL Server               │
        │     • Windows: SQL Express           │
        │     • Mac/Linux: Docker              │
        │     • Cloud: Azure SQL               │
        └──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  2. Install Management Tool          │
        │     • Windows: SSMS                  │
        │     • Mac/Linux: Azure Data Studio   │
        └──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  3. Run Database Setup Scripts       │
        │     ① db/01-schema.sql               │
        │     ② db/02-seed-data.sql (~2 min)   │
        │     ③ db/03-indexes.sql              │
        │     ④ db/04-stored-procedures.sql    │
        └──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  4. Verify Setup                     │
        │     ✓ 750K+ rows created             │
        │     ✓ Indexes created                │
        │     ✓ Procedures created             │
        └──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  MODULE TESTING (Repeat for Each Module)                │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  MODULE A: Slow Search (560x improvement)                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ① PREPARATION                                                       │
│     □ Enable statistics:  SET STATISTICS IO ON; TIME ON;            │
│     □ Enable exec plan:   Ctrl+M (SSMS) or "Explain" button         │
│     □ Clear cache:        EXEC dbo.usp_ClearCache;                  │
│                                                                      │
│  ② RUN BAD QUERY                                                     │
│     □ Open: modules/A-slow-search/01-bad-query.sql                  │
│     □ Run Pattern #1 (leading wildcard LIKE '%smith%')              │
│     □ Check Messages tab: Note logical reads (~2,800)               │
│     □ Check Execution Plan: See Index Scan                          │
│                                                                      │
│  ③ UNDERSTAND THE PROBLEM                                            │
│     □ Open: modules/A-slow-search/02-analysis.sql                   │
│     □ Run queries to understand why index can't be used             │
│                                                                      │
│  ④ APPLY THE FIX                                                     │
│     □ Open: modules/A-slow-search/03-fix.sql                        │
│     □ Run Fix #1 (trailing wildcard LIKE 'Smith%')                  │
│     □ Check Messages tab: Note logical reads (~5)                   │
│     □ Check Execution Plan: See Index Seek                          │
│     □ Calculate: 2800 / 5 = 560x improvement! ✅                     │
│                                                                      │
│  ⑤ REPEAT FOR OTHER PATTERNS                                         │
│     □ Pattern #2: UPPER() function on column                        │
│     □ Pattern #3: Multiple OR conditions                            │
│     □ Pattern #4: Combined wildcards + functions                    │
│     □ Pattern #5: Implicit conversions                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  MODULE B: Covering Index (50x improvement)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ① PREPARATION                                                       │
│     □ Enable statistics & execution plan                            │
│     □ Clear cache                                                   │
│                                                                      │
│  ② RUN BAD QUERY                                                     │
│     □ Open: modules/B-covering-index/01-bad-query.sql               │
│     □ Run Query #1 (customer orders without covering index)         │
│     □ Check Execution Plan: Look for KEY LOOKUP operator            │
│     □ Note logical reads (~5,000+)                                  │
│                                                                      │
│  ③ UNDERSTAND KEY LOOKUPS                                            │
│     □ Open: modules/B-covering-index/02-analysis.sql                │
│     □ Learn about index structure                                   │
│     □ See why Key Lookups are expensive                             │
│                                                                      │
│  ④ CREATE COVERING INDEX                                             │
│     □ Open: modules/B-covering-index/03-fix.sql                     │
│     □ Run index creation:                                           │
│       CREATE INDEX ... INCLUDE (OrderDate, Status, TotalAmount)     │
│     □ Re-run same query                                             │
│     □ Check Execution Plan: NO Key Lookup! ✅                        │
│     □ Note logical reads (~100)                                     │
│     □ Calculate: 5000 / 100 = 50x improvement! ✅                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  MODULE C: Parameter Sniffing (Consistent Performance)              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ① SETUP THE SCENARIO                                                │
│     □ Open: modules/C-parameter-sniffing/01-bad-query.sql           │
│     □ Verify data skew (VIP customers have 40% of orders)           │
│     □ Find sample VIP and Regular customers                         │
│                                                                      │
│  ② DEMONSTRATE THE PROBLEM                                           │
│     □ Clear cache                                                   │
│     □ Run procedure for VIP customer FIRST                          │
│       EXEC usp_GetOrdersByCustomer @CustomerID = [VIP ID]           │
│     □ Note time: _____ ms                                           │
│     □ Run SAME procedure for Regular customer                       │
│       EXEC usp_GetOrdersByCustomer @CustomerID = [Regular ID]       │
│     □ Note time: _____ ms (should be similar, but WRONG plan!)      │
│                                                                      │
│  ③ REVERSE THE ORDER                                                 │
│     □ Clear cache again                                             │
│     □ Run Regular customer FIRST this time                          │
│     □ Then run VIP customer                                         │
│     □ See opposite problem! VIP is now slow                         │
│                                                                      │
│  ④ ANALYZE WITH QUERY STORE                                          │
│     □ Open: modules/C-parameter-sniffing/02-analysis.sql            │
│     □ Check cached plan details                                     │
│     □ See variance in execution times                               │
│                                                                      │
│  ⑤ APPLY FIXES                                                       │
│     □ Open: modules/C-parameter-sniffing/03-fix.sql                 │
│     □ Test Fix #1: OPTION (RECOMPILE)                               │
│     □ Test Fix #2: OPTIMIZE FOR UNKNOWN                             │
│     □ All executions now consistent! ✅                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  MODULE D: Deadlock Demo (100% Elimination)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ① ENABLE DEADLOCK TRACING                                           │
│     □ Open: modules/D-deadlock-demo/01-setup.sql                    │
│     □ Run to enable trace flag 1222                                │
│     □ Create Extended Event session                                 │
│                                                                      │
│  ② PREPARE TWO QUERY WINDOWS                                         │
│     □ Open Window 1 (Session A)                                     │
│     □ Open Window 2 (Session B)                                     │
│                                                                      │
│  ③ CREATE A DEADLOCK                                                 │
│     □ Window 1: Load modules/D-deadlock-demo/02-session-a.sql       │
│     □ Window 1: Press F5 to START                                   │
│       (It locks Product 1, waits, tries Product 2)                  │
│                                                                      │
│     □ Window 2: Load modules/D-deadlock-demo/03-session-b.sql       │
│     □ Window 2: Press F5 IMMEDIATELY                                │
│       (It locks Product 2, waits, tries Product 1)                  │
│                                                                      │
│     □ Wait 5 seconds...                                             │
│     □ BOOM! One window shows Msg 1205 (deadlock victim) ⚠️          │
│     □ Other window completes successfully                           │
│                                                                      │
│  ④ VIEW THE DEADLOCK                                                 │
│     □ Query the Extended Event session                              │
│     □ See deadlock graph XML                                        │
│     □ Identify which session was victim                             │
│                                                                      │
│  ⑤ FIX WITH CONSISTENT LOCKING                                       │
│     □ Open: modules/D-deadlock-demo/04-fix.sql                      │
│     □ Use usp_UpdateInventory_Fixed procedure                       │
│     □ Always locks Product IDs in order (low to high)               │
│     □ Run same scenario - NO deadlock! ✅                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  RECORDING YOUR RESULTS                                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  For EACH module, capture:                                   │
│                                                              │
│  📊 Metrics                                                  │
│     • Logical reads (from Messages tab)                     │
│     • CPU time (from Messages tab)                          │
│     • Elapsed time (from Messages tab)                      │
│                                                              │
│  📈 Execution Plans                                          │
│     • Before: Save as module-X-before.sqlplan               │
│     • After:  Save as module-X-after.sqlplan                │
│                                                              │
│  📝 Screenshots                                              │
│     • Bad query execution plan                              │
│     • Good query execution plan                             │
│     • STATISTICS IO output                                  │
│                                                              │
│  💾 Store in Database                                        │
│     INSERT INTO dbo.QueryBenchmarks                         │
│     (TestName, QueryType, LogicalReads, CPUTimeMs, Notes)   │
│     VALUES ('Module A', 'BAD', 2847, 125, 'Notes...');      │
│                                                              │
└─────────────────────────────────────────────────────────────┘

═════════════════════════════════════════════════════════════
  EXPECTED RESULTS SUMMARY
═════════════════════════════════════════════════════════════

Module A: Slow Search
├─ Before:  ~2,800 logical reads, 125ms CPU
├─ After:   ~5 logical reads, 1ms CPU
└─ Result:  560x improvement ✅

Module B: Covering Index  
├─ Before:  ~5,000 logical reads, Key Lookups present
├─ After:   ~100 logical reads, No Key Lookups
└─ Result:  50x improvement ✅

Module C: Parameter Sniffing
├─ Before:  Inconsistent (5ms vs 500ms depending on order)
├─ After:   Consistent ~20ms for all customers
└─ Result:  Predictable performance ✅

Module D: Deadlock
├─ Before:  Deadlocks occur 30% of concurrent executions
├─ After:   Zero deadlocks with consistent locking
└─ Result:  100% elimination ✅

═════════════════════════════════════════════════════════════

⚡ QUICK COMMANDS CHEAT SHEET
═════════════════════════════════════════════════════════════

-- Enable measurement
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
-- Press Ctrl+M for execution plan

-- Clear cache (dev only!)
EXEC dbo.usp_ClearCache;

-- Check row counts
SELECT 'Customers', COUNT(*) FROM dbo.Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders;

-- View index usage
EXEC dbo.usp_IndexUsageStats;

-- Find missing indexes
EXEC dbo.usp_MissingIndexes;

-- Compare your results
EXEC dbo.usp_CompareQueryStats 'Module A';

═════════════════════════════════════════════════════════════
