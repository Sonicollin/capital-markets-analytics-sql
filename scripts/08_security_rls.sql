-- ============================================================================
-- Capital Markets Analytics Data Warehouse
-- Script 08: Row-Level Security Creation and Implementation
-- DESCRIPTION: Row-Level Security policy restricting access by BranchID.
-- Deploys predicate functions and security policies on core entities.
-- ============================================================================

IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TransactionsBranchPolicy')
    DROP SECURITY POLICY sec.TransactionsBranchPolicy;
IF OBJECT_ID('sec.fn_BranchSecurityPredicate', 'IF') IS NOT NULL
    DROP FUNCTION sec.fn_BranchSecurityPredicate;
GO
-- ----------------------------------------------------------------------------
-- STEP 1: Create Application Context / User-Branch Mapping Table
-- maps SQL users/AD groups to specific BranchIDs
-- ----------------------------------------------------------------------------
IF OBJECT_ID('sec.UserBranchAccess', 'U') IS NULL
BEGIN
    CREATE TABLE sec.UserBranchAccess (
        Username NVARCHAR(128) NOT NULL,
        BranchID INT NOT NULL,
        CONSTRAINT PK_UserBranchAccess PRIMARY KEY (Username, BranchID)
    );
END
GO

-- Secondary index to support lookups starting by BranchID
DROP INDEX IF EXISTS IX_UserBranchAccess_BranchID ON sec.UserBranchAccess;
CREATE NONCLUSTERED INDEX IX_UserBranchAccess_BranchID 
ON sec.UserBranchAccess (BranchID);
GO

-- ----------------------------------------------------------------------------
-- STEP 2: Create Inline Security Predicate Function
-- Returns 1 (True) if the session user is allowed to view the BranchID
-- ----------------------------------------------------------------------------
CREATE FUNCTION sec.fn_BranchSecurityPredicate(@BranchID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
    SELECT 1 AS AccessResult
    WHERE 
        -- Rule A: System Administrators & Service Accounts see all records
        IS_MEMBER('db_owner') = 1 
        OR SESSION_USER = 'dbo'
        
        -- Rule B: User has explicit access assigned in mapping table
        OR EXISTS (
            SELECT 1 
            FROM sec.UserBranchAccess uba
            WHERE uba.Username = SESSION_USER
              AND uba.BranchID = @BranchID
        )
        
        -- Rule C: Allow unassigned/global records (-1) to pass through
        OR @BranchID = -1
);
GO

-- ----------------------------------------------------------------------------
-- STEP 3: Create Security Policy on core.Transactions
-- ----------------------------------------------------------------------------
CREATE SECURITY POLICY sec.TransactionsBranchPolicy
    ADD FILTER PREDICATE sec.fn_BranchSecurityPredicate(BranchID) 
        ON core.Transactions
    WITH (STATE = ON, SCHEMABINDING = ON);
GO