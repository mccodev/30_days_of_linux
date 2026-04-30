#!/usr/bin/env bash
set -euo pipefail

# syshealth.sh — one-shot system health report
# Usage: ./syshealth.sh [--help]

show_help() {
    cat <<EOF
Usage: syshealth.sh [OPTIONS]

Generates a system health report including CPU, memory, disk, load, and top processes.

Options:
  -h, --help    Show this help message and exit
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

header() {
    echo -e "\n${YELLOW}==== $1 ====${NC}"
}

# Date / Uptime
header "SYSTEM INFO"
echo "Date: $(date)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"

# CPU
header "CPU"
if command -v lscpu &>/dev/null; then
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core"
else
    grep -E "model name|cpu cores|processor" /proc/cpuinfo | head -n 4
fi
echo "Load average: $(cut -d' ' -f1-3 /proc/loadavg)"

# Memory
header "MEMORY"
free -h 2>/dev/null || cat /proc/meminfo | head -n 3

# Disk
header "DISK USAGE"
df -h -x tmpfs -x devtmpfs 2>/dev/null || df -h

# Top processes by CPU
header "TOP PROCESSES BY CPU"
ps aux --sort=-%cpu 2>/dev/null | head -n 6 || ps -eo pid,ppid,%cpu,%mem,comm --sort=-%cpu | head -n 6

# Top processes by Memory
header "TOP PROCESSES BY MEMORY"
ps aux --sort=-%mem 2>/dev/null | head -n 6 || ps -eo pid,ppid,%cpu,%mem,comm --sort=-%mem | head -n 6

# Network interfaces (brief)
header "NETWORK INTERFACES"
ip -brief addr show 2>/dev/null || ifconfig -a 2>/dev/null | head -n 10 || echo "No network info available"

echo -e "\n${GREEN}Report complete.${NC}\n"
