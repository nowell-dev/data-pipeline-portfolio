/*
--------------------------------------------------------------------------
Author				: Nowell Tiongco
Create Date			: August 2026
Test script		:
	SELECT 'BEFORE', * FROM DimCustomerFullName ORDER BY CustomerId, EffectiveLoadBatchId

	DECLARE @loadBatchIdTable table	(	id int identity(1,1),
										LoadBatchId int null
									);
	DECLARE @LoadBatchId INT;

	INSERT @loadBatchIdTable ( LoadBatchId ) 
	EXEC dbo.CreateLoadBatchEntry;

	SELECT TOP 1 @LoadBatchId = LoadBatchId
		from @loadBatchIdTable
		where LoadBatchId is not null
		order by id;

	EXEC dbo.[Load_DimCustomerFullName] @LoadBatchId, 'C:\GitHub\data-pipeline-portfolio\customers_file02.csv'

	SELECT 'AFTER', * FROM DimCustomerFullName ORDER BY CustomerId, EffectiveLoadBatchId
--------------------------------------------------------------------------
*/
USE [CustomerETL]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.[Load_DimCustomerFullName]
	@LoadBatchId INT = NULL,
	@fileToLoad NVARCHAR(250)
AS
BEGIN
	SET NOCOUNT ON;

	PRINT '@LoadBatchId: ' + CAST(@LoadBatchId as varchar(10))
	IF @LoadBatchId IS NULL OR NOT EXISTS ( SELECT 1 FROM LoadBatch WHERE LoadBatchId = @LoadBatchId )
	BEGIN
		THROW 51000, 'Invalid LoadBatchId supplied', 1;
	END

	PRINT 'SELECT DATA FROM CSV FILE - BEGIN'
	/*** SELECT DATA FROM CSV FILE - BEGIN ****************************************************/
	DROP TABLE IF EXISTS #Temp;
	CREATE TABLE #Temp
	(
		CustomerId INT,
		FullName NVARCHAR(250)
	);
	------
	DECLARE @sql NVARCHAR(MAX) = N'
		INSERT INTO #Temp ( CustomerId, FullName )
		SELECT DISTINCT
			cast( r.customer_id AS int ),
			cast( r.full_name AS nvarchar(250) )
		FROM OPENROWSET(
			BULK N''' + REPLACE(@fileToLoad, '''', '''''') + N''',
			FORMATFILE = N''C:\GitHub\data-pipeline-portfolio\customers.fmt'',
			FIRSTROW = 2,
			MAXERRORS = 0,
			ERRORFILE = N''C:\GitHub\data-pipeline-portfolio\customers.err'',
			CODEPAGE = ''65001''
		) AS r
		WHERE isnull( r.customer_id, '''' ) <> '''';';
	EXEC sys.sp_executesql @sql;
	------
	/*** SELECT DATA FROM CSV FILE - END ******************************************************/
	PRINT 'SELECT DATA FROM CSV FILE - END'

	PRINT 'SCD Type 2 (Step 1) - BEGIN'
	/*** SCD Type 2 (Step 1) - BEGIN **********************************************************/
	MERGE	DimCustomerFullName dest
	USING	(	SELECT DISTINCT
						CustomerId,
						FullName
				FROM #Temp
	) AS raw
	ON	(
			raw.CustomerId = dest.CustomerId
			AND dest.ExpirationLoadBatchId IS NULL
	)
	-- Kung ang existing CustomerId ay may bagong address, expire that record.
	WHEN	MATCHED
	AND		isnull( raw.FullName, '' ) <> isnull( dest.FullName, '' )
	THEN	UPDATE SET ExpirationLoadBatchId = @LoadBatchId
	-- Kung ang bagong CustomerId ay wala talaga sa dimension table, insert new record.
	WHEN	NOT MATCHED BY TARGET
	THEN	INSERT (
			CustomerId,
			FullName,
			EffectiveLoadBatchId,
			ExpirationLoadBatchId
		)
		VALUES (
			raw.CustomerId,
			raw.FullName,
			@LoadBatchId,
			NULL
		);
	/*** SCD Type 2 (Step 1) - END ************************************************************/
	PRINT 'SCD Type 2 (Step 1) - END'

	PRINT 'SCD Type 2 (Step 2) - BEGIN'
	/*** SCD Type 2 (Step 2) - BEGIN **********************************************************/
	-- Gumagawa ng bagong version ng address matapos i-expire ng Step 1 ang lumang record.
	INSERT INTO DimCustomerFullName	(	CustomerId, 
										FullName, 
										EffectiveLoadBatchId,
										ExpirationLoadBatchId
									)
	SELECT	DISTINCT
			raw.CustomerId,
			raw.FullName,
			@LoadBatchId,
			NULL
	FROM	#Temp raw
	INNER JOIN DimCustomerFullName dest
		ON raw.CustomerId = dest.CustomerId
		AND isnull( raw.FullName, '' ) <> isnull( dest.FullName, '' )
	WHERE	dest.ExpirationLoadBatchId = @LoadBatchId 
	AND		NOT EXISTS (
			SELECT 1 FROM DimCustomerFullName chk
			WHERE chk.CustomerId = raw.CustomerId
			AND chk.FullName = raw.FullName
			AND chk.ExpirationLoadBatchId IS NULL

	);
	/*** SCD Type 2 (Step 2) - END ************************************************************/
	PRINT 'SCD Type 2 (Step 2) - END'

	DROP TABLE IF EXISTS #Temp;

END
GO
