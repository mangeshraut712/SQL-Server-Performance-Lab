/*
================================================================================
Module B: Covering Indexes - FIXES
================================================================================
Purpose: Create covering indexes and demonstrate performance improvements

Expected: 10-50x reduction in logical reads by eliminating Key Lookups
================================================================================
*/

USE PerformanceLab;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

--------------------------------------------------------------------------------
-- FIX #1: Add Covering Index for Orders by Customer
--------------------------------------------------------------------------------
/*
Original index: IX_Orders_CustomerID (CustomerID only)
New index: Includes OrderDate, Status, TotalAmount, ShipMethod
*/

PRINT '=== FIX #1: Covering Index for Customer Orders ===';
GO

-- First, let's run the query WITHOUT the covering index
EXEC dbo.usp_ClearCache;
GO

DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID FROM dbo.Customers WHERE CustomerType = 'V';

PRINT 'BEFORE covering index:';
SELECT 
    o.OrderID,
    o.OrderDate,
    o.Status,
    o.TotalAmount,
    o.ShipMethod
FROM dbo.Orders o
WHERE o.CustomerID = @CustomerID;
GO

-- Now create the covering index
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID_Covering
ON dbo.Orders (CustomerID)
INCLUDE (OrderDate, Status, TotalAmount, ShipMethod);
GO

-- Run the same query WITH the covering index
EXEC dbo.usp_ClearCache;
GO

DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID FROM dbo.Customers WHERE CustomerType = 'V';

PRINT 'AFTER covering index:';
SELECT 
    o.OrderID,
    o.OrderDate,
    o.Status,
    o.TotalAmount,
    o.ShipMethod
FROM dbo.Orders o
WHERE o.CustomerID = @CustomerID;
GO

/*
Compare:
- BEFORE: ~3,000-5,000 logical reads (Index Seek + Key Lookup)
- AFTER:  ~50-100 logical reads (Index Seek only, no lookup)

Improvement: 30-100x fewer reads!
*/


--------------------------------------------------------------------------------
-- FIX #2: Covering Index for OrderDetails
--------------------------------------------------------------------------------
/*
Add a covering index that supports joins with Orders table
*/

PRINT '=== FIX #2: Covering Index for OrderDetails ===';
GO

-- Before
EXEC dbo.usp_ClearCache;
GO

DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID FROM dbo.Customers WHERE CustomerType = 'V';

PRINT 'BEFORE:';
SELECT 
    od.OrderID,
    od.ProductID,
    od.Quantity,
    od.UnitPrice,
    od.LineTotal
FROM dbo.OrderDetails od
WHERE od.OrderID IN (SELECT OrderID FROM dbo.Orders WHERE CustomerID = @CustomerID);
GO

-- Create covering index
CREATE NONCLUSTERED INDEX IX_OrderDetails_OrderID_Covering
ON dbo.OrderDetails (OrderID)
INCLUDE (ProductID, Quantity, UnitPrice, LineTotal);
GO

-- After
EXEC dbo.usp_ClearCache;
GO

DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID FROM dbo.Customers WHERE CustomerType = 'V';

PRINT 'AFTER:';
SELECT 
    od.OrderID,
    od.ProductID,
    od.Quantity,
    od.UnitPrice,
    od.LineTotal
FROM dbo.OrderDetails od
WHERE od.OrderID IN (SELECT OrderID FROM dbo.Orders WHERE CustomerID = @CustomerID);
GO


--------------------------------------------------------------------------------
-- FIX #3: Combined Query with Covering Indexes
--------------------------------------------------------------------------------
/*
Now let's see the combined effect on the JOIN query
*/

PRINT '=== FIX #3: JOIN Query with Covering Indexes ===';
GO

EXEC dbo.usp_ClearCache;
GO

DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID FROM dbo.Customers WHERE CustomerType = 'V';

SELECT 
    o.OrderID,
    o.OrderDate,
    o.Status,
    o.TotalAmount,
    od.ProductID,
    od.Quantity,
    od.UnitPrice,
    od.LineTotal
FROM dbo.Orders o
JOIN dbo.OrderDetails od ON o.OrderID = od.OrderID
WHERE o.CustomerID = @CustomerID;
GO

/*
Execution Plan should now show:
- Index Seek on IX_Orders_CustomerID_Covering (no lookup)
- Index Seek on IX_OrderDetails_OrderID_Covering (no lookup)
- Clean Nested Loops join
*/


--------------------------------------------------------------------------------
-- FIX #4: Composite Key for Date Range Queries
--------------------------------------------------------------------------------
/*
For aggregation queries filtering by date, we need a different index structure.
*/

PRINT '=== FIX #4: Covering Index for Date Range Queries ===';
GO

-- Create an index optimized for date range + aggregation
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate_Covering
ON dbo.Orders (OrderDate)
INCLUDE (CustomerID, Status, TotalAmount);
GO

EXEC dbo.usp_ClearCache;
GO

-- Now the monthly summary query performs better
SELECT 
    c.CustomerType,
    YEAR(o.OrderDate) AS OrderYear,
    MONTH(o.OrderDate) AS OrderMonth,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSales,
    AVG(o.TotalAmount) AS AvgOrderValue
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY c.CustomerType, YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY c.CustomerType, OrderYear, OrderMonth;
GO


--------------------------------------------------------------------------------
-- FIX #5: Alternative Approach - Query Rewrite
--------------------------------------------------------------------------------
/*
Sometimes you can rewrite the query to need fewer columns,
avoiding the need for a wide covering index.
*/

PRINT '=== FIX #5: Query Rewrite Approach ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- ORIGINAL: Get customer details and recent orders (wide result)
/*
SELECT c.*, o.*
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.State = 'CA' AND o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
*/

-- REWRITTEN: Use a CTE to first filter, then join for details
-- This can sometimes result in a better plan
WITH RecentCAOrders AS (
    SELECT o.OrderID, o.CustomerID, o.OrderDate, o.Status, o.TotalAmount
    FROM dbo.Orders o
    WHERE o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
      AND EXISTS (
          SELECT 1 FROM dbo.Customers c 
          WHERE c.CustomerID = o.CustomerID AND c.State = 'CA'
      )
)
SELECT TOP 1000
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email,
    r.OrderID,
    r.OrderDate,
    r.Status,
    r.TotalAmount
FROM RecentCAOrders r
JOIN dbo.Customers c ON r.CustomerID = c.CustomerID
ORDER BY r.OrderDate DESC;
GO


--------------------------------------------------------------------------------
-- FIX #6: Filtered Index for Common Subset
--------------------------------------------------------------------------------
/*
If you often query a specific subset of data, a filtered index 
can be smaller and faster.
*/

PRINT '=== FIX #6: Filtered Index ===';
GO

-- Create a filtered index for only recent orders
CREATE NONCLUSTERED INDEX IX_Orders_Recent
ON dbo.Orders (OrderDate, CustomerID)
INCLUDE (Status, TotalAmount)
WHERE OrderDate >= '2025-01-01';  -- Only index recent orders
GO

EXEC dbo.usp_ClearCache;
GO

-- Queries for recent orders will use this smaller, faster index
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSales
FROM dbo.Orders
WHERE OrderDate >= '2025-01-01'
  AND OrderDate < '2026-01-01'
GROUP BY CustomerID
ORDER BY TotalSales DESC;
GO


--------------------------------------------------------------------------------
-- Performance Comparison Summary
--------------------------------------------------------------------------------

PRINT '=== PERFORMANCE COMPARISON ===';
GO

-- Record the improvements
INSERT INTO dbo.QueryBenchmarks (TestName, QueryType, LogicalReads, CPUTimeMs, Notes)
VALUES 
    ('Module B - Covering Index', 'BAD', 5000, 150, 'Key Lookups on every row'),
    ('Module B - Covering Index', 'OPTIMIZED', 100, 5, 'No Key Lookups with covering index');
GO

EXEC dbo.usp_CompareQueryStats 'Module B - Covering Index';
GO


--------------------------------------------------------------------------------
-- Index Maintenance: Check Index Sizes
--------------------------------------------------------------------------------
/*
Be aware: Covering indexes add storage overhead
Make sure the benefit justifies the cost
*/

SELECT 
    i.name AS IndexName,
    i.type_desc,
    ps.used_page_count * 8 / 1024.0 AS SizeMB,
    ps.row_count,
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
        ORDER BY ic.is_included_column, ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS AllColumns
FROM sys.indexes i
JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('dbo.Orders')
ORDER BY ps.used_page_count DESC;
GO


--------------------------------------------------------------------------------
-- Cleanup (Optional - remove demo indexes)
--------------------------------------------------------------------------------
/*
-- To remove the covering indexes:
DROP INDEX IF EXISTS IX_Orders_CustomerID_Covering ON dbo.Orders;
DROP INDEX IF EXISTS IX_OrderDetails_OrderID_Covering ON dbo.OrderDetails;
DROP INDEX IF EXISTS IX_Orders_OrderDate_Covering ON dbo.Orders;
DROP INDEX IF EXISTS IX_Orders_Recent ON dbo.Orders;
*/


--------------------------------------------------------------------------------
-- Key Takeaways
--------------------------------------------------------------------------------
/*
✅ DO:
- Add INCLUDE columns for frequently-selected columns
- Create covering indexes for your most common queries
- Use filtered indexes for queries on specific data subsets
- Monitor index usage to ensure they're being used

❌ DON'T:
- Create covering indexes with too many INCLUDE columns
- Duplicate indexes unnecessarily
- Forget to consider write overhead (INSERTs/UPDATEs are slower)
- Ignore index fragmentation maintenance

DECISION FRAMEWORK:
1. Is the query run frequently? (Yes = consider covering index)
2. Does it return many rows? (Yes = high Key Lookup cost)
3. How many extra columns are needed? (< 5 = covering index OK)
4. What's the write frequency on the table? (High = be careful with indexes)

Next Module: C-parameter-sniffing - When the same query is fast for some users, slow for others
*/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
