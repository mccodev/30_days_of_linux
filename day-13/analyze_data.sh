#!/bin/bash

# A sample script to demonstrate how jq can be used in a Bash script for parsing and formatting.

echo "=== System Events Overview ==="
# Get the length of the events array
TOTAL_EVENTS=$(jq 'length' events.json)
echo "Total events recorded: $TOTAL_EVENTS"

echo -e "\n=== Error Logs ==="
# Check events.json for ERROR level logs.
# We use -r (raw-output) so the result isn't quoted like a JSON string.
# String interpolation '\(...)' allows formatting directly inside jq.
jq -r '.[] | select(.level == "ERROR") | "[\(.timestamp)] \(.message)"' events.json

echo -e "\n=== Active Users ==="
# Extract users from the users array, filter by active == true, and format nicely.
jq -r '.users[] | select(.active == true) | "- \(.name) (\(.email))"' users.json

echo -e "\n=== Analysis Complete ==="
