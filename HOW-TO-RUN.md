# How to Run This Project

Complete step-by-step guide to set up and run the SQL Server Performance Lab.

---

## Prerequisites

- **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop/)
- **Azure Data Studio** - [Download here](https://docs.microsoft.com/sql/azure-data-studio/download)

---

## Step 1: Start SQL Server

Open Terminal and navigate to the project folder:

```bash
cd /path/to/sqlserver-performance-lab
docker-compose up -d
```

Wait 15 seconds for SQL Server to start.

**Verify it's running:**
```bash
docker ps
```

You should see `sqlserver-lab` with status "Up".

---

## Step 2: Connect with Azure Data Studio

1. Open **Azure Data Studio**
2. Click **New Connection**
3. Enter these details:

| Field | Value |
|-------|-------|
| Server | `localhost` |
| Authentication | SQL Login |
| User name | `sa` |
| Password | `YourStrong@Pass123` |
| Trust server certificate | ✅ Check this |

4. Click **Connect**

---

## Step 3: Create the Database

Run these SQL files **in order**:

### 3.1 Create Schema
1. File → Open File → `db/01-schema.sql`
2. Press **F5** to run
3. Wait for "Schema creation complete!"

### 3.2 Generate Test Data
1. File → Open File → `db/02-seed-data.sql`
2. Press **F5** to run
3. Wait ~2 minutes for "Data generation complete!"

### 3.3 Create Indexes
1. File → Open File → `db/03-indexes.sql`
2. Press **F5** to run
3. Wait for "Index creation complete!"

### 3.4 Create Stored Procedures
1. File → Open File → `db/04-stored-procedures.sql`
2. Press **F5** to run
3. Wait for "Stored procedure creation complete!"

---

## Step 4: Verify Setup

Run this query to check row counts:

```sql
USE PerformanceLab;

SELECT 'Customers' AS TableName, COUNT(*) AS Rows FROM dbo.Customers
UNION ALL SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL SELECT 'OrderDetails', COUNT(*) FROM dbo.OrderDetails
UNION ALL SELECT 'Products', COUNT(*) FROM dbo.Products;
```

**Expected Results:**
| TableName | Rows |
|-----------|------|
| Customers | 50,000 |
| Orders | 200,000 |
| OrderDetails | 500,000+ |
| Products | 1,000 |

---

## Step 5: Run the Learning Modules

### Module A: Slow Search Patterns

1. Open `modules/A-slow-search/01-bad-query.sql`
2. Add at the top:
   ```sql
   SET STATISTICS IO ON;
   ```
3. Run the query (F5)
4. Check Messages tab → Note the "logical reads" number
5. Open `modules/A-slow-search/03-fix.sql`
6. Run and compare the logical reads

**Expected:** Bad query ~700 reads, Fixed query ~6 reads

### Other Modules

Follow the same pattern for modules B through F:
1. Read the module's `README.md`
2. Run `01-bad-query.sql` and note performance
3. Run `03-fix.sql` and compare

---

## Step 6: Run All Tests

To verify everything works:

1. Open `RUN-ALL-TESTS.sql`
2. Press **F5**
3. Wait ~5 minutes
4. Check results in Messages tab

---

## Troubleshooting

### Docker container won't start
```bash
docker-compose down
docker-compose up -d
```

### Connection refused
- Wait 15 seconds after starting Docker
- Check container status: `docker ps`

### "Database does not exist" error
- Make sure you ran `01-schema.sql` first
- Run the setup scripts in order

### Slow seed data script
- This is normal, it generates 750K+ rows
- Takes about 2 minutes

---

## Stopping the Lab

When you're done:

```bash
docker-compose down
```

To completely reset (delete all data):
```bash
docker-compose down -v
```

---

## Quick Command Reference

| Action | Command |
|--------|---------|
| Start SQL Server | `docker-compose up -d` |
| Stop SQL Server | `docker-compose down` |
| Check status | `docker ps` |
| View logs | `docker logs sqlserver-lab` |
| Reset everything | `docker-compose down -v` |

---

**Ready to learn? Start with Module A!**
