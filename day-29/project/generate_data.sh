#!/bin/bash
# generate_data.sh - Build realistic demo datasets for Day 29 SQLite project
set -euo pipefail

REGIONS=(East West North South)
CATEGORIES=(Electronics Clothing Food Books)

echo "Generating sales.csv (200 rows)..."
cat > sales.csv <<'CSV'
date,region,category,amount,qty
CSV

for i in $(seq 1 200); do
  day=$((1 + RANDOM % 28))
  month=$((1 + RANDOM % 12))
  year=$((2024 + RANDOM % 2))
  printf -v date_str "%04d-%02d-%02d" "$year" "$month" "$day"

  region=${REGIONS[$((RANDOM % 4))]}
  category=${CATEGORIES[$((RANDOM % 4))]}
  amount=$(awk "BEGIN{printf \"%.2f\", 10 + ($RANDOM / 32767) * 490}")
  qty=$((1 + RANDOM % 20))

  echo "$date_str,$region,$category,$amount,$qty"
done >> sales.csv

echo "Generating regions.csv (lookup table)..."
cat > regions.csv <<'CSV'
region,manager,timezone
East,Alice,EST
West,Bob,PST
North,Carol,CST
South,Dave,CST
CSV

echo "Generating categories.csv (lookup table)..."
cat > categories.csv <<'CSV'
category,tax_rate
Electronics,0.15
Clothing,0.08
Food,0.05
Books,0.00
CSV

echo "Done. Files created: sales.csv, regions.csv, categories.csv"
ls -lh *.csv
