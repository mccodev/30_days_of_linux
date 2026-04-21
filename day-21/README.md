# Day 21 - Linux Process Management & Monitoring

## Objective

Master Linux process management, monitoring, and optimization techniques to ensure data pipelines run reliably and efficiently. Learn to identify, troubleshoot, and optimize system resource usage for data engineering workloads.

---

## What I Learned

### Process Monitoring for Data Pipelines
- `ps aux | grep pipeline` - find running data pipeline processes
- `top -p $(pgrep -d',' pipeline)` - monitor specific pipeline processes
- `htop` - interactive process viewer with resource usage
- `pgrep -f "etl_pipeline"` - find processes by command name

### Process Control & Signals
- `kill -TERM <PID>` - graceful shutdown (SIGTERM)
- `kill -KILL <PID>` - force terminate (SIGKILL)
- `pkill -f "data_processor"` - kill processes by pattern
- `killall pipeline.sh` - kill all processes by name

### Resource Management
- `nice -n 10 ./heavy_pipeline.sh` - run with lower priority
- `renice +5 -p <PID>` - change priority of running process
- `ulimit -v 1048576` - set memory limit (1GB)
- `free -h && df -h` - check available memory and disk

### Long-Running Processes
- `nohup ./pipeline.sh > pipeline.log 2>&1 &` - run after logout
- `screen -S pipeline` - detachable terminal session
- `tmux new -s data_processing` - terminal multiplexer
- `disown %1` - remove job from shell's job table

### Process Debugging
- `/proc/<PID>/status` - detailed process information
- `/proc/<PID>/fd` - open file descriptors
- `strace -p <PID>` - trace system calls
- `lsof -p <PID>` - list open files

---

## What I Built / Practiced

### Pipeline Monitor Script
```bash
#!/bin/bash
# monitor_pipeline.sh - Check if ETL pipeline is running
PIPELINE_PID=$(pgrep -f "etl_pipeline.sh")
if [ -n "$PIPELINE_PID" ]; then
    echo "Pipeline running (PID: $PIPELINE_PID)"
    top -p $PIPELINE_PID -n 1 | tail -n 1
else
    echo "Pipeline not running - restarting..."
    ./etl_pipeline.sh &
fi
```

### Resource Usage Alert
```bash
#!/bin/bash
# resource_alert.sh - Alert on high resource usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')

if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "ALERT: High CPU usage: ${CPU_USAGE}%"
fi

if (( $(echo "$MEM_USAGE > 85" | bc -l) )); then
    echo "ALERT: High memory usage: ${MEM_USAGE}%"
fi
```

### Process Cleanup Utility
```bash
#!/bin/bash
# cleanup_failed_jobs.sh - Clean up stuck pipeline processes
pkill -f "stuck_processor"
pkill -9 -f "zombie_data_loader"
echo "Cleaned up $(date)"
```

---

## Challenges Faced

- **Pipeline Zombie Processes**: ETL jobs leaving zombie processes after completion - solved by proper signal handling and wait() calls
- **Memory Leaks in Data Processing**: Long-running CSV processing scripts consuming increasing memory - fixed by implementing chunked processing
- **Resource Contention**: Multiple pipeline steps competing for CPU - resolved using `nice` priorities and process coordination
- **Debugging Hanging Processes**: Pipeline stages getting stuck on network operations - used `strace` to identify blocking system calls
- **Process Cleanup on Failure**: Scripts not cleaning up temporary files on crash - implemented trap handlers for graceful shutdown

---

## Key Takeaways

- Always monitor pipeline processes with `pgrep` and `ps` before starting new ones
- Use `nohup` and `screen` for long-running data jobs that must survive logout
- Implement proper signal handling (SIGTERM, SIGINT) in pipeline scripts
- Set appropriate process priorities with `nice` to prevent system overload
- Use `/proc` filesystem for deep debugging of stuck processes
- Resource monitoring prevents pipeline failures due to memory/disk exhaustion

---

## Resources

- `man ps`, `man top`, `man kill`, `man nice`
- [Linux Process Management Guide](https://www.linux.com/training-tutorials/linux-process-management/)
- [Understanding /proc filesystem](https://www.kernel.org/doc/html/latest/filesystems/proc.html)

---

## Output

(Paste your pipeline monitoring scripts, process screenshots, and command outputs here)
