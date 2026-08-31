USE CapitalMarketsDB;
GO

DROP TABLE IF EXISTS staging.RawTransactions;
GO

-- 1. Create Staging Table Definition
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawTransactions')
BEGIN
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
END
GO

-- 2. Bulk Insert CSV Data
BULK INSERT staging.RawTransactions 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\transactions.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

-- 3. Verify Data Load
SELECT TOP 5 * FROM staging.RawTransactions;

-- 4. Repeat for other staging tables as needed
-- Transaction Types Table --
DROP TABLE IF EXISTS staging.RawTransactionTypes;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawTransactionTypes')
BEGIN
    CREATE TABLE staging.RawTransactionTypes (
        TransactionTypeID NVARCHAR(200),
        Description NVARCHAR(255)
    );
END
GO

BULK INSERT staging.RawTransactionTypes 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\transaction_types.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

SELECT TOP 5 * FROM staging.RawTransactionTypes;

-- Loans Table -- 
DROP TABLE IF EXISTS staging.RawLoans;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawLoans')
BEGIN
    CREATE TABLE staging.RawLoans (
        LoanID NVARCHAR(200),
        AccountID NVARCHAR(200),
        LoanStatusID NVARCHAR(200),
        PrincipalAmount NVARCHAR(200),
        InterestRate NVARCHAR(200),
        StartDate NVARCHAR(200),
        EstimatedEndDate NVARCHAR(200)
    );
END
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

SELECT TOP 5 * FROM staging.RawLoans;

-- Loan Status Table --
DROP TABLE IF EXISTS staging.RawLoanStatuses;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawLoanStatuses')
BEGIN
    CREATE TABLE staging.RawLoanStatuses (
        LoanStatusID NVARCHAR(200),
        StatusName NVARCHAR(255)
    );
END
GO

BULK INSERT staging.RawLoanStatuses 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\loan_statuses.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

SELECT TOP 5 * FROM staging.RawLoanStatuses;

-- Customers --
DROP TABLE IF EXISTS staging.RawCustomers;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawCustomers')
BEGIN
    CREATE TABLE staging.RawCustomers (
        CustomerID NVARCHAR(200),
        FirstName NVARCHAR(255),
        LastName NVARCHAR(255),
        DateOfBirth NVARCHAR(200),
        AddressID NVARCHAR(200),
        CustomerTypeID NVARCHAR(200)
    );
END
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

SELECT TOP 5 * FROM staging.RawCustomers;

-- Customer Types Table --
DROP TABLE IF EXISTS staging.RawCustomerTypes;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawCustomerTypes')
BEGIN
    CREATE TABLE staging.RawCustomerTypes (
        CustomerTypeID NVARCHAR(200),
        TypeName NVARCHAR(255)
    );
END
GO

BULK INSERT staging.RawCustomerTypes 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\customer_types.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

SELECT TOP 5 * FROM staging.RawCustomerTypes;

-- Branches Table --
DROP TABLE IF EXISTS staging.RawBranches;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawBranches')
BEGIN
    CREATE TABLE staging.RawBranches (
        BranchID NVARCHAR(200),
        BranchName NVARCHAR(255),
        AddressID NVARCHAR(200)
    );
END
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

SELECT TOP 5 * FROM staging.RawBranches;

-- Addresses Table --
DROP TABLE IF EXISTS staging.RawAddresses;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawAddresses')
BEGIN
    CREATE TABLE staging.RawAddresses (
        AddressID NVARCHAR(200),
        Street NVARCHAR(255),
        City NVARCHAR(255),
        Country NVARCHAR(255),
    );
END
GO

BULK INSERT staging.RawAddresses 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\addresses.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

SELECT TOP 5 * FROM staging.RawAddresses;

-- Accounts Table --
DROP TABLE IF EXISTS staging.RawAccounts;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawAccounts')
BEGIN
    CREATE TABLE staging.RawAccounts (
        AccountID NVARCHAR(200),
        CustomerID NVARCHAR(200),
        AccountTypeID NVARCHAR(255),
        AccountStatusID NVARCHAR(255),
        Balance NVARCHAR(200),
        OpeningDate NVARCHAR(200)
    );
END
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

SELECT TOP 5 * FROM staging.RawAccounts;

-- Account Types Table --
DROP TABLE IF EXISTS staging.RawAccountTypes;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawAccountTypes')
BEGIN
    CREATE TABLE staging.RawAccountTypes (
        AccountTypeID NVARCHAR(200),
        TypeName NVARCHAR(255)
    );
END
GO

BULK INSERT staging.RawAccountTypes 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\account_types.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

SELECT TOP 5 * FROM staging.RawAccountTypes;

-- Account Statuses Table --
DROP TABLE IF EXISTS staging.RawAccountStatuses;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME = 'RawAccountStatuses')
BEGIN
    CREATE TABLE staging.RawAccountStatuses (
        AccountStatusID NVARCHAR(200),
        StatusName NVARCHAR(255)
    );
END
GO

BULK INSERT staging.RawAccountStatuses 
FROM "C:\Users\yabu01-82403ierunway\新しいフォルダー\capital-markets-analytics-sql\data\staging\account_statuses.csv"
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',  -- CSV comma separated
    ROWTERMINATOR = '0x0a',   -- Line break
    FORMAT = 'CSV'          
);
GO

SELECT TOP 5 * FROM staging.RawAccountStatuses;
