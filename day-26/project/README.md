# Multi-Service Data Pipeline

A Docker-based data pipeline that fetches posts from a public API, processes them, and serves results via a REST API.

## Services

- **api-ingestor** — fetches data from JSONPlaceholder and writes CSV to `data/raw/`
- **data-processor** — cleans CSV, computes `title_length` and `word_count`, writes to `data/processed/`
- **database** — PostgreSQL with schema in `database/init.sql`
- **web-api** — Flask app exposing `/health`, `/posts`, and `/summary`
- **monitoring** — polls all services and prints health reports

## Prerequisites

```bash
docker --version
docker compose version
```

## Quick Start

### 1. Run the full pipeline

```bash
cd project/
chmod +x run_pipeline.sh
./run_pipeline.sh
```

This builds images, starts the database, waits for it to be healthy, then brings up all services.

### 2. Check the API

```bash
curl http://localhost:5000/health
curl http://localhost:5000/posts | python -m json.tool
curl http://localhost:5000/summary | python -m json.tool
```

### 3. View logs

```bash
docker compose logs -f web-api
docker compose logs -f api-ingestor
docker compose logs -f data-processor
docker compose logs -f database
```

### 4. Stop everything

```bash
docker compose down
```

To also remove volumes and database data:

```bash
docker compose down -v
```

## Alternative: Simple Standalone Pipeline

For a quick demo without building custom images:

```bash
chmod +x simple_pipeline.sh
./simple_pipeline.sh
```

This runs `docker run` commands directly to fetch and process 10 posts using public Python images.

## Testing

```bash
chmod +x test_pipeline.sh
./test_pipeline.sh
```

The test script:
1. Runs `./run_pipeline.sh`
2. Waits 30 seconds for initialization
3. Checks the health endpoint
4. Verifies processed data files exist
5. Hits `/posts` and `/summary`
6. Prints container status

## Data Flow

1. **api-ingestor** fetches posts from `https://jsonplaceholder.typicode.com/posts`
2. Saves raw CSV to `data/raw/posts_<timestamp>.csv`
3. **data-processor** reads the latest raw file, adds `title_length` and `word_count`, filters posts with title length > 10, and writes:
   - `data/processed/processed_<timestamp>.csv`
   - `data/processed/summary_<timestamp>.csv`
4. **web-api** reads from SQLite `/data/pipeline.db` and serves via Flask on port 5000
5. **monitoring** polls all service health endpoints every 30 seconds

## Troubleshooting

### "No configuration file provided"
Run all `docker compose` commands from the directory containing `docker-compose.yml`:
```bash
cd /path/to/project/
docker compose up -d
```

### Database not ready
Check database logs:
```bash
docker compose logs database
```

### Port 5000 in use
Change the mapping in `docker-compose.yml`:
```yaml
ports:
  - "5001:5000"
```
