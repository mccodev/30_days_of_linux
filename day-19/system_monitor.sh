#!/bin/bash

# System Health Monitor Script
# Description: Comprehensive system monitoring with alerts and logging

set -euo pipefail

# Configuration
LOG_FILE="/var/log/system_monitor.log"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90
ALERT_THRESHOLD_LOAD=2.0
MONITOR_INTERVAL=60
TEMP_DIR="/tmp/system_monitor"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create temp directory
mkdir -p "$TEMP_DIR"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Alert function
send_alert() {
    local metric="$1"
    local value="$2"
    local threshold="$3"
    local message="ALERT: $metric threshold exceeded! Current: $value%, Threshold: $threshold%"
    
    log_message "ALERT" "$message"
    echo -e "${RED}$message${NC}"
    
    # You can add email/Slack notifications here
    # send_email "$message"
    # slack_notify "$message"
}

# Get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//'
}

# Get memory usage
get_memory_usage() {
    free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'
}

# Get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Get load average
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
}

# Get active connections
get_active_connections() {
    ss -s | grep "TCP:" | awk '{print $2}'
}

# Check process health
check_critical_processes() {
    local critical_processes=("sshd" "systemd" "cron")
    local failed_processes=()
    
    for process in "${critical_processes[@]}"; do
        if ! pgrep -x "$process" > /dev/null; then
            failed_processes+=("$process")
        fi
    done
    
    if [ ${#failed_processes[@]} -gt 0 ]; then
        log_message "ERROR" "Critical processes not running: ${failed_processes[*]}"
        echo -e "${RED}Critical processes down: ${failed_processes[*]}${NC}"
    fi
}

# Generate system report
generate_report() {
    local report_file="$TEMP_DIR/system_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== System Health Report ==="
        echo "Generated: $(date)"
        echo ""
        
        echo "=== System Information ==="
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo ""
        
        echo "=== Resource Usage ==="
        echo "CPU Usage: $(get_cpu_usage)%"
        echo "Memory Usage: $(get_memory_usage)%"
        echo "Disk Usage: $(get_disk_usage)%"
        echo "Load Average: $(get_load_average)"
        echo "Active Connections: $(get_active_connections)"
        echo ""
        
        echo "=== Top 5 CPU Processes ==="
        ps aux --sort=-%cpu | head -6 | awk '{printf "%-10s %5s%% %s\n", $1, $3, $11}'
        echo ""
        
        echo "=== Top 5 Memory Processes ==="
        ps aux --sort=-%mem | head -6 | awk '{printf "%-10s %5s%% %s\n", $1, $4, $11}'
        echo ""
        
        echo "=== Disk Usage by Directory ==="
        du -sh /var/log /tmp /home /opt 2>/dev/null || echo "Some directories not accessible"
        echo ""
        
        echo "=== Network Interfaces ==="
        ip addr show | grep -E "^[0-9]+:|inet " | awk '{if($1 ~ /^[0-9]+:/) {print "\n" $2} else {print $2}}'
        
    } > "$report_file"
    
    echo "Report generated: $report_file"
    log_message "INFO" "System report generated: $report_file"
}

# Real-time monitoring function
monitor_system() {
    echo -e "${BLUE}Starting system monitoring...${NC}"
    log_message "INFO" "System monitoring started"
    
    while true; do
        clear
        echo -e "${BLUE}=== System Monitor - $(date) ===${NC}"
        echo ""
        
        # Get current metrics
        cpu_usage=$(get_cpu_usage)
        memory_usage=$(get_memory_usage)
        disk_usage=$(get_disk_usage)
        load_avg=$(get_load_average)
        connections=$(get_active_connections)
        
        # Display metrics with color coding
        echo -e "CPU Usage: ${cpu_usage}%"
        if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
            echo -e "  ${RED}⚠ HIGH CPU USAGE${NC}"
            send_alert "CPU" "$cpu_usage" "$ALERT_THRESHOLD_CPU"
        fi
        
        echo -e "Memory Usage: ${memory_usage}%"
        if (( $(echo "$memory_usage > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
            echo -e "  ${RED}⚠ HIGH MEMORY USAGE${NC}"
            send_alert "Memory" "$memory_usage" "$ALERT_THRESHOLD_MEMORY"
        fi
        
        echo -e "Disk Usage: ${disk_usage}%"
        if [ "$disk_usage" -gt "$ALERT_THRESHOLD_DISK" ]; then
            echo -e "  ${RED}⚠ HIGH DISK USAGE${NC}"
            send_alert "Disk" "$disk_usage" "$ALERT_THRESHOLD_DISK"
        fi
        
        echo -e "Load Average: ${load_avg}"
        if (( $(echo "$load_avg > $ALERT_THRESHOLD_LOAD" | bc -l) )); then
            echo -e "  ${RED}⚠ HIGH LOAD AVERAGE${NC}"
            send_alert "Load" "$load_avg" "$ALERT_THRESHOLD_LOAD"
        fi
        
        echo -e "Active Connections: ${connections}"
        echo ""
        
        # Check critical processes
        check_critical_processes
        
        # Log current status
        log_message "INFO" "CPU: ${cpu_usage}%, Memory: ${memory_usage}%, Disk: ${disk_usage}%, Load: ${load_avg}"
        
        echo -e "${GREEN}Next check in ${MONITOR_INTERVAL} seconds... (Press Ctrl+C to stop)${NC}"
        sleep "$MONITOR_INTERVAL"
    done
}

# Show help
show_help() {
    echo "System Health Monitor"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  monitor     Start real-time monitoring"
    echo "  report      Generate one-time system report"
    echo "  status      Show current system status"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 monitor    # Start continuous monitoring"
    echo "  $0 report     # Generate detailed report"
    echo "  $0 status     # Quick status check"
}

# Quick status check
show_status() {
    echo -e "${BLUE}=== Quick System Status ===${NC}"
    echo "CPU Usage: $(get_cpu_usage)%"
    echo "Memory Usage: $(get_memory_usage)%"
    echo "Disk Usage: $(get_disk_usage)%"
    echo "Load Average: $(get_load_average)"
    echo "Active Connections: $(get_active_connections)"
    echo ""
    check_critical_processes
}

# Main script logic
case "${1:-help}" in
    "monitor")
        monitor_system
        ;;
    "report")
        generate_report
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_help
        ;;
esac
