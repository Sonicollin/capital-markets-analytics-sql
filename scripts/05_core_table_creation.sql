-- ==========================================
-- Capital Markets Analytics Data Warehouse
-- Script 05: Core Tables Initialized and loaded 
-- Loads clean, deduplicated entries into core data tables. Also creates robust reference tables with proper datatypes.
-- Duplicates are sent to the quarantine tables under the audit schema. 
-- ==========================================

USE CapitalMarketsDB;
GO

-- Drop Security Policies
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TransactionsBranchPolicy')
    DROP SECURITY POLICY sec.TransactionsBranchPolicy;
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'AccountsBranchPolicy')
    DROP SECURITY POLICY sec.AccountsBranchPolicy;
GO

-- Drop child tables with FK references first
DROP TABLE IF EXISTS core.Transactions;
DROP TABLE IF EXISTS core.Loans;
DROP TABLE IF EXISTS core.Accounts;
DROP TABLE IF EXISTS core.Customers;
DROP TABLE IF EXISTS core.Branches;
-- Drop parent tables next
DROP TABLE IF EXISTS core.Addresses;
DROP TABLE IF EXISTS core.CustomerTypes;
DROP TABLE IF EXISTS core.LoanStatuses;
DROP TABLE IF EXISTS core.TransactionTypes;
DROP TABLE IF EXISTS core.AccountStatuses;
DROP TABLE IF EXISTS core.AccountTypes;
GO

-- ============================================================================
-- CORE REFERENCE TABLES CREATION & LOAD
-- ============================================================================

-- 1. Account Statuses
IF OBJECT_ID('core.AccountStatuses', 'U') IS NULL
    CREATE TABLE core.AccountStatuses (
        AccountStatusID INT PRIMARY KEY,
        StatusName NVARCHAR(50) NOT NULL,
    );
GO

INSERT INTO core.AccountStatuses (AccountStatusID, StatusName)
SELECT 
    CAST(AccountStatusID AS INT),
    TRIM(StatusName)
FROM staging.RawAccountStatuses;
GO

-- 2. Account Types
IF OBJECT_ID('core.AccountTypes', 'U') IS NULL
    CREATE TABLE core.AccountTypes (
        AccountTypeID INT PRIMARY KEY,
        TypeName NVARCHAR(50) NOT NULL
    );
GO

INSERT INTO core.AccountTypes (AccountTypeID, TypeName)
SELECT 
    CAST(AccountTypeID AS INT),
    TRIM(TypeName)
FROM staging.RawAccountTypes;
GO

-- 3. Addresses
CREATE TABLE core.Addresses (
    AddressID INT PRIMARY KEY,
    Street NVARCHAR(150) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    Country NVARCHAR(100) NOT NULL
);

-- Log redundant Address records into QuarantineAddresses table
WITH RankedAddresses AS (
    SELECT
        AddressID, Street, City, Country,
        ROW_NUMBER() OVER (PARTITION BY AddressID 
            ORDER BY 
                CASE WHEN Street IS NOT NULL AND TRIM(Street) <> '' THEN 1 ELSE 2 END
        ) AS RowNum
    FROM staging.RawAddresses
    WHERE AddressID IS NOT NULL AND TRIM(AddressID) <> ''
)
INSERT INTO audit.QuarantineAddresses (
    AddressID, Street, City, Country, QuarantineReason
)
SELECT r.AddressID, r.Street, r.City, r.Country, 'Duplicate Address ID' AS QuarantineReason
FROM RankedAddresses r
WHERE RowNum > 1 -- Selects the duplicate occurrences of each AddressID
-- Anti-Join Guard: Do not insert if already logged in quarantine
  AND NOT EXISTS (
      SELECT 1 
      FROM audit.QuarantineAddresses q 
      WHERE q.AddressID = r.AddressID
  );
-- Load the unique Address records into the core.Addresses table
WITH RankedAddresses AS (
    SELECT
        AddressID, Street, City, Country,
        ROW_NUMBER() OVER (PARTITION BY AddressID 
            ORDER BY 
                CASE WHEN Street IS NOT NULL AND TRIM(Street) <> '' THEN 1 ELSE 2 END
        ) AS RowNum
    FROM staging.RawAddresses
    WHERE AddressID IS NOT NULL AND TRIM(AddressID) <> ''
)
INSERT INTO core.Addresses (AddressID, Street, City, Country)
SELECT 
    CAST(AddressID AS INT) AS AddressID,
    COALESCE(NULLIF(TRIM(Street), ''), 'Unknown') AS Street,
    COALESCE(NULLIF(TRIM(City), ''), 'Unknown') AS City,
    -- Standardize Country names --
    CASE 
        WHEN TRIM(Country) IN ('United States', 'US', 'U.S.', 'U.S.A.', 'USA', 'United State', 'United States of America') 
            THEN 'United States'
        WHEN TRIM(Country) LIKE '%United%' OR TRIM(Country) LIKE '%US%' OR TRIM(Country) LIKE '%States%'
            THEN 'United States'
        ELSE COALESCE(NULLIF(TRIM(Country), ''), 'United States') 
    END AS Country
FROM RankedAddresses
WHERE RowNum = 1; -- Selects the first occurrence of each AddressID 

-- 4. Customer Types
IF OBJECT_ID('core.CustomerTypes', 'U') IS NULL
    CREATE TABLE core.CustomerTypes (
        CustomerTypeID INT PRIMARY KEY,
        TypeName NVARCHAR(50) NOT NULL
    );
GO

INSERT INTO core.CustomerTypes (CustomerTypeID, TypeName)
SELECT 
    CAST(CustomerTypeID AS INT),
    TRIM(TypeName)
FROM staging.RawCustomerTypes;
GO

-- 5. Loan Statuses
IF OBJECT_ID('core.LoanStatuses', 'U') IS NULL
    CREATE TABLE core.LoanStatuses (
        LoanStatusID INT PRIMARY KEY,
        StatusName NVARCHAR(50) NOT NULL,
    );
GO

INSERT INTO core.LoanStatuses (LoanStatusID, StatusName)
SELECT 
    CAST(LoanStatusID AS INT),
    TRIM(StatusName)
FROM staging.RawLoanStatuses;
GO

-- 6. Transaction Types
IF OBJECT_ID('core.TransactionTypes', 'U') IS NULL
    CREATE TABLE core.TransactionTypes (
        TransactionTypeID INT PRIMARY KEY,
        TypeName NVARCHAR(50) NOT NULL
    );
INSERT INTO core.TransactionTypes (TransactionTypeID, TypeName)
SELECT 
    CAST(TransactionTypeID AS INT),
    TRIM(TypeName)
FROM staging.RawTransactionTypes;
GO

-- 7. Branches
IF OBJECT_ID('core.Branches', 'U') IS NULL
    CREATE TABLE core.Branches (
        BranchID INT PRIMARY KEY,
        BranchName NVARCHAR(100) NOT NULL,
        AddressID INT NOT NULL
        FOREIGN KEY (AddressID) REFERENCES core.Addresses(AddressID)
    );
GO

INSERT INTO core.Branches (BranchID, BranchName, AddressID)
SELECT 
    CAST(BranchID AS INT),
    TRIM(BranchName),
    CAST(AddressID AS INT)
FROM staging.RawBranches;
GO

-- 8. Customers
CREATE TABLE core.Customers (
    CustomerID INT PRIMARY KEY,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    DateOfBirth DATE NOT NULL,
    AddressID INT NOT NULL,
    CustomerTypeID INT NOT NULL,
    FOREIGN KEY (AddressID) REFERENCES core.Addresses(AddressID),
    FOREIGN KEY (CustomerTypeID) REFERENCES core.CustomerTypes(CustomerTypeID)
);
-- Handle Duplicates --

-- Log the redundant Customer records into QuarantineCustomers table
WITH RankedCustomers AS (
    SELECT
        CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID,
        ROW_NUMBER() OVER (PARTITION BY CustomerID 
            ORDER BY 
                CASE WHEN DateOfBirth IS NOT NULL AND TRIM(DateOfBirth) <> 'NaT' THEN 1 
                     WHEN LastName IS NOT NULL AND TRIM(LastName) <> '' THEN 2
                     ELSE 3 END
        ) AS RowNum
    FROM staging.RawCustomers
    WHERE CustomerID IS NOT NULL AND TRIM(CustomerID) <> ''
)
INSERT INTO audit.QuarantineCustomers (
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID, QuarantineReason
)
SELECT r.CustomerID, r.FirstName, r.LastName, r.DateOfBirth, r.AddressID, r.CustomerTypeID, 'Duplicate Customer ID'
FROM RankedCustomers r
WHERE RowNum > 1
-- Anti-Join Guard: Do not insert if already logged in quarantine
AND NOT EXISTS (
    SELECT 1
    FROM audit.QuarantineCustomers q 
    WHERE q.CustomerID = r.CustomerID
);

-- Load the unique Customer records into Core Customers table
WITH RankedCustomers AS (
    SELECT
        CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID,
        ROW_NUMBER() OVER (PARTITION BY CustomerID 
            ORDER BY 
                CASE WHEN DateOfBirth IS NOT NULL AND TRIM(DateOfBirth) <> 'NaT' THEN 1 
                     WHEN LastName IS NOT NULL AND TRIM(LastName) <> '' THEN 2
                     ELSE 3 END
        ) AS RowNum
    FROM staging.RawCustomers
    WHERE CustomerID IS NOT NULL AND TRIM(CustomerID) <> ''
)
INSERT INTO core.Customers (
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID
)
SELECT 
    CAST(CustomerID AS INT) AS CustomerID,
    COALESCE(NULLIF(TRIM(FirstName), ''), 'Unknown') AS FirstName,
    COALESCE(NULLIF(TRIM(LastName), ''), 'Unknown') AS LastName,
    TRY_CAST(
        CASE
            -- Handle cases where the month and day are swapped in the date string 
            WHEN DateOfBirth LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
             AND CAST(SUBSTRING(DateOfBirth, 6, 2) AS INT) > 12
                THEN CONCAT(
                    SUBSTRING(DateOfBirth, 1, 4), '-', 
                    SUBSTRING(DateOfBirth, 9, 2), '-', 
                    SUBSTRING(DateOfBirth, 6, 2)
                )
            ELSE COALESCE(NULLIF(TRIM(DateOfBirth), 'NaT'), '1900-01-01') -- Default to a known date if invalid
        END AS DATE
    ) AS DateOfBirth,
    CAST(AddressID AS INT) AS AddressID,
    CAST(CustomerTypeID AS INT) AS CustomerTypeID
FROM RankedCustomers
WHERE RowNum = 1 -- Selects the first occurrence of each CustomerID
AND CustomerID NOT IN (
    SELECT CAST(CustomerID AS INT) 
    FROM audit.QuarantineCustomers 
    WHERE CustomerID IS NOT NULL AND TRIM(CustomerID) <> '' AND QuarantineReason <> 'Duplicate Customer ID'
);

-- 9. Accounts
CREATE TABLE core.Accounts (
    AccountID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    AccountTypeID INT NOT NULL,
    AccountStatusID INT NOT NULL,
    Balance DECIMAL(18,2) NOT NULL,
    OpeningDate DATE NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES core.Customers(CustomerID),
    FOREIGN KEY (AccountTypeID) REFERENCES core.AccountTypes(AccountTypeID),
    FOREIGN KEY (AccountStatusID) REFERENCES core.AccountStatuses(AccountStatusID)
);

-- Handle duplicates --

-- Log the redundant Account records into QuarantineAccounts table
WITH RankedAccounts AS (
    SELECT
        AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate,
        ROW_NUMBER() OVER (PARTITION BY AccountID
            ORDER BY 
                CASE WHEN CustomerID IS NOT NULL AND TRIM(CustomerID) <> '' THEN 1 
                     WHEN BALANCE IS NOT NULL THEN 2
                     ELSE 3 END
        ) AS RowNum
    FROM staging.RawAccounts
    WHERE AccountID IS NOT NULL AND TRIM(AccountID) <> ''
)
INSERT INTO audit.QuarantineAccounts (
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate, QuarantineReason
)
SELECT r.AccountID, r.CustomerID, r.AccountTypeID, r.AccountStatusID, r.Balance, r.OpeningDate, 'Duplicate Account ID'
FROM RankedAccounts r
WHERE RowNum > 1
-- Anti-Join Guard: Do not insert if already logged in quarantine
AND NOT EXISTS (
    SELECT 1
    FROM audit.QuarantineAccounts q 
    WHERE q.AccountID = r.AccountID
);

-- Load the unique Account records into Core Accounts table
WITH RankedAccounts AS (
    SELECT
        AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate,
        ROW_NUMBER() OVER (PARTITION BY AccountID
            ORDER BY 
                CASE WHEN CustomerID IS NOT NULL AND TRIM(CustomerID) <> '' THEN 1 
                     WHEN BALANCE IS NOT NULL THEN 2
                     ELSE 3 END
        ) AS RowNum
    FROM staging.RawAccounts
    WHERE AccountID IS NOT NULL AND TRIM(AccountID) <> ''
)
INSERT INTO core.Accounts (
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate
)
SELECT 
    CAST(AccountID AS INT) AS AccountID,
    CAST(CustomerID AS INT) AS CustomerID,
    CAST(AccountTypeID AS INT) AS AccountTypeID,
    CAST(AccountStatusID AS INT) AS AccountStatusID,
    CAST(Balance AS DECIMAL(18,2)) AS Balance,
    TRY_CAST(
        CASE
            -- Handle cases where the month and day are swapped in the date string 
            WHEN OpeningDate LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
             AND CAST(SUBSTRING(OpeningDate, 6, 2) AS INT) > 12
                THEN CONCAT(
                    SUBSTRING(OpeningDate, 1, 4), '-', 
                    SUBSTRING(OpeningDate, 9, 2), '-', 
                    SUBSTRING(OpeningDate, 6, 2)
                )
            ELSE COALESCE(NULLIF(TRIM(OpeningDate), 'NaT'), '1900-01-01') -- Default to a known date if invalid
        END AS DATE
    ) AS OpeningDate
FROM RankedAccounts
WHERE RowNum = 1
    AND AccountID NOT IN (
        SELECT AccountID FROM audit.QuarantineAccounts
        WHERE AccountID IS NOT NULL AND TRIM(AccountID) <> '' AND QuarantineReason <> 'Duplicate Account ID'
    );
GO

-- 10. Loans
CREATE TABLE core.Loans (
    LoanID INT PRIMARY KEY,
    AccountID INT NOT NULL,
    LoanStatusID INT NOT NULL,
    PrincipalAmount DECIMAL(18,2) NOT NULL,
    InterestRate DECIMAL(7,4) NOT NULL,
    StartDate DATE NOT NULL,
    EstimatedEndDate DATE NOT NULL,
    FOREIGN KEY (AccountID) REFERENCES core.Accounts(AccountID),
    FOREIGN KEY (LoanStatusID) REFERENCES core.LoanStatuses(LoanStatusID)
);

-- Handle duplicates --

-- Log the redundant Account records into QuarantineAccounts table
WITH RankedLoans AS (
    SELECT
        LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate, StartDate, EstimatedEndDate,
        ROW_NUMBER() OVER (PARTITION BY AccountID
            ORDER BY 
                CASE WHEN AccountID IS NOT NULL AND TRIM(AccountID) <> '' THEN 1 
                     WHEN PrincipalAmount IS NOT NULL THEN 2
                     ELSE 3 END
        ) AS RowNum
    FROM staging.RawLoans
    WHERE LoanID IS NOT NULL AND TRIM(LoanID) <> ''
)
INSERT INTO audit.QuarantineLoans (
    LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate, StartDate, EstimatedEndDate, QuarantineReason
)
SELECT r.LoanID, r.AccountID, r.LoanStatusID, r.PrincipalAmount, r.InterestRate, r.StartDate, r.EstimatedEndDate, 'Duplicate Loan ID'
FROM RankedLoans r
WHERE RowNum > 1
-- Anti-Join Guard: Do not insert if already logged in quarantine
AND NOT EXISTS (
    SELECT 1
    FROM audit.QuarantineLoans q 
    WHERE q.LoanID = r.LoanID
);

-- Load the unique Account records into Core Accounts table
WITH RankedLoans AS (
    SELECT
        LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate, StartDate, EstimatedEndDate,
        ROW_NUMBER() OVER (PARTITION BY LoanID
            ORDER BY 
                CASE WHEN AccountID IS NOT NULL AND TRIM(AccountID) <> '' THEN 1 
                     WHEN PrincipalAmount IS NOT NULL THEN 2
                     ELSE 3 END
        ) AS RowNum
    FROM staging.RawLoans
    WHERE LoanID IS NOT NULL AND TRIM(AccountID) <> ''
)
INSERT INTO core.Loans (
    LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate, StartDate, EstimatedEndDate
)
SELECT 
    CAST(LoanID AS INT) AS LoanID,
    CAST(AccountID AS INT) AS AccountID,
    CAST(LoanStatusID AS INT) AS LoanStatusID,
    CAST(PrincipalAmount AS DECIMAL(18,2)) AS PrincipalAmount,
    CAST(InterestRate AS DECIMAL(5,4)) AS InterestRate,
    TRY_CAST(
        CASE
            -- Handle cases where the month and day are swapped in the date string 
            WHEN StartDate LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
             AND CAST(SUBSTRING(StartDate, 6, 2) AS INT) > 12
                THEN CONCAT(
                    SUBSTRING(StartDate, 1, 4), '-', 
                    SUBSTRING(StartDate, 9, 2), '-', 
                    SUBSTRING(StartDate, 6, 2)
                )
            ELSE COALESCE(NULLIF(TRIM(StartDate), 'NaT'), '1900-01-01') -- Default to a known date if invalid
        END AS DATE
    ) AS StartDate,
    TRY_CAST(
        CASE
            -- Handle cases where the month and day are swapped in the date string 
            WHEN EstimatedEndDate LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
             AND CAST(SUBSTRING(EstimatedEndDate, 6, 2) AS INT) > 12
                THEN CONCAT(
                    SUBSTRING(EstimatedEndDate, 1, 4), '-', 
                    SUBSTRING(EstimatedEndDate, 9, 2), '-', 
                    SUBSTRING(EstimatedEndDate, 6, 2)
                )
            ELSE COALESCE(NULLIF(TRIM(EstimatedEndDate), 'NaT'), '1900-01-01') -- Default to a known date if invalid
        END AS DATE
    ) AS EstimatedEndDate
FROM RankedLoans
WHERE RowNum = 1 AND LoanID NOT IN (
    SELECT LoanID FROM audit.QuarantineLoans WHERE LoanID IS NOT NULL AND TRIM(LoanID) <> '' AND QuarantineReason <> 'Duplicate Loan ID' 
)

-- 11. Transactions
CREATE TABLE core.Transactions (
    TransactionID INT PRIMARY KEY,
    AccountOriginID INT NOT NULL,
    AccountDestinationID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    TransactionDate DATETIME2 NOT NULL,
    BranchID INT,
    Description NVARCHAR(255),
    FOREIGN KEY (AccountOriginID) REFERENCES core.Accounts(AccountID),
    FOREIGN KEY (AccountDestinationID) REFERENCES core.Accounts(AccountID),
    FOREIGN KEY (TransactionTypeID) REFERENCES core.TransactionTypes(TransactionTypeID),
    FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID)
);

-- Handle duplicates --

-- Log the redundant Transaction records into QuarantineTransactions table
WITH RankedTransactions AS (
    SELECT
        TransactionID, AccountOriginID, AccountDestinationID, TransactionTypeID, Amount, TransactionDate, BranchID, Description,
        ROW_NUMBER() OVER (PARTITION BY TransactionID
            ORDER BY 
                CASE WHEN TransactionDate IS NOT NULL AND TRIM(TransactionDate) <> '' THEN 1 
                     ELSE 2 END
        ) AS RowNum
    FROM staging.RawTransactions
    WHERE TransactionID IS NOT NULL AND TRIM(TransactionID) <> ''
)
INSERT INTO audit.QuarantineTransactions (
    TransactionID, AccountOriginID, AccountDestinationID, TransactionTypeID, Amount, TransactionDate, BranchID, 
    Description, QuarantineReason
)
SELECT r.TransactionID, r.AccountOriginID, r.AccountDestinationID, r.TransactionTypeID, r.Amount, r.TransactionDate, r.BranchID, 
        r.Description, 'Duplicate Transaction ID'
FROM RankedTransactions r
WHERE RowNum > 1
-- Anti-Join Guard: Do not insert if already logged in quarantine
AND NOT EXISTS (
    SELECT 1
    FROM audit.QuarantineTransactions q 
    WHERE q.TransactionID = r.TransactionID
);

-- Load the unique Transaction records into Core Transactions table
WITH RankedTransactions AS (
    SELECT
        TransactionID, AccountOriginID, AccountDestinationID, TransactionTypeID, Amount, TransactionDate, BranchID, Description,
        ROW_NUMBER() OVER (PARTITION BY TransactionID
            ORDER BY 
                CASE WHEN TransactionDate IS NOT NULL AND TRIM(TransactionDate) <> '' THEN 1 
                     ELSE 2 END
        ) AS RowNum
    FROM staging.RawTransactions
    WHERE TransactionID IS NOT NULL AND TRIM(TransactionID) <> ''
)
INSERT INTO core.Transactions (
    TransactionID, AccountOriginID, AccountDestinationID, TransactionTypeID, Amount, TransactionDate, BranchID, Description
)
SELECT 
    CAST(TransactionID AS INT) AS TransactionID,
    CAST(AccountOriginID AS INT) AS AccountOriginID,
    CAST(AccountDestinationID AS INT) AS AccountDestinationID,
    CAST(TransactionTypeID AS INT) AS TransactionTypeID,
    CAST(Amount AS DECIMAL(18,2)) AS Amount,
    TRY_CAST(
        CASE
            -- Handle cases where the month and day are swapped in the date string 
            WHEN TransactionDate LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
             AND CAST(SUBSTRING(TransactionDate, 6, 2) AS INT) > 12
                THEN CONCAT(
                    SUBSTRING(TransactionDate, 1, 4), '-', 
                    SUBSTRING(TransactionDate, 9, 2), '-', 
                    SUBSTRING(TransactionDate, 6, 2)
                )
            ELSE COALESCE(NULLIF(TRIM(TransactionDate), 'NaT'), '1900-01-01') -- Default to a known date if invalid
        END AS DATE
    ) AS TransactionDate,
    COALESCE(CAST(BranchID AS INT), -1) AS BranchID,
    COALESCE(Description, 'Unknown') AS Description
FROM RankedTransactions
WHERE RowNum = 1 AND TransactionID NOT IN (
    SELECT TransactionID FROM audit.QuarantineTransactions WHERE TransactionID IS NOT NULL AND TRIM(TransactionID) <> '' AND QuarantineReason <> 'Duplicate Transaction ID' 
)


















