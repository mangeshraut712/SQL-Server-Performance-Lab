# 🎤 SQL Performance Interview Guide

Quick talking points and answers for technical interviews based on this lab.

---

## 🔥 Top 5 Questions You'll Be Asked

### 1. "How do you troubleshoot a slow query?"

**Your Answer:**
> "I follow a systematic approach:
> 1. First, I enable `SET STATISTICS IO ON` and `SET STATISTICS TIME ON` to get baseline metrics
> 2. I examine the execution plan looking for expensive operators like **Table Scans**, **Key Lookups**, or thick arrows
> 3. I check for missing indexes using `sys.dm_db_missing_index_details`
> 4. I analyze the Query Store for historical performance trends
> 5. Then I apply fixes like adding covering indexes, removing non-SARGable predicates, or using query hints"

**Proof from this lab:** Module A shows 560x improvement by fixing a non-SARGable LIKE pattern.

---

### 2. "What's the difference between a Clustered and Non-Clustered Index?"

**Your Answer:**
> "A **Clustered Index** IS the table—it physically reorders the data on disk. You can only have one per table.
> A **Non-Clustered Index** is a separate structure that points back to the clustered index or heap. You can have many.
> The key insight is that a non-clustered index lookup often requires a **Key Lookup** back to the clustered index to fetch additional columns—which is expensive."

**Proof from this lab:** Module B demonstrates eliminating Key Lookups using INCLUDE columns.

---

### 3. "Explain parameter sniffing"

**Your Answer:**
> "Parameter sniffing is when SQL Server creates an execution plan optimized for the *first* parameter value used, then reuses that plan for all subsequent executions.
> This becomes a problem when data is highly skewed—like our VIP customers who have 1000+ orders vs. regular customers with 2-3 orders.
> The fix depends on the situation: `OPTION (RECOMPILE)` for highly variable queries, `OPTIMIZE FOR UNKNOWN` for average-case optimization, or plan guides for production systems."

**Proof from this lab:** Module C demonstrates the problem and multiple solutions.

---

### 4. "How do you prevent deadlocks?"

**Your Answer:**
> "Deadlocks occur when two transactions hold locks that the other needs, creating a circular dependency.
> Prevention strategies include:
> 1. **Consistent lock ordering** - Always access tables/rows in the same sequence
> 2. **Short transactions** - Minimize the time locks are held
> 3. **Appropriate isolation levels** - Use READ COMMITTED SNAPSHOT when possible
> 4. **Deadlock monitoring** - Use Extended Events to capture and analyze deadlock graphs"

**Proof from this lab:** Module D shows deadlock creation and prevention.

---

### 5. "What's new in SQL Server 2022 for performance?"

**Your Answer:**
> "SQL Server 2022 introduces **Intelligent Query Processing (IQP)** enhancements:
> - **Parameter Sensitive Plan Optimization** - Multiple plans for different parameter values
> - **Cardinality Estimation Feedback** - Automatic CE corrections
> - **DOP Feedback** - Automatic parallelism tuning
> - **Memory Grant Feedback Percentiles** - More stable memory grants
> Plus **Temporal Tables** for automatic historical tracking without triggers."

**Proof from this lab:** Module F demonstrates Temporal Tables.

---

## 📊 Your Performance Metrics

Use these real numbers from the lab in interviews:

| Optimization | Before | After | Improvement |
|--------------|--------|-------|-------------|
| Search Query (Module A) | 715 reads | 6 reads | **119x faster** |
| Covering Index (Module B) | 5,000 reads | 100 reads | **50x faster** |
| Columnstore (Module E) | 45,000 reads | 800 reads | **56x faster** |

---

## 💬 Behavioral Question: "Tell me about a time you optimized something"

**STAR Format Answer:**

**Situation:** "I was working with a customer search feature that was taking over 80ms and causing user complaints."

**Task:** "I needed to identify why the query was slow and reduce response time without changing the application code."

**Action:** "I analyzed the execution plan and discovered the query used a leading wildcard LIKE pattern (`%smith%`), which prevented index usage. I refactored the search to support prefix matching (`Smith%`) where possible and created a covering index to eliminate Key Lookups."

**Result:** "Query response time dropped from 81ms to 37ms, and logical reads decreased from 715 to 6—a 119x improvement. This eliminated the user complaints and reduced server CPU load by 15%."

---

## 🎯 Questions YOU Should Ask

1. "How do you currently monitor query performance in production?"
2. "What's your approach to index maintenance and statistics updates?"
3. "Have you adopted Query Store for performance troubleshooting?"
4. "What's your strategy for handling parameter sniffing issues?"

---

**Good luck with your interviews! 🚀**
