/*
================================================================================
Module D: Deadlock Demo - SESSION B
================================================================================
⚠️ RUN THIS IN A SEPARATE QUERY WINDOW!
⚠️ Run this IMMEDIATELY after starting 02-session-a.sql

This session:
1. Begins a transaction  
2. Updates ProductID 2 (acquires lock) - OPPOSITE order from Session A!
3. Waits 5 seconds
4. Tries to update ProductID 1 (will wait for Session A's lock)

The OPPOSITE locking order is what causes the deadlock!
================================================================================
*/

USE PerformanceLab;
GO

PRINT '=== SESSION B: Starting at ' + CONVERT(VARCHAR, GETDATE(), 120) + ' ===';
PRINT 'Step 1: Beginning transaction...';
GO

BEGIN TRANSACTION;
GO

PRINT 'Step 2: Updating Product 2 (acquiring lock)...';
GO

-- Lock Product 2 (opposite order from Session A!)
UPDATE dbo.Inventory
SET QuantityOnHand = QuantityOnHand - 1,
    LastUpdated = SYSDATETIME()
WHERE ProductID = 2;

PRINT 'Step 2 complete: Lock acquired on Product 2';
PRINT 'Step 3: Waiting 5 seconds...';
GO

-- Wait while Session A tries to get Product 2
WAITFOR DELAY '00:00:05';
GO

PRINT 'Step 4: Attempting to update Product 1 (will wait for Session A)...';
GO

-- Try to lock Product 1 - THIS IS WHERE DEADLOCK MAY OCCUR
UPDATE dbo.Inventory
SET QuantityOnHand = QuantityOnHand + 1,
    LastUpdated = SYSDATETIME()
WHERE ProductID = 1;
GO

PRINT 'Step 5: Committing transaction...';
COMMIT TRANSACTION;
PRINT '=== SESSION B: Completed successfully! ===';
GO

/*
If you see this message, Session B won.
If you see "Transaction was deadlocked...", Session B was chosen as victim.

Expected Error for Victim:
Msg 1205, Level 13, State 51
Transaction (Process ID XX) was deadlocked on lock resources with another 
process and has been chosen as the deadlock victim. Rerun the transaction.
*/
