# Day 26 Mini Project: Multi-Service Data Pipeline with Docker

## Project Overview

Build a complete data processing pipeline using Docker containers that:
1. **Ingests** data from a REST API
2. **Processes** and transforms the data
3. **Stores** results in a database
4. **Serves** data via a simple web API
5. **Monitors** the entire pipeline health

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   API      │    │  Processor  │    │ Database    │    │   Web API   │
│  Ingestor  │───▶│  Service    │───▶│  Service    │───▶│  Service    │
│  Container  │    │  Container  │    │  Container  │    │  Container  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## Project Structure

```
day-26-project/
├── docker-compose.yml          # Orchestrate all services
├── api-ingestor/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── ingest.py
├── data-processor/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── process.py
├── database/
│   └── init.sql
├── web-api/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── api.py
├── monitoring/
│   ├── Dockerfile
│   └── health_check.py
├── data/
│   ├── raw/              # Input data storage
│   ├── processed/         # Processed data storage
│   └── logs/             # Pipeline logs
└── README.md
```

## Step 1: API Data Ingestor

**File: `api-ingestor/ingest.py`**
```python
import requests
import json
import csv
import os
from datetime import datetime

# Fetch data from public API
def fetch_data():
    url = "https://jsonplaceholder.typicode.com/posts"
    response = requests.get(url)
    return response.json()

# Save to CSV for processing
def save_to_csv(data, filename):
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['id', 'userId', 'title', 'body'])
        for post in data:
            writer.writerow([post['id'], post['userId'], post['title'], post['body']])

if __name__ == "__main__":
    data = fetch_data()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"/data/raw/posts_{timestamp}.csv"
    save_to_csv(data, filename)
    print(f"Data saved to {filename}")
```

**File: `api-ingestor/Dockerfile`**
```dockerfile
FROM python:3.9-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY ingest.py .
CMD ["python", "ingest.py"]
```

## Step 2: Data Processor

**File: `data-processor/process.py`**
```python
import pandas as pd
import glob
import os
from datetime import datetime

def process_csv(input_file):
    df = pd.read_csv(input_file)
    
    # Data cleaning and transformation
    df['title_length'] = df['title'].str.len()
    df['word_count'] = df['body'].str.split().str.len()
    df['processed_at'] = datetime.now()
    
    # Filter and aggregate
    processed = df[df['title_length'] > 10]
    summary = processed.groupby('userId').agg({
        'title_length': 'mean',
        'word_count': 'mean',
        'id': 'count'
    }).reset_index()
    
    return processed, summary

def main():
    # Find latest raw data file
    files = glob.glob('/data/raw/*.csv')
    if not files:
        print("No data files found")
        return
    
    latest_file = max(files)
    print(f"Processing {latest_file}")
    
    processed_data, summary = process_csv(latest_file)
    
    # Save processed data
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    processed_file = f"/data/processed/processed_{timestamp}.csv"
    summary_file = f"/data/processed/summary_{timestamp}.csv"
    
    processed_data.to_csv(processed_file, index=False)
    summary.to_csv(summary_file, index=False)
    
    print(f"Processed data saved to {processed_file}")
    print(f"Summary saved to {summary_file}")

if __name__ == "__main__":
    main()
```

**File: `data-processor/Dockerfile`**
```dockerfile
FROM python:3.9-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY process.py .
CMD ["python", "process.py"]
```

## Step 3: Database Service

**File: `database/init.sql`**
```sql
CREATE TABLE IF NOT EXISTS processed_posts (
    id INTEGER PRIMARY KEY,
    userId INTEGER,
    title TEXT,
    body TEXT,
    title_length INTEGER,
    word_count INTEGER,
    processed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_summary (
    userId INTEGER PRIMARY KEY,
    avg_title_length REAL,
    avg_word_count REAL,
    post_count INTEGER,
    updated_at TIMESTAMP
);
```

## Step 4: Web API Service

**File: `web-api/api.py`**
```python
from flask import Flask, jsonify
import sqlite3
import os

app = Flask(__name__)

def get_db_connection():
    conn = sqlite3.connect('/data/pipeline.db')
    return conn

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "web-api"})

@app.route('/posts')
def get_posts():
    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM processed_posts ORDER BY processed_at DESC LIMIT 100")
    posts = [dict(row) for row in cursor.fetchall()]
    
    conn.close()
    return jsonify(posts)

@app.route('/summary')
def get_summary():
    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM user_summary ORDER BY updated_at DESC")
    summary = [dict(row) for row in cursor.fetchall()]
    
    conn.close()
    return jsonify(summary)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
```

## Step 5: Health Monitoring

**File: `monitoring/health_check.py`**
```python
import requests
import time
import json
from datetime import datetime

def check_service_health():
    services = {
        'api-ingestor': 'http://api-ingestor:8000/health',
        'data-processor': 'http://data-processor:8001/health', 
        'web-api': 'http://web-api:5000/health',
        'database': 'http://web-api:5000/db-health'
    }
    
    while True:
        timestamp = datetime.now().isoformat()
        status_report = {"timestamp": timestamp, "services": {}}
        
        for service, url in services.items():
            try:
                response = requests.get(url, timeout=5)
                status = "healthy" if response.status_code == 200 else "unhealthy"
            except Exception as e:
                status = f"error: {str(e)}"
            
            status_report["services"][service] = status
        
        print(json.dumps(status_report, indent=2))
        time.sleep(30)

if __name__ == "__main__":
    check_service_health()
```

## Step 6: Docker Compose Orchestration

**File: `docker-compose.yml`**
```yaml
version: '3.8'

services:
  # PostgreSQL Database
  database:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: pipeline_db
      POSTGRES_USER: pipeline_user
      POSTGRES_PASSWORD: pipeline_pass
    volumes:
      - db_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - pipeline_net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pipeline_user -d pipeline_db"]
      interval: 30s
      timeout: 10s
      retries: 3

  # API Data Ingestor
  api-ingestor:
    build: ./api-ingestor
    volumes:
      - ./data:/data
    networks:
      - pipeline_net
    depends_on:
      database:
        condition: service_healthy
    environment:
      - SCHEDULE=*/5 * * * *  # Every 5 minutes for demo

  # Data Processor
  data-processor:
    build: ./data-processor
    volumes:
      - ./data:/data
    networks:
      - pipeline_net
    depends_on:
      - api-ingestor

  # Web API
  web-api:
    build: ./web-api
    ports:
      - "5000:5000"
    volumes:
      - db_data:/data
    networks:
      - pipeline_net
    depends_on:
      database:
        condition: service_healthy
      data-processor:
        condition: service_completed_successfully

  # Health Monitor
  monitoring:
    build: ./monitoring
    networks:
      - pipeline_net
    depends_on:
      - api-ingestor
      - data-processor
      - web-api

volumes:
  db_data:

networks:
  pipeline_net:
    driver: bridge
```

## Step 7: Automation Scripts

**File: `run_pipeline.sh`**
```bash
#!/bin/bash
set -euo pipefail

echo "🐳 Starting Docker Data Pipeline..."

# Build all services
echo "📦 Building Docker images..."
docker-compose build

# Start infrastructure first
echo "🗄️  Starting database..."
docker-compose up -d database

# Wait for database to be ready
echo "⏳ Waiting for database..."
sleep 10

# Start all services
echo "🚀 Starting all services..."
docker-compose up -d

# Show status
echo "📊 Service Status:"
docker-compose ps

echo "✅ Pipeline started!"
echo "🌐 Web API available at: http://localhost:5000"
echo "💾 Data stored in: ./data/"
echo "📈 Monitor logs with: docker-compose logs -f"

# Cleanup script
cat > cleanup.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping pipeline..."
docker-compose down -v
echo "🧹 Cleaning up..."
docker system prune -f
echo "✅ Cleanup complete!"
EOF

chmod +x cleanup.sh
```

## Step 8: Testing the Pipeline

**File: `test_pipeline.sh`**
```bash
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
```

## Learning Objectives

By building this project, you'll master:

1. **Multi-container Architecture**: Design and coordinate multiple services
2. **Service Dependencies**: Manage startup order and health checks
3. **Data Flow**: Move data between containers using volumes
4. **Networking**: Configure container communication
5. **Health Monitoring**: Implement service health checks
6. **Production Practices**: Use environment variables, logging, graceful shutdown
7. **Docker Compose**: Orchestrate complex applications
8. **Automation**: Build shell scripts for deployment and testing

## Extension Ideas

1. **Add Redis**: Cache frequently accessed data
2. **Implement Message Queue**: Use RabbitMQ for async processing
3. **Add Monitoring**: Integrate Prometheus/Grafana
4. **Load Balancing**: Multiple web-api instances
5. **CI/CD Integration**: GitHub Actions for automated deployment
6. **Data Visualization**: Add a dashboard service
7. **Security**: Add authentication and SSL/TLS
8. **Scaling**: Horizontal scaling with Docker Swarm

## Run the Project

```bash
# Clone or create the project structure
mkdir -p day-26-project
cd day-26-project

# Create all the files as shown above
# (Copy each file content into respective directories)

# Run the pipeline
chmod +x run_pipeline.sh test_pipeline.sh
./run_pipeline.sh

# Test everything
./test_pipeline.sh

# Monitor logs
docker-compose logs -f

# Cleanup when done
./cleanup.sh
```

This project combines **all Docker concepts** from Day 26 into a real-world data engineering scenario!
