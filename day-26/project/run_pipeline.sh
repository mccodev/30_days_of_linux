#!/bin/bash
set -euo pipefail

echo "🐳 Starting Docker Data Pipeline..."

# Build all services
echo "📦 Building Docker images..."
docker compose build

# Start infrastructure first
echo "🗄️  Starting database..."
docker compose up -d database

# Wait for database to be ready
echo "⏳ Waiting for database..."
sleep 10

# Start all services
echo "🚀 Starting all services..."
docker compose up -d

# Show status
echo "📊 Service Status:"
docker compose ps

echo "✅ Pipeline started!"
echo "🌐 Web API available at: http://localhost:5000"
echo "💾 Data stored in: ./data/"
echo "📈 Monitor logs with: docker compose logs -f"

# Cleanup script
cat > cleanup.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping pipeline..."
docker compose down -v
echo "🧹 Cleaning up..."
docker system prune -f
echo "✅ Cleanup complete!"
EOF

chmod +x cleanup.sh
