/*
================================================================================
Module D: Deadlock Demo - SESSION A
================================================================================
⚠️ RUN THIS IN A SEPARATE QUERY WINDOW!
⚠️ Run 02-session-a.sql first, then IMMEDIATELY run 03-session-b.sql

This session:
1. Begins a transaction
2. Updates ProductID 1 (acquires lock)
3. Waits 5 seconds (to allow Session B to get its lock)
4. Tries to update ProductID 2 (will wait for Session B's lock)
================================================================================
*/

USE PerformanceLab;
GO

PRINT '=== SESSION A: Starting at ' + CONVERT(VARCHAR, GETDATE(), 120) + ' ===';
PRINT 'Step 1: Beginning transaction...';
GO

BEGIN TRANSACTION;
GO

PRINT 'Step 2: Updating Product 1 (acquiring lock)...';
GO

-- Lock Product 1
UPDATE dbo.Inventory
SET QuantityOnHand = QuantityOnHand - 1,
    LastUpdated = SYSDATETIME()
WHERE ProductID = 1;

PRINT 'Step 2 complete: Lock acquired on Product 1';
PRINT 'Step 3: Waiting 5 seconds (run Session B now!)...';
GO

-- Wait to let Session B acquire its lock
WAITFOR DELAY '00:00:05';
GO

PRINT 'Step 4: Attempting to update Product 2 (will wait for Session B)...';
GO

-- Try to lock Product 2 - THIS IS WHERE DEADLOCK MAY OCCUR
UPDATE dbo.Inventory
SET QuantityOnHand = QuantityOnHand + 1,
    LastUpdated = SYSDATETIME()
WHERE ProductID = 2;
GO

PRINT 'Step 5: Committing transaction...';
COMMIT TRANSACTION;
PRINT '=== SESSION A: Completed successfully! ===';
GO

/*
If you see this message, Session A won.
If you see "Transaction was deadlocked...", Session A was chosen as victim.
*/
