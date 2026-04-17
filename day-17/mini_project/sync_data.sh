#!/bin/bash

# ==============================================================================
# Script: sync_data.sh
# Purpose: Simulates transferring raw data from a local extraction server 
#          to a remote Data Lake backup node using scp and rsync.
# ==============================================================================

set -euo pipefail

# 1. Configuration Variables
# Since we only have one machine in this lab, we mock the "remote server" by 
# syncing data to a different isolated directory on the same local Linux machine.
LOCAL_DATA_DIR="./local_extracts"
MOCK_REMOTE_NODE="/tmp/data_lake_node"

echo "🚀 Setting up local and remote environments..."
mkdir -p "$LOCAL_DATA_DIR"
mkdir -p "$MOCK_REMOTE_NODE"

# Generate 3 dummy API response files Locally
for i in {1..3}; do
    echo "user_id,event_name,timestamp" > "${LOCAL_DATA_DIR}/event_log_${i}.csv"
    echo "$((RANDOM % 100)),click,2026-04-17T10:05:00" >> "${LOCAL_DATA_DIR}/event_log_${i}.csv"
done
echo "✅ Local dummy data generated."
echo "--------------------------------------------------------"

# 2. Secure Copy Protocol (SCP)
# SCP is simple and overrides everything. Used for quick one-off pushes.
echo "🚢 Step 1: Pushing a single file using 'scp'..."
# Note: In a real scenario, syntax is -> scp source_file.csv user@10.0.0.5:/remote/dir
scp "${LOCAL_DATA_DIR}/event_log_1.csv" "${MOCK_REMOTE_NODE}/"
echo "✅ event_log_1 successfully pushed via SCP."
echo "--------------------------------------------------------"

# 3. RSYNC (Remote Sync)
# Rsync is intelligent. It checks what already exists and only moves the difference!
echo "🔄 Step 2: Syncing the entire directory using 'rsync'..."
# -a: Archive mode (recursive, preserve permissions)
# -v: Verbose (see what's happening)
# -z: Compress data during network transfer
rsync -avz "${LOCAL_DATA_DIR}/" "${MOCK_REMOTE_NODE}/"
echo "✅ Initial rsync complete."
echo "--------------------------------------------------------"

# 4. Demonstrating incrementally updating with rsync
echo "📝 Step 3: Mutating local data and re-syncing to show rsync's power..."
echo "999,purchase,2026-04-17T11:00:00" >> "${LOCAL_DATA_DIR}/event_log_2.csv"

# Run rsync again! Watch how it ONLY transfers event_log_2.csv instead of all 3 files.
echo "  [Running rsync AGAIN... Notice it only pushes event_log_2!]"
rsync -avz "${LOCAL_DATA_DIR}/" "${MOCK_REMOTE_NODE}/"

echo "--------------------------------------------------------"

# 5. Demonstrating deletion mirroring with rsync
echo "🗑️  Step 4: Demonstrating --delete flag..."
rm "${LOCAL_DATA_DIR}/event_log_3.csv"
echo "  [Local event_log_3 deleted. Mirroring deletion to remote...]"
# Add --delete to force the remote to mirror our local deletions.
rsync -avz --delete "${LOCAL_DATA_DIR}/" "${MOCK_REMOTE_NODE}/"

echo "--------------------------------------------------------"
echo "🎉 Pipeline finished! Mock remote Data Lake is fully synchronized."
echo "   Check: 'ls -l $MOCK_REMOTE_NODE' to verify."
