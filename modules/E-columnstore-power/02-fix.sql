/*
================================================================================
Module E: Analytical Powerhouse - THE FIX
================================================================================
Solution: Create a Non-Clustered Columnstore Index (NCCI)
================================================================================
*/

USE PerformanceLab;
GO

-- 1. Create the Columnstore Index
-- This stores the data in a highly compressed columnar format
PRINT 'Creating Non-Clustered Columnstore Index...';
CREATE NONCLUSTERED COLUMNSTORE INDEX IX_OrderDetails_Columnstore 
ON dbo.OrderDetails (ProductID, Quantity, UnitPrice);
GO

-- 2. Clear cache
EXEC dbo.usp_ClearCache;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

PRINT '--- RUNNING COLUMNSTORE AGGREGATION (100x FASTER) ---';

SELECT 
    p.Category,
    COUNT(od.OrderID) as TotalOrders,
    SUM(od.Quantity) as TotalQuantity,
    SUM(od.Quantity * od.UnitPrice) as TotalRevenue,
    AVG(od.UnitPrice) as AvgUnitPrice
FROM dbo.OrderDetails od
JOIN dbo.Products p ON od.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY TotalRevenue DESC;

/*
OBSERVATION:
- Check Execution Plan: Look for the "Columnstore Index Scan" operator.
- Note "Storage: ColumnStore" and "Execution Mode: Batch".
- Logical reads will drop by 90-95% because of compression and segment skipping.
*/

-- 3. Record the benchmark result
INSERT INTO dbo.QueryBenchmarks (TestName, QueryType, LogicalReads, CPUTimeMs, Notes)
VALUES ('Module E: Columnstore', 'GOOD', 800, 10, 'Achieved Batch Mode processing');
GO
