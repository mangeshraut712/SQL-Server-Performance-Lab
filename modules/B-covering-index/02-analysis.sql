/*
================================================================================
Module B: Covering Indexes - ANALYSIS
================================================================================
Purpose: Understand Key Lookups and how to identify covering index candidates
================================================================================
*/

USE PerformanceLab;
GO

--------------------------------------------------------------------------------
-- What is a Key Lookup?
--------------------------------------------------------------------------------
/*
A Key Lookup occurs when:
1. SQL Server uses a nonclustered index to find rows
2. But needs additional columns not in that index
3. So it "looks up" each row in the clustered index (base table)

This is like using a book's index to find page numbers,
then flipping to each page to read the actual content.

The problem: Each lookup is a separate random I/O operation!
*/

-- Visualize the structure of our Orders index
SELECT 
    i.name AS IndexName,
    i.type_desc,
    STUFF((
        SELECT ', ' + c.name + ' (Key)'
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        FOR XML PATH('')
    ), 1, 2, '') AS KeyColumns,
    STUFF((
        SELECT ', ' + c.name + ' (Include)'
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
        FOR XML PATH('')
    ), 1, 2, '') AS IncludedColumns
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.Orders')
ORDER BY i.index_id;
GO

/*
Notice: IX_Orders_CustomerID only has CustomerID as the key.
When we SELECT OrderDate, Status, TotalAmount - those are NOT in the index!
*/


--------------------------------------------------------------------------------
-- Measure the Cost of Key Lookups
--------------------------------------------------------------------------------
/*
Let's compare the cost of finding rows vs looking up columns.
*/

SET STATISTICS IO ON;
GO

-- Query 1: Only SELECT columns that ARE in the index
-- (CustomerID is in the key, OrderID is the clustering key)
DECLARE @CustomerID INT = 1;

SELECT OrderID, CustomerID
FROM dbo.Orders 
WHERE CustomerID = @CustomerID;
GO

-- Query 2: SELECT columns NOT in the index (causes Key Lookup)
DECLARE @CustomerID INT = 1;

SELECT OrderID, CustomerID, OrderDate, Status, TotalAmount
FROM dbo.Orders
WHERE CustomerID = @CustomerID;
GO

SET STATISTICS IO OFF;
GO

/*
Compare the logical reads!
Query 1: Just index reads
Query 2: Index reads + table reads (for each row)
*/


--------------------------------------------------------------------------------
-- Identify Key Lookup Candidates from Query Store
--------------------------------------------------------------------------------
/*
Query Store tracks which queries have Key Lookups with high impact.
*/

SELECT TOP 10
    qt.query_sql_text,
    p.query_plan,
    rs.avg_logical_io_reads,
    rs.count_executions,
    rs.avg_duration / 1000 AS avg_duration_ms
FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
JOIN sys.query_store_query q ON p.query_id = q.query_id
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
WHERE CAST(p.query_plan AS NVARCHAR(MAX)) LIKE '%Lookup%'
ORDER BY rs.avg_logical_io_reads DESC;
GO


--------------------------------------------------------------------------------
-- Analyze Missing Index Suggestions
--------------------------------------------------------------------------------
/*
SQL Server tracks when queries could have benefited from different indexes.
These suggestions often include INCLUDE columns to eliminate lookups.
*/

EXEC dbo.usp_MissingIndexes @MinImpact = 1000;
GO


--------------------------------------------------------------------------------
-- Calculate the "Tipping Point"
--------------------------------------------------------------------------------
/*
Key Lookups become WORSE than a table scan at a certain point.
This is called the "tipping point" - typically around 1-5% of rows.

If you're selecting 1% of rows: Index Seek + Key Lookup is good
If you're selecting 15% of rows: Table Scan might be better!
*/

-- Check how many rows we're dealing with
SELECT 
    'Customers' AS TableName,
    COUNT(*) AS TotalRows,
    COUNT(CASE WHEN CustomerType = 'V' THEN 1 END) AS VIPCount,
    COUNT(CASE WHEN CustomerType = 'V' THEN 1 END) * 100.0 / COUNT(*) AS VIPPercent
FROM dbo.Customers
UNION ALL
SELECT 
    'Orders',
    COUNT(*),
    COUNT(CASE WHEN CustomerID IN (SELECT CustomerID FROM dbo.Customers WHERE CustomerType = 'V') THEN 1 END),
    COUNT(CASE WHEN CustomerID IN (SELECT CustomerID FROM dbo.Customers WHERE CustomerType = 'V') THEN 1 END) * 100.0 / COUNT(*)
FROM dbo.Orders;
GO

/*
VIP customers have MANY orders (40% of all orders)
This is why Key Lookups for VIP customers are so expensive!
*/


--------------------------------------------------------------------------------
-- Understand Index Structure Visually
--------------------------------------------------------------------------------
/*
Clustered Index (Base Table):
+----------+-----------+----------+---------+--------+------------+
| OrderID  | CustomerID| OrderDate| Status  | Total  | ShipMethod |
| (Key)    | (Data)    | (Data)   | (Data)  | (Data) | (Data)     |
+----------+-----------+----------+---------+--------+------------+
| 1        | 42        | 2024-01  | Shipped | 150.00 | Express    |
| 2        | 15        | 2024-01  | Pending | 75.00  | Ground     |
| 3        | 42        | 2024-02  | Shipped | 200.00 | Express    |
| ...      | ...       | ...      | ...     | ...    | ...        |

Nonclustered Index on CustomerID:
+------------+----------+
| CustomerID | OrderID  |
| (Key)      | (Pointer)|
+------------+----------+
| 15         | 2        | --> points to row in clustered index
| 42         | 1        | --> points to row in clustered index
| 42         | 3        | --> points to row in clustered index
| ...        | ...      |

When we SELECT OrderDate, Status, TotalAmount WHERE CustomerID = 42:
1. Seek in nonclustered index: Find CustomerID = 42 → OrderIDs 1, 3
2. Key Lookup: Go to clustered index, find row 1, get OrderDate/Status/Total
3. Key Lookup: Go to clustered index, find row 3, get OrderDate/Status/Total

Each Key Lookup is a random I/O operation!
*/


--------------------------------------------------------------------------------
-- Covering Index Structure
--------------------------------------------------------------------------------
/*
A covering index INCLUDEs the needed columns at the leaf level:

Covering Index on CustomerID INCLUDE (OrderDate, Status, TotalAmount):
+------------+----------+-----------+---------+--------+
| CustomerID | OrderID  | OrderDate | Status  | Total  |
| (Key)      | (Pointer)| (Include) |(Include)|(Incl)  |
+------------+----------+-----------+---------+--------+
| 15         | 2        | 2024-01   | Pending | 75.00  |
| 42         | 1        | 2024-01   | Shipped | 150.00 |
| 42         | 3        | 2024-02   | Shipped | 200.00 |

Now when we SELECT OrderDate, Status, TotalAmount WHERE CustomerID = 42:
1. Seek in covering index: Find CustomerID = 42
2. Read OrderDate, Status, TotalAmount from the SAME index page
3. NO Key Lookup needed!

Result: All sequential I/O, much faster!
*/


--------------------------------------------------------------------------------
-- Summary: Key Lookup Impact Factors
--------------------------------------------------------------------------------
/*
Key Lookup cost depends on:

1. NUMBER OF ROWS RETURNED
   - 10 rows = 10 lookups (minor impact)
   - 10,000 rows = 10,000 lookups (major impact)

2. SELECTIVITY OF PREDICATE
   - Highly selective (few rows) = Key Lookups are OK
   - Low selectivity (many rows) = Key Lookups are expensive

3. BUFFER POOL STATE
   - Hot data (already in memory) = Lookups are faster
   - Cold data (on disk) = Lookups are very slow

4. COLUMNS NEEDED
   - Just 1 extra column? Maybe tolerable
   - 5+ extra columns? Definitely add covering index

Next: Run 03-fix.sql to create covering indexes and see the improvement.
*/
GO
