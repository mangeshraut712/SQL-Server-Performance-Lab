/*
================================================================================
Module D: Deadlock Demo - FIXES
================================================================================
Purpose: Strategies to prevent deadlocks
================================================================================
*/

USE PerformanceLab;
GO

--------------------------------------------------------------------------------
-- FIX #1: Consistent Lock Ordering
--------------------------------------------------------------------------------
/*
THE GOLDEN RULE: Always access resources in the same order.

If Session A locks (1, then 2) and Session B locks (1, then 2),
they can NEVER deadlock on these resources!
*/

PRINT '=== FIX #1: Consistent Lock Ordering ===';
GO

-- The FIXED procedure from our setup script demonstrates this:
-- It always updates the LOWER ProductID first, regardless of parameters

-- View the fixed procedure:
EXEC sp_helptext 'dbo.usp_UpdateInventory_Fixed';
GO

-- Test: This will NOT deadlock even with concurrent executions
-- because both sessions lock in ProductID order

-- Session A would run:
-- EXEC dbo.usp_UpdateInventory_Fixed @ProductID1 = 1, @ProductID2 = 2, @Quantity = 5;

-- Session B would run:
-- EXEC dbo.usp_UpdateInventory_Fixed @ProductID1 = 2, @ProductID2 = 1, @Quantity = 3;

-- Both end up locking Product 1 first, then Product 2 - No deadlock!


--------------------------------------------------------------------------------
-- FIX #2: Keep Transactions Short
--------------------------------------------------------------------------------
/*
Longer transactions = higher chance of deadlock.
Do all the preparation BEFORE starting the transaction.
*/

PRINT '=== FIX #2: Short Transactions ===';
GO

-- BAD: Long transaction with unnecessary work inside
/*
BEGIN TRANSACTION;
SELECT @data = ExpensiveCalculation();  -- Don't do this inside!
UPDATE Table1 SET col = @data;
UPDATE Table2 SET col = @data;
COMMIT;
*/

-- GOOD: Prepare first, then quick transaction
/*
SET @data = ExpensiveCalculation();  -- Do preparation outside

BEGIN TRANSACTION;
UPDATE Table1 SET col = @data;
UPDATE Table2 SET col = @data;
COMMIT;
*/


--------------------------------------------------------------------------------
-- FIX #3: Use Read Committed Snapshot (RCSI)
--------------------------------------------------------------------------------
/*
RCSI eliminates reader-writer blocking by using row versioning.
Readers don't block writers, writers don't block readers.
*/

PRINT '=== FIX #3: Read Committed Snapshot Isolation ===';
GO

-- Enable RCSI for the database (one-time setup)
-- ALTER DATABASE PerformanceLab SET READ_COMMITTED_SNAPSHOT ON;

-- Check current setting
SELECT 
    name,
    is_read_committed_snapshot_on,
    snapshot_isolation_state_desc
FROM sys.databases 
WHERE name = 'PerformanceLab';
GO


--------------------------------------------------------------------------------
-- FIX #4: Add Retry Logic in Application
--------------------------------------------------------------------------------
/*
Deadlocks can't always be prevented. Build retry logic into your application.
*/

PRINT '=== FIX #4: Retry Logic Example ===';
GO

CREATE OR ALTER PROCEDURE dbo.usp_UpdateWithRetry
    @ProductID1 INT,
    @ProductID2 INT,
    @Quantity INT,
    @MaxRetries INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RetryCount INT = 0;
    DECLARE @Success BIT = 0;
    
    WHILE @RetryCount < @MaxRetries AND @Success = 0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
            
            -- Use consistent ordering
            IF @ProductID1 < @ProductID2
            BEGIN
                UPDATE dbo.Inventory SET QuantityOnHand = QuantityOnHand - @Quantity WHERE ProductID = @ProductID1;
                UPDATE dbo.Inventory SET QuantityOnHand = QuantityOnHand + @Quantity WHERE ProductID = @ProductID2;
            END
            ELSE
            BEGIN
                UPDATE dbo.Inventory SET QuantityOnHand = QuantityOnHand + @Quantity WHERE ProductID = @ProductID2;
                UPDATE dbo.Inventory SET QuantityOnHand = QuantityOnHand - @Quantity WHERE ProductID = @ProductID1;
            END
            
            COMMIT TRANSACTION;
            SET @Success = 1;
            PRINT 'Transaction completed successfully.';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            
            IF ERROR_NUMBER() = 1205  -- Deadlock
            BEGIN
                SET @RetryCount = @RetryCount + 1;
                PRINT 'Deadlock detected. Retry ' + CAST(@RetryCount AS VARCHAR) + ' of ' + CAST(@MaxRetries AS VARCHAR);
                WAITFOR DELAY '00:00:01';  -- Brief pause before retry
            END
            ELSE
            BEGIN
                THROW;  -- Re-throw non-deadlock errors
            END
        END CATCH
    END
    
    IF @Success = 0
        RAISERROR('Transaction failed after max retries', 16, 1);
END
GO


--------------------------------------------------------------------------------
-- View Captured Deadlock Graph
--------------------------------------------------------------------------------

PRINT '=== View Deadlock Information ===';
GO

-- From error log (if trace flag 1222 is on)
EXEC xp_readerrorlog 0, 1, N'deadlock';
GO

-- From Extended Events
SELECT TOP 5
    DATEADD(HOUR, DATEDIFF(HOUR, GETUTCDATE(), GETDATE()), e.timestamp) AS LocalTime,
    e.event_data
FROM sys.fn_xe_file_target_read_file('DeadlockCapture*.xel', NULL, NULL, NULL) e
WHERE e.object_name = 'xml_deadlock_report'
ORDER BY e.timestamp DESC;
GO


--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------
/*
-- Stop and drop the extended event session:
ALTER EVENT SESSION DeadlockCapture ON SERVER STATE = STOP;
DROP EVENT SESSION DeadlockCapture ON SERVER;

-- Disable trace flag:
DBCC TRACEOFF (1222, -1);
*/


--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

PRINT '';
PRINT '=== DEADLOCK PREVENTION SUMMARY ===';
PRINT '';
PRINT '1. CONSISTENT LOCK ORDERING - Always access objects in same order';
PRINT '2. SHORT TRANSACTIONS - Minimize lock hold time';
PRINT '3. SNAPSHOT ISOLATION - Eliminate reader-writer blocking';
PRINT '4. RETRY LOGIC - Handle deadlocks gracefully in application';
PRINT '5. QUERY OPTIMIZATION - Faster queries = shorter locks';
PRINT '';
GO
