#!/bin/bash

# Performance Baseline Analyzer
# Description: Establish and analyze system performance baselines

set -euo pipefail

# Configuration
BASELINE_DIR="/tmp/system_baselines"
DATA_RETENTION_DAYS=30
SAMPLE_INTERVAL=300  # 5 minutes between samples
SAMPLE_COUNT=12      # 12 samples = 1 hour of data

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create baseline directory
mkdir -p "$BASELINE_DIR"

# Collect system metrics
collect_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    local memory=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local disk=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local connections=$(ss -s | grep "TCP:" | awk '{print $2}')
    local processes=$(ps aux | wc -l)
    
    echo "$timestamp,$cpu,$memory,$disk,$load,$connections,$processes"
}

# Create baseline
create_baseline() {
    local baseline_name="$1"
    local baseline_file="$BASELINE_DIR/baseline_${baseline_name}_$(date +%Y%m%d_%H%M%S).csv"
    
    echo -e "${BLUE}Creating baseline: $baseline_name${NC}"
    echo "timestamp,cpu_usage,memory_usage,disk_usage,load_avg,connections,processes" > "$baseline_file"
    
    echo "Collecting $SAMPLE_COUNT samples over $((SAMPLE_COUNT * SAMPLE_INTERVAL / 60)) minutes..."
    
    for ((i=1; i<=SAMPLE_COUNT; i++)); do
        echo -n "Sample $i/$SAMPLE_COUNT... "
        collect_metrics >> "$baseline_file"
        echo "✓"
        
        if [ $i -lt $SAMPLE_COUNT ]; then
            sleep "$SAMPLE_INTERVAL"
        fi
    done
    
    echo -e "${GREEN}Baseline created: $baseline_file${NC}"
    analyze_baseline "$baseline_file"
}

# Analyze baseline data
analyze_baseline() {
    local baseline_file="$1"
    
    echo -e "${BLUE}=== Baseline Analysis ===${NC}"
    
    # Calculate averages using awk
    awk -F',' '
    NR > 1 {
        cpu_sum += $2; mem_sum += $3; disk_sum += $4; load_sum += $5; conn_sum += $6; proc_sum += $7
        count++
        
        if (NR == 2) {
            cpu_min = cpu_max = $2
            mem_min = mem_max = $3
            disk_min = disk_max = $4
            load_min = load_max = $5
            conn_min = conn_max = $6
            proc_min = proc_max = $7
        } else {
            if ($2 < cpu_min) cpu_min = $2
            if ($2 > cpu_max) cpu_max = $2
            if ($3 < mem_min) mem_min = $3
            if ($3 > mem_max) mem_max = $3
            if ($4 < disk_min) disk_min = $4
            if ($4 > disk_max) disk_max = $4
            if ($5 < load_min) load_min = $5
            if ($5 > load_max) load_max = $5
            if ($6 < conn_min) conn_min = $6
            if ($6 > conn_max) conn_max = $6
            if ($7 < proc_min) proc_min = $7
            if ($7 > proc_max) proc_max = $7
        }
    }
    END {
        printf "CPU Usage:    Avg: %.1f%%, Min: %.1f%%, Max: %.1f%%\n", cpu_sum/count, cpu_min, cpu_max
        printf "Memory Usage: Avg: %.1f%%, Min: %.1f%%, Max: %.1f%%\n", mem_sum/count, mem_min, mem_max
        printf "Disk Usage:   Avg: %.1f%%, Min: %.1f%%, Max: %.1f%%\n", disk_sum/count, disk_min, disk_max
        printf "Load Average: Avg: %.2f, Min: %.2f, Max: %.2f\n", load_sum/count, load_min, load_max
        printf "Connections:  Avg: %.0f, Min: %.0f, Max: %.0f\n", conn_sum/count, conn_min, conn_max
        printf "Processes:    Avg: %.0f, Min: %.0f, Max: %.0f\n", proc_sum/count, proc_min, proc_max
    }' "$baseline_file"
    
    echo ""
    echo -e "${YELLOW}Recommendations:${NC}"
    
    # Generate recommendations based on analysis
    local avg_cpu=$(awk -F',' 'NR>1 {sum+=$2; count++} END {printf "%.1f", sum/count}' "$baseline_file")
    local avg_mem=$(awk -F',' 'NR>1 {sum+=$3; count++} END {printf "%.1f", sum/count}' "$baseline_file")
    
    if (( $(echo "$avg_cpu > 70" | bc -l) )); then
        echo "⚠ High average CPU usage ($avg_cpu%). Consider investigating CPU-intensive processes."
    fi
    
    if (( $(echo "$avg_mem > 80" | bc -l) )); then
        echo "⚠ High average memory usage ($avg_mem%). Consider adding more RAM or optimizing memory usage."
    fi
    
    echo "✓ Baseline established for future comparison."
}

# Compare current status with baseline
compare_with_baseline() {
    local baseline_file="$1"
    
    if [ ! -f "$baseline_file" ]; then
        echo "Error: Baseline file not found: $baseline_file"
        return 1
    fi
    
    echo -e "${BLUE}=== Current vs Baseline Comparison ===${NC}"
    
    # Get current metrics
    local current_metrics=$(collect_metrics)
    local current_cpu=$(echo "$current_metrics" | cut -d',' -f2)
    local current_mem=$(echo "$current_metrics" | cut -d',' -f3)
    local current_disk=$(echo "$current_metrics" | cut -d',' -f4)
    local current_load=$(echo "$current_metrics" | cut -d',' -f5)
    
    # Get baseline averages
    local baseline_cpu=$(awk -F',' 'NR>1 {sum+=$2; count++} END {printf "%.1f", sum/count}' "$baseline_file")
    local baseline_mem=$(awk -F',' 'NR>1 {sum+=$3; count++} END {printf "%.1f", sum/count}' "$baseline_file")
    local baseline_disk=$(awk -F',' 'NR>1 {sum+=$4; count++} END {printf "%.1f", sum/count}' "$baseline_file")
    local baseline_load=$(awk -F',' 'NR>1 {sum+=$5; count++} END {printf "%.2f", sum/count}' "$baseline_file")
    
    printf "%-15s %-10s %-10s %-10s\n" "Metric" "Current" "Baseline" "Diff"
    printf "%-15s %-10s %-10s %-10s\n" "-----" "-------" "--------" "----"
    printf "%-15s %-10s %-10s %-10s\n" "CPU (%)" "$current_cpu" "$baseline_cpu" "$(echo "$current_cpu - $baseline_cpu" | bc)"
    printf "%-15s %-10s %-10s %-10s\n" "Memory (%)" "$current_mem" "$baseline_mem" "$(echo "$current_mem - $baseline_mem" | bc)"
    printf "%-15s %-10s %-10s %-10s\n" "Disk (%)" "$current_disk" "$baseline_disk" "$(echo "$current_disk - $baseline_disk" | bc)"
    printf "%-15s %-10s %-10s %-10s\n" "Load" "$current_load" "$baseline_load" "$(echo "$current_load - $baseline_load" | bc)"
    
    echo ""
    # Alert on significant deviations
    if (( $(echo "($current_cpu - $baseline_cpu) > 20" | bc -l) )); then
        echo -e "${YELLOW}⚠ CPU usage significantly higher than baseline${NC}"
    fi
    
    if (( $(echo "($current_mem - $baseline_mem) > 15" | bc -l) )); then
        echo -e "${YELLOW}⚠ Memory usage significantly higher than baseline${NC}"
    fi
}

# List available baselines
list_baselines() {
    echo -e "${BLUE}Available Baselines:${NC}"
    ls -la "$BASELINE_DIR"/baseline_*.csv 2>/dev/null | awk '{print $9}' | sed "s|$BASELINE_DIR/||" || echo "No baselines found"
}

# Clean old baselines
cleanup_baselines() {
    echo "Cleaning baselines older than $DATA_RETENTION_DAYS days..."
    find "$BASELINE_DIR" -name "baseline_*.csv" -mtime +$DATA_RETENTION_DAYS -delete
    echo "Cleanup completed."
}

# Show help
show_help() {
    echo "Performance Baseline Analyzer"
    echo ""
    echo "Usage: $0 [OPTION] [ARGUMENT]"
    echo ""
    echo "Options:"
    echo "  create <name>     Create new baseline with specified name"
    echo "  compare <file>    Compare current status with baseline"
    echo "  analyze <file>    Analyze existing baseline"
    echo "  list              List available baselines"
    echo "  cleanup           Remove old baselines"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 create normal    # Create baseline named 'normal'"
    echo "  $0 compare baseline_normal_20231219_143022.csv"
    echo "  $0 list            # Show all baselines"
}

# Main script logic
case "${1:-help}" in
    "create")
        if [ -z "${2:-}" ]; then
            echo "Error: Baseline name required"
            show_help
            exit 1
        fi
        create_baseline "$2"
        ;;
    "compare")
        if [ -z "${2:-}" ]; then
            echo "Error: Baseline file required"
            show_help
            exit 1
        fi
        compare_with_baseline "$BASELINE_DIR/$2"
        ;;
    "analyze")
        if [ -z "${2:-}" ]; then
            echo "Error: Baseline file required"
            show_help
            exit 1
        fi
        analyze_baseline "$BASELINE_DIR/$2"
        ;;
    "list")
        list_baselines
        ;;
    "cleanup")
        cleanup_baselines
        ;;
    "help"|*)
        show_help
        ;;
esac
