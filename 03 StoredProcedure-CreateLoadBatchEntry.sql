/*
--------------------------------------------------------------------------
Author				: Nowell Tiongco
Create Date			: August 2026
Description			: Create a new entry in the LoadBatch table
Test script		:
	SELECT 'BEFORE', * FROM LoadBatch ORDER BY  LoadBatchId DESC
	EXEC dbo.CreateLoadBatchEntry
	SELECT 'AFTER', * FROM LoadBatch ORDER BY  LoadBatchId DESC
--------------------------------------------------------------------------
*/
USE [CustomerETL];
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.CreateLoadBatchEntry
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @loadBatchId int;

	INSERT INTO dbo.LoadBatch (
		[FileName],
		[Message]
	)
	VALUES (
		NULL,
		NULL
	);

	SET @loadBatchId = SCOPE_IDENTITY();
	SELECT @loadBatchId AS LoadBatchId;
END
GO