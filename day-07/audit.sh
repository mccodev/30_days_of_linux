#!/usr/bin/env bash
# =============================================================================
# audit.sh — Data Lake Folder Audit Script
# Week 1 Project | Day 07 — 30 Days of Linux for Data Engineering
#
# Usage:  ./audit.sh [data-directory]
#         Defaults to ./data if no argument is supplied.
#
# Output: audit_report.txt  (written to the current directory)
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
DATA_DIR="${1:-./data}"        # Directory to scan (first arg or ./data)
REPORT="audit_report.txt"     # Output report file
LARGE_THRESHOLD_MB=100        # Flag files larger than this many MB

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
separator() {
  printf '%s\n' "----------------------------------------------------------------"
}

bytes_to_human() {
  local bytes="$1"
  if   (( bytes >= 1073741824 )); then printf "%.2f GB" "$(echo "scale=2; $bytes/1073741824" | bc)"
  elif (( bytes >= 1048576    )); then printf "%.2f MB" "$(echo "scale=2; $bytes/1048576"    | bc)"
  elif (( bytes >= 1024       )); then printf "%.2f KB" "$(echo "scale=2; $bytes/1024"       | bc)"
  else                                 printf "%d  B"   "$bytes"
  fi
}

# ---------------------------------------------------------------------------
# Validate the data directory exists
# ---------------------------------------------------------------------------
if [[ ! -d "$DATA_DIR" ]]; then
  echo "ERROR: Directory '$DATA_DIR' not found." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Build the report (writes to $REPORT and echoes to stdout simultaneously)
# ---------------------------------------------------------------------------
{
  printf "DATA LAKE FOLDER AUDIT REPORT\n"
  printf "Generated : %s\n"  "$(date '+%Y-%m-%d %H:%M:%S')"
  printf "Directory : %s\n"  "$(realpath "$DATA_DIR")"
  printf "Threshold : Files > %dMB are flagged as [LARGE]\n" "$LARGE_THRESHOLD_MB"
  separator

  total_files=0
  total_bytes=0
  total_lines=0
  large_count=0

  # find all .csv files, sort the list for a tidy report
  while IFS= read -r -d '' csv_file; do

    total_files=$(( total_files + 1 ))

    # ---- size ---------------------------------------------------------------
    file_bytes=$(stat -c '%s' "$csv_file")
    total_bytes=$(( total_bytes + file_bytes ))
    human_size=$(bytes_to_human "$file_bytes")

    # ---- line count ---------------------------------------------------------
    line_count=$(wc -l < "$csv_file")
    total_lines=$(( total_lines + line_count ))

    # ---- large-file flag ----------------------------------------------------
    file_mb=$(( file_bytes / 1048576 ))
    flag=""
    if (( file_mb >= LARGE_THRESHOLD_MB )); then
      flag=" [LARGE]"
      large_count=$(( large_count + 1 ))
    fi

    # ---- print one record ---------------------------------------------------
    printf "\nFile      : %s%s\n"  "$csv_file" "$flag"
    printf "Size      : %s (%d bytes)\n" "$human_size" "$file_bytes"
    printf "Lines     : %d\n" "$line_count"

  done < <(find "$DATA_DIR" -type f -name "*.csv" -print0 | sort -z)

  # ---------------------------------------------------------------------------
  # Summary
  # ---------------------------------------------------------------------------
  separator
  printf "\nSUMMARY\n"
  separator
  printf "Total CSV files  : %d\n"  "$total_files"
  printf "Total size       : %s\n"  "$(bytes_to_human "$total_bytes")"
  printf "Total lines      : %d\n"  "$total_lines"
  printf "Large files (>%dMB): %d\n" "$LARGE_THRESHOLD_MB" "$large_count"
  separator

} | tee "$REPORT"

echo ""
echo "Report saved to: $(realpath "$REPORT")"
