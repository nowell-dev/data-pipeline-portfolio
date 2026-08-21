/*
--------------------------------------------------------------------------
Author				: Nowell Tiongco
Create Date			: August 2026
Description			: Ang mga script na ito ay para sa testing ng mga stored procedures.
--------------------------------------------------------------------------
*/
USE [CustomerETL];
GO

-- ---------------------------------
-- RUN THE FOLLOWING TEST SCRIPTS ONE AT A TIME.
-- CHECK THE LoadBatch TABLE AFTER EACH EXECUTION.
-- ---------------------------------

-- TEST SCRIPT 1: Normal execution (loading customers_file01.csv)
-- Run "99 Monitoring.sql" during and after the execution of this script to check the LoadBatch table.
EXEC dbo.[Start_LoadBatch] 'C:\GitHub\data-pipeline-portfolio\customers_file01.csv';

-- TEST SCRIPT 2: Normal execution (loading customers_file02.csv)
-- Run "99 Monitoring.sql" during and after the execution of this script to check the LoadBatch table.
EXEC dbo.[Start_LoadBatch] 'C:\GitHub\data-pipeline-portfolio\customers_file02.csv';

-- TEST SCRIPT 3: Normal execution (loading customers_file03.csv)
-- Run "99 Monitoring.sql" during and after the execution of this script to check the LoadBatch table.
EXEC dbo.[Start_LoadBatch] 'C:\GitHub\data-pipeline-portfolio\customers_file03.csv';

-- TEST SCRIPT 4: Error handling test
DROP PROCEDURE Load_DimCustomerAddress
-- Drop a child stored procedure to simulate an error during execution

EXEC dbo.[Start_LoadBatch] 'C:\GitHub\data-pipeline-portfolio\customers_file01.csv';
-- Mag-e-error ito dahil nawawala ang isang child SP
-- After magrun, run "99 Monitoring.sql"
-- Check LoadBatch table. Na-log dapat ang error message.



-- noting follows