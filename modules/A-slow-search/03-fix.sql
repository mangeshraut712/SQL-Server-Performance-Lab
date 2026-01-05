/*
================================================================================
Module A: Slow Search Patterns - FIXES
================================================================================
Purpose: Demonstrate optimized search patterns with measurable improvements.

Expected Improvement: 50-280x reduction in logical reads
================================================================================
*/

USE PerformanceLab;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

--------------------------------------------------------------------------------
-- FIX #1: Remove Leading Wildcard (Best Option)
--------------------------------------------------------------------------------
/*
Original: WHERE LastName LIKE '%smith%'
Fixed:    WHERE LastName LIKE 'Smith%'

If you KNOW the search term is at the start, remove the leading wildcard.
This allows SQL Server to seek directly to matching rows.
*/

PRINT '=== FIX #1: Start-of-string search ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- BAD: Leading wildcard (for comparison)
SELECT CustomerID, FirstName, LastName
FROM dbo.Customers
WHERE LastName LIKE '%smith%';
GO

-- GOOD: Trailing wildcard only
SELECT CustomerID, FirstName, LastName  
FROM dbo.Customers
WHERE LastName LIKE 'Smith%';
GO

/*
Expected Results:
- BAD:  ~2,800 logical reads, Index Scan
- GOOD: ~3-10 logical reads, Index Seek

Improvement: ~300x fewer reads!
*/


--------------------------------------------------------------------------------
-- FIX #2: Remove Function - Use Collation Instead
--------------------------------------------------------------------------------
/*
Original: WHERE UPPER(LastName) = 'JOHNSON'
Fixed:    WHERE LastName = 'Johnson' (if collation is CI)
      or: WHERE LastName = 'Johnson' COLLATE Latin1_General_CI_AS
*/

PRINT '=== FIX #2: Remove function, use collation ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- BAD: Function on column
SELECT CustomerID, FirstName, LastName
FROM dbo.Customers
WHERE UPPER(LastName) = 'JOHNSON';
GO

-- GOOD: Direct comparison (works because collation is case-insensitive)
SELECT CustomerID, FirstName, LastName
FROM dbo.Customers
WHERE LastName = 'Johnson';
GO

/*
Expected Results:
- BAD:  ~2,800 logical reads, Index Scan
- GOOD: ~3-10 logical reads, Index Seek

Improvement: ~300x fewer reads!
*/


--------------------------------------------------------------------------------
-- FIX #3: Create Computed Column for Complex Searches
--------------------------------------------------------------------------------
/*
If you MUST search by a function result, create a computed column
and index it. This pre-calculates the function once during insert/update.
*/

PRINT '=== FIX #3: Computed column with index ===';
GO

-- Create a computed column for the upper-case last name
ALTER TABLE dbo.Customers
ADD LastNameUpper AS UPPER(LastName) PERSISTED;
GO

-- Create an index on the computed column
CREATE NONCLUSTERED INDEX IX_Customers_LastNameUpper
ON dbo.Customers (LastNameUpper)
INCLUDE (FirstName, Email);
GO

EXEC dbo.usp_ClearCache;
GO

-- Now this search CAN use an index!
SELECT CustomerID, FirstName, LastName
FROM dbo.Customers
WHERE LastNameUpper = 'JOHNSON';
GO

/*
The computed column approach:
- Calculates UPPER() once when data is inserted/updated
- Stores the result in the index
- Allows efficient seeks on the computed value
*/


--------------------------------------------------------------------------------
-- FIX #4: Separate Searches Instead of Multi-OR
--------------------------------------------------------------------------------
/*
Original: WHERE LastName LIKE '%x%' OR Email LIKE '%x%'
Fixed:    Use UNION or separate queries

For truly flexible search, consider Full-Text Search instead.
*/

PRINT '=== FIX #4: Separate specific searches ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- BAD: Multiple OR with wildcards
SELECT CustomerID, FirstName, LastName, Email
FROM dbo.Customers
WHERE LastName LIKE '%john%'
   OR Email LIKE '%john%';
GO

-- BETTER: Specific, index-friendly searches
SELECT CustomerID, FirstName, LastName, Email
FROM dbo.Customers
WHERE LastName LIKE 'John%'

UNION

SELECT CustomerID, FirstName, LastName, Email
FROM dbo.Customers
WHERE Email LIKE 'john%';
GO


--------------------------------------------------------------------------------
-- FIX #4b: Full-Text Search (Enterprise Solution)
--------------------------------------------------------------------------------
/*
Full-Text Search is the BEST solution for complex text searching.
It provides linguistic search, ranking, and excellent performance.
*/

PRINT '=== FIX #4b: Full-Text Search Implementation ===';
GO

-- Step 1: Create Full-Text Catalog (one per database)
IF NOT EXISTS (SELECT * FROM sys.fulltext_catalogs WHERE name = 'CustomerCatalog')
BEGIN
    CREATE FULLTEXT CATALOG CustomerCatalog AS DEFAULT;
    PRINT 'Full-Text Catalog created.';
END
ELSE
BEGIN
    PRINT 'Full-Text Catalog already exists.';
END
GO

-- Step 2: Create Full-Text Index on Customers table
IF NOT EXISTS (
    SELECT * FROM sys.fulltext_indexes 
    WHERE object_id = OBJECT_ID('dbo.Customers')
)
BEGIN
    CREATE FULLTEXT INDEX ON dbo.Customers (
        FirstName LANGUAGE 1033,  -- English
        LastName LANGUAGE 1033,
        Email LANGUAGE 1033,
        Notes LANGUAGE 1033
    ) 
    KEY INDEX PK__Customer__A4AE64B8F1F8C8D1  -- Your actual PK name
    ON CustomerCatalog
    WITH CHANGE_TRACKING AUTO;
    
    PRINT 'Full-Text Index created on Customers table.';
    PRINT 'Waiting for initial population...';
    
    -- Wait for index to populate
    WAITFOR DELAY '00:00:05';
END
ELSE
BEGIN
    PRINT 'Full-Text Index already exists.';
END
GO

-- Step 3: Use CONTAINS for full-text search
EXEC dbo.usp_ClearCache;
GO

PRINT 'Running Full-Text Search query:';

-- Search for "smith" in any indexed column
SELECT CustomerID, FirstName, LastName, Email, Notes
FROM dbo.Customers
WHERE CONTAINS((FirstName, LastName, Email), 'smith');
GO

-- Advanced: Search with wildcards (prefix matching)
SELECT CustomerID, FirstName, LastName, Email
FROM dbo.Customers
WHERE CONTAINS((FirstName, LastName, Email), '"john*"');
GO

-- Advanced: Search with proximity (words near each other)
SELECT CustomerID, FirstName, LastName, Email, Notes
FROM dbo.Customers
WHERE CONTAINS(Notes, 'NEAR((important, customer), 5)');
GO

-- Advanced: Search with ranking (FREETEXTTABLE)
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email,
    ft.RANK AS SearchRelevance
FROM dbo.Customers c
JOIN FREETEXTTABLE(dbo.Customers, (FirstName, LastName, Email), 'john smith') ft
    ON c.CustomerID = ft.[KEY]
ORDER BY ft.RANK DESC;
GO

/*
Full-Text Search Benefits:
✅ Linguistic search (word forms, synonyms)
✅ Proximity searches
✅ Relevance ranking
✅ Excellent performance on large text
✅ No need for leading wildcards

Perfect for:
- Product catalogs
- Customer search
- Document management
- Knowledge bases
*/


--------------------------------------------------------------------------------
-- FIX #5: Create Covering Index for Common Searches
--------------------------------------------------------------------------------
/*
Even with a seek, you might get "Key Lookups" to fetch additional columns.
A covering index includes all needed columns, eliminating lookups.
*/

PRINT '=== FIX #5: Covering index ===';
GO

-- Check if we currently have key lookups
-- Run this query with "Include Actual Execution Plan" on:
EXEC dbo.usp_ClearCache;
GO

SELECT CustomerID, FirstName, LastName, Email, City, State
FROM dbo.Customers
WHERE LastName LIKE 'Smith%';
GO

-- Create covering index (INCLUDE the columns we SELECT)
CREATE NONCLUSTERED INDEX IX_Customers_LastName_Covering
ON dbo.Customers (LastName)
INCLUDE (FirstName, Email, City, State);
GO

EXEC dbo.usp_ClearCache;
GO

-- Same query now has NO key lookup!
SELECT CustomerID, FirstName, LastName, Email, City, State
FROM dbo.Customers
WHERE LastName LIKE 'Smith%';
GO


--------------------------------------------------------------------------------
-- FIX #6: Use the Optimized Stored Procedure
--------------------------------------------------------------------------------
/*
Compare the bad vs good stored procedures we created in setup.
*/

PRINT '=== FIX #6: Optimized stored procedure ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- BAD procedure
EXEC dbo.usp_SearchCustomers_Bad @SearchTerm = 'smith';
GO

EXEC dbo.usp_ClearCache;
GO

-- GOOD procedure (uses index-friendly patterns)
EXEC dbo.usp_SearchCustomers_Good @LastName = 'Smith';
GO


--------------------------------------------------------------------------------
-- Performance Comparison Summary
--------------------------------------------------------------------------------

PRINT '=== PERFORMANCE COMPARISON ===';
GO

/*
Record your results:

| Scenario | Logical Reads | CPU Time | Improvement |
|----------|---------------|----------|-------------|
| Bad LIKE '%smith%' | ~2,800 | ~100 ms | baseline |
| Good LIKE 'Smith%' | ~5 | ~1 ms | 560x |
| Bad UPPER(col) = X | ~2,800 | ~100 ms | baseline |
| Good col = X | ~5 | ~1 ms | 560x |
| With Covering Index | ~3 | ~0 ms | even better |
*/

-- Save benchmark results
INSERT INTO dbo.QueryBenchmarks (TestName, QueryType, LogicalReads, CPUTimeMs, Notes)
VALUES 
    ('Module A - Slow Search', 'BAD', 2800, 100, 'Leading wildcard LIKE'),
    ('Module A - Slow Search', 'OPTIMIZED', 5, 1, 'Trailing wildcard + covering index');
GO

-- View comparison
EXEC dbo.usp_CompareQueryStats 'Module A - Slow Search';
GO


--------------------------------------------------------------------------------
-- Cleanup (Optional - remove computed column if not needed)
--------------------------------------------------------------------------------
/*
-- To remove the computed column:
DROP INDEX IX_Customers_LastNameUpper ON dbo.Customers;
ALTER TABLE dbo.Customers DROP COLUMN LastNameUpper;

-- To remove the covering index:  
DROP INDEX IX_Customers_LastName_Covering ON dbo.Customers;
*/


--------------------------------------------------------------------------------
-- Key Takeaways
--------------------------------------------------------------------------------
/*
✅ DO:
- Use trailing wildcards (LIKE 'value%') when possible
- Leverage case-insensitive collation instead of UPPER()/LOWER()
- Create computed columns for frequently-used function expressions
- Use covering indexes to eliminate key lookups
- Consider Full-Text Search for complex text searching

❌ DON'T:
- Use leading wildcards (LIKE '%value%') unless absolutely necessary
- Wrap columns in functions in WHERE clauses
- Use OR across different columns without considering alternatives
- Ignore implicit conversion warnings in execution plans

Next Module: B-covering-index - Dive deeper into covering indexes
*/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
