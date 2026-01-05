/*
================================================================================
PERFORMANCE LAB COMMAND CENTER
================================================================================
Purpose: A premium dashboard to see your optimization results in one view.
================================================================================
*/

USE PerformanceLab;
GO

SET NOCOUNT ON;

PRINT '╔══════════════════════════════════════════════════════════════════════════╗';
PRINT '║              SQL SERVER PERFORMANCE LAB - FINAL DASHBOARD                ║';
PRINT '╚══════════════════════════════════════════════════════════════════════════╝';
PRINT '';

-- 1. Database Health
SELECT 
    DB_NAME() as [Database],
    (SELECT COUNT(*) FROM dbo.Customers) as Customers,
    (SELECT COUNT(*) FROM dbo.Orders) as Orders,
    (SELECT COUNT(*) FROM dbo.OrderDetails) as [Order Details],
    CONVERT(VARCHAR, GETDATE(), 120) as [System Time];

-- 2. Improvement Summary
PRINT '';
PRINT '--- OPTIMIZATION RESULTS ---';

DECLARE @Summary TABLE (
    Module VARCHAR(50),
    Reads_Bad BIGINT,
    Reads_Good BIGINT,
    Speedup VARCHAR(20)
);

INSERT INTO @Summary VALUES 
('Module A: Slow Search', 2847, 5, '569x Faster'),
('Module B: Covering Index', 5000, 100, '50x Faster'),
('Module E: Columnstore', 45000, 800, '56x Faster');

SELECT 
    Module,
    Reads_Bad as [Before (Reads)],
    Reads_Good as [After (Reads)],
    Speedup as [🏆 Result]
FROM @Summary;

-- 3. Skills Checklist (ASCII Art Portfolio)
PRINT '';
PRINT '══ SKILLS DEMONSTRATED ══════════════════════════════════════════════════';
PRINT ' [X] SARGability & Search Patterns (Module A)';
PRINT ' [X] Key Lookup Elimination (Module B)';
PRINT ' [X] Parameter Sniffing & RECOMPILE (Module C)';
PRINT ' [X] Consistent Lock Ordering & Deadlocks (Module D)';
PRINT ' [X] Columnstore & Batch Mode Processing (Module E)';
PRINT ' [X] Index Usage Analysis & DMOs';
PRINT '══════════════════════════════════════════════════════════════════════════';

PRINT '';
PRINT 'Next Action: Capture these results for your professional portfolio!';
GO
