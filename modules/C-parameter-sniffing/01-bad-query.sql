/*
================================================================================
Module C: Parameter Sniffing - DEMONSTRATION
================================================================================
Purpose: Show how parameter sniffing can cause dramatic performance differences
         for the same query with different parameter values.

Setup Note: Our seed data has INTENTIONAL data skew:
  - VIP customers (5%) have 40% of all orders (many orders per customer)
  - Regular customers (70%) have 25% of orders (few orders per customer)
================================================================================
*/

USE PerformanceLab;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

--------------------------------------------------------------------------------
-- Step 1: Verify Data Skew
--------------------------------------------------------------------------------
/*
Let's first confirm our data distribution creates the conditions for
parameter sniffing to cause problems.
*/

PRINT '=== DATA DISTRIBUTION ANALYSIS ===';
GO

-- Show order distribution by customer type
SELECT 
    c.CustomerType,
    COUNT(DISTINCT c.CustomerID) AS CustomerCount,
    COUNT(o.OrderID) AS TotalOrders,
    AVG(OrdersPerCustomer.OrderCount) AS AvgOrdersPerCustomer,
    MAX(OrdersPerCustomer.OrderCount) AS MaxOrdersPerCustomer,
    MIN(OrdersPerCustomer.OrderCount) AS MinOrdersPerCustomer
FROM dbo.Customers c
LEFT JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM dbo.Orders
    GROUP BY CustomerID
) OrdersPerCustomer ON c.CustomerID = OrdersPerCustomer.CustomerID
GROUP BY c.CustomerType
ORDER BY c.CustomerType;
GO

/*
Expected output:
CustomerType | AvgOrdersPerCustomer | MaxOrdersPerCustomer
P (Premium)  | ~5                   | ~20
R (Regular)  | ~1-2                 | ~10
V (VIP)      | ~30-50               | ~100+

This is the SKEW that causes parameter sniffing issues!
*/


--------------------------------------------------------------------------------
-- Step 2: Find Sample Customers
--------------------------------------------------------------------------------

PRINT '=== SAMPLE CUSTOMERS FOR TESTING ===';
GO

-- Find a VIP customer with MANY orders
DECLARE @VIPCustomerID INT;
DECLARE @VIPOrderCount INT;

SELECT TOP 1 
    @VIPCustomerID = c.CustomerID,
    @VIPOrderCount = COUNT(o.OrderID)
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerType = 'V'
GROUP BY c.CustomerID
ORDER BY COUNT(o.OrderID) DESC;

PRINT 'VIP Customer ID: ' + CAST(@VIPCustomerID AS VARCHAR) + 
      ' has ' + CAST(@VIPOrderCount AS VARCHAR) + ' orders';

-- Find a Regular customer with FEW orders
DECLARE @RegularCustomerID INT;
DECLARE @RegularOrderCount INT;

SELECT TOP 1 
    @RegularCustomerID = c.CustomerID,
    @RegularOrderCount = COUNT(o.OrderID)
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerType = 'R'
GROUP BY c.CustomerID
HAVING COUNT(o.OrderID) <= 5
ORDER BY COUNT(o.OrderID);

PRINT 'Regular Customer ID: ' + CAST(@RegularCustomerID AS VARCHAR) + 
      ' has ' + CAST(@RegularOrderCount AS VARCHAR) + ' orders';
GO


--------------------------------------------------------------------------------
-- Step 3: Clear Plan Cache (Important!)
--------------------------------------------------------------------------------
/*
We need to start fresh to observe parameter sniffing behavior.
*/

PRINT '=== CLEARING PLAN CACHE ===';
GO

EXEC dbo.usp_ClearCache;
GO


--------------------------------------------------------------------------------
-- Step 4: Execute Procedure with VIP Customer FIRST
--------------------------------------------------------------------------------
/*
The first execution will compile the procedure with a plan optimized
for the VIP customer (expecting MANY rows).
*/

PRINT '';
PRINT '=== FIRST EXECUTION: VIP Customer (many orders) ===';
PRINT 'This compiles the plan and caches it.';
GO

DECLARE @VIPCustomerID INT;
SELECT TOP 1 @VIPCustomerID = c.CustomerID
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerType = 'V'
GROUP BY c.CustomerID
ORDER BY COUNT(o.OrderID) DESC;

PRINT 'Executing for VIP CustomerID: ' + CAST(@VIPCustomerID AS VARCHAR);

-- Execute the procedure
EXEC dbo.usp_GetOrdersByCustomer @CustomerID = @VIPCustomerID;
GO

/*
Observe:
- Logical reads
- CPU time
- Execution plan (likely shows scan/hash operations for many rows)
- Record these numbers!
*/


--------------------------------------------------------------------------------
-- Step 5: Execute Same Procedure with Regular Customer
--------------------------------------------------------------------------------
/*
Now we execute with a Regular customer. The plan is ALREADY CACHED
from the VIP customer execution, even though it may not be optimal
for the few rows this customer has.
*/

PRINT '';
PRINT '=== SECOND EXECUTION: Regular Customer (few orders) ===';
PRINT 'This REUSES the cached plan from the VIP execution!';
GO

DECLARE @RegularCustomerID INT;
SELECT TOP 1 @RegularCustomerID = c.CustomerID
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerType = 'R'
GROUP BY c.CustomerID
HAVING COUNT(o.OrderID) <= 5
ORDER BY COUNT(o.OrderID);

PRINT 'Executing for Regular CustomerID: ' + CAST(@RegularCustomerID AS VARCHAR);

-- Execute the SAME procedure - plan is reused
EXEC dbo.usp_GetOrdersByCustomer @CustomerID = @RegularCustomerID;
GO

/*
Compare to the VIP execution:
- Logical reads: Should be similar (BAD - we're reading way more than needed!)
- CPU time: Similar
- The plan is wrong for this low-row-count customer
*/


--------------------------------------------------------------------------------
-- Step 6: Reverse Order - Regular First
--------------------------------------------------------------------------------
/*
Let's see what happens when we compile the plan for a REGULAR customer first.
*/

PRINT '';
PRINT '=== REVERSE TEST: Clear cache and run Regular FIRST ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- Run Regular customer first
DECLARE @RegularCustomerID INT;
SELECT TOP 1 @RegularCustomerID = c.CustomerID
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerType = 'R'
GROUP BY c.CustomerID
HAVING COUNT(o.OrderID) <= 5;

PRINT 'First execution (Regular): CustomerID ' + CAST(@RegularCustomerID AS VARCHAR);

EXEC dbo.usp_GetOrdersByCustomer @CustomerID = @RegularCustomerID;
GO

-- Now run VIP customer (reuses plan optimized for Regular!)
DECLARE @VIPCustomerID INT;
SELECT TOP 1 @VIPCustomerID = c.CustomerID
FROM dbo.Customers c
JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerType = 'V'
GROUP BY c.CustomerID
ORDER BY COUNT(o.OrderID) DESC;

PRINT 'Second execution (VIP): CustomerID ' + CAST(@VIPCustomerID AS VARCHAR);

EXEC dbo.usp_GetOrdersByCustomer @CustomerID = @VIPCustomerID;
GO

/*
Now the OPPOSITE problem!
- The plan was optimized for few rows (Index Seek + Nested Loops)
- VIP customer with many rows is SLOW with this plan
- This is parameter sniffing in action!
*/


--------------------------------------------------------------------------------
-- Step 7: Document the Problem
--------------------------------------------------------------------------------

PRINT '';
PRINT '=== PARAMETER SNIFFING SUMMARY ===';
GO

/*
Record your observations:

| Test Scenario | First Exec Type | First Exec Time | Second Exec Time | Problem |
|---------------|-----------------|-----------------|------------------|---------|
| VIP First | VIP (~1000 rows) | ____ ms | ____ ms | Regular too slow |
| Regular First | Regular (~5 rows) | ____ ms | ____ ms | VIP too slow |

The same procedure with the same code has WILDLY different performance
depending on which customer type is executed FIRST after a cache clear.

This is because:
1. SQL Server creates ONE plan per procedure
2. The plan is optimized for the FIRST parameter value seen
3. That plan is reused for ALL subsequent calls
4. If data distribution varies, the plan may be wrong!

Next: Run 02-analysis.sql to understand the mechanics.
      Then 03-fix.sql to see the solutions.
*/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
