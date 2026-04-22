# Day 22 - File-based Message Queue System

## Objective

Build a lightweight message queue system using bash and file system operations to learn core data engineering concepts like producer-consumer patterns, atomic operations, and message serialization.

---

## What I Learned

- **Producer-Consumer Pattern**: Decoupled message production from consumption using file-based queues
- **Atomic File Operations**: Using file system locks (`flock`) to prevent race conditions in concurrent processing
- **Message Serialization**: JSON format for structured data with metadata (ID, timestamp, status, attempts)
- **Queue State Management**: Moving messages through incoming/processing/processed/failed states
- **File Locking Mechanisms**: Implementing exclusive locks for safe concurrent message processing
- **Bash Process Management**: Background processes, timeouts, and signal handling for long-running consumers
- **Real-time Monitoring**: Queue metrics and status tracking with shell scripting 

---

## What I Built / Practiced

### Message Queue System (`queue/` directory)

**Producer Script (`producer.sh`)**
- Creates JSON messages with unique IDs and timestamps
- Atomic file creation in incoming directory
- Queue size reporting and message tracking

**Consumer Script (`consumer.sh`)**
- Continuous message processing loop with file locking
- Moves messages through processing states safely
- Updates message metadata (status, attempts, processed_at)
- Implements timeout and retry mechanisms

**Monitor Script (`monitor.sh`)**
- Real-time queue status dashboard
- Message counts by state (pending/processing/processed/failed)
- Recent processed message history
- Currently processing message tracking

**Queue Architecture**
```
queue/
  incoming/     # New messages waiting to be processed
  processing/   # Messages with active locks (.lock files)
  processed/    # Successfully completed messages
  failed/       # Messages that failed processing
```

**Message Format**
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

---

## Challenges Faced

- **File Locking Race Conditions**: Multiple consumers trying to process same message - solved with atomic lock file creation using `set -C`
- **Message File Naming**: Long timestamps causing line breaks in output - fixed with proper filename generation
- **Concurrent Access**: Ensuring message state transitions are atomic - implemented with file moves and lock coordination
- **Process Cleanup**: Consumer processes not terminating gracefully - added proper signal handling and timeout mechanisms
- **Queue Monitoring**: Real-time status updates while consumer running - separated monitor script for independent observation

---

## Key Takeaways

- **File systems can be queues**: Simple directory structures can implement complex message queue patterns
- **Atomic operations are critical**: File locking and atomic moves prevent data corruption in concurrent systems
- **JSON is universal**: Using JSON for message serialization provides structure and debugging capabilities
- **State machines work**: Moving messages through defined states (incoming/processing/processed) provides clear audit trails
- **Monitoring is essential**: Real-time visibility into queue health prevents silent failures
- **Bash is powerful**: Complex data engineering patterns can be built with basic shell tools
- **Simplicity scales**: Simple file-based queues can handle significant throughput before needing more complex systems

---

## Resources

- [File Locking in Bash](https://www.gnu.org/software/bash/manual/bash.html#Redirections)
- [Producer-Consumer Pattern](https://en.wikipedia.org/wiki/Producer%E2%80%93consumer_problem)
- [Message Queue Concepts](https://aws.amazon.com/message-queue/)
- `man flock` - File locking utility
- `jq` manual - JSON processing tool

---

## Output

### Scripts Created
- `queue/producer.sh` - Message enqueuing script
- `queue/consumer.sh` - Message processing with locking
- `queue/monitor.sh` - Real-time queue status dashboard
- `queue/README.md` - Complete project documentation

### Queue Architecture
- Directory-based state management
- Atomic file operations for concurrency
- JSON message format with metadata
- Lock-based exclusive processing

### Test Results
- Successfully processed 3 test messages
- Demonstrated concurrent-safe operations
- Real-time monitoring working correctly
- Message audit trail complete with timestamps

---
