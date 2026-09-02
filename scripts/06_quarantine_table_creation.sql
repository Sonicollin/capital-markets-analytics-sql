USE CapitalMarketsDB;
GO

-- ==========================================
-- 1. QUARANTINE TRANSACTIONS
-- ==========================================
DROP TABLE IF EXISTS audit.QuarantineTransactions;

CREATE TABLE audit.QuarantineTransactions (
        QuarantineID INT IDENTITY(1,1) PRIMARY KEY,
        TransactionID NVARCHAR(200),
        AccountOriginID NVARCHAR(200),
        AccountDestinationID NVARCHAR(200),
        TransactionTypeID NVARCHAR(200),
        Amount NVARCHAR(200),
        TransactionDate NVARCHAR(200),
        BranchID NVARCHAR(200),
        Description NVARCHAR(255),
        QuarantineReason NVARCHAR(255),
        QuarantineDate DATETIME DEFAULT GETDATE()
);
GO

-- Quarantine Transactions with Missing Dates --
INSERT INTO audit.QuarantineTransactions (
    TransactionID,
    AccountOriginID,
    AccountDestinationID,
    TransactionTypeID,
    Amount,
    TransactionDate,
    BranchID,
    Description,
    QuarantineReason
)
SELECT 
    TransactionID,
    AccountOriginID,
    AccountDestinationID,
    TransactionTypeID,
    Amount,
    TransactionDate,
    BranchID,
    Description,
    'Missing Transaction Date' AS QuarantineReason
FROM staging.RawTransactions
WHERE TransactionDate IS NULL OR TransactionDate = '';
GO

-- MODIFIED: Only quarantine transactions if they reference accounts with CRITICAL data issues
INSERT INTO audit.QuarantineTransactions (
    TransactionID, AccountOriginID, AccountDestinationID, TransactionTypeID,
    Amount, TransactionDate, BranchID, Description, QuarantineReason
)
SELECT DISTINCT
    TransactionID, AccountOriginID, AccountDestinationID, TransactionTypeID,
    Amount, TransactionDate, BranchID, Description,
    CASE
        WHEN AccountOriginID NOT IN (SELECT AccountID FROM staging.RawAccounts)
            THEN 'Referential Integrity Violation: AccountOriginID does not exist in RawAccounts'
        WHEN AccountDestinationID NOT IN (SELECT AccountID FROM staging.RawAccounts)
            THEN 'Referential Integrity Violation: AccountDestinationID does not exist in RawAccounts'
        -- ONLY quarantine if account has CRITICAL issues (not duplicates, not cascaded from customer)
        WHEN AccountOriginID IN (SELECT AccountID FROM audit.QuarantineAccounts 
                                 WHERE QuarantineReason IN (
                                    'Missing Primary Key: AccountID is NULL or Blank',
                                    'OpeningDate is missing',
                                    'Data Format Violation: Unparseable OpeningDate string',
                                    'Logical Business Violation: Future OpeningDate detected'
                                 ))
            THEN 'Referential Integrity Violation: AccountOriginID has critical data quality issues'
        WHEN AccountDestinationID IN (SELECT AccountID FROM audit.QuarantineAccounts 
                                      WHERE QuarantineReason IN (
                                        'Missing Primary Key: AccountID is NULL or Blank',
                                        'OpeningDate is missing',
                                        'Data Format Violation: Unparseable OpeningDate string',
                                        'Logical Business Violation: Future OpeningDate detected'
                                      ))
            THEN 'Referential Integrity Violation: AccountDestinationID has critical data quality issues'
            ELSE 'Referential Integrity Violation: AccountDestinationID is quarantined in QuarantineAccounts'
    END AS QuarantineReason
FROM staging.RawTransactions
WHERE TransactionDate IS NOT NULL AND TransactionDate <> ''
  AND (
    AccountOriginID NOT IN (SELECT AccountID FROM staging.RawAccounts)
    OR AccountDestinationID NOT IN (SELECT AccountID FROM staging.RawAccounts)
    OR AccountOriginID IN (SELECT AccountID FROM audit.QuarantineAccounts 
                           WHERE QuarantineReason NOT IN ('Duplicate Account ID', 'Referential Integrity Violation: CustomerID is quarantined in QuarantineCustomers'))
    OR AccountDestinationID IN (SELECT AccountID FROM audit.QuarantineAccounts 
                               WHERE QuarantineReason NOT IN ('Duplicate Account ID', 'Referential Integrity Violation: CustomerID is quarantined in QuarantineCustomers'))
  );

-- ==========================================
-- 2. QUARANTINE LOANS
-- ==========================================
DROP TABLE IF EXISTS audit.QuarantineLoans;

CREATE TABLE audit.QuarantineLoans (
        QuarantineID INT IDENTITY(1,1) PRIMARY KEY,
        LoanID NVARCHAR(200),
        AccountID NVARCHAR(200),
        LoanStatusID NVARCHAR(200),
        PrincipalAmount NVARCHAR(200),
        InterestRate NVARCHAR(200),
        StartDate NVARCHAR(200),
        EstimatedEndDate NVARCHAR(200),
        QuarantineReason NVARCHAR(255),
        QuarantineDate DATETIME DEFAULT GETDATE()
);
GO

-- Quarantine Loan Records with Missing Start Dates --
INSERT INTO audit.QuarantineLoans (
    LoanID,
    AccountID,
    LoanStatusID,
    PrincipalAmount,
    InterestRate,
    StartDate,
    EstimatedEndDate,
    QuarantineReason
)
SELECT
    LoanID,
    AccountID,
    LoanStatusID,
    PrincipalAmount,
    InterestRate,
    StartDate,
    EstimatedEndDate,
    'Missing Start Date' AS QuarantineReason
FROM staging.RawLoans
WHERE (StartDate IS NULL OR StartDate = '');
GO

-- Quarantine Loan Records with duplicate Loan IDs --
INSERT INTO audit.QuarantineLoans (
    LoanID,
    AccountID,
    LoanStatusID,
    PrincipalAmount,
    InterestRate,
    StartDate,
    EstimatedEndDate,
    QuarantineReason
)
SELECT DISTINCT
    LoanID,
    AccountID,
    LoanStatusID,
    PrincipalAmount,
    InterestRate,
    StartDate,
    EstimatedEndDate,
    'Duplicate Loan ID' AS QuarantineReason
FROM staging.RawLoans
WHERE LoanID IN (
    SELECT LoanID
    FROM staging.RawLoans
    GROUP BY LoanID
    HAVING COUNT(*) > 1
)
GO

-- Quarantine Loan Records with End Date earlier than Start Date
INSERT INTO audit.QuarantineLoans (
    LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate,
    StartDate, EstimatedEndDate, QuarantineReason
)
SELECT
    LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate,
    StartDate, EstimatedEndDate,
    'End Date Earlier than Start Date' AS QuarantineReason
FROM staging.RawLoans
WHERE TRY_CAST(EstimatedEndDate AS DATE) < TRY_CAST(StartDate AS DATE);
GO

-- Quarantine Loan Records with Invalid Account IDs --
INSERT INTO audit.QuarantineLoans (
    LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate,
    StartDate, EstimatedEndDate, QuarantineReason
)
SELECT DISTINCT
    LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate,
    StartDate, EstimatedEndDate,
    CASE
        WHEN AccountID NOT IN (SELECT AccountID FROM staging.RawAccounts)
            THEN 'Referential Integrity Violation: AccountID does not exist in RawAccounts'
        -- ONLY quarantine if account has CRITICAL issues (not duplicates, not cascaded from customer)
        WHEN AccountID IN (SELECT AccountID FROM audit.QuarantineAccounts 
                           WHERE QuarantineReason IN (
                              'Missing Primary Key: AccountID is NULL or Blank',
                              'OpeningDate is missing',
                              'Data Format Violation: Unparseable OpeningDate string',
                              'Logical Business Violation: Future OpeningDate detected'
                           ))
            THEN 'Referential Integrity Violation: AccountID has critical data quality issues'
    END AS QuarantineReason
FROM staging.RawLoans
WHERE AccountID NOT IN (SELECT AccountID FROM staging.RawAccounts)
   OR AccountID IN (SELECT AccountID FROM audit.QuarantineAccounts 
                    WHERE QuarantineReason NOT IN ('Duplicate Account ID', 'Referential Integrity Violation: CustomerID is quarantined in QuarantineCustomers'));
GO

-- ==========================================
-- 3. QUARANTINE ACCOUNTS
-- ==========================================
DROP TABLE IF EXISTS audit.QuarantineAccounts;

CREATE TABLE audit.QuarantineAccounts (
        QuarantineID INT IDENTITY(1,1) PRIMARY KEY,
        AccountID NVARCHAR(200),
        CustomerID NVARCHAR(200),
        AccountTypeID NVARCHAR(200),
        AccountStatusID NVARCHAR(200),
        Balance NVARCHAR(200),
        OpeningDate NVARCHAR(200),
        QuarantineReason NVARCHAR(255),
        QuarantineDate DATETIME DEFAULT GETDATE()
);
GO

-- Quarantine Account Records with Duplicate Account IDs --
INSERT INTO audit.QuarantineAccounts (
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate, QuarantineReason
)
SELECT DISTINCT
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate,
    'Duplicate Account ID' AS QuarantineReason
FROM staging.RawAccounts
WHERE AccountID IN (
    SELECT AccountID
    FROM staging.RawAccounts
    GROUP BY AccountID
    HAVING COUNT(*) > 1
);
GO

-- Move records with missing dates to the Quarantine Table
WITH CleanedAccountDates AS (
    SELECT 
        AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate,
        TRY_CAST(
            CASE 
                WHEN OpeningDate LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
                 AND CAST(SUBSTRING(OpeningDate, 6, 2) AS INT) > 12
                    THEN CONCAT(
                        SUBSTRING(OpeningDate, 1, 4), '-', 
                        SUBSTRING(OpeningDate, 9, 2), '-', 
                        SUBSTRING(OpeningDate, 6, 2)
                    )
                ELSE NULLIF(TRIM(OpeningDate), 'NaT')
            END AS DATE
        ) AS ParsedOpeningDate
    FROM staging.RawAccounts
)
INSERT INTO audit.QuarantineAccounts (
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate, QuarantineReason
)
SELECT 
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate,
    CASE 
        WHEN AccountID IS NULL OR TRIM(AccountID) = '' 
            THEN 'Missing Primary Key: AccountID is NULL or Blank'
        WHEN OpeningDate IS NULL OR TRIM(OpeningDate) = '' 
            THEN 'OpeningDate is missing'
        WHEN ParsedOpeningDate IS NULL 
            THEN 'Data Format Violation: Unparseable OpeningDate string'
        WHEN ParsedOpeningDate > GETDATE() 
            THEN 'Logical Business Violation: Future OpeningDate detected'
        ELSE 'Data Quality Issue: Unknown reason'
    END AS QuarantineReason
FROM CleanedAccountDates
WHERE AccountID IS NULL OR TRIM(AccountID) = ''
   OR OpeningDate IS NULL OR TRIM(OpeningDate) = ''
   OR ParsedOpeningDate IS NULL
   OR ParsedOpeningDate > GETDATE();
GO

-- Quarantine Account Records with Invalid Customer IDs --
INSERT INTO audit.QuarantineAccounts (
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate, QuarantineReason
)
SELECT DISTINCT
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate,
    CASE
        WHEN CustomerID NOT IN (SELECT CustomerID FROM staging.RawCustomers)
            THEN 'Referential Integrity Violation: CustomerID does not exist in RawCustomers'
        -- ONLY quarantine if customer has CRITICAL issues (not duplicates, not cascaded from address)
        WHEN CustomerID IN (SELECT CustomerID FROM audit.QuarantineCustomers 
                            WHERE QuarantineReason IN (
                               'Missing Primary Key: CustomerID is NULL or Blank',
                               'Both First and Last Name are blank',
                               'DateOfBirth is missing/NaT',
                               'Data Format Violation: Unparseable DateOfBirth string',
                               'Future Date of Birth'
                            ))
            THEN 'Referential Integrity Violation: CustomerID quarantined in QuarantineCustomers'
    END AS QuarantineReason
FROM staging.RawAccounts
WHERE CustomerID NOT IN (SELECT CustomerID FROM staging.RawCustomers)
   OR CustomerID IN (SELECT CustomerID FROM audit.QuarantineCustomers 
                     WHERE QuarantineReason NOT IN ('Duplicate Customer ID', 'Referential Integrity Violation: AddressID is quarantined in QuarantineAddresses'));
GO

-- ==========================================
-- 4. QUARANTINE CUSTOMERS
-- ==========================================
DROP TABLE IF EXISTS audit.QuarantineCustomers;

CREATE TABLE audit.QuarantineCustomers (
        QuarantineID INT IDENTITY(1,1) PRIMARY KEY,
        CustomerID NVARCHAR(200),
        FirstName NVARCHAR(200),
        LastName NVARCHAR(200),
        DateOfBirth NVARCHAR(200),
        AddressID NVARCHAR(200),
        CustomerTypeID NVARCHAR(200),
        QuarantineReason NVARCHAR(255),
        QuarantineDate DATETIME DEFAULT GETDATE()
);
GO

-- Quarantine Customer Records with Duplicate Customer IDs --
INSERT INTO audit.QuarantineCustomers (
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID, QuarantineReason
)
SELECT DISTINCT
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID,
    'Duplicate Customer ID' AS QuarantineReason
FROM staging.RawCustomers
WHERE CustomerID IN (
    SELECT CustomerID
    FROM staging.RawCustomers
    GROUP BY CustomerID
    HAVING COUNT(*) > 1
);
GO

-- Quarantine Customer Records with Missing Primary Key, Missing Names or Invalid DOB
WITH CleanedCustomerDates AS (
    SELECT 
        CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID,
        TRY_CAST(
            CASE
            -- Swap month and day if the month is greater than 12 (assuming the format is YYYY-DD-MM) -- 
                WHEN DateOfBirth LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
                 AND CAST(SUBSTRING(DateOfBirth, 6, 2) AS INT) > 12
                    THEN CONCAT(
                        SUBSTRING(DateOfBirth, 1, 4), '-', 
                        SUBSTRING(DateOfBirth, 9, 2), '-', 
                        SUBSTRING(DateOfBirth, 6, 2)
                    )
                ELSE NULLIF(TRIM(DateOfBirth), 'NaT')
            END AS DATE
        ) AS ParsedDOB
    FROM staging.RawCustomers
)
INSERT INTO audit.QuarantineCustomers (
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID, QuarantineReason
)
SELECT 
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID,
    CASE 
        WHEN CustomerID IS NULL OR TRIM(CustomerID) = '' 
            THEN 'Missing Primary Key: CustomerID is NULL or Blank'
        WHEN (FirstName IS NULL OR TRIM(FirstName) = '') AND (LastName IS NULL OR TRIM(LastName) = '') 
            THEN 'Both First and Last Name are blank'
        WHEN DateOfBirth IS NULL OR TRIM(DateOfBirth) = '' OR TRIM(DateOfBirth) = 'NaT' 
            THEN 'DateOfBirth is missing/NaT'
        WHEN ParsedDOB IS NULL 
            THEN 'Data Format Violation: Unparseable DateOfBirth string'
        WHEN ParsedDOB > GETDATE() 
            THEN 'Future Date of Birth'
    END AS QuarantineReason
FROM CleanedCustomerDates
WHERE CustomerID IS NULL OR TRIM(CustomerID) = ''
   OR ((FirstName IS NULL OR TRIM(FirstName) = '') AND (LastName IS NULL OR TRIM(LastName) = ''))
   OR DateOfBirth IS NULL OR TRIM(DateOfBirth) = '' OR TRIM(DateOfBirth) = 'NaT'
   OR ParsedDOB IS NULL
   OR ParsedDOB > GETDATE();
GO

-- Quarantine Customer Records with Invalid Address IDs --
INSERT INTO audit.QuarantineCustomers (
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID, QuarantineReason
)
SELECT DISTINCT
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID,
    CASE
        WHEN AddressID NOT IN (SELECT AddressID FROM staging.RawAddresses)
            THEN 'Referential Integrity Violation: AddressID does not exist in RawAddresses'
        -- ONLY quarantine if address has CRITICAL issues (not duplicates)
        WHEN AddressID IN (SELECT AddressID FROM audit.QuarantineAddresses 
                           WHERE QuarantineReason IN (
                              'Missing Primary Key: AddressID is NULL or Blank',
                              'Missing Country'
                           ))
            THEN 'Referential Integrity Violation: AddressID quarantined in QuarantineAddresses'
    END AS QuarantineReason
FROM staging.RawCustomers
WHERE AddressID NOT IN (SELECT AddressID FROM staging.RawAddresses)
   OR AddressID IN (SELECT AddressID FROM audit.QuarantineAddresses 
                    WHERE QuarantineReason NOT IN ('Duplicate Address ID'));
GO

-- ==========================================
-- 5. QUARANTINE ADDRESSES
-- ========================================== 
DROP TABLE IF EXISTS audit.QuarantineAddresses;

CREATE TABLE audit.QuarantineAddresses (
        QuarantineID INT IDENTITY(1,1) PRIMARY KEY,
        AddressID NVARCHAR(200),
        Street NVARCHAR(200),
        City NVARCHAR(200),
        Country NVARCHAR(200),
        QuarantineReason NVARCHAR(255),
        QuarantineDate DATETIME DEFAULT GETDATE()
);
GO

-- Quarantine Duplicate Address Records --
WITH RankedAddresses AS (
    SELECT
        AddressID, Street, City, Country,
        ROW_NUMBER() OVER (
            PARTITION BY AddressID 
            ORDER BY
                CASE WHEN Street IS NOT NULL AND TRIM(Street) <> '' THEN 1 ELSE 2 END,
                AddressID
        ) AS RowNum
    FROM staging.RawAddresses
    WHERE AddressID IS NOT NULL AND TRIM(AddressID) <> ''
)
INSERT INTO audit.QuarantineAddresses (
    AddressID, Street, City, Country, QuarantineReason
)
SELECT DISTINCT
    AddressID, Street, City, Country,
    'Duplicate Address ID' AS QuarantineReason
FROM RankedAddresses
WHERE RowNum > 1; -- Captures 2nd, 3rd, etc. occurrences of duplicate AddressIDs
GO

-- Quarantine Address Records with Missing Primary Key or Country --
INSERT INTO audit.QuarantineAddresses (
    AddressID,
    Street,
    City,
    Country,
    QuarantineReason
)
SELECT 
    AddressID,
    COALESCE(NULLIF(TRIM(Street), ''), 'UNKNOWN') AS Street,
    COALESCE(NULLIF(TRIM(City), ''), 'UNKNOWN') AS City,
    COALESCE(NULLIF(TRIM(Country), ''), 'UNKNOWN') AS Country,
    'Missing Primary Key: AddressID is NULL or Blank' AS QuarantineReason
FROM staging.RawAddresses
WHERE AddressID IS NULL OR TRIM(AddressID) = ''
GO
