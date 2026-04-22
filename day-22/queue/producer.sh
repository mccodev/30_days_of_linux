#!/bin/bash

# File-based Message Queue Producer
# Usage: ./producer.sh "message content"

QUEUE_DIR="./queue"
INCOMING_DIR="$QUEUE_DIR/incoming"
MESSAGE_ID=$(date +%s%N | cut -c1-13)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Ensure directories exist
mkdir -p "$INCOMING_DIR"

# Create message
MESSAGE_FILE="$INCOMING_DIR/msg_$MESSAGE_ID.json"
cat > "$MESSAGE_FILE" << EOF
{
  "id": "$MESSAGE_ID",
  "timestamp": "$TIMESTAMP",
  "status": "pending",
  "content": "$1",
  "attempts": 0
}
EOF

# Message is already in incoming directory (atomic create)

echo "Enqueued message: $MESSAGE_ID"
echo "Queue size: $(ls -1 "$INCOMING_DIR"/*.json 2>/dev/null | wc -l)"
