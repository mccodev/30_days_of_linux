#!/bin/bash
# generate_data.sh
# Generates a realistic sales dataset for compression benchmarking.
# Usage: ./generate_data.sh [rows] [output_file]

set -euo pipefail

ROWS="${1:-100000}"
OUTPUT="${2:-sales.csv}"

echo "Generating $ROWS rows into $OUTPUT ..."

# Header
printf "order_id,date,region,category,product,quantity,unit_price,discount_pct\n" > "$OUTPUT"

REGIONS=("North" "South" "East" "West" "Central")
CATEGORIES=("Electronics" "Clothing" "Food" "Books" "Home" "Sports")
PRODUCTS=("Widget-A" "Widget-B" "Gadget-X" "Gadget-Y" "Shirt-M" "Shirt-L" "Pants-32" "Pants-34" "Novel-Hard" "Novel-Paper" "Snack-Bar" "Snack-Chip" "Bottle-1L" "Bottle-500ml")

for ((i=1; i<=ROWS; i++)); do
    order_id="ORD-$(printf "%08d" $i)"
    year=$((2020 + RANDOM % 6))
    month=$((1 + RANDOM % 12))
    day=$((1 + RANDOM % 28))
    printf -v date "%04d-%02d-%02d" "$year" "$month" "$day"
    region="${REGIONS[$RANDOM % ${#REGIONS[@]}]}"
    category="${CATEGORIES[$RANDOM % ${#CATEGORIES[@]}]}"
    product="${PRODUCTS[$RANDOM % ${#PRODUCTS[@]}]}"
    qty=$((1 + RANDOM % 20))
    price=$(awk -v r="$RANDOM" 'BEGIN{printf "%.2f", (r/32767)*200 + 5}')
    discount=$((RANDOM % 30))

    printf "%s,%s,%s,%s,%s,%d,%.2f,%d\n" \
        "$order_id" "$date" "$region" "$category" "$product" "$qty" "$price" "$discount"
done >> "$OUTPUT"

SIZE=$(stat -c '%s' "$OUTPUT")
SIZE_HUMAN=$(numfmt --to=iec "$SIZE" 2>/dev/null || echo "$SIZE bytes")

echo "Done. File: $OUTPUT  Rows: $ROWS  Size: $SIZE_HUMAN"
