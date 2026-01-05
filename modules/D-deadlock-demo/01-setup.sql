/*
================================================================================
Module D: Deadlock Demo - SETUP
================================================================================
Purpose: Enable deadlock tracing and prepare test data
================================================================================
*/

USE PerformanceLab;
GO

--------------------------------------------------------------------------------
-- Enable Trace Flag for Deadlock Logging
--------------------------------------------------------------------------------
/*
Trace flag 1222 writes detailed deadlock graphs to the SQL Server error log.
This is the classic way to capture deadlock information.
*/

DBCC TRACEON (1222, -1);
GO

PRINT 'Trace flag 1222 enabled - deadlocks will be logged to error log.';
GO


--------------------------------------------------------------------------------
-- Verify Test Data
--------------------------------------------------------------------------------

-- Make sure we have inventory records to work with
SELECT TOP 10 
    i.InventoryID,
    i.ProductID,
    p.ProductName,
    i.QuantityOnHand,
    i.WarehouseCode
FROM dbo.Inventory i
JOIN dbo.Products p ON i.ProductID = p.ProductID
ORDER BY i.ProductID;
GO

/*
We'll use ProductID 1 and ProductID 2 for our deadlock demo.
Session A will update 1 then 2.
Session B will update 2 then 1.
This creates the classic deadlock pattern!
*/


--------------------------------------------------------------------------------
-- Create Extended Event Session (Modern Approach)
--------------------------------------------------------------------------------

-- Drop if exists
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'DeadlockCapture')
    DROP EVENT SESSION DeadlockCapture ON SERVER;
GO

-- Create extended event to capture deadlocks
CREATE EVENT SESSION DeadlockCapture ON SERVER
ADD EVENT sqlserver.xml_deadlock_report
ADD TARGET package0.event_file(SET filename=N'DeadlockCapture.xel')
WITH (MAX_MEMORY=4096 KB, STARTUP_STATE=ON);
GO

-- Start the session
ALTER EVENT SESSION DeadlockCapture ON SERVER STATE = START;
GO

PRINT 'Extended Event session DeadlockCapture started.';
GO


--------------------------------------------------------------------------------
-- Instructions for Deadlock Demo
--------------------------------------------------------------------------------

PRINT '';
PRINT '================================================================================';
PRINT '                    DEADLOCK DEMO INSTRUCTIONS';
PRINT '================================================================================';
PRINT '';
PRINT '1. Open TWO separate query windows in SSMS';
PRINT '';
PRINT '2. In Window 1: Open and run modules/D-deadlock-demo/02-session-a.sql';
PRINT '   - This will UPDATE ProductID 1, then WAIT, then try ProductID 2';
PRINT '';
PRINT '3. IMMEDIATELY in Window 2: Open and run 03-session-b.sql';
PRINT '   - This will UPDATE ProductID 2, then WAIT, then try ProductID 1';
PRINT '';
PRINT '4. After 2-3 seconds, ONE window will show:';
PRINT '   Msg 1205: Transaction was deadlocked and has been chosen as victim.';
PRINT '';
PRINT '5. The OTHER window will complete successfully.';
PRINT '';
PRINT '6. Run the deadlock analysis query below to see what happened.';
PRINT '';
PRINT '================================================================================';
GO


--------------------------------------------------------------------------------
-- Query to View Captured Deadlocks
--------------------------------------------------------------------------------
/*
Run this AFTER triggering the deadlock to see the captured graph:
*/

-- View deadlock events
SELECT 
    DATEADD(HOUR, DATEDIFF(HOUR, GETUTCDATE(), GETDATE()), e.timestamp) AS LocalTime,
    CAST(e.event_data AS XML).value('(event/data[@name="xml_report"]/value)[1]', 'nvarchar(max)') AS DeadlockGraph
FROM sys.fn_xe_file_target_read_file('DeadlockCapture*.xel', NULL, NULL, NULL) e
WHERE e.object_name = 'xml_deadlock_report'
ORDER BY e.timestamp DESC;
GO
