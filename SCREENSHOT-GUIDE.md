# 📸 Execution Plan Screenshot Guide

## Why Execution Plans Matter for Your Portfolio

Showing execution plans in interviews proves you:
1. **Understand SQL internals** - Not just writing queries, but understanding how they execute
2. **Can diagnose problems** - Identify bottlenecks visually
3. **Know how to optimize** - Demonstrate measurable improvements

---

## How to Capture Execution Plans

### Method 1: Graphical Plan in SSMS (Recommended for Portfolio)

1. **Open SQL Server Management Studio (SSMS)**
2. **Load your bad query** from `01-bad-query.sql`
3. **Enable Actual Execution Plan:**
   - Press `Ctrl + M`, OR
   - Click **Query** → **Include Actual Execution Plan**, OR
   - Click toolbar icon (looks like a query plan with a checkmark)
4. **Execute the query** (F5 or Execute button)
5. **View the plan:**
   - Click the **Execution Plan** tab at the bottom
   - Plan appears as a flowchart (right to left)

#### 🎯 What to Look For (Bad Query)

- ⚠️ **Yellow warning triangles** - Missing indexes, type conversions
- **Table Scan** or **Clustered Index Scan** - Reading entire table (expensive)
- **Key Lookup** - Extra I/O for missing columns
- **Thick arrows** - Large amounts of data flowing
- **High cost percentages** - Where the query spends most time

#### 💾 How to Save

**Option A: Save as image (for presentations)**
- Right-click on plan → **Save Execution Plan As...** → Choose `.sqlplan` format
- Open `.sqlplan` file → Take screenshot (Windows: Win+Shift+S, Mac: Cmd+Shift+4)

**Option B: Save as .sqlplan file (for detailed review)**
- Right-click → **Save Execution Plan As...** → Save as `module-a-bad.sqlplan`
- Later: Open in SSMS to review

---

### Method 2: Azure Data Studio

1. **Open Azure Data Studio**
2. **Connect to your server**
3. **Write your query**
4. **Click "Explain"** button (looks like a lightbulb)
5. **View graphical plan** in Results pane
6. **Screenshot** the plan

---

### Method 3: Get XML Plan (for Blog Posts / Documentation)

```sql
SET SHOWPLAN_XML ON;
GO

-- Your query here
SELECT * FROM dbo.Customers WHERE LastName LIKE '%smith%';
GO

SET SHOWPLAN_XML OFF;
GO
```

The XML output can be:
- Saved as `.sqlplan` file
- Pasted into [SQL Server Plan Explorer](https://statisticsparser.com/) for online sharing
- Included in blog posts for detailed analysis

---

## Screenshot Examples for Each Module

### Module A: Slow Search

**Bad Query Screenshot Checklist:**
- [ ] Table/Index Scan operator visible
- [ ] Yellow warning about no index usage
- [ ] Cost percentage (should be ~100% if only one query)
- [ ] Actual Rows vs Estimated Rows close together
- [ ] STATISTICS IO output showing ~2,800 reads

**Good Query Screenshot Checklist:**
- [ ] Index Seek operator visible (green)
- [ ] Much lower cost percentage
- [ ] No yellow warnings
- [ ] STATISTICS IO showing ~5 reads (560x better!)

**File naming:**
```
portfolio/
  module-a-slow-search/
    ├── 01-bad-like-wildcard-plan.png
    ├── 01-bad-like-wildcard-stats.png
    ├── 02-good-like-trailing-plan.png
    ├── 02-good-like-trailing-stats.png
    ├── 03-bad-upper-function-plan.png
    └── 03-good-direct-compare-plan.png
```

---

### Module B: Covering Index

**Key Things to Highlight:**
- [ ] Key Lookup operator before optimization (nested loop + lookup)
- [ ] Thick arrow between Index Seek and Key Lookup
- [ ] After: Clean Index Seek with no Key Lookup
- [ ] Logical reads reduction (5,000 → 100)

**Screenshot Annotation Ideas:**
- Circle the Key Lookup operator in red
- Draw arrow showing data flow
- Add text: "Eliminated with covering index"

---

### Module C: Parameter Sniffing

**What Makes This Impressive:**
- [ ] Screenshot of SAME procedure with DIFFERENT execution times
- [ ] Query Store screenshot showing variance
- [ ] Execution plan with "Actual Rows: 1000" vs "Estimated Rows: 10"
- [ ] Before/After consistency chart

**Pro Tip:** Create a simple chart in Excel:
```
Execution #  | VIP Customer | Regular Customer
-------------|--------------|------------------
1 (before)   | 50ms         | 500ms  ← Big variance!
2 (before)   | 45ms         | 520ms
3 (before)   | 48ms         | 510ms
-------------|--------------|------------------
1 (after)    | 20ms         | 22ms   ← Consistent!
2 (after)    | 21ms         | 20ms
3 (after)    | 19ms         | 21ms
```

---

### Module D: Deadlock

**Screenshots to Capture:**
- [ ] Deadlock error message (Msg 1205)
- [ ] Deadlock graph XML visualization
- [ ] Two-session setup showing simultaneous execution
- [ ] Both sessions completing successfully after fix

**Deadlock Graph Highlights:**
- Victim process marked with X
- Lock resources shown
- Arrows showing wait-for relationships

---

## Advanced: Creating a Portfolio Presentation

### Structure for GitHub README or Portfolio Site

```markdown
# SQL Server Performance Optimization

## Module A: Search Pattern Optimization

### Problem
![Bad query execution plan](screenshots/module-a-bad.png)
- Table scan on 50,000 rows
- 2,847 logical reads
- 125ms CPU time

### Solution
- Removed leading wildcard
- Created covering index
- Changed to `LIKE 'Smith%'` pattern

### Results
![Optimized query execution plan](screenshots/module-a-good.png)
- Index seek
- **5 logical reads** (560x improvement)
- **1ms CPU time** (125x improvement)

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Logical Reads | 2,847 | 5 | 560x |
| CPU Time | 125ms | 1ms | 125x |
```

---

## Quick Reference: Keyboard Shortcuts

| Action | SSMS Shortcut | Azure Data Studio |
|--------|---------------|-------------------|
| Actual Execution Plan | `Ctrl + M` | Click "Explain" |
| Estimated Plan | `Ctrl + L` | - |
| Execute Query | `F5` | `F5` |
| Results to Text | `Ctrl + T` | - |
| Results to Grid | `Ctrl + D` | - |

---

## Common Mistakes to Avoid

❌ **Don't:** Just show the green plan without explaining what improved
✅ **Do:** Annotate with arrows, circles, before/after comparisons

❌ **Don't:** Only capture the plan without STATISTICS IO/TIME
✅ **Do:** Show both the visual plan AND the numeric proof

❌ **Don't:** Save generic filenames like "plan1.png"
✅ **Do:** Use descriptive names like "customer-search-covering-index-after.png"

❌ **Don't:** Skip the bad query execution plan
✅ **Do:** Always show before AND after side-by-side

---

## Interactive Presentation Tips

When showing this to recruiters/interviewers:

1. **Start with the problem:** "Here's a query taking 500ms in production"
2. **Show the bad plan:** "See this table scan? That's reading 50k rows unnecessarily"
3. **Explain the diagnosis:** "The thick arrow shows massive data movement"
4. **Present your fix:** "I added a covering index with these columns"
5. **Reveal the results:** "Now it's an index seek with 50x fewer reads"
6. **Show the proof:** "Here's the STATISTICS IO output showing the improvement"

**Magic phrase:** "I didn't just make it faster—I can prove exactly WHY it's faster."

---

## Bonus: Video Demo

Consider recording a 2-minute video showing:
1. Running the bad query (with timer)
2. Examining the execution plan
3. Implementing the fix
4. Re-running and showing improvement

Upload to:
- YouTube (unlisted link in resume)
- LinkedIn video post
- Loom/Vimeo for portfolio site

This demonstrates:
- Technical knowledge
- Communication skills
- Real-world problem-solving process
