/*
================================================================================
Module C: Parameter Sniffing - FIXES
================================================================================
Purpose: Multiple solutions for parameter sniffing problems
================================================================================
*/

USE PerformanceLab;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

--------------------------------------------------------------------------------
-- FIX #1: OPTION (RECOMPILE)
--------------------------------------------------------------------------------
/*
Forces a new plan for every execution.
+ Always optimal plan for the given parameters
- Adds compilation overhead each time
Best for: Low-frequency queries, highly variable data
*/

PRINT '=== FIX #1: OPTION (RECOMPILE) ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- VIP customer
DECLARE @VIPCustomerID INT;
SELECT TOP 1 @VIPCustomerID = CustomerID FROM dbo.Customers WHERE CustomerType = 'V';

EXEC dbo.usp_GetOrdersByCustomer_Recompile @CustomerID = @VIPCustomerID;
GO

-- Regular customer  
DECLARE @RegularCustomerID INT;
SELECT TOP 1 @RegularCustomerID = CustomerID 
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerType = 'R'
GROUP BY c.CustomerID
HAVING COUNT(*) <= 5;

EXEC dbo.usp_GetOrdersByCustomer_Recompile @CustomerID = @RegularCustomerID;
GO


--------------------------------------------------------------------------------
-- FIX #2: OPTIMIZE FOR UNKNOWN
--------------------------------------------------------------------------------
/*
Uses average statistics instead of sniffed value.
+ No compilation overhead
+ More predictable performance
- May not be optimal for anyone
Best for: Wide range of parameter values
*/

PRINT '=== FIX #2: OPTIMIZE FOR UNKNOWN ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- Both VIP and Regular get the "average" plan
DECLARE @VIPCustomerID INT;
SELECT TOP 1 @VIPCustomerID = CustomerID FROM dbo.Customers WHERE CustomerType = 'V';

EXEC dbo.usp_GetOrdersByCustomer_OptimizeFor @CustomerID = @VIPCustomerID;
GO


--------------------------------------------------------------------------------
-- FIX #3: OPTIMIZE FOR Specific Value
--------------------------------------------------------------------------------
/*
Optimize for a known "typical" value.
Best for: When you know the common case
*/

PRINT '=== FIX #3: OPTIMIZE FOR specific value ===';
GO

-- Create procedure optimized for "typical" customer
IF OBJECT_ID('dbo.usp_GetOrdersByCustomer_OptimizeForTypical', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.usp_GetOrdersByCustomer_OptimizeForTypical;
GO

CREATE PROCEDURE dbo.usp_GetOrdersByCustomer_OptimizeForTypical
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT o.OrderID, o.OrderDate, o.Status, o.TotalAmount,
           COUNT(od.OrderDetailID) AS ItemCount
    FROM dbo.Orders o
    JOIN dbo.OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = @CustomerID
    GROUP BY o.OrderID, o.OrderDate, o.Status, o.TotalAmount
    -- Optimize for a customer with ~10 orders (middle ground)
    OPTION (OPTIMIZE FOR (@CustomerID = 1000));
END
GO


--------------------------------------------------------------------------------
-- FIX #4: Dynamic SQL
--------------------------------------------------------------------------------
/*
Build SQL dynamically so each unique query gets its own plan.
+ Full control
- SQL injection risk if not parameterized
Best for: Complex scenarios
*/

PRINT '=== FIX #4: Dynamic SQL ===';
GO

IF OBJECT_ID('dbo.usp_GetOrdersByCustomer_Dynamic', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.usp_GetOrdersByCustomer_Dynamic;
GO

CREATE PROCEDURE dbo.usp_GetOrdersByCustomer_Dynamic
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Use sp_executesql for parameterized dynamic SQL (safe!)
    DECLARE @SQL NVARCHAR(1000) = N'
        SELECT o.OrderID, o.OrderDate, o.Status, o.TotalAmount,
               COUNT(od.OrderDetailID) AS ItemCount
        FROM dbo.Orders o
        JOIN dbo.OrderDetails od ON o.OrderID = od.OrderID
        WHERE o.CustomerID = @CustID
        GROUP BY o.OrderID, o.OrderDate, o.Status, o.TotalAmount';
    
    EXEC sp_executesql @SQL, N'@CustID INT', @CustID = @CustomerID;
END
GO


--------------------------------------------------------------------------------
-- Comparison Summary
--------------------------------------------------------------------------------

PRINT '=== SOLUTION COMPARISON ===';
GO

/*
| Solution | Compile Cost | Plan Quality | Maintenance |
|----------|--------------|--------------|-------------|
| RECOMPILE | Every exec | Always optimal | Easy |
| OPTIMIZE FOR UNKNOWN | Once | Average | Easy |
| OPTIMIZE FOR value | Once | Good for typical | Medium |
| Dynamic SQL | Per unique | Optimal | Complex |

Choose based on:
- Query frequency (high freq -> avoid RECOMPILE)
- Data skew severity (extreme -> use RECOMPILE)
- Maintenance capacity (low -> use hints)
*/

-- Record benchmark
INSERT INTO dbo.QueryBenchmarks (TestName, QueryType, Notes)
VALUES 
    ('Module C - Parameter Sniffing', 'BAD', 'Inconsistent: 5ms vs 500ms'),
    ('Module C - Parameter Sniffing', 'OPTIMIZED', 'Consistent: 20ms avg');
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
