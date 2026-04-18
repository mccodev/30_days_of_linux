#!/bin/bash
# Production-ready data pipeline with comprehensive error handling

set -euo pipefail  # Exit on error, undefined vars, and pipeline failures

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="${SCRIPT_DIR}/logs"
readonly TEMP_DIR="${SCRIPT_DIR}/tmp"
readonly DATA_DIR="${SCRIPT_DIR}/data"
readonly CONFIG_FILE="${SCRIPT_DIR}/config.env"

# Load configuration if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Default configuration (can be overridden by config.env)
readonly MAX_RETRIES=${MAX_RETRIES:-3}
readonly RETRY_DELAY=${RETRY_DELAY:-5}
readonly BATCH_SIZE=${BATCH_SIZE:-1000}
readonly TIMEOUT=${TIMEOUT:-300}

# Ensure required directories exist
mkdir -p "${LOG_DIR}" "${TEMP_DIR}" "${DATA_DIR}"

# Logging function with timestamps and log rotation
log() {
    local level="$1"
    shift
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_DIR}/pipeline.log"
    
    # Rotate log if it's larger than 10MB
    if [[ -f "$log_file" ]] && [[ $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file") -gt 10485760 ]]; then
        mv "$log_file" "${log_file}.$(date +%Y%m%d_%H%M%S)"
    fi
    
    echo "[$timestamp] [$level] $*" | tee -a "$log_file"
}

# Cleanup function - guaranteed to run on exit
cleanup() {
    local exit_code=$?
    local temp_files=$(find "$TEMP_DIR" -name "*.tmp" -type f 2>/dev/null || true)
    
    if [[ -n "$temp_files" ]]; then
        log "WARNING" "Cleaning up temporary files: $temp_files"
        rm -f $temp_files
    fi
    
    log "INFO" "Pipeline completed with exit code: $exit_code"
    
    # Send completion notification if configured
    if [[ -n "${WEBHOOK_URL:-}" ]]; then
        send_notification "Pipeline completed" "Exit code: $exit_code"
    fi
}
trap cleanup EXIT

# Send notification function (placeholder for webhook/email)
send_notification() {
    local title="$1"
    local message="$2"
    
    if [[ -n "${WEBHOOK_URL:-}" ]]; then
        # Example Slack webhook
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$title: $message\"}" \
            "$WEBHOOK_URL" 2>/dev/null || log "WARNING" "Failed to send notification"
    fi
}

# Retry mechanism for flaky operations
retry_command() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local command=("$@")
    
    for ((i=1; i<=max_attempts; i++)); do
        log "INFO" "Attempting command (attempt $i/$max_attempts): ${command[*]}"
        
        if "${command[@]}"; then
            log "INFO" "Command succeeded on attempt $i"
            return 0
        fi
        
        if (( i < max_attempts )); then
            log "WARNING" "Command failed, retrying in ${delay}s..."
            sleep "$delay"
        fi
    done
    
    log "ERROR" "Command failed after $max_attempts attempts"
    return 1
}

# Comprehensive input validation
validate_inputs() {
    if [[ $# -lt 1 ]]; then
        log "ERROR" "Usage: $0 <data_source> [--output <output_file>] [--config <config_file>]"
        exit 1
    fi
    
    local data_source="$1"
    
    # Validate data source
    if [[ ! -f "$data_source" ]]; then
        log "ERROR" "Data source file not found: $data_source"
        exit 1
    fi
    
    if [[ ! -r "$data_source" ]]; then
        log "ERROR" "Data source file not readable: $data_source"
        exit 1
    fi
    
    # Check file size
    local file_size=$(stat -f%z "$data_source" 2>/dev/null || stat -c%s "$data_source")
    if (( file_size == 0 )); then
        log "ERROR" "Data source file is empty: $data_source"
        exit 1
    fi
    
    # Validate file format (basic CSV check)
    if ! head -n 1 "$data_source" | grep -q ","; then
        log "WARNING" "Data source may not be CSV format: $data_source"
    fi
    
    log "INFO" "Input validation passed for: $data_source"
}

# Data quality checks
validate_data_quality() {
    local input_file="$1"
    local errors=0
    
    log "INFO" "Running data quality checks on $input_file"
    
    # Check for duplicate rows
    local total_rows=$(wc -l < "$input_file")
    local unique_rows=$(sort -u "$input_file" | wc -l)
    
    if (( total_rows != unique_rows )); then
        local duplicates=$((total_rows - unique_rows))
        log "WARNING" "Found $duplicates duplicate rows in $input_file"
        ((errors++))
    fi
    
    # Check for empty lines
    local empty_lines=$(grep -c '^$' "$input_file" || true)
    if (( empty_lines > 0 )); then
        log "WARNING" "Found $empty_lines empty lines in $input_file"
        ((errors++))
    fi
    
    # Check for malformed rows (different column counts)
    local header_cols=$(head -n 1 "$input_file" | tr ',' '\n' | wc -l)
    local malformed=$(awk -F',' "NF != $header_cols && NR > 1 {print NR}" "$input_file" | wc -l)
    
    if (( malformed > 0 )); then
        log "WARNING" "Found $malformed rows with incorrect column count"
        ((errors++))
    fi
    
    if (( errors > 0 )); then
        log "WARNING" "Data quality check found $errors issues"
    else
        log "INFO" "Data quality checks passed"
    fi
    
    return $errors
}

# Progress tracking
track_progress() {
    local current="$1"
    local total="$2"
    local operation="$3"
    
    local percentage=$((current * 100 / total))
    log "INFO" "Progress: $percentage% ($current/$total) - $operation"
}

# Main pipeline function
run_pipeline() {
    local data_source="$1"
    local output_file="${2:-${DATA_DIR}/processed_$(date +%Y%m%d_%H%M%S).csv}"
    local temp_output="${TEMP_DIR}/$(basename "$output_file").tmp"
    local temp_backup="${TEMP_DIR}/$(basename "$output_file").backup"
    
    log "INFO" "Starting pipeline for: $data_source"
    log "INFO" "Output will be written to: $output_file"
    
    # Validate data quality
    validate_data_quality "$data_source"
    
    # Get file statistics for progress tracking
    local total_lines=$(wc -l < "$data_source")
    log "INFO" "Processing $total_lines lines from $data_source"
    
    # Process data with timeout and progress tracking
    log "INFO" "Processing data from $data_source to $temp_output"
    
    local processed_lines=0
    
    # Use timeout to prevent hanging
    if timeout "$TIMEOUT" bash -c "
        # Remove header, sort, and deduplicate
        tail -n +2 '$data_source' | \
        sort -t',' -k1,1 | \
        uniq > '$temp_output'
    "; then
        processed_lines=$(wc -l < "$temp_output")
        track_progress "$processed_lines" "$total_lines" "Data processing"
    else
        log "ERROR" "Data processing timed out after ${TIMEOUT} seconds"
        return 1
    fi
    
    # Validate output
    if [[ ! -f "$temp_output" ]] || [[ ! -s "$temp_output" ]]; then
        log "ERROR" "Output file is empty or missing: $temp_output"
        return 1
    fi
    
    # Add header back to processed data
    local header=$(head -n 1 "$data_source")
    {
        echo "$header"
        cat "$temp_output"
    } > "${temp_output}.with_header"
    
    # Atomic move - ensures complete file or nothing
    if [[ -f "$output_file" ]]; then
        # Create backup of existing file
        cp "$output_file" "$temp_backup"
        log "INFO" "Created backup of existing file: $temp_backup"
    fi
    
    if mv "${temp_output}.with_header" "$output_file"; then
        log "INFO" "Successfully moved processed data to final location"
        
        # Clean up temp files
        rm -f "$temp_output" "$temp_backup"
        
        # Generate processing statistics
        local output_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file")
        local compression_ratio=$((output_size * 100 / $(stat -f%z "$data_source" 2>/dev/null || stat -c%s "$data_source")))
        
        log "INFO" "Pipeline statistics:"
        log "INFO" "  Input lines: $total_lines"
        log "INFO" "  Output lines: $processed_lines"
        log "INFO" "  Output size: $output_size bytes"
        log "INFO" "  Compression ratio: $compression_ratio%"
        
        return 0
    else
        log "ERROR" "Failed to move processed data to final location"
        # Attempt to restore backup if it exists
        if [[ -f "$temp_backup" ]]; then
            mv "$temp_backup" "$output_file"
            log "INFO" "Restored backup file"
        fi
        return 1
    fi
}

# Batch processing function for large files
process_in_batches() {
    local input_file="$1"
    local output_dir="$2"
    local batch_size="$3"
    
    log "INFO" "Processing $input_file in batches of $batch_size lines"
    
    local total_lines=$(wc -l < "$input_file")
    local batches=$(( (total_lines + batch_size - 1) / batch_size ))
    local header=$(head -n 1 "$input_file")
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Process each batch
    for ((i=1; i<=batches; i++)); do
        local start_line=$(((i-1) * batch_size + 2)) # +2 to skip header
        local end_line=$((i * batch_size + 1))
        local output_file="${output_dir}/batch_${i}_$(date +%Y%m%d_%H%M%S).csv"
        
        log "INFO" "Processing batch $i/$batches (lines $start_line-$end_line)"
        
        # Extract batch
        if sed -n "${start_line},${end_line}p" "$input_file" | \
            sort -t',' -k1,1 | \
            uniq > "${output_file}.tmp"; then
            
            # Add header
            {
                echo "$header"
                cat "${output_file}.tmp"
            } > "$output_file"
            
            rm -f "${output_file}.tmp"
            track_progress "$i" "$batches" "Batch processing"
        else
            log "ERROR" "Failed to process batch $i"
            return 1
        fi
    done
    
    log "INFO" "Batch processing completed. Output in: $output_dir"
    return 0
}

# Configuration validation
validate_config() {
    if [[ -n "${MAX_RETRIES:-}" ]] && ! [[ "$MAX_RETRIES" =~ ^[0-9]+$ ]]; then
        log "ERROR" "MAX_RETRIES must be a positive integer"
        exit 1
    fi
    
    if [[ -n "${BATCH_SIZE:-}" ]] && ! [[ "$BATCH_SIZE" =~ ^[0-9]+$ ]]; then
        log "ERROR" "BATCH_SIZE must be a positive integer"
        exit 1
    fi
    
    if [[ -n "${TIMEOUT:-}" ]] && ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
        log "ERROR" "TIMEOUT must be a positive integer"
        exit 1
    fi
    
    log "INFO" "Configuration validation passed"
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    log "INFO" "Pipeline started at $(date '+%Y-%m-%d %H:%M:%S')"
    log "INFO" "Script: $0"
    log "INFO" "Working directory: $SCRIPT_DIR"
    log "INFO" "Process ID: $$"
    
    # Validate configuration
    validate_config
    
    # Parse command line arguments
    local data_source=""
    local output_file=""
    local use_batches=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output)
                output_file="$2"
                shift 2
                ;;
            --batch)
                use_batches=true
                shift
                ;;
            --config)
                if [[ -f "$2" ]]; then
                    source "$2"
                    log "INFO" "Loaded configuration from: $2"
                else
                    log "ERROR" "Configuration file not found: $2"
                    exit 1
                fi
                shift 2
                ;;
            -*)
                log "ERROR" "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$data_source" ]]; then
                    data_source="$1"
                else
                    log "ERROR" "Multiple data sources specified"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate inputs
    validate_inputs "$data_source"
    
    # Run pipeline
    if [[ "$use_batches" == true ]]; then
        local batch_output_dir="${DATA_DIR}/batches_$(date +%Y%m%d_%H%M%S)"
        process_in_batches "$data_source" "$batch_output_dir" "$BATCH_SIZE"
    else
        run_pipeline "$data_source" "$output_file"
    fi
    
    # Calculate execution time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log "INFO" "Pipeline completed in ${duration} seconds"
}

# Execute main function with all arguments
main "$@"
