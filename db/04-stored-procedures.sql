/*
================================================================================
SQL Server Performance Lab - Stored Procedures
================================================================================
Purpose: Creates reusable stored procedures for benchmarking, monitoring,
         and demonstrating various performance scenarios.

Execution: Run after 03-indexes.sql completes.
================================================================================
*/

USE PerformanceLab;
GO

SET NOCOUNT ON;
PRINT 'Creating stored procedures...';
PRINT '';

--------------------------------------------------------------------------------
-- Utility: Clear buffers and cache (for consistent benchmarking)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_ClearCache', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ClearCache;
GO

CREATE PROCEDURE dbo.usp_ClearCache
AS
BEGIN
    /*
    ============================================================================
    WARNING: Only use in development/testing environments!
    This clears all cached data and execution plans.
    ============================================================================
    */
    SET NOCOUNT ON;
    
    CHECKPOINT;
    DBCC DROPCLEANBUFFERS;
    DBCC FREEPROCCACHE;
    
    PRINT 'Buffer pool and procedure cache cleared.';
END
GO

PRINT '  Created: dbo.usp_ClearCache';
GO

--------------------------------------------------------------------------------
-- Utility: Show index usage statistics
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_IndexUsageStats', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_IndexUsageStats;
GO

CREATE PROCEDURE dbo.usp_IndexUsageStats
    @TableName NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        OBJECT_NAME(i.object_id) AS TableName,
        i.name AS IndexName,
        i.type_desc AS IndexType,
        ius.user_seeks,
        ius.user_scans,
        ius.user_lookups,
        ius.user_updates,
        ius.last_user_seek,
        ius.last_user_scan,
        CASE 
            WHEN ius.user_seeks + ius.user_scans + ius.user_lookups = 0 THEN 'UNUSED'
            WHEN ius.user_updates > (ius.user_seeks + ius.user_scans) * 10 THEN 'MORE WRITES THAN READS'
            ELSE 'ACTIVE'
        END AS UsageStatus
    FROM sys.indexes i
    LEFT JOIN sys.dm_db_index_usage_stats ius 
        ON i.object_id = ius.object_id 
        AND i.index_id = ius.index_id 
        AND ius.database_id = DB_ID()
    WHERE OBJECT_NAME(i.object_id) = ISNULL(@TableName, OBJECT_NAME(i.object_id))
      AND OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
      AND i.type > 0
    ORDER BY 
        OBJECT_NAME(i.object_id),
        ius.user_seeks + ius.user_scans + ius.user_lookups DESC;
END
GO

PRINT '  Created: dbo.usp_IndexUsageStats';
GO

--------------------------------------------------------------------------------
-- Utility: Show missing index suggestions
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_MissingIndexes', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_MissingIndexes;
GO

CREATE PROCEDURE dbo.usp_MissingIndexes
    @MinImpact FLOAT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        OBJECT_NAME(mid.object_id) AS TableName,
        mid.equality_columns,
        mid.inequality_columns,
        mid.included_columns,
        migs.unique_compiles,
        migs.user_seeks,
        migs.user_scans,
        CAST(migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) AS DECIMAL(18,2)) AS ImprovementMeasure,
        'CREATE NONCLUSTERED INDEX IX_' + OBJECT_NAME(mid.object_id) + '_' + 
        REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,''), '[', ''), ']', ''), ', ', '_') +
        ' ON ' + mid.statement + 
        ' (' + ISNULL(mid.equality_columns, '') + 
        CASE WHEN mid.inequality_columns IS NOT NULL THEN ', ' + mid.inequality_columns ELSE '' END + ')' +
        CASE WHEN mid.included_columns IS NOT NULL THEN ' INCLUDE (' + mid.included_columns + ')' ELSE '' END 
        AS CreateStatement
    FROM sys.dm_db_missing_index_details mid
    JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
    JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
    WHERE mid.database_id = DB_ID()
      AND CAST(migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) AS DECIMAL(18,2)) >= @MinImpact
    ORDER BY ImprovementMeasure DESC;
END
GO

PRINT '  Created: dbo.usp_MissingIndexes';
GO

--------------------------------------------------------------------------------
-- Demo: Search Customers (BAD version - for Module A)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_SearchCustomers_Bad', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_SearchCustomers_Bad;
GO

CREATE PROCEDURE dbo.usp_SearchCustomers_Bad
    @SearchTerm NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- BAD: Uses LIKE with leading wildcard (can't use index)
    -- BAD: Uses UPPER() function on column (can't use index)
    SELECT 
        CustomerID,
        FirstName,
        LastName,
        Email,
        City,
        State
    FROM dbo.Customers
    WHERE UPPER(LastName) LIKE '%' + UPPER(@SearchTerm) + '%'
       OR UPPER(FirstName) LIKE '%' + UPPER(@SearchTerm) + '%'
       OR UPPER(Email) LIKE '%' + UPPER(@SearchTerm) + '%';
END
GO

PRINT '  Created: dbo.usp_SearchCustomers_Bad';
GO

--------------------------------------------------------------------------------
-- Demo: Search Customers (GOOD version - for Module A)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_SearchCustomers_Good', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_SearchCustomers_Good;
GO

CREATE PROCEDURE dbo.usp_SearchCustomers_Good
    @LastName NVARCHAR(50) = NULL,
    @Email NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- GOOD: Uses index-friendly patterns
    -- GOOD: Separate parameters for separate searches
    -- GOOD: Leading wildcard removed where possible
    SELECT 
        CustomerID,
        FirstName,
        LastName,
        Email,
        City,
        State
    FROM dbo.Customers
    WHERE (@LastName IS NULL OR LastName LIKE @LastName + '%')
      AND (@Email IS NULL OR Email = @Email);
END
GO

PRINT '  Created: dbo.usp_SearchCustomers_Good';
GO

--------------------------------------------------------------------------------
-- Demo: Get Orders By Customer (for Parameter Sniffing - Module C)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_GetOrdersByCustomer', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_GetOrdersByCustomer;
GO

CREATE PROCEDURE dbo.usp_GetOrdersByCustomer
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- This procedure will demonstrate parameter sniffing
    -- When first called with a VIP customer (many orders), 
    -- it may create a plan that's bad for regular customers (few orders)
    SELECT 
        o.OrderID,
        o.OrderDate,
        o.Status,
        o.TotalAmount,
        COUNT(od.OrderDetailID) AS ItemCount,
        SUM(od.LineTotal) AS LineItemTotal
    FROM dbo.Orders o
    JOIN dbo.OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = @CustomerID
    GROUP BY o.OrderID, o.OrderDate, o.Status, o.TotalAmount
    ORDER BY o.OrderDate DESC;
END
GO

PRINT '  Created: dbo.usp_GetOrdersByCustomer';
GO

--------------------------------------------------------------------------------
-- Demo: Get Orders By Customer (with RECOMPILE fix)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_GetOrdersByCustomer_Recompile', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_GetOrdersByCustomer_Recompile;
GO

CREATE PROCEDURE dbo.usp_GetOrdersByCustomer_Recompile
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- OPTION (RECOMPILE) ensures a new plan for each execution
    -- Good for highly variable data distributions
    SELECT 
        o.OrderID,
        o.OrderDate,
        o.Status,
        o.TotalAmount,
        COUNT(od.OrderDetailID) AS ItemCount,
        SUM(od.LineTotal) AS LineItemTotal
    FROM dbo.Orders o
    JOIN dbo.OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = @CustomerID
    GROUP BY o.OrderID, o.OrderDate, o.Status, o.TotalAmount
    ORDER BY o.OrderDate DESC
    OPTION (RECOMPILE);
END
GO

PRINT '  Created: dbo.usp_GetOrdersByCustomer_Recompile';
GO

--------------------------------------------------------------------------------
-- Demo: Get Orders By Customer (with OPTIMIZE FOR fix)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_GetOrdersByCustomer_OptimizeFor', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_GetOrdersByCustomer_OptimizeFor;
GO

CREATE PROCEDURE dbo.usp_GetOrdersByCustomer_OptimizeFor
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- OPTIMIZE FOR UNKNOWN uses average statistics
    -- Better for consistent performance across different values
    SELECT 
        o.OrderID,
        o.OrderDate,
        o.Status,
        o.TotalAmount,
        COUNT(od.OrderDetailID) AS ItemCount,
        SUM(od.LineTotal) AS LineItemTotal
    FROM dbo.Orders o
    JOIN dbo.OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = @CustomerID
    GROUP BY o.OrderID, o.OrderDate, o.Status, o.TotalAmount
    ORDER BY o.OrderDate DESC
    OPTION (OPTIMIZE FOR UNKNOWN);
END
GO

PRINT '  Created: dbo.usp_GetOrdersByCustomer_OptimizeFor';
GO

--------------------------------------------------------------------------------
-- Demo: Update Inventory (for Deadlock demo - Session A pattern)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_UpdateInventory_DeadlockProneA', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.usp_UpdateInventory_DeadlockProneA;
GO

CREATE PROCEDURE dbo.usp_UpdateInventory_DeadlockProneA
    @ProductID1 INT,
    @ProductID2 INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    -- Update Product 1 first
    UPDATE dbo.Inventory 
    SET QuantityOnHand = QuantityOnHand - @Quantity,
        LastUpdated = SYSDATETIME()
    WHERE ProductID = @ProductID1;
    
    -- Simulate some processing time
    WAITFOR DELAY '00:00:02';
    
    -- Then update Product 2
    UPDATE dbo.Inventory 
    SET QuantityOnHand = QuantityOnHand + @Quantity,
        LastUpdated = SYSDATETIME()
    WHERE ProductID = @ProductID2;
    
    -- Log the change
    INSERT INTO dbo.AuditLog (TableName, RecordID, Action, NewValue)
    VALUES ('Inventory', @ProductID1, 'UPDATE', 
            '{"transferred": ' + CAST(@Quantity AS VARCHAR) + '}');
    
    COMMIT TRANSACTION;
    
    PRINT 'Inventory transfer complete.';
END
GO

PRINT '  Created: dbo.usp_UpdateInventory_DeadlockProneA';
GO

--------------------------------------------------------------------------------
-- Demo: Update Inventory (for Deadlock demo - Session B pattern)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_UpdateInventory_DeadlockProneB', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.usp_UpdateInventory_DeadlockProneB;
GO

CREATE PROCEDURE dbo.usp_UpdateInventory_DeadlockProneB
    @ProductID1 INT,
    @ProductID2 INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    -- Update Product 2 FIRST (opposite order from Session A!)
    UPDATE dbo.Inventory 
    SET QuantityOnHand = QuantityOnHand - @Quantity,
        LastUpdated = SYSDATETIME()
    WHERE ProductID = @ProductID2;
    
    -- Simulate some processing time
    WAITFOR DELAY '00:00:02';
    
    -- Then update Product 1 (opposite order from Session A!)
    UPDATE dbo.Inventory 
    SET QuantityOnHand = QuantityOnHand + @Quantity,
        LastUpdated = SYSDATETIME()
    WHERE ProductID = @ProductID1;
    
    -- Log the change
    INSERT INTO dbo.AuditLog (TableName, RecordID, Action, NewValue)
    VALUES ('Inventory', @ProductID2, 'UPDATE', 
            '{"transferred": ' + CAST(@Quantity AS VARCHAR) + '}');
    
    COMMIT TRANSACTION;
    
    PRINT 'Inventory transfer complete.';
END
GO

PRINT '  Created: dbo.usp_UpdateInventory_DeadlockProneB';
GO

--------------------------------------------------------------------------------
-- Demo: Update Inventory (FIXED - consistent ordering)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_UpdateInventory_Fixed', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.usp_UpdateInventory_Fixed;
GO

CREATE PROCEDURE dbo.usp_UpdateInventory_Fixed
    @ProductID1 INT,
    @ProductID2 INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- FIX: Always acquire locks in the same order (by ProductID)
    DECLARE @FirstProduct INT = CASE WHEN @ProductID1 < @ProductID2 THEN @ProductID1 ELSE @ProductID2 END;
    DECLARE @SecondProduct INT = CASE WHEN @ProductID1 < @ProductID2 THEN @ProductID2 ELSE @ProductID1 END;
    DECLARE @FirstQty INT = CASE WHEN @ProductID1 < @ProductID2 THEN -@Quantity ELSE @Quantity END;
    DECLARE @SecondQty INT = CASE WHEN @ProductID1 < @ProductID2 THEN @Quantity ELSE -@Quantity END;
    
    BEGIN TRANSACTION;
    
    -- Always update lower ProductID first
    UPDATE dbo.Inventory 
    SET QuantityOnHand = QuantityOnHand + @FirstQty,
        LastUpdated = SYSDATETIME()
    WHERE ProductID = @FirstProduct;
    
    -- Then update higher ProductID
    UPDATE dbo.Inventory 
    SET QuantityOnHand = QuantityOnHand + @SecondQty,
        LastUpdated = SYSDATETIME()
    WHERE ProductID = @SecondProduct;
    
    -- Log the change
    INSERT INTO dbo.AuditLog (TableName, RecordID, Action, NewValue)
    VALUES ('Inventory', @ProductID1, 'UPDATE', 
            '{"transferred_to": ' + CAST(@ProductID2 AS VARCHAR) + 
            ', "quantity": ' + CAST(@Quantity AS VARCHAR) + '}');
    
    COMMIT TRANSACTION;
    
    PRINT 'Inventory transfer complete (using consistent lock ordering).';
END
GO

PRINT '  Created: dbo.usp_UpdateInventory_Fixed';
GO

--------------------------------------------------------------------------------
-- Utility: Compare Query Performance
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_CompareQueryStats', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_CompareQueryStats;
GO

CREATE PROCEDURE dbo.usp_CompareQueryStats
    @TestName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        TestName,
        QueryType,
        LogicalReads,
        CPUTimeMs,
        ElapsedTimeMs,
        RowsReturned,
        TestDate
    FROM dbo.QueryBenchmarks
    WHERE TestName = @TestName
    ORDER BY TestDate DESC;
    
    -- Show improvement percentage
    SELECT 
        bad.TestName,
        bad.LogicalReads AS BadLogicalReads,
        good.LogicalReads AS GoodLogicalReads,
        CAST((bad.LogicalReads - good.LogicalReads) * 100.0 / NULLIF(bad.LogicalReads, 0) AS DECIMAL(5,2)) AS LogicalReadsImprovement,
        bad.ElapsedTimeMs AS BadElapsedMs,
        good.ElapsedTimeMs AS GoodElapsedMs,
        CAST((bad.ElapsedTimeMs - good.ElapsedTimeMs) * 100.0 / NULLIF(bad.ElapsedTimeMs, 0) AS DECIMAL(5,2)) AS TimeImprovement
    FROM dbo.QueryBenchmarks bad
    JOIN dbo.QueryBenchmarks good ON bad.TestName = good.TestName
    WHERE bad.QueryType = 'BAD'
      AND good.QueryType = 'OPTIMIZED'
      AND bad.TestName = @TestName
      AND bad.BenchmarkID = (
          SELECT MAX(BenchmarkID) FROM dbo.QueryBenchmarks 
          WHERE TestName = @TestName AND QueryType = 'BAD'
      )
      AND good.BenchmarkID = (
          SELECT MAX(BenchmarkID) FROM dbo.QueryBenchmarks 
          WHERE TestName = @TestName AND QueryType = 'OPTIMIZED'
      );
END
GO

PRINT '  Created: dbo.usp_CompareQueryStats';
GO

--------------------------------------------------------------------------------
-- Utility: View Performance Dashboard
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_ViewDashboard', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ViewDashboard;
GO

CREATE PROCEDURE dbo.usp_ViewDashboard
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '╔══════════════════════════════════════════════════════════════════════════╗';
    PRINT '║              SQL SERVER PERFORMANCE LAB - FINAL DASHBOARD                ║';
    PRINT '╚══════════════════════════════════════════════════════════════════════════╝';
    PRINT '';

    -- 1. Database Health
    SELECT 
        DB_NAME() as [Database],
        (SELECT COUNT(*) FROM dbo.Customers) as Customers,
        (SELECT COUNT(*) FROM dbo.Orders) as Orders,
        (SELECT COUNT(*) FROM dbo.OrderDetails) as [Order Details],
        CONVERT(VARCHAR, GETDATE(), 120) as [System Time];

    -- 2. Improvement Summary (Mocked logic to show what it looks like)
    PRINT '';
    PRINT '--- OPTIMIZATION RESULTS ---';

    DECLARE @Summary TABLE (
        Module VARCHAR(50),
        Reads_Bad BIGINT,
        Reads_Good BIGINT,
        Speedup VARCHAR(20)
    );

    INSERT INTO @Summary VALUES 
    ('Module A: Slow Search', 2847, 5, '569x Faster'),
    ('Module B: Covering Index', 5000, 100, '50x Faster'),
    ('Module E: Columnstore', 45000, 800, '56x Faster');

    SELECT 
        Module,
        Reads_Bad as [Before (Reads)],
        Reads_Good as [After (Reads)],
        Speedup as [🏆 Result]
    FROM @Summary;

    -- 3. Skills Checklist
    PRINT '';
    PRINT '══ SKILLS DEMONSTRATED ══════════════════════════════════════════════════';
    PRINT ' [X] SARGability & Search Patterns (Module A)';
    PRINT ' [X] Key Lookup Elimination (Module B)';
    PRINT ' [X] Parameter Sniffing & RECOMPILE (Module C)';
    PRINT ' [X] Consistent Lock Ordering & Deadlocks (Module D)';
    PRINT ' [X] Columnstore & Batch Mode Processing (Module E)';
    PRINT ' [X] Index Usage Analysis & DMOs';
    PRINT '══════════════════════════════════════════════════════════════════════════';
END
GO

PRINT '  Created: dbo.usp_ViewDashboard';
GO

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------
PRINT '';
PRINT '================================================================================';
PRINT 'Stored procedure creation complete!';
PRINT '================================================================================';
PRINT '';

SELECT 
    name AS ProcedureName,
    create_date AS CreatedDate,
    CASE 
        WHEN name LIKE '%Bad%' THEN 'Demo - Shows bad pattern'
        WHEN name LIKE '%Good%' OR name LIKE '%Fixed%' THEN 'Demo - Shows optimized pattern'
        WHEN name LIKE '%Recompile%' OR name LIKE '%OptimizeFor%' THEN 'Demo - Parameter sniffing fix'
        WHEN name LIKE '%DeadlockProne%' THEN 'Demo - Creates deadlock'
        ELSE 'Utility'
    END AS Purpose
FROM sys.procedures
WHERE is_ms_shipped = 0
ORDER BY name;

PRINT '';
PRINT 'Setup complete! You can now work through the modules in /modules folder.';
PRINT '';
PRINT 'Quick test:';
PRINT '  EXEC dbo.usp_IndexUsageStats;';
PRINT '  EXEC dbo.usp_MissingIndexes;';
GO
