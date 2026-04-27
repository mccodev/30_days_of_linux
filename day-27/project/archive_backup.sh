#!/bin/bash
# archive_backup.sh
# Archives a directory using tar + pigz (parallel gzip) with optional encryption.
# Creates a dated backup archive and generates a manifest.
# Usage: ./archive_backup.sh <source_dir> [output_dir]

set -euo pipefail

SRC="${1:?Usage: $0 <source_dir> [output_dir]}"
DEST="${2:-./backups}"
DATE=$(date +%Y%m%d_%H%M%S)
BASENAME=$(basename "$SRC")
ARCHIVE="$DEST/${BASENAME}_${DATE}.tar.gz"
MANIFEST="$DEST/${BASENAME}_${DATE}.manifest.txt"

if [[ ! -d "$SRC" ]]; then
    echo "Error: source directory not found: $SRC"
    exit 1
fi

mkdir -p "$DEST"

echo "=================================================================="
echo "Data Lake Backup Archive"
echo "Source : $SRC"
echo "Archive: $ARCHIVE"
echo "=================================================================="

# Count files and total size before archiving
FILE_COUNT=$(find "$SRC" -type f | wc -l)
TOTAL_BYTES=$(find "$SRC" -type f -exec stat -c '%s' {} + | awk '{s+=$1} END {print s}')
TOTAL_HUMAN=$(numfmt --to=iec "$TOTAL_BYTES" 2>/dev/null || echo "${TOTAL_BYTES}B")

echo "Files to archive: $FILE_COUNT"
echo "Total size     : $TOTAL_HUMAN"
echo ""

# Determine compression program
if command -v pigz &> /dev/null; then
    COMPRESSOR="pigz"
    echo "Using parallel compression: pigz"
else
    COMPRESSOR="gzip"
    echo "Using standard compression: gzip"
    echo "Tip: install pigz (sudo apt install pigz) for faster multi-core compression"
fi

# Create archive with tar
start=$(date +%s.%N)
if [[ "$COMPRESSOR" == "pigz" ]]; then
    tar --use-compress-program=pigz -cvf "$ARCHIVE" -C "$(dirname "$SRC")" "$(basename "$SRC")" > "$MANIFEST"
else
    tar -czvf "$ARCHIVE" -C "$(dirname "$SRC")" "$(basename "$SRC")" > "$MANIFEST"
fi
end=$(date +%s.%N)
ARCHIVE_TIME=$(awk -v s="$start" -v e="$end" 'BEGIN{printf "%.3f", e-s}')

ARCHIVE_SIZE=$(stat -c '%s' "$ARCHIVE")
ARCHIVE_HUMAN=$(numfmt --to=iec "$ARCHIVE_SIZE" 2>/dev/null || echo "${ARCHIVE_SIZE}B")
RATIO=$(awk -v o="$TOTAL_BYTES" -v a="$ARCHIVE_SIZE" 'BEGIN{printf "%.2f", o/a}')

echo ""
echo "------------------------------------------------------------------"
echo "Archive created : $ARCHIVE"
echo "Archive size    : $ARCHIVE_HUMAN"
echo "Compression ratio: ${RATIO}x"
echo "Time elapsed    : ${ARCHIVE_TIME}s"
echo "Manifest        : $MANIFEST"
echo "------------------------------------------------------------------"

# Verify archive integrity
echo ""
echo "Verifying archive integrity ..."
tar -tzf "$ARCHIVE" > /dev/null 2>&1 && echo "Archive is valid." || echo "WARNING: Archive verification failed!"

echo ""
echo "To extract this archive:"
echo "  tar -xzf $ARCHIVE -C /destination/path"
echo ""
echo "To list contents without extracting:"
echo "  tar -tzf $ARCHIVE | head -20"
