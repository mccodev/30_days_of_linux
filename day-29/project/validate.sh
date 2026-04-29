#!/bin/bash
# validate.sh - Data quality validation checks for the sales database
set -euo pipefail

DB="sales.db"
ERRORS=0

if [[ ! -f "$DB" ]]; then
  echo "Database not found. Run ./setup_db.sh first."
  exit 1
fi

check() {
  local name="$1"
  local query="$2"
  local count
  count=$(sqlite3 "$DB" "$query")
  if [ "$count" -gt 0 ]; then
    echo "  FAIL: $name — $count rows affected"
    ERRORS=$((ERRORS + 1))
  else
    echo "  PASS: $name"
  fi
}

echo "=========================================="
echo "  Data Quality Validation"
echo "=========================================="

check "Negative amounts"      "SELECT COUNT(*) FROM sales WHERE amount < 0;"
check "Missing region"        "SELECT COUNT(*) FROM sales WHERE region IS NULL OR region = '';"
check "Missing category"      "SELECT COUNT(*) FROM sales WHERE category IS NULL OR category = '';"
check "Zero or negative qty"  "SELECT COUNT(*) FROM sales WHERE qty <= 0;"
check "Future dates"          "SELECT COUNT(*) FROM sales WHERE date > date('now');"
check "Invalid region"        "SELECT COUNT(*) FROM sales WHERE region NOT IN (SELECT region FROM regions);"
check "Invalid category"      "SELECT COUNT(*) FROM sales WHERE category NOT IN (SELECT category FROM categories);"
check "Duplicate rows"        "SELECT COUNT(*) FROM (SELECT date, region, category, amount, qty, COUNT(*) AS c FROM sales GROUP BY date, region, category, amount, qty HAVING c > 1);"

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "All checks passed."
  exit 0
else
  echo "$ERRORS check(s) failed."
  exit 1
fi
