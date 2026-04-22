# File-based Message Queue MVP

## Overview
A lightweight message queue system built with bash and file system operations. Perfect for learning data engineering concepts like producer-consumer patterns, atomic operations, and message serialization.

## Features
- **Producer**: Enqueue messages as JSON files
- **Consumer**: Process messages with file locking
- **Monitor**: Real-time queue status and statistics
- **Atomic Operations**: Safe concurrent processing
- **Message Tracking**: Full audit trail with timestamps

## Quick Start

### 1. Enqueue Messages
```bash
./producer.sh "Process customer data batch #1234"
./producer.sh "Generate daily sales report"
```

### 2. Start Consumer
```bash
./consumer.sh  # Runs continuously, processes messages
```

### 3. Monitor Queue
```bash
./monitor.sh  # Shows queue status and recent messages
```

## Architecture

```
queue/
  incoming/     # New messages waiting to be processed
  processing/   # Messages currently being processed (with locks)
  processed/    # Successfully completed messages
  failed/       # Failed messages (for retry logic)
```

## Data Engineering Concepts Learned

1. **Producer-Consumer Pattern**: Decoupled message production and consumption
2. **Atomic File Operations**: Using file system for safe concurrent access
3. **Message Serialization**: JSON format for structured data
4. **File Locking**: Preventing race conditions with `flock`
5. **Queue Management**: Moving messages through processing states
6. **Monitoring & Observability**: Real-time queue metrics

## Message Format
```json
{
  "id": "1776887331115",
  "timestamp": "2026-04-22T19:49:03Z",
  "status": "processed",
  "content": "Process customer data batch #1234",
  "attempts": 1,
  "processed_at": "2026-04-22T19:49:05Z"
}
```

## Extensions (Next Steps)
- Add retry logic for failed messages
- Implement priority queues
- Add message TTL (time-to-live)
- Build multiple consumer workers
- Add backpressure handling
- Integrate with external APIs

## Usage Example
```bash
# Terminal 1: Start consumer
./consumer.sh

# Terminal 2: Add messages
./producer.sh "ETL job: sales_data_2024_04_22.csv"
./producer.sh "API sync: customer_updates.json"

# Terminal 3: Monitor
./monitor.sh
```

This MVP demonstrates core data engineering patterns using basic Linux tools and bash scripting.
