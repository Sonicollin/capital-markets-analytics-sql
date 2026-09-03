USE CapitalMarketsDB;
GO

-- ==========================================
-- 1. QUARANTINE ADDRESSES
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

-- Quarantine Address Records with Missing Primary Key --
INSERT INTO audit.QuarantineAddresses (
    AddressID,
    Street,
    City,
    Country,
    QuarantineReason
)
SELECT 
    AddressID,
    Street,
    City,
    Country,
    'Missing Primary Key: AddressID is NULL or Blank' AS QuarantineReason
FROM staging.RawAddresses
WHERE AddressID IS NULL OR TRIM(AddressID) = ''
GO

-- ==========================================
-- 2. QUARANTINE CUSTOMERS
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

-- Quarantine Customer Records with Missing Primary Key or Invalid DOB
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
        -- WHEN ParsedDOB IS NULL 
        --     THEN 'Data Format Violation: Unparseable DateOfBirth string'
        WHEN ParsedDOB > GETDATE() 
            THEN 'Future Date of Birth'
    END AS QuarantineReason
FROM CleanedCustomerDates
WHERE CustomerID IS NULL OR TRIM(CustomerID) = ''
--    OR ParsedDOB IS NULL
   OR ParsedDOB > GETDATE();
GO

-- Quarantine Customer Records with Invalid Address IDs --
INSERT INTO audit.QuarantineCustomers (
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID, QuarantineReason
)
SELECT
    CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID,
    CASE
        WHEN AddressID NOT IN (SELECT AddressID FROM staging.RawAddresses)
            THEN 'Referential Integrity Violation: AddressID does not exist in RawAddresses'
        -- ONLY quarantine if address has CRITICAL issues (not duplicates)
        WHEN AddressID IN (SELECT AddressID FROM audit.QuarantineAddresses WHERE QuarantineReason <> 'Duplicate Address ID')
            THEN 'Referential Integrity Violation: AddressID quarantined in QuarantineAddresses'
    END AS QuarantineReason
FROM staging.RawCustomers
WHERE AddressID NOT IN (SELECT AddressID FROM staging.RawAddresses)
   OR AddressID IN (SELECT AddressID FROM audit.QuarantineAddresses WHERE QuarantineReason <> 'Duplicate Address ID');
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

-- Quarantine Accounts with Missing AccountID, Orphan Records, Missing Balances, or Missing AccountTypeIDs
INSERT INTO audit.QuarantineAccounts (
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate, QuarantineReason
)
SELECT 
    AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate,
    CASE 
        WHEN AccountID IS NULL OR TRIM(AccountID) = '' 
            THEN 'Missing Primary Key: AccountID is NULL or Blank'
        WHEN CustomerID IS NULL OR TRIM(CustomerID) = ''
            THEN 'Missing Foreign Key: CustomerID is NULL or Blank'
        WHEN CustomerID NOT IN (SELECT CustomerID FROM staging.RawCustomers)
            THEN 'Referential Integrity Violation: CustomerID does not exist in RawCustomers'
        WHEN CustomerID IN (SELECT CustomerID FROM audit.QuarantineCustomers WHERE QuarantineReason <> 'Duplicate Customer ID')
            THEN 'Referential Integrity Violation: CustomerID quarantined in QuarantineCustomers'
        WHEN TRY_CAST(Balance AS DECIMAL(18,2)) IS NULL
            THEN 'Missing Balance'
        WHEN TRY_CAST(AccountTypeID AS INT) IS NULL
            THEN 'Missing AccountTypeID'
    END AS QuarantineReason
FROM staging.RawAccounts
WHERE AccountID IS NULL OR TRIM(AccountID) = ''
   OR CustomerID IS NULL OR TRIM(CustomerID) = ''
   OR CustomerID NOT IN (SELECT CustomerID FROM staging.RawCustomers)
   OR CustomerID IN (SELECT CustomerID FROM audit.QuarantineCustomers WHERE QuarantineReason <> 'Duplicate Customer ID')
   OR TRY_CAST(Balance AS DECIMAL(18,2)) IS NULL
   OR TRY_CAST(AccountTypeID AS INT) IS NULL;
GO

-- ==========================================
-- 4. QUARANTINE LOANS
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

-- Quarantine Loan Records with Missing LoanIDs, Orphan Records, NULL Principal Amounts,
-- Invalid Interest Amounts, and NULL StartDates --
INSERT INTO audit.QuarantineLoans (
    LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate, StartDate,
    EstimatedEndDate, QuarantineReason
)
SELECT
    LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate,
    StartDate, EstimatedEndDate,
    CASE
        WHEN LoanID IS NULL OR TRIM(LoanID) = ''
            THEN 'Missing Primary Key: LoanID is NULL or blank'
        WHEN AccountID IS NULL OR TRIM(AccountID) = ''
            THEN 'Missing Foreign Key: AccountID is NULL or blank'
        WHEN CAST(AccountID AS INT) NOT IN (SELECT AccountID FROM staging.RawAccounts)
            THEN 'Referential Integrity Violation: AccountID does not exist in RawAccounts'
        WHEN CAST(AccountID AS INT) IN (SELECT AccountID FROM audit.QuarantineAccounts WHERE QuarantineReason <> 'Duplicate Account ID')
            THEN 'Referential Integrity Violation: AccountID quarantined in QuarantineAccounts'
        WHEN TRY_CAST(PrincipalAmount AS DECIMAL(18,2)) IS NULL
            THEN 'Principal Amount is NULL'
        WHEN TRY_CAST(InterestRate AS DECIMAL(7,4)) IS NULL 
            THEN 'Interest Rate is NULL'
        WHEN TRY_CAST(InterestRate AS DECIMAL(7,4)) < 0
            THEN 'Interest Rate is negative'
        WHEN StartDate IS NULL OR TRIM(StartDate) = '' OR TRY_CAST(StartDate AS DATE) IS NULL
            THEN 'Start Date is NULL or blank'
        WHEN EstimatedEndDate IS NOT NULL AND TRIM(EstimatedEndDate) <> ''
            AND TRY_CAST(EstimatedEndDate AS DATE) < TRY_CAST(StartDate AS DATE)
            THEN 'Start Date is after Estimated End Date'
        ELSE NULL END AS QuarantineReason
FROM staging.RawLoans
WHERE 
    -- Primary Key Failure
    LoanID IS NULL OR TRIM(LoanID) = ''
    -- Foreign Key Check
    OR AccountID IS NULL OR TRIM(AccountID) = ''
    OR CAST(AccountID AS INT) NOT IN (SELECT AccountID FROM staging.RawAccounts)
    OR CAST(AccountID AS INT) IN (SELECT AccountID FROM audit.QuarantineAccounts WHERE QuarantineReason <> 'Duplicate Account ID')   
    -- Financial Metric Corruption
    OR TRY_CAST(PrincipalAmount AS DECIMAL(18,2)) IS NULL
    OR TRY_CAST(InterestRate AS DECIMAL(7,4)) IS NULL OR TRY_CAST(InterestRate AS DECIMAL(5,4)) < 0
    -- Origination Date Failure
    OR StartDate IS NULL OR TRIM(StartDate) = '' OR TRY_CAST(StartDate AS DATE) IS NULL
    -- Logical Timeline Check
    OR (
        EstimatedEndDate IS NOT NULL 
        AND TRIM(EstimatedEndDate) <> '' 
        AND TRY_CAST(EstimatedEndDate AS DATE) < TRY_CAST(StartDate AS DATE)
    );
GO

-- ==========================================
-- 5. QUARANTINE TRANSACTIONS
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


SELECT * FROM audit.QuarantineTransactions

SELECT QuarantineReason, COUNT(*) AS QuarantinedCount FROM audit.QuarantineAddresses GROUP BY QuarantineReason ORDER BY QuarantinedCount DESC;
SELECT QuarantineReason, COUNT(*) AS QuarantinedCount FROM audit.QuarantineCustomers GROUP BY QuarantineReason ORDER BY QuarantinedCount DESC;
SELECT QuarantineReason, COUNT(*) AS QuarantinedCount FROM audit.QuarantineAccounts GROUP BY QuarantineReason ORDER BY QuarantinedCount DESC;
SELECT QuarantineReason, COUNT(*) AS QuarantinedCount FROM audit.QuarantineTransactions GROUP BY QuarantineReason ORDER BY QuarantinedCount DESC;