# Changelog

All notable changes to this project are documented in this file.

## [2.0.0] - 2026-01-05

### Added
- **Module E: Columnstore Power** - Demonstrates 100x speedup with Non-Clustered Columnstore Indexes
- **Module F: Temporal Tables** - SQL Server 2022+ time-travel query capabilities
- **CI/CD Pipeline** - GitHub Actions for automated testing on every push
- **Python Visualization** - Generate professional performance charts (`scripts/visualize_results.py`)
- **Makefile** - One-command developer workflow (`make setup`, `make test`, etc.)
- **Interview Guide** - STAR format answers and talking points for technical interviews
- **Screenshot Guide** - Instructions for capturing portfolio-quality execution plans
- **Performance Dashboard** - ASCII art results summary (`PERFORMANCE-DASHBOARD.sql`)
- **Engineering Workbook** - Structured document for recording lab findings

### Changed
- **README.md** - Complete overhaul with 2025 tech standards, ARM64 native badges, and IQP focus
- **docker-compose.yml** - Optimized for Apple Silicon (M1/M2/M3)
- **Stored Procedures** - Added `usp_ViewDashboard` for quick results summary

### Fixed
- `02-seed-data.sql` - Fixed missing `SubCatNum` column in ProductBase CTE

## [1.0.0] - 2026-01-04

### Added
- Initial release with 4 core modules (A, B, C, D)
- 750K+ rows of synthetic test data
- Complete database setup scripts
- Module READMEs with expected results

---

## Version Format

This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes to database schema
- **MINOR**: New modules or features
- **PATCH**: Bug fixes and documentation updates
