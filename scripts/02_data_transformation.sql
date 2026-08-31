USE CapitalMarketsDB;
GO

-- Quarantine bad transactions
DROP TABLE IF EXISTS audit.QuarantineTransactions;

SELECT * FROM sys.tables WHERE name = 'QuarantineTransactions' AND schema_id = SCHEMA_ID('audit');
BEGIN
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
END
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

SELECT * FROM sys.tables WHERE name = 'QuarantineLoans' AND schema_id = SCHEMA_ID('audit');
BEGIN
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
END
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

SELECT * FROM sys.tables WHERE name = 'QuarantineCustomers' AND schema_id = SCHEMA_ID('audit');
BEGIN
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
END
GO

-- Quarantine Unusable Customer Records
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
        WHEN TRY_CAST(REPLACE(TRIM(DateOfBirth), '.', '-') AS DATE) IS NULL 
            THEN 'Data Format Violation: Unparseable DateOfBirth string'
        WHEN TRY_CAST(REPLACE(TRIM(DateOfBirth), '.', '-') AS DATE) > GETDATE() 
            THEN 'Logical Business Violation: Future DateOfBirth detected'
    END AS QuarantineReason
FROM staging.RawCustomers
WHERE CustomerID IS NULL OR TRIM(CustomerID) = ''
   OR ((FirstName IS NULL OR TRIM(FirstName) = '') AND (LastName IS NULL OR TRIM(LastName) = ''))
   OR DateOfBirth IS NULL OR TRIM(DateOfBirth) = '' OR TRIM(DateOfBirth) = 'NaT'
   OR TRY_CAST(REPLACE(TRIM(DateOfBirth), '.', '-') AS DATE) IS NULL
   OR TRY_CAST(REPLACE(TRIM(DateOfBirth), '.', '-') AS DATE) > GETDATE();
GO

-- 3. Verification Query: Inspect Cleaned DOB Output
SELECT 
    CustomerID,
    ISNULL(NULLIF(TRIM(FirstName), ''), 'Unknown') AS FirstName,
    ISNULL(NULLIF(TRIM(LastName), ''), 'Unknown') AS LastName,
    -- Pre-clean strings ('NaT' to NULL, '.' to '-') then cast cleanly to DATE
    TRY_CAST(
        REPLACE(
            NULLIF(TRIM(DateOfBirth), 'NaT'), 
            '.', '-'
        ) AS DATE
    ) AS CleanDateOfBirth
FROM staging.RawCustomers
WHERE CustomerID NOT IN (SELECT CustomerID FROM audit.QuarantineCustomers);
GO

SELECT * FROM audit.QuarantineCustomers
WHERE QuarantineReason != 'Data Format Violation: Unparseable DateOfBirth string';


