<div align="center">

# 🎓 SQL Server Performance Lab

### Learn SQL tuning through six hands-on scenarios, 750K+ rows of data, and measurable before/after results

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](docker-compose.yml)
[![SQL Server](https://img.shields.io/badge/SQL_Server-2019%2B-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![T-SQL](https://img.shields.io/badge/T--SQL-Performance_Lab-0078D4?style=for-the-badge)](https://learn.microsoft.com/sql/t-sql/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

[Features](#-features) • [Stack](#-stack) • [Quick Start](#-quick-start) • [Structure](#-project-structure) • [Scripts](#-scripts) • [License](#-license) • [Contact](#-contact)

</div>

---

## Table of Contents

- [About](#-about)
- [Features](#-features)
- [Stack](#-stack)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Scripts](#-scripts)
- [License](#-license)
- [Contact](#-contact)

## About

SQL Server Performance Lab is a guided tuning sandbox for learning how query shape, indexes, parameters, and concurrency affect execution plans. Each module pairs a slow query with an optimized fix so you can measure the improvement in logical reads and runtime.

## Features

- Six focused modules covering search patterns, covering indexes, parameter sniffing, deadlocks, columnstore indexes, and temporal tables
- 750K+ rows of seeded test data for realistic tuning exercises
- Step-by-step setup instructions in `HOW-TO-RUN.md`
- Repeatable validation with `RUN-ALL-TESTS.sql`
- Practical measurement workflow using `SET STATISTICS IO/TIME ON`

## Stack

| Area | Technologies |
| --- | --- |
| Database | SQL Server 2019+, T-SQL |
| Local Environment | Docker Compose |
| Clients | Azure Data Studio, SSMS |
| Docs | Markdown guides and SQL scripts |

## Quick Start

```bash
docker-compose up -d
```

Connect with `sa` / `YourStrong@Pass123`, then run the SQL files in order:

1. `db/01-schema.sql`
2. `db/02-seed-data.sql`
3. `db/03-indexes.sql`
4. `db/04-stored-procedures.sql`

After that, open `RUN-ALL-TESTS.sql` and execute it in Azure Data Studio or SSMS.

## Project Structure

```text
sql-server-performance-lab/
├── db/                    # Schema, seed data, indexes, procedures
├── modules/               # Module A-F learning scenarios
├── RUN-ALL-TESTS.sql      # End-to-end validation script
├── HOW-TO-RUN.md          # Full setup walkthrough
├── docker-compose.yml     # SQL Server container stack
└── README.md              # Project overview
```

## Scripts

The main commands and files you will use are:

```bash
docker-compose up -d
docker-compose down
docker-compose down -v
```

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
```

Use the module-specific `01-bad-query.sql`, `02-analysis.sql`, and `03-fix.sql` files to compare the baseline and optimized versions.

## License

MIT. See [LICENSE](LICENSE) for details.

## Contact

- Repository: [mangeshraut712/SQL-Server-Performance-Lab](https://github.com/mangeshraut712/SQL-Server-Performance-Lab)
- Issues: open a GitHub issue in this repository
