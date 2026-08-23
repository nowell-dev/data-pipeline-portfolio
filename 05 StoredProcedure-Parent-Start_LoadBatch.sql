/*
--------------------------------------------------------------------------
Author				: Nowell Tiongco
Create Date			: August 2026
Description			: Execute child stored procedures
Test script		: 
	EXEC dbo.[Start_LoadBatch] 'C:\GitHub\data-pipeline-portfolio\customers_file01.csv';
	EXEC dbo.[Start_LoadBatch] 'C:\GitHub\data-pipeline-portfolio\customers_file02.csv';
	EXEC dbo.[Start_LoadBatch] 'C:\GitHub\data-pipeline-portfolio\customers_file03.csv';
--------------------------------------------------------------------------
*/
USE [CustomerETL]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.[Start_LoadBatch]
	@fileToLoad NVARCHAR(250)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @errorMessage varchar(8000);
	DECLARE @loadBatchIdTable table ( id int identity(1,1), LoadBatchId int null );
	DECLARE @LoadBatchId INT;

	BEGIN TRY
		------------------------------------------------------------
		-- ETL ORCHESTRATION FLOW
		-- Step 1: create a new batch row in LoadBatch
		-- Step 2: mark the batch as "Loading..."
		-- Step 3: run each child loader procedure in sequence
		-- Step 4: mark the batch as completed if all child loads succeed
		-- Step 5: rollback and log the error if any child procedure fails
		------------------------------------------------------------

		------------------------------------------------------------
		-- -- TEST PARAMETER
		-- DECLARE @fileToLoad NVARCHAR(250) = N'C:\GitHub\data-pipeline-portfolio\customers_file01.csv';
		-- DECLARE @loadBatchIdTable table ( id int identity(1,1), LoadBatchId int null );
		-- DECLARE @LoadBatchId INT;
		------------------------------------------------------------

		-- Create a new log entry for this load execution.
		PRINT 'EXECUTING dbo.CreateLoadBatchEntry - BEGIN'
		------
		INSERT @loadBatchIdTable ( LoadBatchId ) 
		EXEC dbo.CreateLoadBatchEntry;
		------
		SELECT TOP 1 @loadBatchId = LoadBatchId
			from @loadBatchIdTable
			where LoadBatchId is not null
			order by id;
		------
		SELECT '@LoadBatchId: ' + CAST(@LoadBatchId AS varchar(10))
		------
		PRINT 'EXECUTING dbo.CreateLoadBatchEntry - END'
		PRINT ''

		BEGIN TRAN;

		PRINT 'Update LoadBatch - BEGIN'
		UPDATE dbo.LoadBatch
		SET [FileName] = @fileToLoad,
			[Message] = 'Loading...'
		WHERE LoadBatchId = @LoadBatchId
		PRINT 'Update LoadBatch - END'
		PRINT ''

		Waitfor delay '00:00:05' -- delay to allow monitoring of LoadBatch while this stored procedure is running.

		-- Load customer full name dimension history.
		PRINT 'EXECUTING dbo.[Load_DimCustomerFullName] - BEGIN'
		EXEC dbo.[Load_DimCustomerFullName] @loadBatchId, @fileToLoad
		PRINT 'EXEC dbo.[Load_DimCustomerFullName] - END'
		PRINT ''

		Waitfor delay '00:00:05' -- delay to allow monitoring of LoadBatch while this stored procedure is running.

		-- Load customer email dimension history.
		PRINT 'EXECUTING dbo.[Load_DimCustomerEmail] - BEGIN'
		EXEC dbo.[Load_DimCustomerEmail] @loadBatchId, @fileToLoad
		PRINT 'EXEC dbo.[Load_DimCustomerEmail] - END'
		PRINT ''

		Waitfor delay '00:00:05' -- delay to allow monitoring of LoadBatch while this stored procedure is running.

		-- Load customer phone dimension history.
		PRINT 'EXECUTING dbo.[Load_DimCustomerPhone] - BEGIN'
		EXEC dbo.[Load_DimCustomerPhone] @loadBatchId, @fileToLoad
		PRINT 'EXEC dbo.[Load_DimCustomerPhone] - END'
		PRINT ''

		Waitfor delay '00:00:05' -- delay to allow monitoring of LoadBatch while this stored procedure is running.

		-- Load customer address dimension history.
		PRINT 'EXECUTING dbo.[Load_DimCustomerAddress] - BEGIN'
		EXEC dbo.[Load_DimCustomerAddress] @loadBatchId, @fileToLoad
		PRINT 'EXEC dbo.[Load_DimCustomerAddress] - END'
		PRINT ''

		Waitfor delay '00:00:05' -- delay to allow monitoring of LoadBatch while this stored procedure is running.

		PRINT 'Update LoadBatch - BEGIN'
		UPDATE dbo.LoadBatch
		SET [Message] = 'Loaded successfully'
		WHERE LoadBatchId = @LoadBatchId
		PRINT 'Update LoadBatch - END'
		PRINT ''

		COMMIT;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;

		PRINT 'Failed with error message: ' + ERROR_MESSAGE()

		UPDATE	dbo.LoadBatch
		SET		[Message]	= 'Failed with error message: ' + ERROR_MESSAGE()
		WHERE	LoadBatchId	= @loadBatchId
	END CATCH

END
GO
