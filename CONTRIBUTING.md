# Contributing to SQL Server Performance Lab

Thank you for your interest in contributing! This project welcomes contributions from the community.

## 🚀 Quick Start for Contributors

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your changes
4. **Make changes** and test them
5. **Submit a Pull Request**

## 📋 Types of Contributions

### 🐛 Bug Reports
- Use the GitHub Issues tab
- Include steps to reproduce
- Include your SQL Server version and environment

### 💡 New Modules
- Each module should follow the existing structure:
  ```
  modules/X-module-name/
  ├── README.md          # Explanation of the problem
  ├── 01-bad-query.sql   # Demonstrates the problem
  ├── 02-analysis.sql    # Analysis of why it's slow
  └── 03-fix.sql         # The optimized solution
  ```
- Must include measurable before/after metrics
- Must work on SQL Server 2019+

### 📖 Documentation
- Improvements to README.md
- Additional interview questions
- Translations

## ✅ Code Standards

### SQL Scripts
- Use `SET NOCOUNT ON` in procedures
- Include clear comments explaining the "why"
- Use consistent formatting (4-space indentation)
- Stats should be enabled before tests:
  ```sql
  SET STATISTICS IO ON;
  SET STATISTICS TIME ON;
  ```

### Markdown
- Use clear headings
- Include code blocks with proper language tags
- Keep lines under 120 characters

## 🧪 Testing Your Changes

Before submitting:

1. Run the full test suite:
   ```bash
   make test
   ```

2. Verify row counts:
   ```sql
   USE PerformanceLab;
   SELECT 'Customers', COUNT(*) FROM dbo.Customers
   UNION ALL SELECT 'Orders', COUNT(*) FROM dbo.Orders;
   ```

3. Test on a fresh database:
   ```bash
   make clean && make init && make test
   ```

## 📝 Commit Message Format

Use conventional commits:
- `feat: Add Module G for JSON performance`
- `fix: Correct row count in seed script`
- `docs: Update interview guide`
- `refactor: Simplify usp_ClearCache`

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Questions?** Open an issue or reach out!
