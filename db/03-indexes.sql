/*
================================================================================
SQL Server Performance Lab - Index Creation
================================================================================
Purpose: Creates indexes to support the performance demonstrations.
         Some indexes are intentionally "bad" or missing to show improvements.

Execution: Run after 02-seed-data.sql completes.

Note: We create SOME indexes here, but intentionally leave out others
      so that the modules can demonstrate adding them for optimization.
================================================================================
*/

USE PerformanceLab;
GO

SET NOCOUNT ON;
PRINT 'Creating indexes...';
PRINT '';

--------------------------------------------------------------------------------
-- Customers Table Indexes
--------------------------------------------------------------------------------
PRINT 'Creating Customer indexes...';

-- Basic index on LastName (but NOT a covering index - intentional)
CREATE NONCLUSTERED INDEX IX_Customers_LastName 
ON dbo.Customers (LastName);

-- Index on Email for lookups
CREATE NONCLUSTERED INDEX IX_Customers_Email 
ON dbo.Customers (Email);

-- Index on CustomerType (for parameter sniffing demo)
CREATE NONCLUSTERED INDEX IX_Customers_CustomerType 
ON dbo.Customers (CustomerType);

-- Index on State for geographic queries
CREATE NONCLUSTERED INDEX IX_Customers_State 
ON dbo.Customers (State);

PRINT '  Customer indexes created: 4';
GO

--------------------------------------------------------------------------------
-- Products Table Indexes
--------------------------------------------------------------------------------
PRINT 'Creating Product indexes...';

-- Index on Category
CREATE NONCLUSTERED INDEX IX_Products_Category 
ON dbo.Products (Category);

-- Index on SKU (unique already exists from table creation)

PRINT '  Product indexes created: 1';
GO

--------------------------------------------------------------------------------
-- Orders Table Indexes
--------------------------------------------------------------------------------
PRINT 'Creating Order indexes...';

-- Index on CustomerID for joins
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID 
ON dbo.Orders (CustomerID);

-- Index on OrderDate for date range queries
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate 
ON dbo.Orders (OrderDate);

-- Index on Status
CREATE NONCLUSTERED INDEX IX_Orders_Status 
ON dbo.Orders (Status);

-- Composite index for common query pattern (but intentionally non-covering)
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID_OrderDate 
ON dbo.Orders (CustomerID, OrderDate);

PRINT '  Order indexes created: 4';
GO

--------------------------------------------------------------------------------
-- OrderDetails Table Indexes
--------------------------------------------------------------------------------
PRINT 'Creating OrderDetails indexes...';

-- Index on OrderID for joins
CREATE NONCLUSTERED INDEX IX_OrderDetails_OrderID 
ON dbo.OrderDetails (OrderID);

-- Index on ProductID for joins
CREATE NONCLUSTERED INDEX IX_OrderDetails_ProductID 
ON dbo.OrderDetails (ProductID);

PRINT '  OrderDetails indexes created: 2';
GO

--------------------------------------------------------------------------------
-- Inventory Table Indexes
--------------------------------------------------------------------------------
PRINT 'Creating Inventory indexes...';

-- Index on ProductID already exists as UNIQUE constraint

-- Index on WarehouseCode
CREATE NONCLUSTERED INDEX IX_Inventory_WarehouseCode 
ON dbo.Inventory (WarehouseCode);

PRINT '  Inventory indexes created: 1';
GO

--------------------------------------------------------------------------------
-- AuditLog Table Indexes
--------------------------------------------------------------------------------
PRINT 'Creating AuditLog indexes...';

-- Index on TableName and RecordID for lookups
CREATE NONCLUSTERED INDEX IX_AuditLog_Table_Record 
ON dbo.AuditLog (TableName, RecordID);

-- Index on ChangedDate for time-based queries
CREATE NONCLUSTERED INDEX IX_AuditLog_ChangedDate 
ON dbo.AuditLog (ChangedDate);

PRINT '  AuditLog indexes created: 2';
GO

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------
PRINT '';
PRINT '================================================================================';
PRINT 'Index creation complete!';
PRINT '================================================================================';
PRINT '';

-- Show all indexes
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    STUFF((
        SELECT ', ' + c.name + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS KeyColumns,
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
        ORDER BY ic.index_column_id
        FOR XML PATH('')
    ), 1, 2, '') AS IncludedColumns
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND i.type > 0
ORDER BY t.name, i.name;

PRINT '';
PRINT 'Note: Additional indexes will be created in the module demos';
PRINT 'to show the impact of proper indexing.';
PRINT '';
PRINT 'Next step: Run 04-stored-procedures.sql to create helper procedures.';
GO
