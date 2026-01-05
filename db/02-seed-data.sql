/*
================================================================================
SQL Server Performance Lab - Seed Data Generation
================================================================================
Purpose: Generates 500K+ rows of synthetic test data using pure T-SQL.
         No external files or downloads required.

Execution: Run after 01-schema.sql completes.
           Takes approximately 1-2 minutes to generate all data.

Data Distribution (important for testing):
  - Customers: 50,000 rows with varied name patterns
  - Products: 1,000 rows across 10 categories
  - Orders: 200,000 rows with date skew (more recent = more orders)
  - OrderDetails: 500,000+ rows (2-3 items per order average)
  - Inventory: 1,000 rows (one per product)
================================================================================
*/

USE PerformanceLab;
GO

SET NOCOUNT ON;
PRINT 'Starting data generation at ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '';

--------------------------------------------------------------------------------
-- Helper: Numbers table for set-based operations
--------------------------------------------------------------------------------
PRINT 'Creating helper numbers table...';
GO

IF OBJECT_ID('tempdb..#Numbers') IS NOT NULL DROP TABLE #Numbers;

;WITH L0 AS (SELECT 1 AS c UNION ALL SELECT 1),
      L1 AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
      L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
      L3 AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
      L4 AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
      L5 AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
      Nums AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM L5)
SELECT TOP 1000000 n INTO #Numbers FROM Nums;

CREATE UNIQUE CLUSTERED INDEX IX_Numbers ON #Numbers(n);
GO

--------------------------------------------------------------------------------
-- Seed Products (1,000 rows)
--------------------------------------------------------------------------------
PRINT 'Generating 1,000 products...';
GO

-- Category definitions for realistic product data
DECLARE @Categories TABLE (
    CategoryName NVARCHAR(50),
    SubCategories NVARCHAR(500)
);

INSERT INTO @Categories VALUES
('Electronics', 'Smartphones,Laptops,Tablets,Headphones,Cameras,Speakers,Monitors,Keyboards'),
('Clothing', 'Shirts,Pants,Dresses,Jackets,Shoes,Accessories,Socks,Hats'),
('Home & Garden', 'Furniture,Lighting,Bedding,Kitchen,Outdoor,Storage,Decor,Tools'),
('Sports', 'Fitness,Cycling,Running,Swimming,Basketball,Golf,Yoga,Camping'),
('Books', 'Fiction,Non-Fiction,Science,History,Biography,Children,Cooking,Self-Help'),
('Beauty', 'Skincare,Makeup,Haircare,Fragrance,Bath,Nails,Tools,Sets'),
('Toys', 'Action Figures,Board Games,Puzzles,Building,Dolls,Outdoor,Educational,Electronics'),
('Food', 'Snacks,Beverages,Organic,International,Baking,Condiments,Canned,Frozen'),
('Office', 'Supplies,Furniture,Technology,Organization,Writing,Paper,Shipping,Breakroom'),
('Automotive', 'Parts,Accessories,Tools,Care,Electronics,Safety,Performance,Interior');

-- Generate products
;WITH CategorySplit AS (
    SELECT 
        CategoryName,
        TRIM(value) AS SubCategory,
        ROW_NUMBER() OVER (PARTITION BY CategoryName ORDER BY (SELECT NULL)) AS SubCatNum
    FROM @Categories
    CROSS APPLY STRING_SPLIT(SubCategories, ',')
),
ProductBase AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY c.CategoryName, cs.SubCategory, n.n) AS RowNum,
        c.CategoryName,
        cs.SubCategory,
        n.n AS ProductNum
    FROM @Categories c
    CROSS JOIN CategorySplit cs
    CROSS JOIN (SELECT TOP 13 n FROM #Numbers) n
    WHERE c.CategoryName = cs.CategoryName
)
INSERT INTO dbo.Products (ProductName, SKU, Category, SubCategory, UnitPrice, Cost, UnitsInStock, ReorderLevel, Weight, Description)
SELECT TOP 1000
    -- Generate realistic product names
    cs.SubCategory + ' ' + 
    CASE (pb.RowNum % 5)
        WHEN 0 THEN 'Pro'
        WHEN 1 THEN 'Elite'
        WHEN 2 THEN 'Basic'
        WHEN 3 THEN 'Premium'
        WHEN 4 THEN 'Standard'
    END + ' ' +
    CASE (pb.RowNum % 7)
        WHEN 0 THEN 'X1'
        WHEN 1 THEN 'V2'
        WHEN 2 THEN 'Max'
        WHEN 3 THEN 'Plus'
        WHEN 4 THEN 'Mini'
        WHEN 5 THEN 'Ultra'
        WHEN 6 THEN 'Lite'
    END AS ProductName,
    -- SKU: Category prefix + number
    UPPER(LEFT(pb.CategoryName, 3)) + '-' + RIGHT('00000' + CAST(pb.RowNum AS VARCHAR), 5) AS SKU,
    pb.CategoryName,
    cs.SubCategory,
    -- Price between $5 and $2000, weighted toward lower prices
    CAST(5 + (POWER(RAND(CHECKSUM(NEWID())), 0.5) * 1995) AS DECIMAL(10,2)) AS UnitPrice,
    -- Cost is 40-70% of price
    CAST((5 + (POWER(RAND(CHECKSUM(NEWID())), 0.5) * 1995)) * (0.4 + RAND(CHECKSUM(NEWID())) * 0.3) AS DECIMAL(10,2)) AS Cost,
    -- Stock 0-500
    ABS(CHECKSUM(NEWID())) % 500 AS UnitsInStock,
    -- Reorder level 5-50
    5 + ABS(CHECKSUM(NEWID())) % 45 AS ReorderLevel,
    -- Weight 0.1-50 lbs
    CAST(0.1 + RAND(CHECKSUM(NEWID())) * 49.9 AS DECIMAL(8,2)) AS Weight,
    'High-quality ' + LOWER(cs.SubCategory) + ' product with excellent features and durability.' AS Description
FROM ProductBase pb
JOIN CategorySplit cs ON pb.CategoryName = cs.CategoryName AND pb.SubCatNum = cs.SubCatNum;

PRINT '  Products created: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

--------------------------------------------------------------------------------
-- Seed Customers (50,000 rows)
--------------------------------------------------------------------------------
PRINT 'Generating 50,000 customers...';
GO

-- First names (200 names for variety)
DECLARE @FirstNames TABLE (ID INT IDENTITY(1,1), FirstName NVARCHAR(50));
INSERT INTO @FirstNames (FirstName) VALUES
('James'),('Mary'),('John'),('Patricia'),('Robert'),('Jennifer'),('Michael'),('Linda'),('William'),('Elizabeth'),
('David'),('Barbara'),('Richard'),('Susan'),('Joseph'),('Jessica'),('Thomas'),('Sarah'),('Charles'),('Karen'),
('Christopher'),('Nancy'),('Daniel'),('Lisa'),('Matthew'),('Betty'),('Anthony'),('Margaret'),('Mark'),('Sandra'),
('Donald'),('Ashley'),('Steven'),('Kimberly'),('Paul'),('Emily'),('Andrew'),('Donna'),('Joshua'),('Michelle'),
('Kenneth'),('Dorothy'),('Kevin'),('Carol'),('Brian'),('Amanda'),('George'),('Melissa'),('Edward'),('Deborah'),
('Ronald'),('Stephanie'),('Timothy'),('Rebecca'),('Jason'),('Sharon'),('Jeffrey'),('Laura'),('Ryan'),('Cynthia'),
('Jacob'),('Kathleen'),('Gary'),('Amy'),('Nicholas'),('Angela'),('Eric'),('Shirley'),('Jonathan'),('Anna'),
('Stephen'),('Brenda'),('Larry'),('Pamela'),('Justin'),('Emma'),('Scott'),('Nicole'),('Brandon'),('Helen'),
('Benjamin'),('Samantha'),('Samuel'),('Katherine'),('Raymond'),('Christine'),('Gregory'),('Debra'),('Frank'),('Rachel'),
('Alexander'),('Carolyn'),('Patrick'),('Janet'),('Jack'),('Catherine'),('Dennis'),('Maria'),('Jerry'),('Heather'),
('Tyler'),('Diane'),('Aaron'),('Ruth'),('Jose'),('Julie'),('Adam'),('Olivia'),('Nathan'),('Joyce'),
('Henry'),('Virginia'),('Douglas'),('Victoria'),('Zachary'),('Kelly'),('Peter'),('Lauren'),('Kyle'),('Christina'),
('Ethan'),('Joan'),('Jeremy'),('Evelyn'),('Walter'),('Judith'),('Christian'),('Megan'),('Keith'),('Andrea'),
('Roger'),('Cheryl'),('Terry'),('Hannah'),('Austin'),('Jacqueline'),('Sean'),('Martha'),('Gerald'),('Gloria'),
('Carl'),('Teresa'),('Harold'),('Ann'),('Dylan'),('Sara'),('Arthur'),('Madison'),('Lawrence'),('Frances'),
('Jordan'),('Kathryn'),('Jesse'),('Janice'),('Bryan'),('Jean'),('Billy'),('Abigail'),('Bruce'),('Alice'),
('Gabriel'),('Judy'),('Joe'),('Sophia'),('Logan'),('Grace'),('Albert'),('Denise'),('Willie'),('Amber'),
('Alan'),('Doris'),('Juan'),('Marilyn'),('Wayne'),('Danielle'),('Elijah'),('Beverly'),('Randy'),('Isabella'),
('Roy'),('Theresa'),('Vincent'),('Diana'),('Ralph'),('Natalie'),('Eugene'),('Brittany'),('Russell'),('Charlotte'),
('Bobby'),('Marie'),('Mason'),('Kayla'),('Philip'),('Alexis'),('Louis'),('Lori'),('Harry'),('Julia');

-- Last names (200 names for variety)
DECLARE @LastNames TABLE (ID INT IDENTITY(1,1), LastName NVARCHAR(50));
INSERT INTO @LastNames (LastName) VALUES
('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),('Miller'),('Davis'),('Rodriguez'),('Martinez'),
('Hernandez'),('Lopez'),('Gonzalez'),('Wilson'),('Anderson'),('Thomas'),('Taylor'),('Moore'),('Jackson'),('Martin'),
('Lee'),('Perez'),('Thompson'),('White'),('Harris'),('Sanchez'),('Clark'),('Ramirez'),('Lewis'),('Robinson'),
('Walker'),('Young'),('Allen'),('King'),('Wright'),('Scott'),('Torres'),('Nguyen'),('Hill'),('Flores'),
('Green'),('Adams'),('Nelson'),('Baker'),('Hall'),('Rivera'),('Campbell'),('Mitchell'),('Carter'),('Roberts'),
('Gomez'),('Phillips'),('Evans'),('Turner'),('Diaz'),('Parker'),('Cruz'),('Edwards'),('Collins'),('Reyes'),
('Stewart'),('Morris'),('Morales'),('Murphy'),('Cook'),('Rogers'),('Gutierrez'),('Ortiz'),('Morgan'),('Cooper'),
('Peterson'),('Bailey'),('Reed'),('Kelly'),('Howard'),('Ramos'),('Kim'),('Cox'),('Ward'),('Richardson'),
('Watson'),('Brooks'),('Chavez'),('Wood'),('James'),('Bennett'),('Gray'),('Mendoza'),('Ruiz'),('Hughes'),
('Price'),('Alvarez'),('Castillo'),('Sanders'),('Patel'),('Myers'),('Long'),('Ross'),('Foster'),('Jimenez'),
('Powell'),('Jenkins'),('Perry'),('Russell'),('Sullivan'),('Bell'),('Coleman'),('Butler'),('Henderson'),('Barnes'),
('Gonzales'),('Fisher'),('Vasquez'),('Simmons'),('Stokes'),('Dixon'),('Hunt'),('Burns'),('Warren'),('Williamson'),
('Ferguson'),('Chapman'),('Spencer'),('Hawkins'),('Boyd'),('Stanley'),('Gardner'),('Stephens'),('Washington'),('Grant'),
('Dunn'),('Lawrence'),('Wells'),('Webb'),('Reynolds'),('Medina'),('Wallace'),('Vargas'),('Douglas'),('Arnold'),
('Patterson'),('Moreno'),('Ford'),('Palmer'),('Wagner'),('Lynch'),('Bishop'),('Hudson'),('Soto'),('Knight'),
('Hicks'),('Henry'),('Carr'),('Cruz'),('Black'),('Hunter'),('Gordon'),('Fox'),('Rose'),('Davidson'),
('Duncan'),('Austin'),('Burke'),('Harrison'),('Shaw'),('George'),('Obrien'),('Stone'),('Johnston'),('Lane'),
('Freeman'),('Ryan'),('Holmes'),('Meyer'),('Rice'),('Tucker'),('Owens'),('Carroll'),('Andrews'),('Hart'),
('Kennedy'),('Woods'),('Perkins'),('Hamilton'),('Graham'),('Marshall'),('Dean'),('Mcdonald'),('Snyder'),('Fletcher'),
('Gibson'),('Payne'),('Daniels'),('Harper'),('Stephenson'),('Matthews'),('Murray'),('Griffin'),('Mccoy'),('Hayes');

-- State codes
DECLARE @States TABLE (ID INT IDENTITY(1,1), StateCode CHAR(2));
INSERT INTO @States (StateCode) VALUES
('AL'),('AK'),('AZ'),('AR'),('CA'),('CO'),('CT'),('DE'),('FL'),('GA'),
('HI'),('ID'),('IL'),('IN'),('IA'),('KS'),('KY'),('LA'),('ME'),('MD'),
('MA'),('MI'),('MN'),('MS'),('MO'),('MT'),('NE'),('NV'),('NH'),('NJ'),
('NM'),('NY'),('NC'),('ND'),('OH'),('OK'),('OR'),('PA'),('RI'),('SC'),
('SD'),('TN'),('TX'),('UT'),('VT'),('VA'),('WA'),('WV'),('WI'),('WY');

-- City names
DECLARE @Cities TABLE (ID INT IDENTITY(1,1), CityName NVARCHAR(50));
INSERT INTO @Cities (CityName) VALUES
('Springfield'),('Franklin'),('Clinton'),('Madison'),('Georgetown'),('Salem'),('Bristol'),('Fairview'),
('Manchester'),('Oxford'),('Arlington'),('Jackson'),('Burlington'),('Milton'),('Greenville'),('Newport'),
('Lexington'),('Ashland'),('Chester'),('Dover'),('Oakland'),('Winchester'),('Clayton'),('Lebanon'),
('Hudson'),('Plymouth'),('Aurora'),('Riverside'),('Kingston'),('Harrison'),('Monroe'),('Centerville');

-- Generate customers
INSERT INTO dbo.Customers (FirstName, LastName, Email, Phone, Address, City, State, ZipCode, CustomerType, CreditLimit, IsActive, Notes, CreatedDate)
SELECT TOP 50000
    fn.FirstName,
    ln.LastName,
    -- Email with some duplicates (realistic)
    LOWER(fn.FirstName) + '.' + LOWER(ln.LastName) + 
    CASE WHEN n.n % 5 = 0 THEN '' ELSE CAST(n.n % 1000 AS VARCHAR) END +
    CASE (n.n % 4)
        WHEN 0 THEN '@gmail.com'
        WHEN 1 THEN '@yahoo.com'
        WHEN 2 THEN '@outlook.com'
        ELSE '@company.com'
    END AS Email,
    -- Phone
    '(' + RIGHT('000' + CAST(200 + (n.n % 800) AS VARCHAR), 3) + ') ' +
    RIGHT('000' + CAST(n.n % 1000 AS VARCHAR), 3) + '-' +
    RIGHT('0000' + CAST(n.n % 10000 AS VARCHAR), 4) AS Phone,
    -- Address
    CAST(100 + (n.n % 9900) AS VARCHAR) + ' ' +
    CASE ((n.n / 7) % 10)
        WHEN 0 THEN 'Main'
        WHEN 1 THEN 'Oak'
        WHEN 2 THEN 'Maple'
        WHEN 3 THEN 'Cedar'
        WHEN 4 THEN 'Pine'
        WHEN 5 THEN 'Elm'
        WHEN 6 THEN 'Washington'
        WHEN 7 THEN 'Lake'
        WHEN 8 THEN 'Park'
        ELSE 'Hill'
    END + ' ' +
    CASE ((n.n / 3) % 5)
        WHEN 0 THEN 'Street'
        WHEN 1 THEN 'Avenue'
        WHEN 2 THEN 'Road'
        WHEN 3 THEN 'Drive'
        ELSE 'Boulevard'
    END AS Address,
    c.CityName AS City,
    s.StateCode AS State,
    RIGHT('00000' + CAST(10000 + (n.n % 89999) AS VARCHAR), 5) AS ZipCode,
    -- Customer type: 70% Regular, 25% Premium, 5% VIP
    CASE 
        WHEN n.n % 100 < 70 THEN 'R'
        WHEN n.n % 100 < 95 THEN 'P'
        ELSE 'V'
    END AS CustomerType,
    -- Credit limit based on type
    CASE 
        WHEN n.n % 100 < 70 THEN 1000 + (n.n % 4000)
        WHEN n.n % 100 < 95 THEN 5000 + (n.n % 15000)
        ELSE 20000 + (n.n % 80000)
    END AS CreditLimit,
    -- 95% active
    CASE WHEN n.n % 100 < 95 THEN 1 ELSE 0 END AS IsActive,
    CASE WHEN n.n % 20 = 0 THEN 'Important customer - handle with care' ELSE NULL END AS Notes,
    -- Created dates spread over last 5 years
    DATEADD(DAY, -1 * (n.n % 1825), SYSDATETIME()) AS CreatedDate
FROM #Numbers n
CROSS JOIN @FirstNames fn
CROSS JOIN @LastNames ln
CROSS JOIN @States s
CROSS JOIN @Cities c
WHERE n.n <= 50000
  AND fn.ID = 1 + (n.n % 200)
  AND ln.ID = 1 + ((n.n / 200) % 200)
  AND s.ID = 1 + (n.n % 50)
  AND c.ID = 1 + ((n.n / 50) % 32);

PRINT '  Customers created: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

--------------------------------------------------------------------------------
-- Seed Orders (200,000 rows)
-- IMPORTANT: Data skew - VIP customers have WAY more orders than regular
--------------------------------------------------------------------------------
PRINT 'Generating 200,000 orders (with data skew for parameter sniffing demo)...';
GO

-- Create temporary staging for order generation
IF OBJECT_ID('tempdb..#OrderStaging') IS NOT NULL DROP TABLE #OrderStaging;

-- Generate orders with intentional skew:
-- VIP customers (5%) get 40% of orders
-- Premium customers (25%) get 35% of orders  
-- Regular customers (70%) get 25% of orders
;WITH VIPCustomers AS (
    SELECT CustomerID FROM dbo.Customers WHERE CustomerType = 'V'
),
PremiumCustomers AS (
    SELECT CustomerID FROM dbo.Customers WHERE CustomerType = 'P'
),
RegularCustomers AS (
    SELECT CustomerID FROM dbo.Customers WHERE CustomerType = 'R'
),
VIPOrders AS (
    SELECT TOP 80000 -- 40% of 200K
        v.CustomerID,
        DATEADD(DAY, -1 * ABS(CHECKSUM(NEWID())) % 730, SYSDATETIME()) AS OrderDate,
        n.n AS OrderNum
    FROM VIPCustomers v
    CROSS JOIN #Numbers n
    WHERE n.n <= 80000 / (SELECT COUNT(*) FROM VIPCustomers) + 1
),
PremiumOrders AS (
    SELECT TOP 70000 -- 35% of 200K
        p.CustomerID,
        DATEADD(DAY, -1 * ABS(CHECKSUM(NEWID())) % 730, SYSDATETIME()) AS OrderDate,
        n.n AS OrderNum
    FROM PremiumCustomers p
    CROSS JOIN #Numbers n
    WHERE n.n <= 70000 / (SELECT COUNT(*) FROM PremiumCustomers) + 1
),
RegularOrders AS (
    SELECT TOP 50000 -- 25% of 200K
        r.CustomerID,
        DATEADD(DAY, -1 * ABS(CHECKSUM(NEWID())) % 730, SYSDATETIME()) AS OrderDate,
        n.n AS OrderNum
    FROM RegularCustomers r
    CROSS JOIN #Numbers n
    WHERE n.n <= 50000 / (SELECT COUNT(*) FROM RegularCustomers) + 1
)
SELECT CustomerID, OrderDate INTO #OrderStaging
FROM (
    SELECT TOP 80000 CustomerID, OrderDate FROM VIPOrders
    UNION ALL
    SELECT TOP 70000 CustomerID, OrderDate FROM PremiumOrders
    UNION ALL
    SELECT TOP 50000 CustomerID, OrderDate FROM RegularOrders
) Combined;

-- Insert orders
INSERT INTO dbo.Orders (CustomerID, OrderDate, ShipDate, Status, ShipMethod, SubTotal, Tax, Freight, TotalAmount, Notes)
SELECT TOP 200000
    os.CustomerID,
    os.OrderDate,
    -- Ship date: 1-7 days after order date (NULL for pending/cancelled)
    CASE 
        WHEN n.n % 10 < 7 THEN DATEADD(DAY, 1 + (n.n % 7), os.OrderDate)
        ELSE NULL
    END AS ShipDate,
    -- Status distribution
    CASE 
        WHEN n.n % 100 < 5 THEN 'Pending'
        WHEN n.n % 100 < 10 THEN 'Processing'
        WHEN n.n % 100 < 15 THEN 'Cancelled'
        WHEN n.n % 100 < 70 THEN 'Delivered'
        ELSE 'Shipped'
    END AS Status,
    -- Ship method
    CASE (n.n % 4)
        WHEN 0 THEN 'Standard Ground'
        WHEN 1 THEN 'Express'
        WHEN 2 THEN 'Next Day Air'
        ELSE 'Economy'
    END AS ShipMethod,
    -- Amounts (will be updated after OrderDetails)
    0 AS SubTotal,
    0 AS Tax,
    0 AS Freight,
    0 AS TotalAmount,
    CASE WHEN n.n % 50 = 0 THEN 'Rush order - priority handling' ELSE NULL END AS Notes
FROM #OrderStaging os
JOIN #Numbers n ON n.n <= 200000
WHERE n.n <= 200000;

DROP TABLE #OrderStaging;

PRINT '  Orders created: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- Show distribution for parameter sniffing demo
SELECT 
    c.CustomerType,
    COUNT(DISTINCT c.CustomerID) AS CustomerCount,
    COUNT(o.OrderID) AS OrderCount,
    COUNT(o.OrderID) * 100.0 / (SELECT COUNT(*) FROM dbo.Orders) AS PctOfOrders
FROM dbo.Customers c
LEFT JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerType
ORDER BY c.CustomerType;
GO

--------------------------------------------------------------------------------
-- Seed OrderDetails (500,000+ rows)
--------------------------------------------------------------------------------
PRINT 'Generating 500,000+ order details...';
GO

-- Each order gets 1-5 line items
;WITH OrderItems AS (
    SELECT 
        o.OrderID,
        n.n AS ItemNum,
        p.ProductID,
        p.UnitPrice
    FROM dbo.Orders o
    CROSS APPLY (
        SELECT TOP (1 + ABS(CHECKSUM(NEWID())) % 5) n 
        FROM #Numbers 
        ORDER BY NEWID()
    ) n
    CROSS APPLY (
        SELECT TOP 1 ProductID, UnitPrice 
        FROM dbo.Products 
        ORDER BY NEWID()
    ) p
)
INSERT INTO dbo.OrderDetails (OrderID, ProductID, Quantity, UnitPrice, Discount)
SELECT 
    OrderID,
    ProductID,
    1 + ABS(CHECKSUM(NEWID())) % 10 AS Quantity,
    UnitPrice,
    -- 80% no discount, 15% small discount, 5% big discount
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 100 < 80 THEN 0.00
        WHEN ABS(CHECKSUM(NEWID())) % 100 < 95 THEN CAST((5 + ABS(CHECKSUM(NEWID())) % 10) / 100.0 AS DECIMAL(4,2))
        ELSE CAST((15 + ABS(CHECKSUM(NEWID())) % 15) / 100.0 AS DECIMAL(4,2))
    END AS Discount
FROM OrderItems;

PRINT '  OrderDetails created: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

--------------------------------------------------------------------------------
-- Update Order totals
--------------------------------------------------------------------------------
PRINT 'Updating order totals...';
GO

UPDATE o
SET 
    SubTotal = od.SubTotal,
    Tax = od.SubTotal * 0.08,
    Freight = 
        CASE 
            WHEN o.ShipMethod = 'Next Day Air' THEN 25.00
            WHEN o.ShipMethod = 'Express' THEN 15.00
            WHEN o.ShipMethod = 'Standard Ground' THEN 8.00
            ELSE 5.00
        END,
    TotalAmount = od.SubTotal + (od.SubTotal * 0.08) + 
        CASE 
            WHEN o.ShipMethod = 'Next Day Air' THEN 25.00
            WHEN o.ShipMethod = 'Express' THEN 15.00
            WHEN o.ShipMethod = 'Standard Ground' THEN 8.00
            ELSE 5.00
        END
FROM dbo.Orders o
JOIN (
    SELECT OrderID, SUM(LineTotal) AS SubTotal
    FROM dbo.OrderDetails
    GROUP BY OrderID
) od ON o.OrderID = od.OrderID;

PRINT '  Order totals updated: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

--------------------------------------------------------------------------------
-- Seed Inventory (1,000 rows - one per product)
--------------------------------------------------------------------------------
PRINT 'Generating inventory records...';
GO

INSERT INTO dbo.Inventory (ProductID, WarehouseCode, QuantityOnHand, QuantityReserved)
SELECT 
    ProductID,
    CASE (ProductID % 5)
        WHEN 0 THEN 'NYC'
        WHEN 1 THEN 'LAX'
        WHEN 2 THEN 'CHI'
        WHEN 3 THEN 'DAL'
        ELSE 'SEA'
    END AS WarehouseCode,
    100 + ABS(CHECKSUM(NEWID())) % 900 AS QuantityOnHand,
    ABS(CHECKSUM(NEWID())) % 50 AS QuantityReserved
FROM dbo.Products;

PRINT '  Inventory records created: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

--------------------------------------------------------------------------------
-- Generate some audit log entries
--------------------------------------------------------------------------------
PRINT 'Generating sample audit log entries...';
GO

INSERT INTO dbo.AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedDate)
SELECT TOP 10000
    CASE (n.n % 3)
        WHEN 0 THEN 'Customers'
        WHEN 1 THEN 'Orders'
        ELSE 'Products'
    END AS TableName,
    n.n % 1000 + 1 AS RecordID,
    CASE (n.n % 4)
        WHEN 0 THEN 'INSERT'
        WHEN 1 THEN 'UPDATE'
        WHEN 2 THEN 'UPDATE'
        ELSE 'DELETE'
    END AS Action,
    CASE WHEN n.n % 4 > 0 THEN '{"status":"old"}' ELSE NULL END AS OldValue,
    CASE WHEN n.n % 4 < 3 THEN '{"status":"new"}' ELSE NULL END AS NewValue,
    DATEADD(MINUTE, -1 * n.n, SYSDATETIME()) AS ChangedDate
FROM #Numbers n
WHERE n.n <= 10000;

PRINT '  Audit log entries created: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

--------------------------------------------------------------------------------
-- Update statistics for accurate query plans
--------------------------------------------------------------------------------
PRINT 'Updating statistics...';
GO

UPDATE STATISTICS dbo.Customers WITH FULLSCAN;
UPDATE STATISTICS dbo.Products WITH FULLSCAN;
UPDATE STATISTICS dbo.Orders WITH FULLSCAN;
UPDATE STATISTICS dbo.OrderDetails WITH FULLSCAN;
UPDATE STATISTICS dbo.Inventory WITH FULLSCAN;
UPDATE STATISTICS dbo.AuditLog WITH FULLSCAN;
GO

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------
DROP TABLE #Numbers;
GO

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------
PRINT '';
PRINT '================================================================================';
PRINT 'Data generation complete!';
PRINT '================================================================================';
PRINT '';

SELECT 'Summary' AS [Data Generation Summary], '' AS [Value]
UNION ALL
SELECT 'Customers', CAST(COUNT(*) AS VARCHAR) FROM dbo.Customers
UNION ALL
SELECT 'Products', CAST(COUNT(*) AS VARCHAR) FROM dbo.Products
UNION ALL
SELECT 'Orders', CAST(COUNT(*) AS VARCHAR) FROM dbo.Orders
UNION ALL
SELECT 'OrderDetails', CAST(COUNT(*) AS VARCHAR) FROM dbo.OrderDetails
UNION ALL
SELECT 'Inventory', CAST(COUNT(*) AS VARCHAR) FROM dbo.Inventory
UNION ALL
SELECT 'AuditLog', CAST(COUNT(*) AS VARCHAR) FROM dbo.AuditLog;

PRINT '';
PRINT 'Next step: Run 03-indexes.sql to create performance indexes.';
GO
