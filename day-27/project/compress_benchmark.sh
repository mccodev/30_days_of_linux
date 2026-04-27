#!/bin/bash
# compress_benchmark.sh
# Benchmarks gzip, bzip2, xz, and pigz on a given file.
# Usage: ./compress_benchmark.sh <file>

set -euo pipefail

FILE="${1:?Usage: $0 <file>}"

if [[ ! -f "$FILE" ]]; then
    echo "Error: file not found: $FILE"
    exit 1
fi

ORIG_SIZE=$(stat -c '%s' "$FILE")
ORIG_HUMAN=$(numfmt --to=iec "$ORIG_SIZE" 2>/dev/null || echo "${ORIG_SIZE}B")

echo "=================================================================="
echo "Compression Benchmark: $FILE"
echo "Original size: $ORIG_HUMAN ($ORIG_SIZE bytes)"
echo "=================================================================="
printf "%-12s %-12s %-12s %-10s %-10s\n" "Tool" "Size" "Ratio" "Time(s)" "Speed"
echo "------------------------------------------------------------------"

# gzip
echo -n "Benchmarking gzip ... "
start=$(date +%s.%N)
gzip -k -c "$FILE" > /dev/null
end=$(date +%s.%N)
GZIP_TIME=$(awk -v s="$start" -v e="$end" 'BEGIN{printf "%.3f", e-s}')
gzip -k "$FILE"
GZIP_SIZE=$(stat -c '%s' "$FILE.gz")
GZIP_RATIO=$(awk -v o="$ORIG_SIZE" -v c="$GZIP_SIZE" 'BEGIN{printf "%.2f", o/c}')
GZIP_HUMAN=$(numfmt --to=iec "$GZIP_SIZE")
printf "%-12s %-12s %-12s %-10s %-10s\n" "gzip" "$GZIP_HUMAN" "${GZIP_RATIO}x" "$GZIP_TIME" "$(awk -v s="$ORIG_SIZE" -v t="$GZIP_TIME" 'BEGIN{printf "%.1f", (s/1048576)/t}') MB/s"

# bzip2
echo -n "Benchmarking bzip2 ... "
start=$(date +%s.%N)
bzip2 -k -c "$FILE" > /dev/null
end=$(date +%s.%N)
BZIP_TIME=$(awk -v s="$start" -v e="$end" 'BEGIN{printf "%.3f", e-s}')
bzip2 -k "$FILE"
BZIP_SIZE=$(stat -c '%s' "$FILE.bz2")
BZIP_RATIO=$(awk -v o="$ORIG_SIZE" -v c="$BZIP_SIZE" 'BEGIN{printf "%.2f", o/c}')
BZIP_HUMAN=$(numfmt --to=iec "$BZIP_SIZE")
printf "%-12s %-12s %-12s %-10s %-10s\n" "bzip2" "$BZIP_HUMAN" "${BZIP_RATIO}x" "$BZIP_TIME" "$(awk -v s="$ORIG_SIZE" -v t="$BZIP_TIME" 'BEGIN{printf "%.1f", (s/1048576)/t}') MB/s"

# xz (limit to level 6 to avoid very long wait on large files)
echo -n "Benchmarking xz ... "
start=$(date +%s.%N)
xz -k -6 -c "$FILE" > /dev/null
end=$(date +%s.%N)
XZ_TIME=$(awk -v s="$start" -v e="$end" 'BEGIN{printf "%.3f", e-s}')
xz -k -6 "$FILE"
XZ_SIZE=$(stat -c '%s' "$FILE.xz")
XZ_RATIO=$(awk -v o="$ORIG_SIZE" -v c="$XZ_SIZE" 'BEGIN{printf "%.2f", o/c}')
XZ_HUMAN=$(numfmt --to=iec "$XZ_SIZE")
printf "%-12s %-12s %-12s %-10s %-10s\n" "xz" "$XZ_HUMAN" "${XZ_RATIO}x" "$XZ_TIME" "$(awk -v s="$ORIG_SIZE" -v t="$XZ_TIME" 'BEGIN{printf "%.1f", (s/1048576)/t}') MB/s"

# pigz (if available)
if command -v pigz &> /dev/null; then
    echo -n "Benchmarking pigz ... "
    start=$(date +%s.%N)
    pigz -k -c "$FILE" > /dev/null
    end=$(date +%s.%N)
    PIGZ_TIME=$(awk -v s="$start" -v e="$end" 'BEGIN{printf "%.3f", e-s}')
    pigz -k "$FILE"
    PIGZ_SIZE=$(stat -c '%s' "$FILE.gz")
    PIGZ_RATIO=$(awk -v o="$ORIG_SIZE" -v c="$PIGZ_SIZE" 'BEGIN{printf "%.2f", o/c}')
    PIGZ_HUMAN=$(numfmt --to=iec "$PIGZ_SIZE")
    printf "%-12s %-12s %-12s %-10s %-10s\n" "pigz" "$PIGZ_HUMAN" "${PIGZ_RATIO}x" "$PIGZ_TIME" "$(awk -v s="$ORIG_SIZE" -v t="$PIGZ_TIME" 'BEGIN{printf "%.1f", (s/1048576)/t}') MB/s"
else
    echo "pigz not installed. Run: sudo apt install pigz"
fi

echo "=================================================================="
echo "Cleanup: remove compressed artifacts with: rm -f $FILE.gz $FILE.bz2 $FILE.xz"
