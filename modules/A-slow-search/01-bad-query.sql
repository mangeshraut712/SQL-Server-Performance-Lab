/*
================================================================================
Module A: Slow Search Patterns - BAD QUERIES
================================================================================
Purpose: Demonstrate search patterns that prevent index usage

Instructions:
1. Enable statistics (SET STATISTICS IO ON; SET STATISTICS TIME ON;)
2. Include Actual Execution Plan (Ctrl+M in SSMS)
3. Clear cache before each test: EXEC dbo.usp_ClearCache;
4. Run each query and observe the metrics
================================================================================
*/

USE PerformanceLab;
GO

-- Enable measurement
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Clear cache for accurate measurement
EXEC dbo.usp_ClearCache;
GO

--------------------------------------------------------------------------------
-- BAD PATTERN #1: Leading Wildcard LIKE
--------------------------------------------------------------------------------
/*
Problem: LIKE '%value%' cannot use an index because SQL Server doesn't know
where in the column the value might appear.

Expected: Full table/index scan, ~2,800 logical reads
*/

PRINT '=== BAD PATTERN #1: Leading Wildcard LIKE ===';
GO

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    City,
    State
FROM dbo.Customers
WHERE LastName LIKE '%smith%';
GO

/*
Look for in execution plan:
- Index Scan (not Seek)
- High "Number of Rows Read" vs "Actual Rows"
- Warning about "Predicate" (not "Seek Predicate")
*/


--------------------------------------------------------------------------------
-- BAD PATTERN #2: Function on Column
--------------------------------------------------------------------------------
/*
Problem: UPPER(column) = VALUE prevents index usage because SQL Server
must evaluate the function for every row before comparing.

Expected: Full scan, ~2,800 logical reads
*/

PRINT '=== BAD PATTERN #2: Function on Column ===';
GO

-- Clear cache
EXEC dbo.usp_ClearCache;
GO

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email
FROM dbo.Customers
WHERE UPPER(LastName) = 'JOHNSON';
GO

/*
Look for in execution plan:
- Index Scan or Clustered Index Scan
- High cost percentage on the Scan operator
*/


--------------------------------------------------------------------------------
-- BAD PATTERN #3: Multiple OR Conditions Across Different Columns
--------------------------------------------------------------------------------
/*
Problem: OR conditions across different columns often result in table scans
because different indexes would be needed for each condition.

Expected: Could force scan or inefficient index union
*/

PRINT '=== BAD PATTERN #3: OR Across Columns ===';
GO

EXEC dbo.usp_ClearCache;
GO

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    Phone
FROM dbo.Customers
WHERE LastName LIKE '%john%'
   OR Email LIKE '%john%'
   OR Phone LIKE '%555%';
GO

/*
Look for in execution plan:
- Table Scan or multiple Index Scans with Concatenation
- High logical reads
*/


--------------------------------------------------------------------------------
-- BAD PATTERN #4: Combining Functions and Wildcards (The Worst!)
--------------------------------------------------------------------------------
/*
Problem: This is the worst case - both patterns combined.
This is the pattern used in dbo.usp_SearchCustomers_Bad

Expected: Maximum logical reads, slowest execution
*/

PRINT '=== BAD PATTERN #4: Functions + Wildcards Combined ===';
GO

EXEC dbo.usp_ClearCache;
GO

DECLARE @SearchTerm NVARCHAR(50) = 'smith';

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    City,
    State
FROM dbo.Customers
WHERE UPPER(LastName) LIKE '%' + UPPER(@SearchTerm) + '%'
   OR UPPER(FirstName) LIKE '%' + UPPER(@SearchTerm) + '%'
   OR UPPER(Email) LIKE '%' + UPPER(@SearchTerm) + '%';
GO

/*
Look for in execution plan:
- Clustered Index Scan (reading every row)
- Very high "Actual Rows Read"
- Filter operator with complex predicate

Record your measurements:
- Logical Reads: _______
- CPU Time: _______ ms
- Elapsed Time: _______ ms
- Rows Returned: _______
*/


--------------------------------------------------------------------------------
-- BAD PATTERN #5: Implicit Conversion
--------------------------------------------------------------------------------
/*
Problem: When comparing columns of different types, SQL Server may need
to convert every row, preventing index seeks.

Note: In our schema, this is less common, but here's an example:
*/

PRINT '=== BAD PATTERN #5: Implicit Conversion ===';
GO

EXEC dbo.usp_ClearCache;
GO

-- This forces conversion if we pass a number where a string is expected
DECLARE @ZipCode INT = 10001;

SELECT CustomerID, FirstName, LastName, ZipCode
FROM dbo.Customers
WHERE ZipCode = @ZipCode;  -- ZipCode is VARCHAR, @ZipCode is INT
GO

/*
Look for in execution plan:
- Warning triangle (!) indicating implicit conversion
- Possible scan instead of seek
*/


--------------------------------------------------------------------------------
-- Summary: Record Your Baseline Measurements
--------------------------------------------------------------------------------
/*
Fill in your observations:

| Pattern | Logical Reads | CPU Time (ms) | Plan Type |
|---------|---------------|---------------|-----------|
| #1 Leading % | _____ | _____ | _________ |
| #2 Function | _____ | _____ | _________ |
| #3 Multi-OR | _____ | _____ | _________ |
| #4 Combined | _____ | _____ | _________ |
| #5 Implicit | _____ | _____ | _________ |

Next: Run 02-analysis.sql to understand why these are slow.
*/
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
