/*
================================================================================
Module E: Analytical Powerhouse - THE BAD QUERY
================================================================================
Scenario: Management wants a report showing total sales and average quantity 
          per product category. This is an "Analytical" query.
================================================================================
*/

USE PerformanceLab;
GO

-- 1. Enable statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- 2. Clear cache for a fair test
EXEC dbo.usp_ClearCache;
GO

PRINT '--- RUNNING ROW-STORE AGGREGATION (SLOW) ---';

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
OBSERSVATION:
- Check "Messages" tab: Note the high number of logical reads on OrderDetails.
- Check Execution Plan: You will see "Row Mode" processing.
- The query has to touch every row to find the totals.
*/
