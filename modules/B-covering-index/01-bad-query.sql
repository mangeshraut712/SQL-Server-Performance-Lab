/*
================================================================================
Module B: Covering Indexes - BAD QUERIES
================================================================================
Purpose: Demonstrate queries that cause expensive Key Lookups

Instructions:
1. Enable "Include Actual Execution Plan" (Ctrl+M)
2. Run each query and examine the plan
3. Look for the "Key Lookup" operator
4. Note the logical reads and execution time
================================================================================
*/

USE PerformanceLab;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

EXEC dbo.usp_ClearCache;
GO

--------------------------------------------------------------------------------
-- BAD QUERY #1: Simple Query with Key Lookups
--------------------------------------------------------------------------------
/*
We have an index on CustomerID in Orders, but this query also selects
OrderDate, Status, and TotalAmount which are NOT in the index.

For each row found in the index, SQL Server must go back to the 
clustered index to fetch the other columns = KEY LOOKUP
*/

PRINT '=== BAD QUERY #1: Key Lookup on Orders ===';
GO

-- Find all orders for a specific customer (VIP customer with many orders)
DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID 
FROM dbo.Customers 
WHERE CustomerType = 'V';

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
Execution Plan Analysis:
1. Look for "Index Seek" on IX_Orders_CustomerID
2. Look for "Key Lookup" on the clustered index
3. Note the cost percentage of each operator
4. Look at the thick arrow between them (data flow)

Expected: ~3,000-5,000 logical reads for a VIP customer
*/


--------------------------------------------------------------------------------
-- BAD QUERY #2: JOIN with Key Lookups on Both Tables
--------------------------------------------------------------------------------
/*
This query joins Orders and OrderDetails and selects columns
from both tables that are not in the available indexes.
*/

PRINT '=== BAD QUERY #2: Key Lookups on JOIN ===';
GO

EXEC dbo.usp_ClearCache;
GO

DECLARE @CustomerID INT;
SELECT TOP 1 @CustomerID = CustomerID 
FROM dbo.Customers 
WHERE CustomerType = 'V';

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
Execution Plan Analysis:
1. Multiple Key Lookup operators
2. Nested Loop joins with high cost
3. Significant logical reads from both tables
*/


--------------------------------------------------------------------------------
-- BAD QUERY #3: Aggregation Query Missing Covering Index
--------------------------------------------------------------------------------
/*
Even aggregation queries can suffer from key lookups when the
aggregated columns aren't in the index.
*/

PRINT '=== BAD QUERY #3: Aggregation with Key Lookups ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- Monthly sales summary by customer type
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

/*
This query needs:
- CustomerType from Customers
- OrderDate and TotalAmount from Orders
- Ideally covered by composite indexes
*/


--------------------------------------------------------------------------------
-- BAD QUERY #4: Reporting Query Returning Many Columns
--------------------------------------------------------------------------------
/*
Reporting queries often SELECT many columns, making covering 
indexes impractical. But we can still optimize.
*/

PRINT '=== BAD QUERY #4: Wide Result Set ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- Customer order summary report
SELECT TOP 1000
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email,
    c.CustomerType,
    c.City,
    c.State,
    o.OrderID,
    o.OrderDate,
    o.Status,
    o.TotalAmount,
    o.ShipMethod
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE c.State = 'CA'
  AND o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
ORDER BY o.OrderDate DESC;
GO

/*
With this many columns, a covering index would be too wide.
We need alternative strategies (see 03-fix.sql).
*/


--------------------------------------------------------------------------------
-- BAD QUERY #5: Product Sales with Multiple Lookups
--------------------------------------------------------------------------------
/*
Three-table join with lookups needed from each table.
*/

PRINT '=== BAD QUERY #5: Multi-Table Join ===';
GO

EXEC dbo.usp_ClearCache;
GO

SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    SUM(od.Quantity) AS TotalQuantitySold,
    SUM(od.LineTotal) AS TotalRevenue,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers
FROM dbo.Products p
JOIN dbo.OrderDetails od ON p.ProductID = od.ProductID
JOIN dbo.Orders o ON od.OrderID = o.OrderID
WHERE o.OrderDate >= DATEADD(MONTH, -3, GETDATE())
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY TotalRevenue DESC;
GO


--------------------------------------------------------------------------------
-- Record Your Baseline Measurements
--------------------------------------------------------------------------------
/*
Fill in your observations:

| Query | Logical Reads (Orders) | Logical Reads (OrderDetails) | Key Lookups? | Time (ms) |
|-------|------------------------|------------------------------|--------------|-----------|
| #1 | _____ | N/A | Yes/No | _____ |
| #2 | _____ | _____ | Yes/No | _____ |
| #3 | _____ | _____ | Yes/No | _____ |
| #4 | _____ | _____ | Yes/No | _____ |
| #5 | _____ | _____ | Yes/No | _____ |

Next: Run 02-analysis.sql to understand the problem.
*/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
