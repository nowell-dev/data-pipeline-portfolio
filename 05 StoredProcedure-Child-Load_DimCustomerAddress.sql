/*
--------------------------------------------------------------------------
Author				: Nowell Tiongco
Create Date			: August 2026
Test script		:
	SELECT 'BEFORE', * FROM DimCustomerAddress ORDER BY CustomerId, EffectiveLoadBatchId

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

	EXEC dbo.[Load_DimCustomerAddress] @LoadBatchId, 'C:\GitHub\data-pipeline-portfolio\customers_file01.csv'

	SELECT 'AFTER', * FROM DimCustomerAddress ORDER BY CustomerId, EffectiveLoadBatchId
--------------------------------------------------------------------------
*/
USE [CustomerETL]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.[Load_DimCustomerAddress]
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
		Address NVARCHAR(250),
		City NVARCHAR(250),
		Province NVARCHAR(250)
	);
	------
	DECLARE @sql NVARCHAR(MAX) = N'
		INSERT INTO #Temp ( CustomerId, Address, City, Province )
		SELECT DISTINCT
			cast( r.customer_id AS int ),
			cast( r.address AS nvarchar(250) ),
			cast( r.city AS nvarchar(250) ),
			cast( r.province AS nvarchar(250) )
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
	MERGE	DimCustomerAddress dest
	USING	(	SELECT DISTINCT
						CustomerId,
						Address,
						City,
						Province
				FROM #Temp
	) AS raw
	ON	(
			raw.CustomerId = dest.CustomerId
			AND dest.ExpirationLoadBatchId IS NULL
	)
	-- Kung ang existing CustomerId ay may bagong address, expire that record.
	WHEN	MATCHED
	AND		(	isnull( raw.Address, '' ) <> isnull( dest.Address, '' )
			OR	isnull( raw.City, '' ) <> isnull( dest.City, '' )
			OR	isnull( raw.Province, '' ) <> isnull( dest.Province, '' )
			)
	THEN	UPDATE SET ExpirationLoadBatchId = @LoadBatchId
	-- Kung ang bagong CustomerId ay wala talaga sa dimension table, insert new record.
	WHEN	NOT MATCHED BY TARGET
	THEN	INSERT (
			CustomerId,
			Address,
			City,
			Province,
			EffectiveLoadBatchId,
			ExpirationLoadBatchId
		)
		VALUES (
			raw.CustomerId,
			raw.Address,
			raw.City,
			raw.Province,
			@LoadBatchId,
			NULL
		);
	/*** SCD Type 2 (Step 1) - END ************************************************************/
	PRINT 'SCD Type 2 (Step 1) - END'

	PRINT 'SCD Type 2 (Step 2) - BEGIN'
	/*** SCD Type 2 (Step 2) - BEGIN **********************************************************/
	-- Gumagawa ng bagong version ng address matapos i-expire ng Step 1 ang lumang record.
	INSERT INTO DimCustomerAddress	(	CustomerId, 
										Address,
										City,
										Province, 
										EffectiveLoadBatchId,
										ExpirationLoadBatchId
									)
	SELECT	DISTINCT
			raw.CustomerId,
			raw.Address,
			raw.City,
			raw.Province,
			@LoadBatchId,
			NULL
	FROM	#Temp raw
	INNER JOIN DimCustomerAddress dest
		ON raw.CustomerId = dest.CustomerId
		AND	(	isnull( raw.Address, '' ) <> isnull( dest.Address, '' )
			OR	isnull( raw.City, '' ) <> isnull( dest.City, '' )
			OR	isnull( raw.Province, '' ) <> isnull( dest.Province, '' )
			)
	WHERE	dest.ExpirationLoadBatchId = @LoadBatchId 
	AND		NOT EXISTS (
			SELECT 1 FROM DimCustomerAddress chk
			WHERE chk.CustomerId = raw.CustomerId
			AND chk.Address = raw.Address
			AND chk.City = raw.City
			AND chk.Province = raw.Province
			AND chk.ExpirationLoadBatchId IS NULL

	);
	/*** SCD Type 2 (Step 2) - END ************************************************************/
	PRINT 'SCD Type 2 (Step 2) - END'

	DROP TABLE IF EXISTS #Temp;

END
GO