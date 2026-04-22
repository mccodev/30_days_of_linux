#!/bin/bash

# File-based Message Queue Consumer
# Usage: ./consumer.sh

QUEUE_DIR="./queue"
INCOMING_DIR="$QUEUE_DIR/incoming"
PROCESSING_DIR="$QUEUE_DIR/processing"
PROCESSED_DIR="$QUEUE_DIR/processed"
FAILED_DIR="$QUEUE_DIR/failed"

# Ensure directories exist
mkdir -p "$INCOMING_DIR" "$PROCESSING_DIR" "$PROCESSED_DIR" "$FAILED_DIR"

# Function to acquire lock
acquire_lock() {
    local lock_file="$1"
    local timeout=10
    local count=0
    
    while [ $count -lt $timeout ]; do
        if (set -C; echo $$ > "$lock_file") 2>/dev/null; then
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    return 1
}

# Function to release lock
release_lock() {
    rm -f "$1"
}

# Main consumer loop
while true; do
    # Find next message to process
    for msg_file in "$INCOMING_DIR"/*.json; do
        [ -f "$msg_file" ] || break
        
        msg_name=$(basename "$msg_file")
        lock_file="$PROCESSING_DIR/${msg_name}.lock"
        
        # Try to acquire lock for this message
        if acquire_lock "$lock_file"; then
            echo "Processing: $msg_name"
            
            # Move to processing directory
            mv "$msg_file" "$PROCESSING_DIR/"
            processing_file="$PROCESSING_DIR/$msg_name"
            
            # Read message content
            content=$(cat "$processing_file")
            
            # Simulate processing (could be any data transformation)
            sleep 2
            
            # Update message status
            updated_content=$(echo "$content" | jq --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '
                .status = "processed" |
                .processed_at = $timestamp |
                .attempts += 1
            ')
            
            echo "$updated_content" > "$processing_file"
            
            # Move to processed
            mv "$processing_file" "$PROCESSED_DIR/"
            
            # Release lock
            release_lock "$lock_file"
            
            echo "Completed: $msg_name"
            echo "Queue size: $(ls -1 "$INCOMING_DIR"/*.json 2>/dev/null | wc -l)"
        fi
    done
    
    # Sleep before checking again
    sleep 1
done
