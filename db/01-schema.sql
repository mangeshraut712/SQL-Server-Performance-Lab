/*
================================================================================
SQL Server Performance Lab - Schema Creation
================================================================================
Purpose: Creates the PerformanceLab database with tables designed to 
         demonstrate various performance issues and optimization techniques.

Execution: Run this script first, before any other scripts.
           
Tables Created:
  - Customers (50K rows)
  - Products (1K rows)
  - Orders (200K rows)
  - OrderDetails (500K rows)
  - AuditLog (for deadlock demos)
  - Inventory (for deadlock demos)
================================================================================
*/

-- Create database
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'PerformanceLab')
BEGIN
    ALTER DATABASE PerformanceLab SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PerformanceLab;
END
GO

CREATE DATABASE PerformanceLab;
GO

USE PerformanceLab;
GO

-- Enable Query Store for tracking query performance
ALTER DATABASE PerformanceLab SET QUERY_STORE = ON;
ALTER DATABASE PerformanceLab SET QUERY_STORE (
    OPERATION_MODE = READ_WRITE,
    MAX_STORAGE_SIZE_MB = 500,
    INTERVAL_LENGTH_MINUTES = 1
);
GO

PRINT 'Creating schema...';
GO

--------------------------------------------------------------------------------
-- Customers Table
-- Used for: Slow search patterns (LIKE, UPPER/LOWER)
--------------------------------------------------------------------------------
CREATE TABLE dbo.Customers (
    CustomerID      INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    FirstName       NVARCHAR(50) NOT NULL,
    LastName        NVARCHAR(50) NOT NULL,
    Email           NVARCHAR(100) NOT NULL,
    Phone           VARCHAR(20) NULL,
    Address         NVARCHAR(200) NULL,
    City            NVARCHAR(50) NULL,
    State           CHAR(2) NULL,
    ZipCode         VARCHAR(10) NULL,
    Country         NVARCHAR(50) DEFAULT 'USA',
    CustomerType    CHAR(1) NOT NULL DEFAULT 'R',  -- R=Regular, P=Premium, V=VIP
    CreditLimit     DECIMAL(12,2) DEFAULT 1000.00,
    IsActive        BIT DEFAULT 1,
    Notes           NVARCHAR(MAX) NULL,
    CreatedDate     DATETIME2 DEFAULT SYSDATETIME(),
    ModifiedDate    DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- Add check constraint for CustomerType
ALTER TABLE dbo.Customers 
ADD CONSTRAINT CK_Customers_CustomerType 
CHECK (CustomerType IN ('R', 'P', 'V'));
GO

--------------------------------------------------------------------------------
-- Products Table
-- Used for: Join optimization, covering indexes
--------------------------------------------------------------------------------
CREATE TABLE dbo.Products (
    ProductID       INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    ProductName     NVARCHAR(100) NOT NULL,
    SKU             VARCHAR(20) NOT NULL UNIQUE,
    Category        NVARCHAR(50) NOT NULL,
    SubCategory     NVARCHAR(50) NULL,
    UnitPrice       DECIMAL(10,2) NOT NULL,
    Cost            DECIMAL(10,2) NOT NULL,
    UnitsInStock    INT DEFAULT 0,
    ReorderLevel    INT DEFAULT 10,
    Discontinued    BIT DEFAULT 0,
    Weight          DECIMAL(8,2) NULL,
    Description     NVARCHAR(500) NULL,
    CreatedDate     DATETIME2 DEFAULT SYSDATETIME()
);
GO

--------------------------------------------------------------------------------
-- Orders Table
-- Used for: Parameter sniffing, date range queries, joins
--------------------------------------------------------------------------------
CREATE TABLE dbo.Orders (
    OrderID         INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    CustomerID      INT NOT NULL,
    OrderDate       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ShipDate        DATETIME2 NULL,
    Status          VARCHAR(20) NOT NULL DEFAULT 'Pending',
    ShipMethod      VARCHAR(50) NULL,
    SubTotal        DECIMAL(12,2) DEFAULT 0,
    Tax             DECIMAL(12,2) DEFAULT 0,
    Freight         DECIMAL(12,2) DEFAULT 0,
    TotalAmount     DECIMAL(12,2) DEFAULT 0,
    Notes           NVARCHAR(500) NULL,
    
    CONSTRAINT FK_Orders_Customers 
        FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID)
);
GO

-- Add check constraint for Status
ALTER TABLE dbo.Orders 
ADD CONSTRAINT CK_Orders_Status 
CHECK (Status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'));
GO

--------------------------------------------------------------------------------
-- OrderDetails Table
-- Used for: Join optimization, aggregation queries, covering indexes
--------------------------------------------------------------------------------
CREATE TABLE dbo.OrderDetails (
    OrderDetailID   INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    OrderID         INT NOT NULL,
    ProductID       INT NOT NULL,
    Quantity        INT NOT NULL DEFAULT 1,
    UnitPrice       DECIMAL(10,2) NOT NULL,
    Discount        DECIMAL(4,2) DEFAULT 0,
    LineTotal       AS (Quantity * UnitPrice * (1 - Discount)) PERSISTED,
    
    CONSTRAINT FK_OrderDetails_Orders 
        FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID),
    CONSTRAINT FK_OrderDetails_Products 
        FOREIGN KEY (ProductID) REFERENCES dbo.Products(ProductID),
    CONSTRAINT CK_OrderDetails_Quantity 
        CHECK (Quantity > 0),
    CONSTRAINT CK_OrderDetails_Discount 
        CHECK (Discount >= 0 AND Discount <= 1)
);
GO

--------------------------------------------------------------------------------
-- Inventory Table
-- Used for: Deadlock demonstrations
--------------------------------------------------------------------------------
CREATE TABLE dbo.Inventory (
    InventoryID     INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    ProductID       INT NOT NULL UNIQUE,
    WarehouseCode   CHAR(3) NOT NULL,
    QuantityOnHand  INT NOT NULL DEFAULT 0,
    QuantityReserved INT NOT NULL DEFAULT 0,
    LastUpdated     DATETIME2 DEFAULT SYSDATETIME(),
    
    CONSTRAINT FK_Inventory_Products 
        FOREIGN KEY (ProductID) REFERENCES dbo.Products(ProductID)
);
GO

--------------------------------------------------------------------------------
-- AuditLog Table
-- Used for: Deadlock demonstrations, high-insert scenarios
--------------------------------------------------------------------------------
CREATE TABLE dbo.AuditLog (
    AuditID         BIGINT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    TableName       NVARCHAR(128) NOT NULL,
    RecordID        INT NOT NULL,
    Action          VARCHAR(10) NOT NULL,
    OldValue        NVARCHAR(MAX) NULL,
    NewValue        NVARCHAR(MAX) NULL,
    ChangedBy       NVARCHAR(128) DEFAULT SYSTEM_USER,
    ChangedDate     DATETIME2 DEFAULT SYSDATETIME()
);
GO

--------------------------------------------------------------------------------
-- Statistics Table
-- Used for: Tracking query performance in demos
--------------------------------------------------------------------------------
CREATE TABLE dbo.QueryBenchmarks (
    BenchmarkID     INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    TestName        NVARCHAR(100) NOT NULL,
    QueryType       VARCHAR(20) NOT NULL, -- 'BAD' or 'OPTIMIZED'
    LogicalReads    BIGINT NULL,
    PhysicalReads   BIGINT NULL,
    CPUTimeMs       INT NULL,
    ElapsedTimeMs   INT NULL,
    RowsReturned    INT NULL,
    TestDate        DATETIME2 DEFAULT SYSDATETIME(),
    Notes           NVARCHAR(500) NULL
);
GO

PRINT 'Schema creation complete!';
PRINT '';
PRINT 'Tables created:';
PRINT '  - dbo.Customers';
PRINT '  - dbo.Products';
PRINT '  - dbo.Orders';
PRINT '  - dbo.OrderDetails';
PRINT '  - dbo.Inventory';
PRINT '  - dbo.AuditLog';
PRINT '  - dbo.QueryBenchmarks';
PRINT '';
PRINT 'Next step: Run 02-seed-data.sql to populate tables with test data.';
GO
