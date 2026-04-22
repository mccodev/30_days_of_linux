#!/bin/bash

# Queue Monitor - Shows queue status and statistics
# Usage: ./monitor.sh

QUEUE_DIR="./queue"
INCOMING_DIR="$QUEUE_DIR/incoming"
PROCESSING_DIR="$QUEUE_DIR/processing"
PROCESSED_DIR="$QUEUE_DIR/processed"
FAILED_DIR="$QUEUE_DIR/failed"

echo "=== Message Queue Status ==="
echo "Time: $(date)"
echo

# Count messages in each state
incoming_count=$(ls -1 "$INCOMING_DIR"/*.json 2>/dev/null | wc -l)
processing_count=$(ls -1 "$PROCESSING_DIR"/*.json 2>/dev/null | wc -l)
processed_count=$(ls -1 "$PROCESSED_DIR"/*.json 2>/dev/null | wc -l)
failed_count=$(ls -1 "$FAILED_DIR"/*.json 2>/dev/null | wc -l)

echo "Queue Status:"
echo "  Pending:    $incoming_count"
echo "  Processing: $processing_count"
echo "  Processed:  $processed_count"
echo "  Failed:     $failed_count"
echo

# Show recent processed messages
if [ "$processed_count" -gt 0 ]; then
    echo "Recent Processed Messages:"
    ls -lt "$PROCESSED_DIR"/*.json 2>/dev/null | head -3 | while read -r line; do
        msg_file=$(echo "$line" | awk '{print $9}')
        if [ -f "$msg_file" ]; then
            msg_id=$(jq -r '.id' "$msg_file")
            timestamp=$(jq -r '.processed_at // .timestamp' "$msg_file")
            echo "  $msg_id - $timestamp"
        fi
    done
fi

# Show processing messages
if [ "$processing_count" -gt 0 ]; then
    echo
    echo "Currently Processing:"
    ls "$PROCESSING_DIR"/*.json 2>/dev/null | while read -r msg_file; do
        msg_id=$(jq -r '.id' "$msg_file")
        echo "  $msg_id"
    done
fi
