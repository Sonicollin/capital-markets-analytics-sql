# Capital Markets Analytics - Project Checklist

## Phase 1: Setup & Architecture
- [x] Create GitHub repository
- [x] Initialize local directory structure
- [x] Add `.gitignore` and initial commit
- [x] Source public financial dataset (trades/prices)
- [x] Initialize CapitalMarketsDB database and staging schema
- [x] Import raw data into SQL Server staging tables

## Phase 2: SQL Data Warehouse & Logic
- [x] Write `01_schema_setup.sql` (Star schema fact/dim tables)
- [x] Write `02_staging_load.sql` (Load Raw Data in Staging tables)
- [x] Write `03_reference_tables.sql` (Lookup tables)
- [x] Write `04_quarantine_tables.sql` (Quarantine bad data using CTEs)
- [x] Write `05_core_table_creation.sql` (Populate Core Tables using CTEs and Window functions, and quarantine duplicates)
- [x] Write `06_optimize_index.sql` (Create non-clustered indexes on foreign key columns)
- [x] Write `07_analytics_views.sql` (Create clean views of several tables using joins from core tables to reference tables)
- [x] Write `08_security_rls.sql` (Implement Row-Level Security)
- [x] Write `09_main_deploy.sql` (Deployment script that runs with SQLCMD in SSMS)

## Phase 3: Power BI Dashboard
- [ ] Connect Power BI to SQL Server views
- [ ] Build DAX measures for Portfolio P&L and Volatility
- [ ] Design Executive Dashboard visual layout

## Phase 4: Documentation & Polish
- [ ] Write production-ready `README.md` with visual architecture diagram
- [ ] Code cleanup and comment formatting