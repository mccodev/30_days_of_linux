#!/bin/bash
set -euo pipefail

echo "🐳 Simple Docker Pipeline Demo"

# Create data directories
mkdir -p data/{raw,processed,logs}

# Step 1: Run API Ingestor
echo "📥 Step 1: Fetching data..."
docker run --rm \
  -v "$(pwd)/data:/data" \
  --name api-test \
  python:3.9-alpine \
  sh -c "
    apk add --no-cache curl
    python -c \"
import requests, csv, os, json
from datetime import datetime
response = requests.get('https://jsonplaceholder.typicode.com/posts')
data = response.json()
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
filename = f'/data/raw/posts_{timestamp}.csv'
os.makedirs(os.path.dirname(filename), exist_ok=True)
with open(filename, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['id', 'userId', 'title', 'body'])
    for post in data[:10]:  # Just first 10 for demo
        writer.writerow([post['id'], post['userId'], post['title'], post['body']])
print(f'Data saved to {filename}')
    "

echo "✅ Data fetched and saved!"

# Step 2: Process the data
echo "⚙️  Step 2: Processing data..."
docker run --rm \
  -v "$(pwd)/data:/data" \
  --name process-test \
  python:3.9-alpine \
  sh -c "
    apk add --no-cache curl
    python -c \"
import pandas as pd, glob, os
from datetime import datetime
files = glob.glob('/data/raw/*.csv')
if files:
    latest_file = max(files)
    print(f'Processing {latest_file}')
    df = pd.read_csv(latest_file)
    df['title_length'] = df['title'].str.len()
    df['processed_at'] = datetime.now()
    processed_file = f'/data/processed/processed_{datetime.now().strftime(\"%Y%m%d_%H%M%S\")}.csv'
    os.makedirs(os.path.dirname(processed_file), exist_ok=True)
    df.to_csv(processed_file, index=False)
    print(f'Processed data saved to {processed_file}')
else:
    print('No files to process')
    "
  "

echo "✅ Data processed!"

# Step 3: Show results
echo "📊 Results:"
echo "Raw files:"
ls -la data/raw/ 2>/dev/null || echo "  No raw files"
echo "Processed files:"
ls -la data/processed/ 2>/dev/null || echo "  No processed files"

echo "🎉 Pipeline complete!"
echo "💡 Data is available in ./data/ directory"
