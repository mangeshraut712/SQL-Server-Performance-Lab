/*
================================================================================
Module F: Temporal Tables - TIME-TRAVEL ANALYSIS
================================================================================
Query historical data "as it was" at any point in time
================================================================================
*/

USE PerformanceLab;
GO

-- 1. Query current state
PRINT '--- CURRENT STATE ---';

SELECT 
    CustomerID,
    CreditLimit,
    LastModifiedBy
FROM dbo.CustomerCreditHistory;
GO

-- 2. Time-travel: See data as it was 30 seconds ago
PRINT '--- DATA AS IT WAS 30 SECONDS AGO ---';

DECLARE @TimePoint DATETIME2 = DATEADD(SECOND, -30, SYSDATETIME());

SELECT 
    CustomerID,
    CreditLimit,
    LastModifiedBy,
    @TimePoint AS [Queried Time Point]
FROM dbo.CustomerCreditHistory
FOR SYSTEM_TIME AS OF @TimePoint;
GO

-- 3. See all changes for a specific customer
PRINT '--- ALL CHANGES FOR CUSTOMER (Audit Trail) ---';

DECLARE @CustomerID INT = (SELECT TOP 1 CustomerID FROM dbo.CustomerCreditHistory ORDER BY CustomerID);

SELECT 
    CustomerID,
    CreditLimit,
    LastModifiedBy,
    ValidFrom AS [Changed At],
    ValidTo AS [Valid Until]
FROM dbo.CustomerCreditHistory
FOR SYSTEM_TIME ALL
WHERE CustomerID = @CustomerID
ORDER BY ValidFrom;
GO

-- 4. Find changes within a time range
PRINT '--- CHANGES IN THE LAST MINUTE ---';

DECLARE @StartTime DATETIME2 = DATEADD(MINUTE, -1, SYSDATETIME());
DECLARE @EndTime DATETIME2 = SYSDATETIME();

SELECT 
    CustomerID,
    CreditLimit,
    LastModifiedBy,
    ValidFrom,
    ValidTo
FROM dbo.CustomerCreditHistory
FOR SYSTEM_TIME BETWEEN @StartTime AND @EndTime
ORDER BY ValidFrom DESC;
GO

-- 5. Audit Report: Who changed what, when?
PRINT '--- COMPLETE AUDIT REPORT ---';

SELECT 
    h.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    h.CreditLimit AS [Historical Limit],
    h.LastModifiedBy AS [Modified By],
    h.ValidFrom AS [Changed At],
    DATEDIFF(SECOND, h.ValidFrom, h.ValidTo) AS [Duration (Seconds)]
FROM dbo.CustomerCreditHistory_History h
JOIN dbo.Customers c ON h.CustomerID = c.CustomerID
ORDER BY h.ValidFrom DESC;
GO

PRINT '';
PRINT '╔══════════════════════════════════════════════════════════════╗';
PRINT '║  MODULE F COMPLETE: Temporal Tables                         ║';
PRINT '╚══════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  ✅ Zero application code needed for change tracking';
PRINT '  ✅ Query data "as it was" at any point in time';
PRINT '  ✅ Complete audit trail for compliance';
PRINT '  ✅ Built-in performance optimization by SQL Server';
GO
