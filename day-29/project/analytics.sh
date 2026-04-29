#!/bin/bash
# analytics.sh - Run analytical queries on the sales database
set -euo pipefail

DB="sales.db"

if [[ ! -f "$DB" ]]; then
  echo "Database not found. Run ./setup_db.sh first."
  exit 1
fi

echo "=========================================="
echo "  Day 29 — SQLite Analytics Report"
echo "=========================================="
echo ""

echo "--- 1. Total Revenue per Region ---"
sqlite3 "$DB" -column -header \
  "SELECT s.region, SUM(s.amount) AS revenue, SUM(s.qty) AS units_sold
   FROM sales s
   GROUP BY s.region
   ORDER BY revenue DESC;"
echo ""

echo "--- 2. Revenue per Category ---"
sqlite3 "$DB" -column -header \
  "SELECT s.category, ROUND(SUM(s.amount), 2) AS revenue,
          ROUND(AVG(s.amount), 2) AS avg_order,
          COUNT(*) AS order_count
   FROM sales s
   GROUP BY s.category
   ORDER BY revenue DESC;"
echo ""

echo "--- 3. Enriched Report: Region + Manager ---"
sqlite3 "$DB" -column -header \
  "SELECT r.region, r.manager, r.timezone,
          ROUND(SUM(s.amount), 2) AS revenue,
          COUNT(*) AS orders
   FROM sales s
   JOIN regions r ON s.region = r.region
   GROUP BY r.region
   ORDER BY revenue DESC;"
echo ""

echo "--- 4. Tax-Adjusted Revenue per Category ---"
sqlite3 "$DB" -column -header \
  "SELECT c.category, c.tax_rate,
          ROUND(SUM(s.amount), 2) AS gross_revenue,
          ROUND(SUM(s.amount) * (1 - c.tax_rate), 2) AS net_revenue
   FROM sales s
   JOIN categories c ON s.category = c.category
   GROUP BY c.category
   ORDER BY gross_revenue DESC;"
echo ""

echo "--- 5. Monthly Revenue Trend ---"
sqlite3 "$DB" -column -header \
  "SELECT substr(date, 1, 7) AS month,
          ROUND(SUM(amount), 2) AS revenue,
          COUNT(*) AS orders
   FROM sales
   GROUP BY month
   ORDER BY month;"
echo ""

echo "--- 6. Top 10 Largest Single Orders ---"
sqlite3 "$DB" -column -header \
  "SELECT date, region, category, amount, qty
   FROM sales
   ORDER BY amount DESC
   LIMIT 10;"
echo ""

echo "Report complete."
