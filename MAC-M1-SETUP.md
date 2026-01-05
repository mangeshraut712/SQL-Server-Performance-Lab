# 🍎 Complete Setup Guide for Mac M1 (Apple Silicon)

## Step-by-Step: SQL Server Performance Lab on MacBook Pro M1

**You have:** MacBook Pro M1 + Docker ✅  
**You need:** SQL Server + Azure Data Studio  
**Time:** ~20 minutes

---

## Part 1️⃣: Start SQL Server in Docker (5 minutes)

### Step 1: Make Sure Docker Desktop is Running

1. Open **Docker Desktop** app (look for whale icon in menu bar)
2. Wait for it to say "Docker Desktop is running"
3. If not installed, download from: https://www.docker.com/products/docker-desktop/

### Step 2: Pull and Run SQL Server Container

Open **Terminal** app and run these commands **one at a time**:

```bash
# Pull SQL Server 2022 for ARM (Apple Silicon)
docker pull mcr.microsoft.com/azure-sql-edge:latest

# Run SQL Server container
docker run -d \
  --name sqlserver-lab \
  --platform linux/arm64 \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong@Pass123" \
  -p 1433:1433 \
  mcr.microsoft.com/azure-sql-edge:latest
```

**Important Notes:**
- For **M1 Mac**, we use `azure-sql-edge` (ARM-compatible)
- Password: `YourStrong@Pass123` (you can change this, but remember it!)
- Port: `1433` (standard SQL Server port)

### Step 3: Verify SQL Server is Running

```bash
# Check if container is running
docker ps
```

**Expected Output:**
```
CONTAINER ID   IMAGE                                    STATUS
abc123def456   mcr.microsoft.com/azure-sql-edge:latest  Up 30 seconds
```

✅ **If you see this, SQL Server is running!**

### Step 4: Test Connection

```bash
# Try connecting to SQL Server
docker exec -it sqlserver-lab /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "YourStrong@Pass123" \
  -Q "SELECT @@VERSION"
```

**Expected Output:**
```
Microsoft SQL Azure Edge (ARM64) - 16.0.x.x
...
```

✅ **If you see version info, connection works!**

---

## Part 2️⃣: Install Azure Data Studio (5 minutes)

Azure Data Studio is the **best SQL client for Mac** (Microsoft's official tool).

### Step 1: Download Azure Data Studio

```bash
# Using Homebrew (recommended)
brew install --cask azure-data-studio
```

**OR** Download manually:
- Go to: https://aka.ms/azuredatastudio
- Click **Download for macOS**
- Open the `.zip` file
- Drag **Azure Data Studio** to Applications folder

### Step 2: Launch Azure Data Studio

```bash
# Open from Terminal
open -a "Azure Data Studio"
```

**OR** Open from Applications folder

---

## Part 3️⃣: Connect to SQL Server (2 minutes)

### Step 1: Create New Connection

1. Azure Data Studio opens
2. Click **"New Connection"** (or press `⌘+Shift+N`)
3. Fill in these details:

```
Connection type:     Microsoft SQL Server
Server:              localhost
Authentication:      SQL Login
User name:           sa
Password:            YourStrong@Pass123
Database:            <Default>
Trust Server Cert:   ✅ (check this box!)
```

4. Click **Connect**

✅ **If connected, you'll see "localhost" in the Servers panel on the left**

---

## Part 4️⃣: Create the Performance Lab Database (5 minutes)

### Step 1: Open Schema Script

1. In Azure Data Studio, click **File** → **Open File**
2. Navigate to: `/Users/mangeshraut/Downloads/sqlserver-performance-lab/db/01-schema.sql`
3. Click **Open**

### Step 2: Execute Schema Script

1. Make sure you're connected to server (green dot on "localhost")
2. Click **Run** button (or press `F5`)
3. Wait for "Schema creation complete!" in Messages panel

**Expected Output:**
```
Creating schema...
  - dbo.Customers
  - dbo.Products
  - dbo.Orders
  - dbo.OrderDetails
  ...
Schema creation complete!
```

### Step 3: Generate Test Data (Takes ~2 minutes)

1. **File** → **Open File** → `db/02-seed-data.sql`
2. Click **Run** (F5)
3. **WAIT** - this generates 750K+ rows (shows progress messages)

**Expected Output:**
```
Generating 1,000 products...
  Products created: 1000
Generating 50,000 customers...
  Customers created: 50000
...
Data generation complete!
```

⏳ **This takes 1-2 minutes - don't interrupt!**

### Step 4: Create Indexes

1. **File** → **Open File** → `db/03-indexes.sql`
2. Click **Run** (F5)
3. Wait for "Index creation complete!"

### Step 5: Create Stored Procedures

1. **File** → **Open File** → `db/04-stored-procedures.sql`
2. Click **Run** (F5)
3. Wait for "Stored procedure creation complete!"

---

## Part 5️⃣: Verify Everything Works (2 minutes)

### Run Verification Query

1. Click **New Query** button (or `⌘+N`)
2. Paste this code:

```sql
USE PerformanceLab;

SELECT 'Customers' AS TableName, COUNT(*) AS Rows FROM dbo.Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL
SELECT 'OrderDetails', COUNT(*) FROM dbo.OrderDetails
UNION ALL
SELECT 'Products', COUNT(*) FROM dbo.Products;
```

3. Click **Run** (F5)

**Expected Output:**
```
TableName       Rows
--------------------------
Customers       50000
Orders          200000
OrderDetails    500000+
Products        1000
```

✅ **If you see these numbers, setup is complete!**

---

## Part 6️⃣: Run the Automated Test Suite (5 minutes)

### Quick Test: See 560x Improvement NOW

1. **File** → **Open File** → `RUN-ALL-TESTS.sql`
2. Click **Run** (F5)
3. Watch the automated tests run through all 4 modules

**Expected Output:**
```
╔══════════════════════════════════════════════╗
║  TEST SUITE COMPLETE!                        ║
╚══════════════════════════════════════════════╝

TestNumber  Module                         Status
------------------------------------------------
1           Module A: Slow Search          ✅ PASS
2           Module B: Covering Index       ✅ PASS
3           Module C: Parameter Sniffing   ✅ PASS
4           Module D: Deadlock Prevention  ✅ PASS
```

🎉 **All modules working!**

---

## 🎯 Quick Command Cheat Sheet (Copy-Paste Ready)

### Docker Management Commands

```bash
# See if SQL Server is running
docker ps

# Stop SQL Server
docker stop sqlserver-lab

# Start SQL Server (after stopping)
docker start sqlserver-lab

# Restart SQL Server
docker restart sqlserver-lab

# View SQL Server logs
docker logs sqlserver-lab

# Remove SQL Server container (if you want to start fresh)
docker rm -f sqlserver-lab

# Then re-run the "docker run" command from Part 1
```

### Connection Details (Save This!)

```
Server:     localhost
Port:       1433
Username:   sa
Password:   YourStrong@Pass123
Database:   PerformanceLab
```

---

## 🐛 Troubleshooting Common M1 Mac Issues

### Issue 1: "Cannot connect to server"

**Fix:**
```bash
# Make sure Docker is running
docker ps

# If container stopped, start it
docker start sqlserver-lab

# Check logs for errors
docker logs sqlserver-lab
```

### Issue 2: "Port 1433 already in use"

**Fix:**
```bash
# See what's using port 1433
lsof -i :1433

# If another container is running, stop it
docker ps
docker stop <container-name>

# Or use a different port
docker run -d \
  --name sqlserver-lab \
  --platform linux/arm64 \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong@Pass123" \
  -p 1434:1433 \
  mcr.microsoft.com/azure-sql-edge:latest

# Then connect using: localhost,1434
```

### Issue 3: "Platform mismatch" error

**Fix:** Make sure you're using `azure-sql-edge` (not `mssql-server`)
```bash
# Remove old container
docker rm -f sqlserver-lab

# Use ARM-compatible image
docker pull mcr.microsoft.com/azure-sql-edge:latest

# Run with --platform flag
docker run -d \
  --name sqlserver-lab \
  --platform linux/arm64 \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrong@Pass123" \
  -p 1433:1433 \
  mcr.microsoft.com/azure-sql-edge:latest
```

### Issue 4: Azure Data Studio won't connect

**Fix:** Enable "Trust Server Certificate"
1. In connection dialog
2. Click **"Advanced"** button
3. Find **"Trust Server Certificate"**
4. Set to **True** ✅
5. Click **OK** and connect

### Issue 5: Scripts running slow

**Fix:** Give Docker more resources
1. Open **Docker Desktop**
2. Click **Settings** (gear icon)
3. Go to **Resources**
4. Set:
   - CPUs: 4
   - Memory: 4 GB
5. Click **Apply & Restart**

---

## 📊 Test Individual Modules

After automated tests pass, explore each module:

### Module A: Slow Search (560x improvement)

```bash
# In Azure Data Studio:
# 1. Open: modules/A-slow-search/01-bad-query.sql
# 2. Click "Explain" button (lightbulb icon)
# 3. Run (F5)
# 4. Note logical reads: ~2,800
# 
# Then:
# 1. Open: modules/A-slow-search/03-fix.sql
# 2. Run (F5)
# 3. Note logical reads: ~5
# 4. Improvement: 560x! ✅
```

### Module B: Covering Index (50x improvement)

```bash
# 1. Open: modules/B-covering-index/01-bad-query.sql
# 2. Click "Explain" button
# 3. Look for "Key Lookup" operator
# 4. Run fix script: 03-fix.sql
# 5. No more Key Lookup! ✅
```

---

## ✅ Success Checklist

Mark these off as you complete:

**Setup:**
- [ ] Docker Desktop running (whale icon visible)
- [ ] SQL Server container running (`docker ps` shows it)
- [ ] Azure Data Studio installed and opens
- [ ] Connected to SQL Server (green dot on "localhost")
- [ ] Ran `db/01-schema.sql` - Success
- [ ] Ran `db/02-seed-data.sql` - Success (waited ~2 min)
- [ ] Ran `db/03-indexes.sql` - Success
- [ ] Ran `db/04-stored-procedures.sql` - Success
- [ ] Verification query shows 750K+ rows

**Testing:**
- [ ] Ran `RUN-ALL-TESTS.sql` - All ✅ PASS
- [ ] Tested Module A - 560x improvement seen
- [ ] Tested Module B - Key Lookups eliminated
- [ ] Tested Module C - Consistency achieved
- [ ] Tested Module D - Deadlock created & fixed

---

## 🚀 Quick Start Summary (TL;DR)

```bash
# 1. Start SQL Server (Terminal)
docker run -d --name sqlserver-lab --platform linux/arm64 \
  -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Pass123" \
  -p 1433:1433 mcr.microsoft.com/azure-sql-edge:latest

# 2. Install Azure Data Studio
brew install --cask azure-data-studio

# 3. Connect to localhost with sa / YourStrong@Pass123

# 4. Run these SQL files in Azure Data Studio:
#    - db/01-schema.sql
#    - db/02-seed-data.sql (wait 2 min)
#    - db/03-indexes.sql
#    - db/04-stored-procedures.sql
#    - RUN-ALL-TESTS.sql

# 5. See all modules pass! ✅
```

---

## 🎓 What's Next?

After everything is running:

1. **Explore modules** - Work through each one in detail
2. **Capture screenshots** - Document your results
3. **Practice explaining** - Prepare for interviews
4. **Add to portfolio** - Already on GitHub! ✅

---

## 📞 Still Stuck?

### Check Docker Status
```bash
docker ps
docker logs sqlserver-lab
```

### Check Connection
```bash
docker exec -it sqlserver-lab /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "YourStrong@Pass123" \
  -Q "SELECT 1"
```

If you see `1` as output, SQL Server is working!

---

**🎉 You're all set! Your M1 Mac is ready to run the SQL Server Performance Lab using Docker + Azure Data Studio!**

**Start here:** Run the commands in **Part 1** (Terminal), then **Part 2** (Azure Data Studio install), then **Part 3-6** in Azure Data Studio.
