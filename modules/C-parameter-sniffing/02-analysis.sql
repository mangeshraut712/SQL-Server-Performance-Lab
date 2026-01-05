/*
================================================================================
Module C: Parameter Sniffing - ANALYSIS
================================================================================
Purpose: Detect and understand parameter sniffing in your queries
================================================================================
*/

USE PerformanceLab;
GO

-- View cached plans for our procedure
SELECT 
    cp.objtype,
    cp.usecounts,
    cp.size_in_bytes / 1024 AS size_kb,
    st.text AS query_text
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE st.text LIKE '%usp_GetOrdersByCustomer%'
  AND cp.objtype = 'Proc';
GO

-- Show statistics for CustomerID column
DBCC SHOW_STATISTICS('dbo.Orders', 'IX_Orders_CustomerID');
GO

-- Detect parameter sniffing via high variance in Query Store
SELECT TOP 10
    q.query_id,
    qt.query_sql_text,
    MIN(rs.avg_duration / 1000.0) AS min_duration_ms,
    MAX(rs.avg_duration / 1000.0) AS max_duration_ms,
    MAX(rs.avg_duration) / NULLIF(MIN(rs.avg_duration), 1) AS variance_ratio
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id  
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
GROUP BY q.query_id, qt.query_sql_text
HAVING MAX(rs.avg_duration) / NULLIF(MIN(rs.avg_duration), 1) > 10
ORDER BY variance_ratio DESC;
GO

/*
Signs of Parameter Sniffing:
1. Same procedure fast for some, slow for others
2. High variance in execution times
3. Actual rows differ greatly from Estimated rows
*/
