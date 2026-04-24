# Day 24 - System Monitoring Tools

## Objective

- Learn essential Linux system monitoring tools for tracking system performance, resource usage, and troubleshooting
- Master commands for monitoring CPU, memory, disk, network, and process activity
- Understand how to interpret monitoring data and identify performance bottlenecks

---

## What I Learned

- **Basic Monitoring Commands**:
  - `free -h` - Shows memory usage in human-readable format
  - `df -h` - Displays disk space usage for all mounted filesystems
  - `du -sh` - Shows disk usage of specific directories
  - `top` - Real-time process monitoring with CPU/memory usage
  - `htop` - Enhanced version of top with better UI (available on system)

- **Process Management**:
  - `ps aux` - Shows all running processes with detailed information
  - `ps -eo pid,ppid,user,%cpu,%mem,comm` - Custom process listing with specific fields
  - `kill <PID>` - Terminates processes by PID
  - `nice -n <level> <command>` - Runs processes with adjusted priority
  - `renice <level> -p <PID>` - Changes priority of running processes

- **Advanced Monitoring Tools**:
  - `vmstat 1 3` - Reports virtual memory statistics every second for 3 iterations
  - `iostat -x 1 2` - Shows extended I/O statistics with 1-second intervals
  - `netstat -tuln` - Displays listening TCP/UDP ports and network connections
  - `ss -tuln` - Modern replacement for netstat with better performance

---

## What I Built / Practiced

- **System Monitoring Script** (`system_monitor.sh`):
  - Comprehensive monitoring script that reports key system metrics
  - Displays system information, memory usage, disk usage, CPU usage
  - Shows top processes by CPU and memory consumption
  - Reports active network connections and system load details
  - Provides timestamped reports for tracking system performance over time

- **Hands-on Process Management**:
  - Created background processes and practiced terminating them
  - Adjusted process priorities using nice command
  - Monitored process behavior with different priority levels

---

## Challenges Faced

- Understanding vmstat output format - the columns represent different metrics (procs, memory, swap, io, system, cpu)
- Interpreting iostat extended output - many columns showing various I/O performance metrics
- Distinguishing between netstat and ss - ss is newer and faster but netstat is more widely known
- Process priority levels - understanding how nice values work (higher numbers = lower priority)

---

## Key Takeaways

- **Monitoring is essential** for system administration and performance troubleshooting
- **Multiple tools provide different perspectives** - no single tool shows everything
- **Real-time vs snapshot monitoring** - some tools show live data (top/htop) while others provide snapshots (vmstat/iostat)
- **Process management matters** - understanding how to control process priorities and terminate processes is crucial
- **Automation is key** - creating monitoring scripts helps track system health over time
- **Resource bottlenecks** - monitoring helps identify CPU, memory, disk, or network constraints

---

## Resources

- `man free`, `man df`, `man du`, `man top`, `man ps` - Built-in manual pages
- `man vmstat`, `man iostat`, `man netstat`, `man ss` - Advanced monitoring tool documentation
- [Linux Performance Monitoring Guide](https://www.brendangregg.com/linuxperf.html) - Comprehensive performance analysis
- [htop official site](https://htop.dev/) - Interactive process viewer

---

## Output

**System Monitoring Script (`system_monitor.sh`):**
```bash
#!/bin/bash
# Comprehensive system monitoring script that reports:
# - System information and uptime
# - Memory usage with free -h
# - Disk usage with df -h
# - CPU usage percentage
# - Top processes by CPU and memory
# - Network connection counts
# - System load details with vmstat
```

**Sample Script Output:**
```
======================================
System Monitoring Report - Fri Apr 24 15:30:29 EAT 2026
======================================

=== System Information ===
Uptime: up 16 hours, 42 minutes
Load Average:  2.51, 2.28, 1.81
Kernel: 6.17.0-22-generic
OS: Linux

=== Memory Usage ===
               total        used        free      shared  buff/cache   available
Mem:           7.1Gi       5.5Gi       370Mi       940Mi       2.5Gi       1.7Gi
Swap:           12Gi       1.7Gi        11Gi

=== Disk Usage ===
/dev/sda3         46G   40G   92% /
/dev/sda6         76G   54G   75% /home
/dev/sda1         99M  6.3M    7% /boot/efi
/dev/sda4        105G  104G   99% /media/emangdev/New Volume

=== CPU Usage ===
CPU Usage: 45.5%

=== Top 5 Processes by CPU ===
    PID USER     %CPU %MEM COMMAND
  53139 emangdev 46.4  6.9 brave
  55498 emangdev 38.3  5.9 windsurf
  37043 emangdev 13.3  1.3 brave
  55461 emangdev 11.6  1.9 windsurf
  55415 emangdev  5.8  2.8 windsurf
```

**Key Commands Practiced:**
- `free -h` - Memory monitoring
- `df -h` - Disk space monitoring  
- `top -b -n 1` - One-shot process monitoring
- `ps aux | head -10` - Process listing
- `vmstat 1 3` - Memory and system statistics
- `iostat -x 1 2` - I/O performance statistics
- `ss -tuln` - Network connection monitoring
