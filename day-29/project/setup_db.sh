#!/bin/bash
# setup_db.sh - Create SQLite database and import CSV files
set -euo pipefail

DB="sales.db"

echo "Removing old database (if any)..."
rm -f "$DB"

echo "Creating schema and importing data..."
sqlite3 "$DB" <<'EOF'
-- Main sales table
CREATE TABLE sales (
  date TEXT,
  region TEXT,
  category TEXT,
  amount REAL,
  qty INTEGER
);

-- Lookup tables
CREATE TABLE regions (
  region TEXT PRIMARY KEY,
  manager TEXT,
  timezone TEXT
);

CREATE TABLE categories (
  category TEXT PRIMARY KEY,
  tax_rate REAL
);

-- Import CSVs
.mode csv
.import sales.csv sales
.import regions.csv regions
.import categories.csv categories

-- Remove the header row that got imported as data
DELETE FROM sales WHERE date = 'date';
DELETE FROM regions WHERE region = 'region';
DELETE FROM categories WHERE category = 'category';

-- Indexes for performance
CREATE INDEX idx_sales_region ON sales(region);
CREATE INDEX idx_sales_category ON sales(category);
CREATE INDEX idx_sales_date ON sales(date);
EOF

echo "Database ready: $DB"
echo "Tables:"
sqlite3 "$DB" ".tables"
echo ""
echo "Row counts:"
sqlite3 "$DB" "SELECT 'sales', COUNT(*) FROM sales UNION ALL SELECT 'regions', COUNT(*) FROM regions UNION ALL SELECT 'categories', COUNT(*) FROM categories;"
