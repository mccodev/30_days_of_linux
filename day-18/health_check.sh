#!/bin/bash
# System health monitoring for data pipelines

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="${SCRIPT_DIR}/logs"
readonly STATUS_LOG="${LOG_DIR}/health_status.log"

# Thresholds
readonly DISK_WARNING=80
readonly DISK_CRITICAL=95
readonly MEM_WARNING=80
readonly MEM_CRITICAL=90
readonly CPU_WARNING=70
readonly CPU_CRITICAL=90

# Data quality thresholds
readonly DATA_AGE_WARNING_HOURS=24
readonly DATA_SIZE_WARNING_MB=100

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function with timestamps
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$STATUS_LOG"
}

# Check disk usage
check_disk_usage() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    local status=0
    
    if (( usage >= DISK_CRITICAL )); then
        log "CRITICAL" "Disk usage at ${usage}% (threshold: ${DISK_CRITICAL}%)"
        status=2
    elif (( usage >= DISK_WARNING )); then
        log "WARNING" "Disk usage at ${usage}% (threshold: ${DISK_WARNING}%)"
        status=1
    else
        log "INFO" "Disk usage at ${usage}% - OK"
    fi
    
    return $status
}

# Check memory usage
check_memory_usage() {
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    local status=0
    
    if (( mem_usage >= MEM_CRITICAL )); then
        log "CRITICAL" "Memory usage at ${mem_usage}% (threshold: ${MEM_CRITICAL}%)"
        status=2
    elif (( mem_usage >= MEM_WARNING )); then
        log "WARNING" "Memory usage at ${mem_usage}% (threshold: ${MEM_WARNING}%)"
        status=1
    else
        log "INFO" "Memory usage at ${mem_usage}% - OK"
    fi
    
    return $status
}

# Check CPU usage
check_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    local status=0
    
    if (( cpu_usage >= CPU_CRITICAL )); then
        log "CRITICAL" "CPU usage at ${cpu_usage}% (threshold: ${CPU_CRITICAL}%)"
        status=2
    elif (( cpu_usage >= CPU_WARNING )); then
        log "WARNING" "CPU usage at ${cpu_usage}% (threshold: ${CPU_WARNING}%)"
        status=1
    else
        log "INFO" "CPU usage at ${cpu_usage}% - OK"
    fi
    
    return $status
}

# Check data quality metrics
check_data_quality() {
    local data_dir="${SCRIPT_DIR}/data"
    local status=0
    
    if [[ ! -d "$data_dir" ]]; then
        log "WARNING" "Data directory not found: $data_dir"
        return 1
    fi
    
    # Check for stale data (files older than warning threshold)
    local stale_files=$(find "$data_dir" -type f -mtime +$((${DATA_AGE_WARNING_HOURS}/24)) 2>/dev/null | wc -l)
    if (( stale_files > 0 )); then
        log "WARNING" "Found $stale_files data files older than ${DATA_AGE_WARNING_HOURS} hours"
        status=1
    fi
    
    # Check for unusually small files (potential corruption)
    local small_files=$(find "$data_dir" -type f -size -${DATA_SIZE_WARNING_MB}M 2>/dev/null | wc -l)
    if (( small_files > 0 )); then
        log "WARNING" "Found $small_files data files smaller than ${DATA_SIZE_WARNING_MB}MB (possible corruption)"
        status=1
    fi
    
    # Check for empty files
    local empty_files=$(find "$data_dir" -type f -empty 2>/dev/null | wc -l)
    if (( empty_files > 0 )); then
        log "CRITICAL" "Found $empty_files empty data files"
        status=2
    fi
    
    if (( status == 0 )); then
        log "INFO" "Data quality checks passed - OK"
    fi
    
    return $status
}

# Check process health
check_process_health() {
    local status=0
    
    # Check for zombie processes
    local zombies=$(ps aux | awk '$8 ~ /^Z/ { print $2 }' | wc -l)
    if (( zombies > 0 )); then
        log "WARNING" "Found $zombies zombie processes"
        status=1
    fi
    
    # Check for high memory consuming processes
    local high_mem_procs=$(ps aux --sort=-%mem | awk 'NR>1 && $4>50 { print $11 }' | head -5)
    if [[ -n "$high_mem_procs" ]]; then
        log "WARNING" "High memory processes detected: $high_mem_procs"
        status=1
    fi
    
    if (( status == 0 )); then
        log "INFO" "Process health checks passed - OK"
    fi
    
    return $status
}

# Send alert function (placeholder for actual alerting)
send_alert() {
    local severity="$1"
    local message="$2"
    
    # Log the alert
    log "ALERT" "[$severity] $message"
    
    # Here you could add email, Slack, or other alerting mechanisms
    # Example: mail -s "Health Alert: $severity" admin@example.com <<< "$message"
    # Example: curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" https://hooks.slack.com/your/webhook
}

# Generate summary report
generate_summary() {
    local overall_status="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "=========================================="
    echo "Health Check Summary - $timestamp"
    echo "Overall Status: $overall_status"
    echo "=========================================="
    
    # Show recent log entries
    echo ""
    echo "Recent Log Entries:"
    tail -n 20 "$STATUS_LOG" | grep -E "(CRITICAL|WARNING|ERROR)" || echo "No critical issues found"
    
    echo ""
    echo "Full log available at: $STATUS_LOG"
}

# Main health check function
main() {
    local overall_status=0
    local check_status=0
    
    log "INFO" "Starting comprehensive health check"
    
    # Run all checks
    check_disk_usage || check_status=$?
    (( overall_status = overall_status > check_status ? overall_status : check_status ))
    
    check_memory_usage || check_status=$?
    (( overall_status = overall_status > check_status ? overall_status : check_status ))
    
    check_cpu_usage || check_status=$?
    (( overall_status = overall_status > check_status ? overall_status : check_status ))
    
    check_data_quality || check_status=$?
    (( overall_status = overall_status > check_status ? overall_status : check_status ))
    
    check_process_health || check_status=$?
    (( overall_status = overall_status > check_status ? overall_status : check_status ))
    
    # Determine overall status message
    local status_message="OK"
    if (( overall_status == 2 )); then
        status_message="CRITICAL"
        send_alert "CRITICAL" "System health check failed with critical issues"
    elif (( overall_status == 1 )); then
        status_message="WARNING"
        send_alert "WARNING" "System health check found warning conditions"
    else
        log "INFO" "All health checks passed successfully"
    fi
    
    # Generate summary
    generate_summary "$status_message"
    
    log "INFO" "Health check completed with status: $status_message"
    exit $overall_status
}

# Execute main function
main "$@"
