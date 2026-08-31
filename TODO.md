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
- [ ] Write `02_data_transformation.sql` (CTEs, Window functions, Moving averages)
- [ ] Add indexes for query performance optimization
- [ ] Write `03_analytics_views.sql` (Reporting views)
- [ ] Write `04_security_rls.sql` (Row-Level Security predicates)

## Phase 3: Power BI Dashboard
- [ ] Connect Power BI to SQL Server views
- [ ] Build DAX measures for Portfolio P&L and Volatility
- [ ] Design Executive Dashboard visual layout

## Phase 4: Documentation & Polish
- [ ] Write production-ready `README.md` with visual architecture diagram
- [ ] Code cleanup and comment formatting