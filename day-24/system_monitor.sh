#!/bin/bash

# System Monitoring Script
# Reports key system metrics in a readable format

echo "======================================"
echo "System Monitoring Report - $(date)"
echo "======================================"
echo

# System Information
echo "=== System Information ==="
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Kernel: $(uname -r)"
echo "OS: $(uname -s)"
echo

# Memory Usage
echo "=== Memory Usage ==="
free -h
echo

# Disk Usage
echo "=== Disk Usage ==="
df -h | grep -E '^/dev/' | awk '{printf "%-15s %5s %5s %5s %s\n", $1, $2, $3, $5, $6}'
echo

# CPU Usage
echo "=== CPU Usage ==="
CPU_USAGE=$(top -b -n 1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
echo "CPU Usage: ${CPU_USAGE}%"
echo

# Top Processes by CPU
echo "=== Top 5 Processes by CPU ==="
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -6
echo

# Top Processes by Memory
echo "=== Top 5 Processes by Memory ==="
ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -6
echo

# Network Connections
echo "=== Active Network Connections ==="
ss -tuln | wc -l
echo "Total listening ports: $(ss -tuln | wc -l)"
echo

# System Load
echo "=== System Load Details ==="
vmstat 1 2 | tail -1
echo

echo "======================================"
echo "Report completed at $(date)"
echo "======================================"
