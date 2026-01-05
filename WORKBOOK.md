# 📒 Performance Lab Workbook

Use this workbook to record your findings and track your journey through the optimization modules.

---

## 👤 Participant Details
- **Engineer Initials:** ________
- **Platform:** ________ (e.g., M1 Mac, Windows Server)
- **Start Date:** ________

---

## 🛠️ Module A: Search Optimization
**Scenario:** Inefficient `LIKE` clauses and function-wrapped columns.

| Metric | Before Fix | After Fix | Factor |
| :--- | :--- | :--- | :--- |
| **Logical Reads** | | | |
| **CPU Time (ms)** | | | |
| **Elapsed Time** | | | |

**Reflection:**
- What operator appeared in the Execution Plan *before*? ________________
- What operator appeared *after*? ________________

---

## 🏗️ Module B: Covering Indexes
**Scenario:** Eliminating expensive Key Lookups.

| Metric | Before Fix | After Fix | Factor |
| :--- | :--- | :--- | :--- |
| **Logical Reads** | | | |
| **Operator Count**| | | |

**Reflection:**
- Why was the "Key Lookup" operator present? ________________
- How did `INCLUDE` columns resolve this? ________________

---

## 🧪 Module C: Parameter Sniffing
**Scenario:** Execution plan cache inconsistency.

| Execution Order | VIP Customer | Regular Customer | Notes |
| :--- | :--- | :--- | :--- |
| **VIP First** | ms | ms | |
| **Regular First** | ms | ms | |

**Reflection:**
- Which fix provided the most consistent results? ________________

---

## 🔒 Module D: Deadlock Demo
**Scenario:** Concurrent updates causing circular blocking.

| Run # | Result |
| :--- | :--- |
| **Attempt 1 (Original)** | [ ] Success [ ] Deadlock Victim |
| **Attempt 2 (Original)** | [ ] Success [ ] Deadlock Victim |
| **Attempt 3 (Fixed)**    | [ ] Success [ ] Deadlock Victim |

**Reflection:**
- What did you see in the Deadlock Graph? ________________

---

## 📊 Module E: Columnstore Power
**Scenario:** High-volume data aggregation.

| Metric | Row-Store | Columnstore | Improvement |
| :--- | :--- | :--- | :--- |
| **Logical Reads** | | | |
| **Process Mode**  | [Row] | [Batch] | |

**Reflection:**
- How much did the logical reads decrease? ________________

---

## 🏆 Final Result Summary
Run the **Dashboard Script** (`PERFORMANCE-DASHBOARD.sql`) and paste your results here:

```text
[Paste Results Table Here]
```

---

*Verified by Antigravity Performance Lab.*
