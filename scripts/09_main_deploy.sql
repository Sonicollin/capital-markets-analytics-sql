-- ============================================================================
-- SCRIPT: main_deploy.sql
-- DESCRIPTION: Master Orchestration Script for Financial Data Warehouse.
-- USAGE: Execute in SSMS with SQLCMD Mode enabled (Query -> SQLCMD Mode).
-- ============================================================================

:setvar DatabaseName "CapitalMarketsDB"
:setvar ScriptPath "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\scripts\"
USE $(DatabaseName);
GO

-- Set session options for strict ANSI compliance and error handling
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '====================================================================';
PRINT 'STARTING PIPELINE DEPLOYMENT: ' + CAST(GETDATE() AS VARCHAR(30));
PRINT '====================================================================';
GO


-- ----------------------------------------------------------------------------
-- STEP 1: SCHEMAS & INFRASTRUCTURE SETUP
-- Creates staging, core, audit, analytics, and sec schemas.
-- ----------------------------------------------------------------------------
PRINT '--> Step 1: Initializing Schemas and Infrastructure...';
:r $(ScriptPath)01_schema_setup.sql
GO


-- ----------------------------------------------------------------------------
-- STEP 2: STAGING DDL & INGESTION
-- Creates raw staging tables and ingests source landing files.
-- ----------------------------------------------------------------------------
PRINT '--> Step 2: Loading Staging Data (staging schema)...';
:r $(ScriptPath)02_staging_load.sql
GO


-- ----------------------------------------------------------------------------
-- STEP 3: CORE REFERENCE TABLES
-- Loads static lookup dimensions (AccountTypes, CustomerTypes, Branches, etc.).
-- Dependency: Required BEFORE Core and Analytics joins.
-- ----------------------------------------------------------------------------
PRINT '--> Step 3: Populating Reference Dimensions (core schema)...';
:r $(ScriptPath)03_reference_tables.sql
GO


-- ----------------------------------------------------------------------------
-- STEP 4: QUARANTINE DDL & INITIALIZATION
-- Creates audit tables for hard failures and quality exceptions.
-- ----------------------------------------------------------------------------
PRINT '--> Step 4: Initializing Audit & Quarantine Schema (audit schema)...';
:r $(ScriptPath)04_quarantine_tables.sql
GO


-- ----------------------------------------------------------------------------
-- STEP 5: CORE ENTITIES & UNIFIED QUARANTINE LOAD
-- Loads clean, deduplicated entities (Addresses, Customers, Accounts, Loans, Transactions)
-- into core schema while passing duplicates/corrupt rows into audit.
-- Dependency Order: Addresses -> Customers -> Accounts -> Loans -> Transactions.
-- ----------------------------------------------------------------------------
PRINT '--> Step 5: Processing & Loading Core Entities (core & audit schemas)...';
:r $(ScriptPath)05_core_table_creation.sql
GO


-- ----------------------------------------------------------------------------
-- STEP 6: INDEX OPTIMIZATION
-- Creates non-clustered indexes on Foreign Keys and date search paths.
-- Dependency: Executed after physical tables are built and populated.
-- ----------------------------------------------------------------------------
PRINT '--> Step 6: Deploying Non-Clustered Indexes...';
:r $(ScriptPath)06_optimize_index.sql
GO


-- ----------------------------------------------------------------------------
-- STEP 7: ANALYTICS CONSUMPTION LAYER
-- Recreates Gold Layer reporting views (v_CustomerOverview, v_TransactionLedger, etc.).
-- ----------------------------------------------------------------------------
PRINT '--> Step 7: Creating Analytics Reporting Views (analytics schema)...';
:r $(ScriptPath)07_analytics_views.sql
GO


-- ----------------------------------------------------------------------------
-- STEP 8: ROW-LEVEL SECURITY (RLS)
-- Deploys predicate functions and security policies on core entities.
-- ----------------------------------------------------------------------------
PRINT '--> Step 8: Applying Row-Level Security Policies (sec schema)...';
:r $(ScriptPath)08_security_rls.sql
GO


PRINT '====================================================================';
PRINT 'PIPELINE DEPLOYMENT COMPLETE: ' + CAST(GETDATE() AS VARCHAR(30));
PRINT '====================================================================';
GO