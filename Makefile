# Makefile for SQL Server Performance Lab

.PHONY: help setup start stop test clean dashboard

help:
	@echo "SQL Server Performance Lab - Available Commands"
	@echo "================================================"
	@echo "make setup       - Start Docker container and wait for SQL Server"
	@echo "make init        - Initialize database (schema, data, indexes, procedures)"
	@echo "make test        - Run all automated tests"
	@echo "make dashboard   - Display performance dashboard"
	@echo "make stop        - Stop Docker container"
	@echo "make clean       - Stop and remove container + volumes"
	@echo "make restart     - Clean restart of entire environment"

setup:
	@echo "🚀 Starting SQL Server container..."
	docker-compose up -d
	@echo "⏳ Waiting for SQL Server to be ready..."
	@sleep 15
	@echo "✅ SQL Server is ready!"

init: setup
	@echo "📊 Creating schema..."
	docker exec -i sqlserver-lab /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Pass123" -i /db/01-schema.sql || true
	@echo "🌱 Seeding data (this takes ~2 minutes)..."
	docker exec -i sqlserver-lab /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Pass123" -i /db/02-seed-data.sql || true
	@echo "🔧 Creating indexes..."
	docker exec -i sqlserver-lab /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Pass123" -i /db/03-indexes.sql || true
	@echo "⚙️  Creating stored procedures..."
	docker exec -i sqlserver-lab /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Pass123" -i /db/04-stored-procedures.sql || true
	@echo "✅ Database initialization complete!"

test:
	@echo "🧪 Running automated test suite..."
	docker exec -i sqlserver-lab /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Pass123" -i /RUN-ALL-TESTS.sql || true

dashboard:
	@echo "📊 Displaying performance dashboard..."
	docker exec -i sqlserver-lab /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Pass123" -Q "USE PerformanceLab; EXEC dbo.usp_ViewDashboard;" || true

stop:
	@echo "🛑 Stopping SQL Server container..."
	docker-compose down

clean:
	@echo "🧹 Cleaning up containers and volumes..."
	docker-compose down -v
	@echo "✅ Cleanup complete!"

restart: clean setup init
	@echo "🔄 Environment restarted successfully!"

# Quick start for new users
quickstart: setup
	@echo ""
	@echo "✨ SQL Server Performance Lab is ready!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Run 'make init' to create the database"
	@echo "2. Run 'make test' to verify everything works"
	@echo "3. Run 'make dashboard' to see your results"
	@echo ""
	@echo "Or connect manually:"
	@echo "  Server: localhost:1433"
	@echo "  User: sa"
	@echo "  Password: YourStrong@Pass123"
