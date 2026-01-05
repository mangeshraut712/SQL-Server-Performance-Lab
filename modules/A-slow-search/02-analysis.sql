/*
================================================================================
Module A: Slow Search Patterns - ANALYSIS
================================================================================
Purpose: Understand WHY the bad patterns are slow and what SQL Server
         is actually doing under the hood.
================================================================================
*/

USE PerformanceLab;
GO

--------------------------------------------------------------------------------
-- Understanding Index Structure
--------------------------------------------------------------------------------
/*
An index is like a phone book - sorted in a specific order.
If you know the last name, you can find "Smith" very quickly.
But if you only know "the name contains 'mith' somewhere", 
you have to read EVERY entry.
*/

-- Let's look at the indexes on Customers table
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS IndexColumns
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.Customers')
ORDER BY i.index_id;
GO


--------------------------------------------------------------------------------
-- Why Leading Wildcard Fails
--------------------------------------------------------------------------------
/*
Index on LastName is sorted like:
  Adams, Anderson, Baker, Brown, Davis, Garcia, Johnson, Smith, Williams, ...

Query: WHERE LastName LIKE '%son%'

The '%' at the start means "anything can be before 'son'"
SQL Server cannot know if 'Anderson', 'Johnson', 'Wilson' match without checking!

This is like asking: "Find everyone whose name has 'son' somewhere in it"
vs asking: "Find everyone whose name starts with 'John'"
*/

-- Show the difference in execution plans
SET SHOWPLAN_TEXT ON;
GO

-- CAN use index (starts with)
SELECT CustomerID, LastName FROM dbo.Customers WHERE LastName LIKE 'John%';
GO

-- CANNOT use index efficiently (contains)
SELECT CustomerID, LastName FROM dbo.Customers WHERE LastName LIKE '%John%';
GO

SET SHOWPLAN_TEXT OFF;
GO


--------------------------------------------------------------------------------
-- Why Functions on Columns Fail
--------------------------------------------------------------------------------
/*
Index on LastName stores: 'Johnson', 'JOHNSON', 'johnson' (actual casing)
Index does NOT store: UPPER('Johnson')

Query: WHERE UPPER(LastName) = 'JOHNSON'

SQL Server must:
1. Read each row
2. Apply UPPER() to the LastName value
3. Compare result to 'JOHNSON'

This defeats the entire purpose of the index!
*/

-- The index physically looks like this (sample):
SELECT TOP 20 
    LastName,
    UPPER(LastName) AS WhatQueryNeeds
FROM dbo.Customers
ORDER BY LastName;
GO


--------------------------------------------------------------------------------
-- Analyzing with Extended Events (Optional Advanced)
--------------------------------------------------------------------------------
/*
You can trace exactly what SQL Server is doing:

-- Create trace for query execution details
CREATE EVENT SESSION [QueryAnalysis] ON SERVER 
ADD EVENT sqlserver.query_post_execution_showplan
WHERE database_name = 'PerformanceLab'
ADD TARGET package0.event_file(SET filename=N'QueryAnalysis');

ALTER EVENT SESSION [QueryAnalysis] ON SERVER STATE = START;
*/


--------------------------------------------------------------------------------
-- Check for Missing Index Suggestions
--------------------------------------------------------------------------------
/*
SQL Server tracks when queries could have benefited from indexes.
Let's see if it has any suggestions:
*/

EXEC dbo.usp_MissingIndexes;
GO


--------------------------------------------------------------------------------
-- Analyze a Specific Bad Query
--------------------------------------------------------------------------------
/*
Let's get detailed execution stats for Pattern #4 (the worst one):
*/

-- Use Query Store to see how the query performed
SELECT TOP 5
    qt.query_sql_text,
    qsrs.count_executions,
    qsrs.avg_logical_io_reads,
    qsrs.avg_cpu_time / 1000.0 AS avg_cpu_time_ms,
    qsrs.avg_duration / 1000.0 AS avg_duration_ms,
    CAST(qsrs.avg_logical_io_reads AS VARCHAR) + ' reads in ' + 
    CAST(qsrs.avg_duration / 1000.0 AS VARCHAR) + 'ms' AS Summary
FROM sys.query_store_runtime_stats qsrs
JOIN sys.query_store_plan qsp ON qsrs.plan_id = qsp.plan_id
JOIN sys.query_store_query qsq ON qsp.query_id = qsq.query_id
JOIN sys.query_store_query_text qt ON qsq.query_text_id = qt.query_text_id
WHERE qt.query_sql_text LIKE '%LIKE%smith%'
ORDER BY qsrs.avg_logical_io_reads DESC;
GO


--------------------------------------------------------------------------------
-- Visualize the Problem: Scan vs Seek
--------------------------------------------------------------------------------
/*
INDEX SCAN (Bad):
  - Reads EVERY page in the index
  - Like reading an entire phone book to find everyone named "Johnson"
  - Our Customers table has ~2,800 pages
  
INDEX SEEK (Good):
  - Jumps directly to the relevant pages
  - Like opening the phone book to the "J" section
  - Typically reads 2-10 pages for a single value

The difference: 2,800 reads vs 5 reads = 560x worse!
*/

-- See how many pages our table uses
SELECT 
    t.name AS TableName,
    p.rows AS RowCount,
    SUM(a.total_pages) AS TotalPages,
    SUM(a.used_pages) AS UsedPages,
    SUM(a.data_pages) AS DataPages,
    SUM(a.total_pages) * 8 / 1024 AS TotalSizeMB
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.name = 'Customers'
GROUP BY t.name, p.rows;
GO


--------------------------------------------------------------------------------
-- The Case-Sensitivity Challenge
--------------------------------------------------------------------------------
/*
Often, UPPER() or LOWER() is used for case-insensitive searches.
But there are better ways!

Default collation in SQL Server is often case-insensitive:
*/

-- Check our database collation
SELECT 
    DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS DatabaseCollation;
GO

-- Check column collation
SELECT 
    c.name AS ColumnName,
    c.collation_name
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('dbo.Customers')
  AND c.name = 'LastName';
GO

/*
If the collation ends in '_CI_' (Case Insensitive), you DON'T need UPPER()!

SQL_Latin1_General_CP1_CI_AS
                     ^^
                     CI = Case Insensitive

This means: WHERE LastName = 'JOHNSON'
Is equivalent to: WHERE LastName = 'johnson'
Without any function calls!
*/


--------------------------------------------------------------------------------
-- Summary: Key Insights
--------------------------------------------------------------------------------
/*
1. LEADING WILDCARDS prevent index seeks because the search pattern
   doesn't match how the index is sorted.

2. FUNCTIONS ON COLUMNS prevent index seeks because the index stores
   the actual column value, not the function result.

3. SQL Server MUST read every row when it can't use an index seek,
   resulting in thousands of unnecessary logical reads.

4. Case-insensitive collations make UPPER()/LOWER() unnecessary
   for most text comparisons.

5. Missing Index DMV suggestions can help identify optimization opportunities.

Next: Run 03-fix.sql to see the optimized alternatives.
*/
GO
