#!/bin/bash
# Comprehensive log analysis and monitoring tool

LOG_FILE="${1:-/var/log/syslog}"
PATTERN="${2:-ERROR}"
ALERT_THRESHOLD=5

echo "=== Log Analysis Report ==="
echo "Analyzing: $LOG_FILE"
echo "Pattern: $PATTERN"
echo "Generated: $(date)"
echo

# Check if log file exists and is readable
if [ ! -r "$LOG_FILE" ]; then
    echo "❌ Error: Cannot read log file $LOG_FILE"
    echo "Try running with sudo or check file permissions"
    exit 1
fi

# Count pattern occurrences
COUNT=$(grep -c "$PATTERN" "$LOG_FILE" 2>/dev/null || echo "0")
echo "Total '$PATTERN' occurrences: $COUNT"

# Alert if threshold exceeded
if [ "$COUNT" -gt "$ALERT_THRESHOLD" ]; then
    echo "⚠️  ALERT: Pattern count exceeds threshold ($ALERT_THRESHOLD)"
fi

# Show recent occurrences
echo
echo "Recent occurrences:"
grep "$PATTERN" "$LOG_FILE" | tail -10

# Hourly breakdown (last 24 hours)
echo
echo "Hourly breakdown (last 24 hours):"
for hour in {23..0}; do
    hour_start=$(date -d "$hour hours ago" +"%b %d %H")
    count=$(grep "$hour_start" "$LOG_FILE" 2>/dev/null | grep -c "$PATTERN" || echo "0")
    echo "$(date -d "$hour hours ago" +"%H:00"): $count"
done

# Top error patterns (if searching for ERROR)
if [ "$PATTERN" = "ERROR" ]; then
    echo
    echo "Top error types:"
    grep "ERROR" "$LOG_FILE" | awk -F'ERROR:' '{print $2}' | sort | uniq -c | sort -nr | head -5
fi

# File size information
echo
echo "Log file information:"
ls -lh "$LOG_FILE" | awk '{print "Size: " $5 ", Modified: " $6 " " $7 " " $8}'

echo
echo "=== End of Report ==="
