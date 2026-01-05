/*
================================================================================
Module F: Temporal Tables (System-Versioned) - SETUP
================================================================================
Demonstrates automatic historical tracking using SQL Server 2022+ feature
================================================================================
*/

USE PerformanceLab;
GO

-- 1. Create a System-Versioned Temporal Table
PRINT 'Creating temporal table for customer credit limits...';

CREATE TABLE dbo.CustomerCreditHistory
(
    CustomerID INT NOT NULL,
    CreditLimit DECIMAL(10,2) NOT NULL,
    LastModifiedBy NVARCHAR(100) NOT NULL,
    
    -- Required temporal columns
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),
    
    CONSTRAINT PK_CustomerCreditHistory PRIMARY KEY (CustomerID)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.CustomerCreditHistory_History));
GO

PRINT 'Temporal table created successfully!';
PRINT '';
PRINT 'What was created:';
PRINT '  1. dbo.CustomerCreditHistory (current data)';
PRINT '  2. dbo.CustomerCreditHistory_History (historical data)';
PRINT '';
PRINT 'Next step: Run 02-demo.sql to see it in action!';
GO
