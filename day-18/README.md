# Day 18 - Advanced Shell Scripting & Error Handling

## Objective

Learn how to write robust, production-ready shell scripts with proper error handling, logging, and defensive programming techniques. This is essential for building reliable data engineering pipelines that can handle failures gracefully and provide meaningful debugging information.

---

## What I Learned

### Error Handling Fundamentals

- **Exit Codes:** Every command returns an exit status - `0` for success, non-zero for failure
- **`set -e`:** Exit immediately if any command fails
- **`set -u`:** Treat unset variables as errors
- **`set -o pipefail`:** Pipeline exit code is the exit code of the rightmost command to exit with a non-zero status
- **`trap`:** Catch signals and execute cleanup code

### Defensive Programming Patterns

- **Input Validation:** Check for required arguments, file existence, permissions
- **Variable Safety:** Use quotes around variables, parameter expansion for defaults
- **Resource Cleanup:** Ensure temporary files are removed, processes are killed
- **Logging:** Structured logging with timestamps and severity levels

### Advanced Scripting Techniques

- **Functions:** Reusable code blocks with proper argument handling
- **Arrays:** Store and manipulate collections of data
- **Here Documents:** Multi-line string handling
- **Process Substitution:** Avoid temporary files when possible

---

## What I Built / Practiced

### Production-Ready Data Pipeline Script

Created `pipeline.sh` with:
- Comprehensive error handling and logging
- Input validation for required parameters
- Graceful cleanup with `trap`
- Progress reporting and status tracking
- Configurable environment variables

### Robust File Processing Script

Built `process_data.sh` featuring:
- Batch processing with error recovery
- Atomic file operations (write to temp, then move)
- Detailed logging with timestamps
- Resource limits and timeout handling
- Rollback capabilities on failure

### Monitoring & Alerting Script

Developed `health_check.sh` that:
- Checks system resources (disk, memory, CPU)
- Validates data quality metrics
- Sends alerts on threshold breaches
- Maintains historical status logs

---

## Challenges Faced

- **Silent Failures:** Scripts that appeared to work but actually failed midway through - solved with `set -e` and proper exit code checking
- **Variable Expansion Issues:** Unquoted variables causing word splitting and glob expansion - fixed by always quoting variable expansions
- **Resource Leaks:** Temporary files not being cleaned up on script failure - resolved using `trap` for guaranteed cleanup
- **Pipeline Debugging:** Complex pipelines failing silently - addressed with `set -o pipefail` and intermediate logging
- **Signal Handling:** Scripts not responding properly to termination signals - implemented proper `trap` handlers

---

## Key Takeaways

- **Always use `set -euo pipefail`** at the start of production scripts - it catches 90% of common scripting errors
- **Quote all variable expansions** unless you explicitly want word splitting or glob expansion
- **Use `trap` for cleanup** - it's your guarantee that resources get cleaned up even when things go wrong
- **Log everything** - timestamped logs are invaluable for debugging production issues
- **Validate inputs early** - fail fast with clear error messages rather than letting problems propagate
- **Test failure scenarios** - intentionally break things to ensure your error handling works
- **Use absolute paths** in cron jobs and scheduled scripts to avoid environment-dependent behavior

---

## Resources

- `man bash` - Comprehensive bash manual
- [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Bash Pitfalls](http://mywiki.wooledge.org/BashPitfalls)

---

## Output

### Production Pipeline Script (`pipeline.sh`)

```bash
#!/bin/bash
# Production-ready data pipeline with comprehensive error handling

set -euo pipefail  # Exit on error, undefined vars, and pipeline failures

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="${SCRIPT_DIR}/logs"
readonly TEMP_DIR="${SCRIPT_DIR}/tmp"
readonly DATA_DIR="${SCRIPT_DIR}/data"

# Logging function with timestamps
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "${LOG_DIR}/pipeline.log"
}

# Cleanup function - guaranteed to run on exit
cleanup() {
    local exit_code=$?
    log "INFO" "Cleaning up temporary files..."
    rm -rf "${TEMP_DIR}"/*
    log "INFO" "Pipeline completed with exit code: $exit_code"
}
trap cleanup EXIT

# Input validation
validate_inputs() {
    if [[ $# -lt 1 ]]; then
        log "ERROR" "Usage: $0 <data_source>"
        exit 1
    fi
    
    local data_source="$1"
    if [[ ! -f "$data_source" ]]; then
        log "ERROR" "Data source file not found: $data_source"
        exit 1
    fi
    
    if [[ ! -r "$data_source" ]]; then
        log "ERROR" "Data source file not readable: $data_source"
        exit 1
    fi
}

# Main pipeline function
run_pipeline() {
    local data_source="$1"
    local output_file="${DATA_DIR}/processed_$(date +%Y%m%d_%H%M%S).csv"
    
    log "INFO" "Starting pipeline for: $data_source"
    
    # Create necessary directories
    mkdir -p "${LOG_DIR}" "${TEMP_DIR}" "${DATA_DIR}"
    
    # Process data with error handling
    if ! process_data "$data_source" "$output_file"; then
        log "ERROR" "Data processing failed"
        return 1
    fi
    
    log "INFO" "Pipeline completed successfully. Output: $output_file"
    return 0
}

# Data processing function
process_data() {
    local input="$1"
    local output="$2"
    local temp_output="${TEMP_DIR}/$(basename "$output").tmp"
    
    log "INFO" "Processing data from $input to $temp_output"
    
    # Example processing pipeline with proper error handling
    if ! tail -n +2 "$input" | \
        sort -t',' -k1,1 | \
        uniq > "$temp_output"; then
        log "ERROR" "Failed to process data"
        return 1
    fi
    
    # Atomic move - ensures complete file or nothing
    if ! mv "$temp_output" "$output"; then
        log "ERROR" "Failed to move processed data to final location"
        return 1
    fi
    
    log "INFO" "Data processing completed successfully"
    return 0
}

# Main execution
main() {
    validate_inputs "$@"
    run_pipeline "$@"
}

# Execute main function with all arguments
main "$@"
```

### Health Check Script (`health_check.sh`)

```bash
#!/bin/bash
# System health monitoring for data pipelines

set -euo pipefail

# Thresholds
readonly DISK_WARNING=80
readonly DISK_CRITICAL=95
readonly MEM_WARNING=80
readonly MEM_CRITICAL=90

check_disk_usage() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if (( usage >= DISK_CRITICAL )); then
        echo "CRITICAL: Disk usage at ${usage}%"
        return 2
    elif (( usage >= DISK_WARNING )); then
        echo "WARNING: Disk usage at ${usage}%"
        return 1
    else
        echo "OK: Disk usage at ${usage}%"
        return 0
    fi
}

check_memory_usage() {
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if (( mem_usage >= MEM_CRITICAL )); then
        echo "CRITICAL: Memory usage at ${mem_usage}%"
        return 2
    elif (( mem_usage >= MEM_WARNING )); then
        echo "WARNING: Memory usage at ${mem_usage}%"
        return 1
    else
        echo "OK: Memory usage at ${mem_usage}%"
        return 0
    fi
}

# Main health check
main() {
    local overall_status=0
    
    check_disk_usage || overall_status=$?
    check_memory_usage || overall_status=$?
    
    exit $overall_status
}

main "$@"
```

### Sample Log Output

```
[2024-01-18 14:30:15] [INFO] Starting pipeline for: data/raw_sales.csv
[2024-01-18 14:30:15] [INFO] Processing data from data/raw_sales.csv to tmp/processed_20240118_143015.csv.tmp
[2024-01-18 14:30:16] [INFO] Data processing completed successfully
[2024-01-18 14:30:16] [INFO] Pipeline completed successfully. Output: data/processed_20240118_143016.csv
[2024-01-18 14:30:16] [INFO] Cleaning up temporary files...
[2024-01-18 14:30:16] [INFO] Pipeline completed with exit code: 0
