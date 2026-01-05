# 📸 Portfolio Screenshot Guide

This guide shows you exactly how to capture professional screenshots and execution plans for interviews, presentations, and your portfolio.

---

## 🎯 What to Capture

### 1. **Before/After Execution Plans** (Most Important!)

**For Module A (Slow Search):**

**Bad Query Screenshot:**
- Show the **Index Scan** operator (highlight it in red)
- Capture the **cost percentage** (should be ~100%)
- Include the **Messages tab** showing logical reads (~715)

**Good Query Screenshot:**
- Show the **Index Seek** operator (highlight in green)
- Capture the **cost percentage** (should be ~15%)
- Include the **Messages tab** showing logical reads (~6)

**Side-by-Side Template:**
```
+-----------------+     vs     +-----------------+
| BEFORE          |            | AFTER           |
| Index Scan 100% |            | Index Seek 15%  |
| Reads: 715      |            | Reads: 6        |
| Time: 81ms      |            | Time: 37ms      |
+-----------------+            +-----------------+
         ⬇️
    119x FASTER ✅
```

---

## 📊 Step-by-Step Capture Process

### **A. Setting Up Azure Data Studio**

1. **Enable Execution Plan**:
   - Click the **"Estimated Plan"** button before running
   - Or click **"Enable Actual Plan"** checkbox, then run

2. **Enable Statistics**:
   ```sql
   SET STATISTICS IO ON;
   SET STATISTICS TIME ON;
   ```

3. **Clear Cache** (for consistent results):
   ```sql
   EXEC dbo.usp_ClearCache;
   ```

---

### **B. Capturing Module Screenshots**

#### **Module A: Search Optimization**

1. Open `modules/A-slow-search/01-bad-query.sql`
2. Run the leading wildcard query (line ~30)
3. **Screenshot 1**: Query Plan tab showing **Index Scan**
4. **Screenshot 2**: Messages tab showing logical reads
5. Open `modules/A-slow-search/03-fix.sql`
6. Run the optimized query
7. **Screenshot 3**: Query Plan tab showing **Index Seek**
8. **Screenshot 4**: Messages tab showing reduced logical reads

**Professional Annotation:**
- Use arrows to highlight the key operators
- Circle the cost percentages
- Add text: "Before: 715 reads → After: 6 reads = 119x improvement"

---

#### **Module B: Covering Index**

**What to Highlight:**
- **Before**: Key Lookup operator (expensive!)
- **After**: No Key Lookup, just Index Seek
- **Metric**: Logical reads reduction (5,000 → 100)

**Pro Tip**: Zoom in on the **Key Lookup** operator and show the tooltip that says "Cost: XX%"

---

#### **Module C: Parameter Sniffing**

**Unique Screenshot Approach:**

Create a **comparison table** showing:
```
Execution Order | VIP Customer | Regular Customer
------------------------------------------------
VIP First       | 15ms        | 250ms (BAD!)
Regular First   | 320ms (BAD!)| 8ms
With RECOMPILE  | 15ms        | 8ms (GOOD!)
```

---

#### **Module E: Columnstore**

**What to Highlight:**
- **Before**: "Execution Mode: Row" in execution plan
- **After**: "Execution Mode: Batch" in execution plan
- **Storage**: "Storage: ColumnStore" label
- **Metric**: 45,000 reads → 800 reads

---

## 🎨 Professional Presentation Tips

### **For LinkedIn Posts:**

**Template:**
```
🚀 SQL Performance Optimization: Real Results

Challenge: Customer search taking 81ms with 715 logical reads
Solution: Removed leading wildcard, optimized index strategy
Result: 37ms with 6 reads (119x improvement! ⚡)

Tech: SQL Server 2022, Execution Plan Analysis, Index Tuning
[Attach before/after screenshots]

#SQLServer #DatabaseOptimization #PerformanceEngineering
```

---

### **For Resume/Portfolio:**

**Bullet Point Format:**
- "Optimized customer search queries from 715 to 6 logical reads (119x improvement) by analyzing execution plans and removing non-SARGable predicates"
- "Eliminated Key Lookup operators through strategic INCLUDE column indexing, reducing I/O by 98%"
- "Resolved parameter sniffing issues affecting VIP customer queries using RECOMPILE hints and Query Store analysis"

---

### **For Technical Interviews:**

**Story Structure:**
1. **Situation**: "I noticed the customer search was doing a full index scan..."
2. **Analysis**: "By examining the execution plan, I identified a leading wildcard pattern..."
3. **Action**: "I refactored the query to remove the leading wildcard and ensured the index could be used..."
4. **Result**: "Reduced logical reads from 715 to 6—a 119x improvement—and cut response time by 54%"

---

## 📹 Video Demo (Optional)

**If creating a screen recording:**

1. **Start with the problem**: Show the slow query running in real-time
2. **Analyze**: Open the execution plan, highlight the bad operator
3. **Fix**: Show the code change (side-by-side)
4. **Verify**: Run the optimized query, show the improvement
5. **Explain**: Narrate why this happened and how you fixed it

**Recommended Tools:**
- macOS: **QuickTime** or **Screen Studio**
- Windows: **OBS Studio**
- **Loom** for quick cloud-hosted demos

---

## 🎯 Quick Checklist

Before you share your screenshots:

- [ ] **High Resolution**: At least 1920x1080
- [ ] **Clear Text**: Zoom in on important parts
- [ ] **Annotations**: Use arrows/circles to guide the viewer
- [ ] **Context**: Include the query text in the screenshot
- [ ] **Metrics**: Always show the before/after numbers
- [ ] **Professional**: Remove any sensitive data or unnecessary toolbars

---

**Your screenshots are proof of your engineering skills. Make them count!** 📸✨
