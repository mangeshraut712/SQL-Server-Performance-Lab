# Module D: Deadlock Demonstration

## 🎯 Objective

Learn how deadlocks occur, how to capture them, and how to prevent them through proper transaction design.

## ❌ The Problem

A **deadlock** occurs when:
1. Transaction A holds Lock 1 and waits for Lock 2
2. Transaction B holds Lock 2 and waits for Lock 1
3. Neither can proceed → SQL Server kills one (the "victim")

### Classic Deadlock Pattern

```
Session A                     Session B
─────────                     ─────────
BEGIN TRAN                    BEGIN TRAN
UPDATE Table1 (Lock T1)       UPDATE Table2 (Lock T2)
   ↓                             ↓
WAITFOR...                    WAITFOR...
   ↓                             ↓
UPDATE Table2 (Wait T2)  ──►  UPDATE Table1 (Wait T1)
       ↑                              │
       └──────── DEADLOCK! ◄──────────┘
```

## 📊 What You'll Learn

| Topic | Description |
|-------|-------------|
| Deadlock creation | How to reliably reproduce deadlocks |
| Deadlock detection | Using trace flags and extended events |
| Deadlock graphs | Reading the XML deadlock report |
| Prevention | Consistent lock ordering pattern |

## 🔬 Lab Steps

### Step 1: Setup (01-setup.sql)
- Enable deadlock tracing
- Verify test data exists
- Prepare two sessions

### Step 2: Create Deadlock
- Open TWO query windows (sessions)
- Run `02-session-a.sql` in window 1
- Run `03-session-b.sql` in window 2
- Watch one become the deadlock victim

### Step 3: Capture and Analyze
- View the deadlock graph
- Understand lock contention
- Identify the root cause

### Step 4: Implement Fix (04-fix.sql)
- Consistent lock ordering
- Retry logic
- Other prevention strategies

## 📁 Files in This Module

| File | Description |
|------|-------------|
| `01-setup.sql` | Enable deadlock tracing |
| `02-session-a.sql` | First deadlock participant |
| `03-session-b.sql` | Second deadlock participant |
| `04-fix.sql` | Prevention strategies |

## 📚 Prevention Strategies

1. **Consistent Lock Ordering**: Always access objects in the same order
2. **Keep Transactions Short**: Reduce lock hold time
3. **Use Lower Isolation Levels**: When appropriate (READ COMMITTED, SNAPSHOT)
4. **Retry Logic**: Handle deadlocks gracefully in application code
5. **Query Optimization**: Faster queries = shorter locks

## ⚠️ Important Notes

- Run in a TEST environment only
- You need TWO separate query sessions
- One session WILL receive a deadlock error
- The error is expected behavior
