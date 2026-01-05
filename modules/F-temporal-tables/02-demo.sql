/*
================================================================================
Module F: Temporal Tables - DEMO
================================================================================
Demonstrates automatic change tracking and time-travel queries
================================================================================
*/

USE PerformanceLab;
GO

-- 1. Seed initial data
PRINT '--- Seeding Initial Credit Limits ---';

INSERT INTO dbo.CustomerCreditHistory (CustomerID, CreditLimit, LastModifiedBy)
SELECT TOP 10
    CustomerID,
    CreditLimit,
    'System Import'
FROM dbo.Customers
WHERE CustomerType = 'V'; -- VIP customers

SELECT * FROM dbo.CustomerCreditHistory;
GO

-- Wait a moment
WAITFOR DELAY '00:00:02';

-- 2. Simulate a credit limit increase
PRINT '--- Increasing Credit Limits for Top Customers ---';

UPDATE dbo.CustomerCreditHistory
SET CreditLimit = CreditLimit * 1.5,
    LastModifiedBy = 'Manager: Jane Doe'
WHERE CustomerID IN (SELECT TOP 3 CustomerID FROM dbo.CustomerCreditHistory);

SELECT CustomerID, CreditLimit, LastModifiedBy FROM dbo.CustomerCreditHistory;
GO

-- Wait again
WAITFOR DELAY '00:00:02';

-- 3. Simulate a risk reduction
PRINT '--- Reducing Credit Limit Due to Risk Assessment ---';

UPDATE dbo.CustomerCreditHistory
SET CreditLimit = CreditLimit * 0.7,
    LastModifiedBy = 'Risk Team: Automated Review'
WHERE CustomerID = (SELECT TOP 1 CustomerID FROM dbo.CustomerCreditHistory ORDER BY CustomerID);

SELECT CustomerID, CreditLimit, LastModifiedBy FROM dbo.CustomerCreditHistory;
GO

-- 4. Check the history table (automatic!)
PRINT '--- Viewing Historical Changes (Automatically Tracked!) ---';

SELECT 
    CustomerID,
    CreditLimit,
    LastModifiedBy,
    ValidFrom,
    ValidTo
FROM dbo.CustomerCreditHistory_History  -- The automatic history table
ORDER BY CustomerID, ValidFrom;
GO

PRINT '';
PRINT '✅ Notice: Every change was automatically tracked!';
PRINT '';
PRINT 'Next: Run 03-analysis.sql to query "point-in-time" data!';
GO
