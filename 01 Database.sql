/*
--------------------------------------------------------------------------
Author				: Nowell Tiongco
Create Date			: August 2026
Description			: Create tables
--------------------------------------------------------------------------
*/
USE [master];
GO

-- CREATE DATABASE - BEGIN
IF DB_ID('CustomerETL') IS NULL
BEGIN
    CREATE DATABASE [CustomerETL];
END
GO
-- CREATE DATABASE - END



-- nothing follows