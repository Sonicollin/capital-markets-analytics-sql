-- ==========================================
-- Capital Markets Analytics Data Warehouse
-- Script 02: Raw Data Staging Table Initialization and Load
-- ==========================================

USE CapitalMarketsDB;
GO

DROP TABLE IF EXISTS staging.RawTransactions;
GO

-- 1. Create Staging Table Definition
CREATE TABLE staging.RawTransactions (
        TransactionID NVARCHAR(200),
        AccountOriginID NVARCHAR(200),
        AccountDestinationID NVARCHAR(200),
        TransactionTypeID NVARCHAR(200),
        Amount NVARCHAR(200),
        TransactionDate NVARCHAR(200),
        BranchID NVARCHAR(200),
        Description NVARCHAR(255)
);
GO

BULK INSERT staging.RawTransactions 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\transactions.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

-- Loans Table -- 
DROP TABLE IF EXISTS staging.RawLoans;
GO

CREATE TABLE staging.RawLoans (
        LoanID NVARCHAR(200),
        AccountID NVARCHAR(200),
        LoanStatusID NVARCHAR(200),
        PrincipalAmount NVARCHAR(200),
        InterestRate NVARCHAR(200),
        StartDate NVARCHAR(200),
        EstimatedEndDate NVARCHAR(200)
    );
GO

BULK INSERT staging.RawLoans 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\loans.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

-- Customers --
DROP TABLE IF EXISTS staging.RawCustomers;
GO

CREATE TABLE staging.RawCustomers (
        CustomerID NVARCHAR(200),
        FirstName NVARCHAR(255),
        LastName NVARCHAR(255),
        DateOfBirth NVARCHAR(200),
        AddressID NVARCHAR(200),
        CustomerTypeID NVARCHAR(200)
    );
GO

BULK INSERT staging.RawCustomers 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\customers.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

-- Branches Table --
DROP TABLE IF EXISTS staging.RawBranches;
GO

CREATE TABLE staging.RawBranches (
        BranchID NVARCHAR(200),
        BranchName NVARCHAR(255),
        AddressID NVARCHAR(200)
);
GO

BULK INSERT staging.RawBranches 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\branches.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

-- Accounts Table --
DROP TABLE IF EXISTS staging.RawAccounts;
GO

CREATE TABLE staging.RawAccounts (
        AccountID NVARCHAR(200),
        CustomerID NVARCHAR(200),
        AccountTypeID NVARCHAR(255),
        AccountStatusID NVARCHAR(255),
        Balance NVARCHAR(200),
        OpeningDate NVARCHAR(200)
);
GO

BULK INSERT staging.RawAccounts 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\accounts.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

