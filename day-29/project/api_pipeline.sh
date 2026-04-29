#!/bin/bash
# api_pipeline.sh - Lightweight ETL: API -> SQLite -> CSV report
set -euo pipefail

DB="pipeline.db"
API_URL="https://jsonplaceholder.typicode.com/posts"
REPORT="top_posts.csv"

echo "Step 1: Clean start"
rm -f "$DB" "$REPORT"

echo "Step 2: Create table"
sqlite3 "$DB" "CREATE TABLE posts (id INTEGER, userId INTEGER, title TEXT, body TEXT);"

echo "Step 3: Fetch from API -> parse with jq -> import into SQLite"
curl -s "$API_URL" \
  | jq -r '.[] | [.id, .userId, .title, .body] | @csv' \
  | sqlite3 "$DB" ".import /dev/stdin posts"

echo "Step 4: Verify import count"
sqlite3 "$DB" "SELECT COUNT(*) || ' posts imported' FROM posts;"

echo "Step 5: Generate report — top 10 longest posts by word count -> CSV"
sqlite3 "$DB" -csv <<EOF > "$REPORT"
SELECT
  userId,
  id,
  title,
  LENGTH(body) - LENGTH(REPLACE(body, ' ', '')) + 1 AS word_count
FROM posts
ORDER BY word_count DESC
LIMIT 10;
EOF

echo ""
echo "Step 6: Preview report"
column -t -s ',' "$REPORT" | head -12

echo ""
echo "Done. Report written to: $REPORT"
