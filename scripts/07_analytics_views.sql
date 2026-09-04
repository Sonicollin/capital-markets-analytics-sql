-- ============================================================================
-- Capital Markets Analytics Data Warehouse
-- Script 07: Analytics Views
-- DESCRIPTION: Analytics consumption layer joining core entities and lookup dimensions.
-- Recreates Gold Layer reporting views (v_CustomerOverview, v_TransactionLedger, etc.).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VIEW 1: v_CustomerOverview
-- Provides a 360-degree customer view, resolving addresses and customer types.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('analytics.v_CustomerOverview', 'V') IS NOT NULL
    DROP VIEW analytics.v_CustomerOverview;
GO

CREATE VIEW analytics.v_CustomerOverview AS
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.FirstName + ' ' + c.LastName AS FullName,
    c.DateOfBirth,
    DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) - 
        CASE 
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, c.DateOfBirth, GETDATE()), c.DateOfBirth) > GETDATE() 
            THEN 1 ELSE 0 
        END AS Age,
    ct.TypeName AS CustomerType,
    a.Street,
    a.City,
    a.Country
FROM core.Customers c
LEFT JOIN core.CustomerTypes ct 
    ON c.CustomerTypeID = ct.CustomerTypeID
LEFT JOIN core.Addresses a 
    ON c.AddressID = a.AddressID;
GO
-- ----------------------------------------------------------------------------
-- VIEW 2: v_AccountPortfolio
-- Summarizes customer accounts with resolved types, statuses, and branch locations.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('analytics.v_AccountPortfolio', 'V') IS NOT NULL
    DROP VIEW analytics.v_AccountPortfolio;
GO

CREATE VIEW analytics.v_AccountPortfolio AS
SELECT 
    acc.AccountID,
    acc.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    act.TypeName AS AccountType,
    acs.StatusName AS AccountStatus,
    acc.Balance,
    acc.OpeningDate
FROM core.Accounts acc
INNER JOIN core.Customers c 
    ON acc.CustomerID = c.CustomerID
LEFT JOIN core.AccountTypes act 
    ON acc.AccountTypeID = act.AccountTypeID
LEFT JOIN core.AccountStatuses acs 
    ON acc.AccountStatusID = acs.AccountStatusID
GO
-- ----------------------------------------------------------------------------
-- VIEW 3: v_TransactionLedger
-- Complete ledger joining origin/destination accounts and transaction classifications.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('analytics.v_TransactionLedger', 'V') IS NOT NULL
    DROP VIEW analytics.v_TransactionLedger;
GO

CREATE VIEW analytics.v_TransactionLedger AS
SELECT 
    t.TransactionID,
    t.TransactionDate,
    tt.TypeName AS TransactionType,
    t.Amount,
    
    -- Origin Account Details
    t.AccountOriginID,
    origCust.FirstName + ' ' + origCust.LastName AS OriginCustomerName,
    
    -- Destination Account Details
    t.AccountDestinationID,
    destCust.FirstName + ' ' + destCust.LastName AS DestinationCustomerName,
    
    b.BranchName AS ProcessingBranch,
    t.Description
FROM core.Transactions t
LEFT JOIN core.TransactionTypes tt 
    ON t.TransactionTypeID = tt.TransactionTypeID
LEFT JOIN core.Accounts origAcc 
    ON t.AccountOriginID = origAcc.AccountID
LEFT JOIN core.Customers origCust 
    ON origAcc.CustomerID = origCust.CustomerID
LEFT JOIN core.Accounts destAcc 
    ON t.AccountDestinationID = destAcc.AccountID
LEFT JOIN core.Customers destCust 
    ON destAcc.CustomerID = destCust.CustomerID
LEFT JOIN core.Branches b 
    ON t.BranchID = b.BranchID;
GO
-- ----------------------------------------------------------------------------
-- VIEW 4: v_LoanExposure
-- Evaluates loan portfolios, interest yield exposure, and customer balance ties.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('analytics.v_LoanExposure', 'V') IS NOT NULL
    DROP VIEW analytics.v_LoanExposure;
GO

CREATE VIEW analytics.v_LoanExposure AS
SELECT 
    l.LoanID,
    l.AccountID,
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS BorrowerName,
    ls.StatusName AS LoanStatus,
    l.PrincipalAmount,
    l.InterestRate,
    -- Estimated Annualized Interest Income
    CAST(l.PrincipalAmount * l.InterestRate AS DECIMAL(18,2)) AS EstimatedAnnualInterestIncome,
    l.StartDate,
    l.EstimatedEndDate,
    DATEDIFF(DAY, l.StartDate, COALESCE(l.EstimatedEndDate, GETDATE())) AS LoanDurationDays
FROM core.Loans l
INNER JOIN core.Accounts acc 
    ON l.AccountID = acc.AccountID
INNER JOIN core.Customers c 
    ON acc.CustomerID = c.CustomerID
LEFT JOIN core.LoanStatuses ls 
    ON l.LoanStatusID = ls.LoanStatusID;
GO