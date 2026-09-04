-- ==========================================
-- Capital Markets Analytics Data Warehouse
-- Script 06: Index Optimization
-- Creates non-clustered indexes on Foreign Keys and date search paths.
-- Dependency: Executed after physical tables are built and populated.
-- ==========================================

-- ----------------------------------------------------------------------------
-- 1. Optimize core.Customers Lookups
-- Supports JOINs on AddressID and CustomerTypeID
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS IX_Customers_CustomerTypeID ON core.Customers;
CREATE NONCLUSTERED INDEX IX_Customers_CustomerTypeID 
ON core.Customers (CustomerTypeID);

DROP INDEX IF EXISTS IX_Customers_AddressID ON core.Customers;
CREATE NONCLUSTERED INDEX IX_Customers_AddressID 
ON core.Customers (AddressID);

-- ----------------------------------------------------------------------------
-- 2. Optimize core.Accounts Lookups
-- Supports JOINs on CustomerID, AccountTypeID, AccountStatusID, and BranchID
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS IX_Accounts_CustomerID ON core.Accounts;
CREATE NONCLUSTERED INDEX IX_Accounts_CustomerID 
ON core.Accounts (CustomerID);

DROP INDEX IF EXISTS IX_Accounts_AccountTypeID ON core.Accounts;
CREATE NONCLUSTERED INDEX IX_Accounts_AccountTypeID 
ON core.Accounts (AccountTypeID);

DROP INDEX IF EXISTS IX_Accounts_AccountStatusID ON core.Accounts;
CREATE NONCLUSTERED INDEX IX_Accounts_AccountStatusID 
ON core.Accounts (AccountStatusID);

-- ----------------------------------------------------------------------------
-- 3. Optimize core.Transactions Ledger Joins & Time-Series Filters
-- ----------------------------------------------------------------------------
-- Indexes origin and destination accounts for rapid double-entry lookups
DROP INDEX IF EXISTS IX_Transactions_AccountOriginID ON core.Transactions;
CREATE NONCLUSTERED INDEX IX_Transactions_AccountOriginID 
ON core.Transactions (AccountOriginID);

DROP INDEX IF EXISTS IX_Transactions_AccountDestinationID ON core.Transactions;
CREATE NONCLUSTERED INDEX IX_Transactions_AccountDestinationID 
ON core.Transactions (AccountDestinationID);

-- Covered index for time-series date filters (frequently queried in BI)
DROP INDEX IF EXISTS IX_Transactions_TransactionDate ON core.Transactions;
CREATE NONCLUSTERED INDEX IX_Transactions_TransactionDate 
ON core.Transactions (TransactionDate)
INCLUDE (Amount, TransactionTypeID); -- Includes payload columns to avoid bookmark lookups

DROP INDEX IF EXISTS IX_Transactions_BranchID ON core.Transactions;
CREATE NONCLUSTERED INDEX IX_Transactions_BranchID
ON core.Transactions (BranchID)

-- ----------------------------------------------------------------------------
-- 4. Optimize core.Loans Portfolio Exposure
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS IX_Loans_AccountID ON core.Loans;
CREATE NONCLUSTERED INDEX IX_Loans_AccountID 
ON core.Loans (AccountID);

DROP INDEX IF EXISTS IX_Loans_LoanStatusID ON core.Loans;
CREATE NONCLUSTERED INDEX IX_Loans_LoanStatusID 
ON core.Loans (LoanStatusID);
GO

-- ----------------------------------------------------------------------------
-- 5. Optimize core.Branches Address Lookup
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS IX_Branches_AddressID ON core.Branches;
CREATE NONCLUSTERED INDEX IX_Branches_AddressID
ON core.Branches (AddressID);
GO