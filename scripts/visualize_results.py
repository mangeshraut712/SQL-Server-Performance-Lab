"""
SQL Server Performance Lab - Results Visualization
Generates charts from QueryBenchmarks table for portfolio presentation
"""

import pyodbc
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

# Configuration
SERVER = 'localhost,1433'
DATABASE = 'PerformanceLab'
USERNAME = 'sa'
PASSWORD = 'YourStrong@Pass123'

def get_connection():
    """Create database connection"""
    conn_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'
    return pyodbc.connect(conn_string)

def fetch_benchmark_data():
    """Fetch benchmark data from QueryBenchmarks table"""
    query = """
    SELECT 
        TestName,
        QueryType,
        LogicalReads,
        CPUTimeMs,
        ElapsedTimeMs,
        RowsReturned,
        TestDate
    FROM dbo.QueryBenchmarks
    ORDER BY TestName, QueryType;
    """
    
    with get_connection() as conn:
        df = pd.read_sql(query, conn)
    
    return df

def create_comparison_chart(df, module_name):
    """Create before/after comparison chart for a specific module"""
    
    module_data = df[df['TestName'].str.contains(module_name, case=False)]
    
    if module_data.empty:
        print(f"No data found for {module_name}")
        return
    
    # Pivot data for easy plotting
    pivot_data = module_data.pivot_table(
        values='LogicalReads',
        index='TestName',
        columns='QueryType',
        aggfunc='mean'
    )
    
    # Create figure
    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    fig.suptitle(f'{module_name} - Performance Optimization Results', fontsize=16, fontweight='bold')
    
    # Chart 1: Logical Reads Comparison
    ax1 = axes[0]
    pivot_data.plot(kind='bar', ax=ax1, color=['#e74c3c', '#2ecc71'])
    ax1.set_title('Logical Reads: Before vs After', fontsize=12)
    ax1.set_ylabel('Logical Reads', fontsize=10)
    ax1.set_xlabel('Test Scenario', fontsize=10)
    ax1.legend(['Bad Query', 'Optimized'], loc='upper right')
    ax1.grid(axis='y', alpha=0.3)
    
    # Add improvement percentage
    if 'BAD' in pivot_data.columns and 'OPTIMIZED' in pivot_data.columns:
        for idx, row in enumerate(pivot_data.itertuples()):
            if row.BAD > 0:
                improvement = (row.BAD - row.OPTIMIZED) / row.BAD * 100
                ax1.text(idx, max(row.BAD, row.OPTIMIZED) * 1.05, 
                        f'{improvement:.1f}% ↓', 
                        ha='center', fontsize=9, fontweight='bold', color='green')
    
    # Chart 2: Execution Time
    pivot_time = module_data.pivot_table(
        values='ElapsedTimeMs',
        index='TestName',
        columns='QueryType',
        aggfunc='mean'
    )
    
    ax2 = axes[1]
    pivot_time.plot(kind='bar', ax=ax2, color=['#e74c3c', '#2ecc71'])
    ax2.set_title('Execution Time: Before vs After', fontsize=12)
    ax2.set_ylabel('Time (ms)', fontsize=10)
    ax2.set_xlabel('Test Scenario', fontsize=10)
    ax2.legend(['Bad Query', 'Optimized'], loc='upper right')
    ax2.grid(axis='y', alpha=0.3)
    
    plt.tight_layout()
    
    # Save figure
    filename = f'results_{module_name.lower().replace(" ", "_")}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.png'
    plt.savefig(filename, dpi=300, bbox_inches='tight')
    print(f"✅ Chart saved: {filename}")
    
    plt.show()

def create_overall_summary():
    """Create overall performance summary dashboard"""
    
    df = fetch_benchmark_data()
    
    # Calculate improvements
    summary_data = []
    
    for test_name in df['TestName'].unique():
        test_df = df[df['TestName'] == test_name]
        
        bad_row = test_df[test_df['QueryType'] == 'BAD']
        good_row = test_df[test_df['QueryType'] == 'OPTIMIZED']
        
        if not bad_row.empty and not good_row.empty:
            bad_reads = bad_row['LogicalReads'].values[0]
            good_reads = good_row['LogicalReads'].values[0]
            
            if bad_reads > 0:
                improvement = (bad_reads - good_reads) / bad_reads * 100
                speedup = bad_reads / good_reads if good_reads > 0 else 0
                
                summary_data.append({
                    'Module': test_name,
                    'Before': bad_reads,
                    'After': good_reads,
                    'Improvement %': improvement,
                    'Speedup': f'{speedup:.1f}x'
                })
    
    summary_df = pd.DataFrame(summary_data)
    
    # Create summary chart
    fig, ax = plt.subplots(figsize=(12, 6))
    
    x = range(len(summary_df))
    width = 0.35
    
    bars1 = ax.bar([i - width/2 for i in x], summary_df['Before'], width, 
                   label='Before', color='#e74c3c', alpha=0.8)
    bars2 = ax.bar([i + width/2 for i in x], summary_df['After'], width,
                   label='After', color='#2ecc71', alpha=0.8)
    
    ax.set_xlabel('Optimization Module', fontsize=12, fontweight='bold')
    ax.set_ylabel('Logical Reads', fontsize=12, fontweight='bold')
    ax.set_title('SQL Performance Lab - Complete Results Summary', fontsize=14, fontweight='bold')
    ax.set_xticks(x)
    ax.set_xticklabels(summary_df['Module'], rotation=15, ha='right')
    ax.legend()
    ax.grid(axis='y', alpha=0.3)
    
    # Add speedup labels
    for idx, row in summary_df.iterrows():
        ax.text(idx, max(row['Before'], row['After']) * 1.05,
               row['Speedup'],
               ha='center', fontsize=10, fontweight='bold', color='green')
    
    plt.tight_layout()
    
    filename = f'overall_summary_{datetime.now().strftime("%Y%m%d_%H%M%S")}.png'
    plt.savefig(filename, dpi=300, bbox_inches='tight')
    print(f"✅ Summary chart saved: {filename}")
    
    plt.show()
    
    # Print summary table
    print("\n" + "="*80)
    print("SQL PERFORMANCE LAB - RESULTS SUMMARY")
    print("="*80)
    print(summary_df.to_string(index=False))
    print("="*80)

if __name__ == "__main__":
    print("🚀 SQL Server Performance Lab - Results Visualization")
    print("="*60)
    
    try:
        # Create overall summary
        create_overall_summary()
        
        # Optional: Create individual module charts
        # create_comparison_chart(fetch_benchmark_data(), "Module A")
        # create_comparison_chart(fetch_benchmark_data(), "Module B")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\nMake sure:")
        print("  1. SQL Server is running (docker-compose up -d)")
        print("  2. Database is initialized (make init)")
        print("  3. Tests have been run (make test)")
        print("  4. ODBC Driver 17 is installed")
