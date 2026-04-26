#!/bin/bash
set -euo pipefail

echo "🧪 Testing Docker Data Pipeline..."

# Test 1: Build and start
echo "Test 1: Building and starting services..."
./run_pipeline.sh

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 30

# Test 2: Check service health
echo "Test 2: Checking service health..."
curl -f http://localhost:5000/health || echo "❌ Web API health check failed"

# Test 3: Verify data processing
echo "Test 3: Checking data processing..."
if [ -f "./data/processed/processed_*.csv" ]; then
    echo "✅ Data processing working"
    echo "📁 Processed files:"
    ls -la ./data/processed/
else
    echo "❌ No processed data found"
fi

# Test 4: API endpoints
echo "Test 4: Testing API endpoints..."
echo "Posts endpoint:"
curl -s http://localhost:5000/posts | head -c 200
echo -e "\n\nSummary endpoint:"
curl -s http://localhost:5000/summary | head -c 200

# Test 5: Container monitoring
echo -e "\n\nTest 5: Container status:"
docker-compose ps

echo -e "\n🎉 Pipeline testing complete!"
echo "📊 View live data at: http://localhost:5000/posts"
