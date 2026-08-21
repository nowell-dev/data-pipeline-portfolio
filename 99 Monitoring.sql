USE [CustomerETL];
GO

--------------------------------------------------------------------------
-- MONITORING QUERY
-- Use this script during and after a batch execution to inspect:
-- 1) the current batch status
-- 2) the historical state of each customer dimension table
-- 3) whether the pipeline is loading or failed
--------------------------------------------------------------------------

SELECT *
FROM dbo.LoadBatch WITH(NOLOCK)
ORDER BY LoadBatchId DESC;

SELECT *
FROM dbo.DimCustomerFullName WITH(NOLOCK)
ORDER BY CustomerId, EffectiveLoadBatchId;

SELECT *
FROM dbo.DimCustomerEmail WITH(NOLOCK)
ORDER BY CustomerId, EffectiveLoadBatchId;

SELECT *
FROM dbo.DimCustomerPhone WITH(NOLOCK)
ORDER BY CustomerId, EffectiveLoadBatchId;

SELECT *
FROM dbo.DimCustomerAddress WITH(NOLOCK)
ORDER BY CustomerId, EffectiveLoadBatchId;

--------------------------------------------------------------------------
-- Expected pattern:
-- LoadBatch.Message should show one of these statuses:
--   Loading...
--   Loaded successfully
--   Failed with error message: ...
--
-- For the history tables, you should see multiple rows for the same CustomerId
-- whenever a value changes, due to the SCD Type 2 pattern.
--------------------------------------------------------------------------