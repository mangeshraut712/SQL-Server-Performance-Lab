# 📊 Performance Results Tracker

Use this template to record your actual measurements as you work through each module.

## Module A: Slow Search Patterns

### Test 1: Leading Wildcard LIKE

| Metric | Bad Query (`LIKE '%smith%'`) | Optimized (`LIKE 'Smith%'`) | Improvement |
|--------|------------------------------|------------------------------|-------------|
| Logical Reads | __________ | __________ | __________x |
| CPU Time (ms) | __________ | __________ | __________x |
| Elapsed Time (ms) | __________ | __________ | __________x |
| Index Operation | Scan / Seek | Scan / Seek | - |

**Expected:** ~2,800 reads → ~5 reads = **560x improvement**

### Test 2: Function on Column

| Metric | Bad Query (`UPPER(LastName)`) | Optimized (Direct comparison) | Improvement |
|--------|-------------------------------|-------------------------------|-------------|
| Logical Reads | __________ | __________ | __________x |
| CPU Time (ms) | __________ | __________ | __________x |
| Elapsed Time (ms) | __________ | __________ | __________x |

**Expected:** ~2,800 reads → ~5 reads = **560x improvement**

---

## Module B: Covering Index

### Test: Customer Orders Query

| Metric | Before (Key Lookups) | After (Covering Index) | Improvement |
|--------|----------------------|------------------------|-------------|
| Logical Reads (Orders) | __________ | __________ | __________x |
| Logical Reads (OrderDetails) | __________ | __________ | __________x |
| CPU Time (ms) | __________ | __________ | __________x |
| Elapsed Time (ms) | __________ | __________ | __________x |
| Key Lookups Present? | Yes / No | Yes / No | - |

**Expected:** ~5,000 reads → ~100 reads = **50x improvement**

---

## Module C: Parameter Sniffing

### Test: Same Procedure, Different Customers

| Customer Type | Execution 1 (ms) | Execution 2 (ms) | Execution 3 (ms) | Avg (ms) |
|---------------|------------------|------------------|------------------|----------|
| **Before Fix** | | | | |
| VIP Customer | __________ | __________ | __________ | __________ |
| Regular Customer | __________ | __________ | __________ | __________ |
| **After Fix (RECOMPILE)** | | | | |
| VIP Customer | __________ | __________ | __________ | __________ |
| Regular Customer | __________ | __________ | __________ | __________ |

**Expected:** Inconsistent (5ms vs 500ms) → Consistent (~20ms avg)

**Variance Ratio Before:** __________
**Variance Ratio After:** __________

---

## Module D: Deadlock Demo

### Deadlock Occurrence Test

| Test Run | Session A Result | Session B Result | Deadlock Occurred? | Victim |
|----------|------------------|------------------|-----------------------|--------|
| **Before Fix** | | | | |
| Run 1 | Success / Deadlock | Success / Deadlock | Yes / No | A / B |
| Run 2 | Success / Deadlock | Success / Deadlock | Yes / No | A / B |
| Run 3 | Success / Deadlock | Success / Deadlock | Yes / No | A / B |
| **After Fix** | | | | |
| Run 1 | Success / Deadlock | Success / Deadlock | Yes / No | - |
| Run 2 | Success / Deadlock | Success / Deadlock | Yes / No | - |
| Run 3 | Success / Deadlock | Success / Deadlock | Yes / No | - |

**Expected:** Deadlocks eliminated with consistent lock ordering

---

## Summary Dashboard

| Module | Status | Improvement Achieved | Notes |
|--------|--------|----------------------|-------|
| A: Slow Search | ⬜ Not Started / ⬜ In Progress / ⬜ Complete | __________x | |
| B: Covering Index | ⬜ Not Started / ⬜ In Progress / ⬜ Complete | __________x | |
| C: Parameter Sniffing | ⬜ Not Started / ⬜ In Progress / ⬜ Complete | Consistent: Yes / No | |
| D: Deadlock Demo | ⬜ Not Started / ⬜ In Progress / ⬜ Complete | Eliminated: Yes / No | |

---

## How to Use This Tracker

1. **Before each test:** Run `EXEC dbo.usp_ClearCache;` to clear SQL Server cache
2. **Enable statistics:** Run `SET STATISTICS IO ON; SET STATISTICS TIME ON;`
3. **Record measurements:** Copy metrics from Messages tab in SSMS
4. **Save execution plans:** Right-click plan → Save As → `module-X-bad.sqlplan` / `module-X-fixed.sqlplan`
5. **Calculate improvement:** `Improvement = Before / After` (e.g., 2800 / 5 = 560x)

---

## Execution Plan Screenshot Checklist

For each module, capture:

- [ ] **Bad query execution plan** - Look for warnings (yellow triangles)
- [ ] **Good query execution plan** - Compare operator costs
- [ ] **STATISTICS IO output** - Messages tab in SSMS
- [ ] **STATISTICS TIME output** - Messages tab in SSMS
- [ ] **Index usage before/after** - Run `EXEC dbo.usp_IndexUsageStats;`

**Pro Tip:** Create a folder for each module and save all evidence there for your portfolio!
