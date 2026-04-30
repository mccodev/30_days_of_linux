#!/usr/bin/env bash
set -euo pipefail

# backup.sh — configurable rsync backup wrapper with logging
# Usage: ./backup.sh [OPTIONS] SOURCE DESTINATION

show_help() {
    cat <<EOF
Usage: backup.sh [OPTIONS] SOURCE DESTINATION

Wraps rsync with sensible defaults, progress display, and logging.

Options:
  -h, --help        Show this help message and exit
  -n, --dry-run     Perform a trial run with no changes
  -e, --exclude PATTERN
                    Exclude files matching PATTERN (can be used multiple times)

Examples:
  backup.sh ~/Documents /mnt/backup/documents
  backup.sh -n ~/Pictures /mnt/backup/pictures
  backup.sh -e '*.tmp' -e 'node_modules' ~/project /mnt/backup/project
EOF
}

DRY_RUN=""
EXCLUDES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        -e|--exclude)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --exclude requires a pattern" >&2
                exit 1
            fi
            EXCLUDES+=("--exclude=$2")
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            show_help >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -lt 2 ]]; then
    echo "Error: SOURCE and DESTINATION are required" >&2
    show_help >&2
    exit 1
fi

SOURCE="$1"
DEST="$2"

if [[ ! -e "$SOURCE" ]]; then
    echo "Error: SOURCE does not exist: $SOURCE" >&2
    exit 1
fi

LOG_DIR="$HOME/.local/var/log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/backup-$(date +%Y%m%d-%H%M%S).log"

# Build rsync options
OPTS=(-avh --progress --delete)
if [[ -n "$DRY_RUN" ]]; then
    OPTS+=("$DRY_RUN")
fi
if [[ ${#EXCLUDES[@]} -gt 0 ]]; then
    OPTS+=("${EXCLUDES[@]}")
fi

echo "Starting backup..."
echo "  Source:      $SOURCE"
echo "  Destination: $DEST"
echo "  Log file:    $LOGFILE"
if [[ -n "$DRY_RUN" ]]; then
    echo "  Mode:        DRY RUN (no changes)"
fi

# Run backup
rsync "${OPTS[@]}" "$SOURCE" "$DEST" 2>&1 | tee "$LOGFILE"

EXIT_CODE=${PIPESTATUS[0]}

if [[ $EXIT_CODE -eq 0 ]]; then
    echo ""
    echo "Backup completed successfully. Log: $LOGFILE"
else
    echo ""
    echo "Backup finished with warnings/errors (exit code: $EXIT_CODE). Check log: $LOGFILE" >&2
fi

exit $EXIT_CODE
