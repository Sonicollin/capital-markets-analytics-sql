USE CapitalMarketsDB;
GO

-- Quarantine bad transactions
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

-- Move records with missing dates to the Quarantine Table
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

-- Quarantine bad loan records -- 
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

-- Move records with missing dates to the Quarantine Loans Table
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
    'Missing Start or Estimated End Date' AS QuarantineReason
FROM staging.RawLoans
WHERE (StartDate IS NULL OR StartDate = '') 
    OR (EstimatedEndDate IS NULL OR EstimatedEndDate = '');
GO

-- Quarantine records with duplicate Loan IDs
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

-- Loan records with End Date earlier than Start Date
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
    'End Date Earlier than Start Date' AS QuarantineReason
FROM staging.RawLoans
WHERE TRY_CAST(EstimatedEndDate AS DATE) < TRY_CAST(StartDate AS DATE);
GO

-- Quarantine bad customer records
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

-- Quarantine Customer Records with Missing Primary Key, Missing Names or Invalid DOB
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
        WHEN TRY_CAST(
                CASE 
                -- Check for YYYY-DD-MM pattern (where middle number is a day > 12)
                WHEN DateOfBirth LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
                AND CAST(SUBSTRING(DateOfBirth, 6, 2) AS INT) > 12
                    THEN CONCAT(
                        SUBSTRING(DateOfBirth, 1, 4), '-', 
                        SUBSTRING(DateOfBirth, 9, 2), '-', 
                        SUBSTRING(DateOfBirth, 6, 2)
                    )
                -- Fallback for standard formatting (dots to dashes, 'NaT' handling)
                ELSE DateOfBirth
                END AS DATE) IS NULL
            THEN 'Data Format Violation: Unparseable DateOfBirth string'
        WHEN TRY_CAST(DateOfBirth AS DATE) > GETDATE() 
            THEN 'Logical Business Violation: Future DateOfBirth detected'
    END AS QuarantineReason
FROM staging.RawCustomers
WHERE CustomerID IS NULL OR TRIM(CustomerID) = ''
   OR ((FirstName IS NULL OR TRIM(FirstName) = '') AND (LastName IS NULL OR TRIM(LastName) = ''))
   OR DateOfBirth IS NULL OR TRIM(DateOfBirth) = '' OR TRIM(DateOfBirth) = 'NaT'
   OR TRY_CAST(
                CASE 
                -- Check for YYYY-DD-MM pattern (where middle number is a day > 12)
                WHEN DateOfBirth LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
                AND CAST(SUBSTRING(DateOfBirth, 6, 2) AS INT) > 12
                    THEN CONCAT(
                        SUBSTRING(DateOfBirth, 1, 4), '-', 
                        SUBSTRING(DateOfBirth, 9, 2), '-', 
                        SUBSTRING(DateOfBirth, 6, 2)
                    )
                -- Fallback for standard formatting (dots to dashes, 'NaT' handling)
                ELSE DateOfBirth
                END AS DATE) IS NULL
   OR TRY_CAST(CASE 
                -- Check for YYYY-DD-MM pattern (where middle number is a day > 12)
                WHEN DateOfBirth LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
                AND CAST(SUBSTRING(DateOfBirth, 6, 2) AS INT) > 12
                    THEN CONCAT(
                        SUBSTRING(DateOfBirth, 1, 4), '-', 
                        SUBSTRING(DateOfBirth, 9, 2), '-', 
                        SUBSTRING(DateOfBirth, 6, 2)
                    )
                -- Fallback for standard formatting (dots to dashes, 'NaT' handling)
                ELSE DateOfBirth
                END AS DATE) > GETDATE();
GO

-- 3. Verification Query: Inspect Cleaned DOB Output
-- SELECT 
--     CustomerID,
--     ISNULL(NULLIF(TRIM(FirstName), ''), 'Unknown') AS FirstName,
--     ISNULL(NULLIF(TRIM(LastName), ''), 'Unknown') AS LastName,
--     DateOfBirth,
--     -- Pre-clean strings ('NaT' to NULL, '.' to '-') then cast cleanly to DATE
--     TRY_CAST(
--                 CASE 
--                 -- Check for YYYY-DD-MM pattern (where middle number is a day > 12)
--                 WHEN DateOfBirth LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
--                 AND CAST(SUBSTRING(DateOfBirth, 6, 2) AS INT) > 12
--                     THEN CONCAT(
--                         SUBSTRING(DateOfBirth, 1, 4), '-', 
--                         SUBSTRING(DateOfBirth, 9, 2), '-', 
--                         SUBSTRING(DateOfBirth, 6, 2)
--                     )
--                 -- Fallback for standard formatting (dots to dashes, 'NaT' handling)
--                 ELSE DateOfBirth
--                 END AS DATE) AS CleanDateOfBirth
-- FROM staging.RawCustomers
-- WHERE CustomerID NOT IN (SELECT CustomerID FROM audit.QuarantineCustomers)
-- GO

-- Quarantine Accounts Table --
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

-- Move records with missing dates to the Quarantine Table
INSERT INTO audit.QuarantineAccounts (
    AccountID,
    CustomerID,
    AccountTypeID,
    AccountStatusID,
    Balance,
    OpeningDate,
    QuarantineReason
)
SELECT 
    AccountID,
    CustomerID,
    AccountTypeID,
    AccountStatusID,
    Balance,
    OpeningDate,
    CASE 
        WHEN AccountID IS NULL OR TRIM(AccountID) = '' 
            THEN 'Missing Primary Key: AccountID is NULL or Blank'
        WHEN OpeningDate IS NULL OR TRIM(OpeningDate) = '' 
            THEN 'OpeningDate is missing'
        WHEN TRY_CAST(
                CASE 
                -- Check for YYYY-DD-MM pattern (where middle number is a day > 12)
                WHEN OpeningDate LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
                AND CAST(SUBSTRING(OpeningDate, 6, 2) AS INT) > 12
                    THEN CONCAT(
                        SUBSTRING(OpeningDate, 1, 4), '-', 
                        SUBSTRING(OpeningDate, 9, 2), '-', 
                        SUBSTRING(OpeningDate, 6, 2)
                    )
                -- Fallback for standard formatting (dots to dashes, 'NaT' handling)
                ELSE OpeningDate
                END AS DATE) IS NULL
            THEN 'Data Format Violation: Unparseable OpeningDate string'
        WHEN TRY_CAST(OpeningDate AS DATE) > GETDATE() 
            THEN 'Logical Business Violation: Future OpeningDate detected'
    END AS QuarantineReason
FROM staging.RawAccounts
WHERE AccountID IS NULL OR TRIM(AccountID) = ''
    OR OpeningDate IS NULL OR TRIM(OpeningDate) = ''
    OR TRY_CAST(
                CASE 
                -- Check for YYYY-DD-MM pattern (where middle number is a day > 12)
                WHEN OpeningDate LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
                AND CAST(SUBSTRING(OpeningDate, 6, 2) AS INT) > 12
                    THEN CONCAT(
                        SUBSTRING(OpeningDate, 1, 4), '-', 
                        SUBSTRING(OpeningDate, 9, 2), '-', 
                        SUBSTRING(OpeningDate, 6, 2)
                    )
                -- Fallback for standard formatting (dots to dashes, 'NaT' handling)
                ELSE OpeningDate
                END AS DATE) IS NULL
    OR TRY_CAST(CASE 
                -- Check for YYYY-DD-MM pattern (where middle number is a day > 12)
                WHEN OpeningDate LIKE '[1-2][0-9][0-9][0-9]-[0-3][0-9]-[0-1][0-9]'
                AND CAST(SUBSTRING(OpeningDate, 6, 2) AS INT) > 12
                    THEN CONCAT(
                        SUBSTRING(OpeningDate, 1, 4), '-', 
                        SUBSTRING(OpeningDate, 9, 2), '-', 
                        SUBSTRING(OpeningDate, 6, 2)
                    )
                -- Fallback for standard formatting (dots to dashes, 'NaT' handling)
                ELSE OpeningDate
                END AS DATE) > GETDATE();
GO

-- Quarantine Addresses Table -- 
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
    CASE 
        WHEN AddressID IS NULL OR TRIM(AddressID) = '' 
            THEN 'Missing Primary Key: AddressID is NULL or Blank'
        WHEN Street IS NULL OR TRIM(Street) = '' 
            THEN 'Missing Street'
        WHEN City IS NULL OR TRIM(City) = '' 
            THEN 'Missing City'
        WHEN Country IS NULL OR TRIM(Country) = '' 
            THEN 'Missing Country'
    END AS QuarantineReason
FROM staging.RawAddresses
WHERE AddressID IS NULL OR TRIM(AddressID) = ''
    OR Street IS NULL OR TRIM(Street) = ''
    OR City IS NULL OR TRIM(City) = ''
    OR Country IS NULL OR TRIM(Country) = '';
GO


