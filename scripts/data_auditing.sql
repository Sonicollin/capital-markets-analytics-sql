USE CapitalMarketsDB;
GO 


-- SELECT 'Transaction Types'
-- SELECT * FROM staging.RawTransactionTypes;
-- SELECT 'Transactions'
-- SELECT TOP 5 * FROM staging.RawTransactions;
-- SELECT 'Loan Statuses'
-- SELECT * FROM staging.RawLoanStatuses;
-- SELECT 'Loans'
-- SELECT TOP 5 * FROM staging.RawLoans;
-- SELECT 'Account Statuses'
-- SELECT * FROM staging.RawAccountStatuses;
-- SELECT 'Account Types'
-- SELECT * FROM staging.RawAccountTypes;
-- SELECT 'Accounts'
-- SELECT TOP 5 * FROM staging.RawAccounts;
-- SELECT 'Customer Types'
-- SELECT * FROM staging.RawCustomerTypes;
-- SELECT 'Customers'
-- SELECT TOP 5 * FROM staging.RawCustomers;
-- SELECT 'Branches'
-- SELECT TOP 5 * FROM staging.RawBranches;
-- SELECT 'Addresses'
-- SELECT TOP 5 * FROM staging.RawAddresses;


SELECT DISTINCT CustomerID FROM staging.RawCustomers
GROUP BY CustomerID
HAVING COUNT(*) > 1; -- Identifies duplicate CustomerIDs

SELECT * FROM staging.RawCustomers
WHERE CustomerID = 10056; -- Example of a duplicate CustomerID



