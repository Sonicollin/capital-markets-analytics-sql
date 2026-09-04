-- ==========================================
-- Capital Markets Analytics Data Warehouse
-- Script 03: Reference Tables Initialized and Loaded
-- ==========================================

-- Account Types Table --
DROP TABLE IF EXISTS staging.RawAccountTypes;
GO

CREATE TABLE staging.RawAccountTypes (
        AccountTypeID NVARCHAR(200),
        TypeName NVARCHAR(255)
    );
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

-- Account Statuses Table --
DROP TABLE IF EXISTS staging.RawAccountStatuses;
GO

CREATE TABLE staging.RawAccountStatuses (
        AccountStatusID NVARCHAR(200),
        StatusName NVARCHAR(255)
    );
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

-- Addresses Table --
DROP TABLE IF EXISTS staging.RawAddresses;
GO

CREATE TABLE staging.RawAddresses (
        AddressID NVARCHAR(200),
        Street NVARCHAR(255),
        City NVARCHAR(255),
        Country NVARCHAR(255),
    );
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

-- Customer Types Table --
DROP TABLE IF EXISTS staging.RawCustomerTypes;
GO

CREATE TABLE staging.RawCustomerTypes (
        CustomerTypeID NVARCHAR(200),
        TypeName NVARCHAR(255)
    );
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

-- Loan Status Table --
DROP TABLE IF EXISTS staging.RawLoanStatuses;
GO

CREATE TABLE staging.RawLoanStatuses (
        LoanStatusID NVARCHAR(200),
        StatusName NVARCHAR(255)
    );
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

-- Transaction Types Table --
DROP TABLE IF EXISTS staging.RawTransactionTypes;
GO

CREATE TABLE staging.RawTransactionTypes (
        TransactionTypeID NVARCHAR(200),
        TypeName NVARCHAR(255)
    );
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