#!/bin/bash
# stream_process.sh
# Demonstrates processing compressed CSV/JSONL files WITHOUT decompressing to disk.
# Usage: ./stream_process.sh <file.csv[.gz|.bz2|.xz]>

set -euo pipefail

FILE="${1:?Usage: $0 <file.csv[.gz|.bz2|.xz]>}"

if [[ ! -f "$FILE" ]]; then
    echo "Error: file not found: $FILE"
    exit 1
fi

# Determine the decompression tool based on extension
CAT_CMD="cat"
if [[ "$FILE" == *.gz ]]; then
    CAT_CMD="zcat"
    GREP_CMD="zgrep"
    LESS_CMD="zless"
elif [[ "$FILE" == *.bz2 ]]; then
    CAT_CMD="bzcat"
    GREP_CMD="bzgrep"
    LESS_CMD="bzless"
elif [[ "$FILE" == *.xz ]]; then
    CAT_CMD="xzcat"
    GREP_CMD="xzgrep"
    LESS_CMD="xzless"
else
    GREP_CMD="grep"
    LESS_CMD="less"
fi

echo "=================================================================="
echo "Streaming Processor: $FILE"
echo "Using: $CAT_CMD / $GREP_CMD / $LESS_CMD"
echo "=================================================================="

# --- 1. Preview first 5 rows (no decompression to disk) ---
echo ""
echo "--- 1. First 5 rows ---"
$CAT_CMD "$FILE" | head -n 5

# --- 2. Count total rows (excluding header) ---
echo ""
echo "--- 2. Total data rows ---"
TOTAL=$($CAT_CMD "$FILE" | tail -n +2 | wc -l)
echo "$TOTAL"

# --- 3. Sum the revenue column (field 7 = unit_price, field 6 = quantity) ---
echo ""
echo "--- 3. Total revenue (quantity * unit_price) ---"
$CAT_CMD "$FILE" | awk -F',' 'NR > 1 {sum += $6 * $7} END {printf "Total Revenue: $ %.2f\n", sum}'

# --- 4. Average unit price by region ---
echo ""
echo "--- 4. Average unit price by region ---"
$CAT_CMD "$FILE" | awk -F',' '
    NR > 1 {
        region = $3
        price = $7
        total[region] += price
        count[region]++
    }
    END {
        printf "%-12s %-10s %-15s\n", "Region", "Count", "Avg Unit Price"
        for (r in total) {
            printf "%-12s %-10d $ %-14.2f\n", r, count[r], total[r]/count[r]
        }
    }'

# --- 5. Count how many orders are from the "North" region ---
echo ""
echo "--- 5. Orders from North region ---"
$GREP_CMD "^[^,]*,[^,]*,North" "$FILE" | wc -l

# --- 6. Extract high-value orders (unit_price > 100) and compress into new file ---
OUTPUT="high_value_orders.csv.gz"
echo ""
echo "--- 6. Extract high-value orders (unit_price > 100) → $OUTPUT ---"
$CAT_CMD "$FILE" | awk -F',' 'NR == 1 || $7 > 100 {print}' | gzip > "$OUTPUT"
SIZE=$(stat -c '%s' "$OUTPUT" 2>/dev/null || echo 0)
SIZE_H=$(numfmt --to=iec "$SIZE" 2>/dev/null || echo "${SIZE}B")
ROWS_OUT=$($CAT_CMD "$OUTPUT" | tail -n +2 | wc -l)
echo "Wrote $ROWS_OUT rows → $OUTPUT ($SIZE_H)"

echo ""
echo "=================================================================="
echo "All operations were streamed. No uncompressed file was written to disk."
echo "=================================================================="
