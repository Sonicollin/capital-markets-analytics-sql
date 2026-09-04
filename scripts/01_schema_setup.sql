-- ==========================================
-- Capital Markets Analytics Data Warehouse
-- Script 01: Database & Schema Initialization
-- ==========================================

-- 1. Create Database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'CapitalMarketsDB')
BEGIN
    CREATE DATABASE CapitalMarketsDB;
    PRINT 'Database CapitalMarketsDB created successfully.';
END
GO

-- 2. Switch context to the new database
USE CapitalMarketsDB;
GO

-- 3. Create Staging Schema for raw CSV imports
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'staging')
BEGIN
    EXEC('CREATE SCHEMA staging');
    PRINT 'Schema [staging] created successfully.';
END
GO

-- 5. Create Audit Schema for data quality checks
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'audit')
BEGIN
    EXEC('CREATE SCHEMA audit');
    PRINT 'Schema [audit] created successfully.';
END

-- 6. Create Core Schema for core data structures
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'core')
BEGIN
    EXEC('CREATE SCHEMA core');
    PRINT 'Schema [core] created successfully.';
END
GO

-- 7. Create Analytics Schema for processed data
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'analytics')
BEGIN
    EXEC('CREATE SCHEMA analytics');
    PRINT 'Schema [analytics] created successfully.';
END

-- 8. Create Security schema for Row-Level Security
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'sec')
BEGIN
    EXEC('CREATE SCHEMA sec');
END
GO