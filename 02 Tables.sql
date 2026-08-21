/*
--------------------------------------------------------------------------
Author				: Nowell Tiongco
Create Date			: August 2026
Description			: Create tables
--------------------------------------------------------------------------
*/
USE [CustomerETL];
GO

--------------------------------------------------------------------------
-- DATA MODEL OVERVIEW
-- This project uses a simple batch-load tracking table plus multiple customer
-- dimension tables. Each table stores the customer attribute history in a way
-- that supports Slowly Changing Dimension (SCD) Type 2 behavior.
--
-- LoadBatch: stores metadata for each ETL execution, including file name and status.
-- DimCustomerFullName: stores historical versions of customer full names.
-- DimCustomerEmail: stores historical versions of customer emails.
-- DimCustomerPhone: stores historical versions of customer phone numbers.
-- DimCustomerAddress: stores historical versions of customer addresses.
--
-- Why this pattern matters:
-- 1) every load is traceable to a specific batch
-- 2) attribute changes are preserved over time
-- 3) historical queries can show what was true at a certain point in time
--------------------------------------------------------------------------

IF OBJECT_ID(N'dbo.DimCustomerFullName', N'U') IS NOT NULL
    DROP TABLE dbo.DimCustomerFullName;
GO
IF OBJECT_ID(N'dbo.DimCustomerEmail', N'U') IS NOT NULL
    DROP TABLE dbo.DimCustomerEmail;
GO
IF OBJECT_ID(N'dbo.DimCustomerAddress', N'U') IS NOT NULL
    DROP TABLE dbo.DimCustomerAddress;
GO
IF OBJECT_ID(N'dbo.DimCustomerPhone', N'U') IS NOT NULL
    DROP TABLE dbo.DimCustomerPhone;
GO



-- CREATE dbo.LoadBatch - BEGIN
-- This table is the audit trail of each pipeline execution.
-- It records which file was loaded, when it was loaded, and whether the load
-- completed successfully or failed.
IF OBJECT_ID(N'dbo.LoadBatch', N'U') IS NOT NULL  
	DROP TABLE [dbo].LoadBatch;  
GO
CREATE TABLE LoadBatch(
	[LoadBatchId]				INT			IDENTITY(1,1)	NOT NULL,	/*Primary Key*/
	[ImportDate]			DATETIME					NOT NULL,	/*default( getdate() )*/
	[FileName]				VARCHAR(500)				NULL,
	[Message]				NVARCHAR(800)				NULL
	--PRIMARY KEY [LoadBatchId] Constraint
	CONSTRAINT [PK_LoadBatch_LoadBatchId] PRIMARY KEY CLUSTERED --> define name of constraint
	(
		[LoadBatchId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
-- DEFAULT (getdate()) Constraint for Address
ALTER TABLE [dbo].[LoadBatch] ADD CONSTRAINT [DF_LoadBatch_ImportDate] --> define name of constraint
DEFAULT (getdate()) FOR [ImportDate]
GO
-- CREATE dbo.LoadBatch - END



-- CREATE dbo.DimCustomerFullName - BEGIN
IF OBJECT_ID(N'dbo.DimCustomerFullName', N'U') IS NOT NULL  
	DROP TABLE [dbo].DimCustomerFullName;  
GO
CREATE TABLE DimCustomerFullName (
	[CustomerKey]			[int] IDENTITY(1,1)	NOT	NULL,	-- SURROGATE KEY
	[CustomerId]			[int]				NOT	NULL,	-- BUSINESS KEY
	[FullName]				[nvarchar](2000)		NULL,
	----------
	[EffectiveLoadBatchId]			[int]			NOT	NULL,	/*FOREIGN KEY REFERENCES LoadBatch(LoadBatchId)*/
	[ExpirationLoadBatchId]		[int]				NULL,	/*FOREIGN KEY REFERENCES LoadBatch(LoadBatchId)*/
	-- PRIMARY KEY Constraint
	CONSTRAINT [PK_DimCustomerFullName_CustomerKey]
		PRIMARY KEY ([CustomerKey]) --> define name of constraint
);
GO
-- FOREIGN KEY REFERENCES LoadBatch(LoadBatchId) Constraint
ALTER TABLE [dbo].[DimCustomerFullName]		WITH	NOCHECK		ADD	CONSTRAINT [FK__DimCustomerFullName_EffectiveLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
FOREIGN KEY([EffectiveLoadBatchId])
REFERENCES [dbo].[LoadBatch] ([LoadBatchId])
GO
ALTER TABLE [dbo].[DimCustomerFullName]			 	  CHECK			CONSTRAINT [FK__DimCustomerFullName_EffectiveLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
GO
-- FOREIGN KEY REFERENCES LoadBatch(LoadBatchId) Constraint
ALTER TABLE [dbo].[DimCustomerFullName]		WITH	NOCHECK		ADD	CONSTRAINT [FK__DimCustomerFullName_ExpirationLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
FOREIGN KEY([ExpirationLoadBatchId])
REFERENCES [dbo].[LoadBatch] ([LoadBatchId])
GO
ALTER TABLE [dbo].[DimCustomerFullName]				  CHECK			CONSTRAINT [FK__DimCustomerFullName_ExpirationLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
GO
-- CREATE dbo.DimCustomerFullName - END



-- CREATE dbo.DimCustomerEmail - BEGIN
IF OBJECT_ID(N'dbo.DimCustomerEmail', N'U') IS NOT NULL  
	DROP TABLE [dbo].DimCustomerEmail;  
GO
CREATE TABLE DimCustomerEmail (
	[EmailKey]					[int] IDENTITY(1,1)	NOT	NULL,	-- SURROGATE KEY
	[CustomerId]				[int]				NOT	NULL,	-- BUSINESS KEY
	[Email]						[nvarchar](250)			NULL,
	----------
	[EffectiveLoadBatchId]			[int]				NOT	NULL,	/*FOREIGN KEY REFERENCES LoadBatch(LoadBatchId)*/
	[ExpirationLoadBatchId]		[int]					NULL,	/*FOREIGN KEY REFERENCES LoadBatch(LoadBatchId)*/
	-- PRIMARY KEY Constraint
	CONSTRAINT [PK_DimCustomerEmail_EmailKey]
		PRIMARY KEY ([EmailKey]) --> define name of constraint
);
GO
-- FOREIGN KEY REFERENCES LoadBatch(LoadBatchId) Constraint
ALTER TABLE [dbo].[DimCustomerEmail]		WITH	NOCHECK		ADD	CONSTRAINT [FK__DimCustomerEmail_EffectiveLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
FOREIGN KEY([EffectiveLoadBatchId])
REFERENCES [dbo].[LoadBatch] ([LoadBatchId])
GO
ALTER TABLE [dbo].[DimCustomerEmail]			 	  CHECK			CONSTRAINT [FK__DimCustomerEmail_EffectiveLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
GO
-- FOREIGN KEY REFERENCES LoadBatch(LoadBatchId) Constraint
ALTER TABLE [dbo].[DimCustomerEmail]		WITH	NOCHECK		ADD	CONSTRAINT [FK__DimCustomerEmail_ExpirationLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
FOREIGN KEY([ExpirationLoadBatchId])
REFERENCES [dbo].[LoadBatch] ([LoadBatchId])
GO
ALTER TABLE [dbo].[DimCustomerEmail]				  CHECK			CONSTRAINT [FK__DimCustomerEmail_ExpirationLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
GO
-- CREATE dbo.DimCustomerEmail - END



-- CREATE dbo.DimCustomerAddress - BEGIN
IF OBJECT_ID(N'dbo.DimCustomerAddress', N'U') IS NOT NULL  
	DROP TABLE [dbo].DimCustomerAddress;  
GO
CREATE TABLE DimCustomerAddress (
	[AddressKey]			[int] IDENTITY(1,1)	NOT	NULL,	-- SURROGATE KEY
	[CustomerId]			[int]				NOT	NULL,	-- BUSINESS KEY
	[Address]				[nvarchar](2000)		NULL,
	[City]					[nvarchar](250)			NULL,
	[Province]				[nvarchar](250)			NULL,
	----------
	[EffectiveLoadBatchId]			[int]			NOT	NULL,	/*FOREIGN KEY REFERENCES LoadBatch(LoadBatchId)*/
	[ExpirationLoadBatchId]		[int]				NULL,	/*FOREIGN KEY REFERENCES LoadBatch(LoadBatchId)*/
	-- PRIMARY KEY Constraint
	CONSTRAINT [PK_DimCustomerAddress_AddressKey]
		PRIMARY KEY ([AddressKey]) --> define name of constraint
);
GO
-- FOREIGN KEY REFERENCES LoadBatch(LoadBatchId) Constraint
ALTER TABLE [dbo].[DimCustomerAddress]		WITH	NOCHECK		ADD	CONSTRAINT [FK__DimCustomerAddress_EffectiveLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
FOREIGN KEY([EffectiveLoadBatchId])
REFERENCES [dbo].[LoadBatch] ([LoadBatchId])
GO
ALTER TABLE [dbo].[DimCustomerAddress]			 	  CHECK			CONSTRAINT [FK__DimCustomerAddress_EffectiveLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
GO
-- FOREIGN KEY REFERENCES LoadBatch(LoadBatchId) Constraint
ALTER TABLE [dbo].[DimCustomerAddress]		WITH	NOCHECK		ADD	CONSTRAINT [FK__DimCustomerAddress_ExpirationLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
FOREIGN KEY([ExpirationLoadBatchId])
REFERENCES [dbo].[LoadBatch] ([LoadBatchId])
GO
ALTER TABLE [dbo].[DimCustomerAddress]				  CHECK			CONSTRAINT [FK__DimCustomerAddress_ExpirationLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
GO
-- CREATE dbo.DimCustomerAddress - END



-- CREATE dbo.DimCustomerPhone - BEGIN
IF OBJECT_ID(N'dbo.DimCustomerPhone', N'U') IS NOT NULL  
	DROP TABLE [dbo].DimCustomerPhone;  
GO
CREATE TABLE DimCustomerPhone (
	[PhoneKey]					[int] IDENTITY(1,1)	NOT	NULL,	-- SURROGATE KEY
	[CustomerId]				[int]				NOT	NULL,	-- BUSINESS KEY
	[Phone]						[nvarchar](2000)		NULL,
	----------
	[EffectiveLoadBatchId]		[int]			NOT	NULL,	/*FOREIGN KEY REFERENCES LoadBatch(LoadBatchId)*/
	[ExpirationLoadBatchId]		[int]				NULL	/*FOREIGN KEY REFERENCES LoadBatch(LoadBatchId)*/
	CONSTRAINT [PK_DimCustomerPhone_PhoneKey]
		PRIMARY KEY ([PhoneKey]) --> define name of constraint
);
GO
-- FOREIGN KEY REFERENCES LoadBatch(LoadBatchId) Constraint
ALTER TABLE [dbo].[DimCustomerPhone]		WITH	NOCHECK		ADD	CONSTRAINT [FK__DimCustomerPhone_EffectiveLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
FOREIGN KEY([EffectiveLoadBatchId])
REFERENCES [dbo].[LoadBatch] ([LoadBatchId])
GO
ALTER TABLE [dbo].[DimCustomerPhone]			 	  CHECK			CONSTRAINT [FK__DimCustomerPhone_EffectiveLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
GO
-- FOREIGN KEY REFERENCES LoadBatch(LoadBatchId) Constraint
ALTER TABLE [dbo].[DimCustomerPhone]		WITH	NOCHECK		ADD	CONSTRAINT [FK__DimCustomerPhone_ExpirationLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
FOREIGN KEY([ExpirationLoadBatchId])
REFERENCES [dbo].[LoadBatch] ([LoadBatchId])
GO
ALTER TABLE [dbo].[DimCustomerPhone]				  CHECK			CONSTRAINT [FK__DimCustomerPhone_ExpirationLoadBatchId__LoadBatch_LoadBatchId] --> define name of constraint
GO
-- CREATE dbo.DimCustomerPhone - END



-- nothing follows