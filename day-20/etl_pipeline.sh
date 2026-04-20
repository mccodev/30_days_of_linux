#!/bin/bash

# Data Engineering ETL Pipeline


set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
DATA_DIR="${SCRIPT_DIR}/data"
DB_FILE="${DATA_DIR}/pipeline.db"
CONFIG_FILE="${SCRIPT_DIR}/config.json"

# Create necessary directories
mkdir -p "${LOG_DIR}" "${DATA_DIR}"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_DIR}/pipeline.log"
}

# Error handling
trap 'log "ERROR" "Pipeline failed at line $LINENO"' ERR
trap 'log "INFO" "Pipeline started"' EXIT

# Function: Extract data from CSV files
extract_csv() {
    log "INFO" "Starting CSV extraction"
    local csv_file="${DATA_DIR}/source_data.csv"
    
    if [[ ! -f "$csv_file" ]]; then
        log "ERROR" "Source CSV file not found: $csv_file"
        return 1
    fi
    
    # Count records
    local record_count=$(wc -l < "$csv_file")
    log "INFO" "Found $record_count records in CSV file"
    
    # Create temporary file for processing
    local temp_file="${DATA_DIR}/temp_extracted.csv"
    cp "$csv_file" "$temp_file"
    
    echo "$temp_file"
}

# Function: Extract data from API
extract_api() {
    log "INFO" "Starting API extraction"
    local api_url="https://jsonplaceholder.typicode.com/users"
    local output_file="${DATA_DIR}/api_data.json"
    
    # Extract data with retry logic
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -s -f -o "$output_file" "$api_url"; then
            log "INFO" "API extraction successful"
            echo "$output_file"
            return 0
        else
            retry_count=$((retry_count + 1))
            log "WARN" "API extraction failed, retry $retry_count/$max_retries"
            sleep 2
        fi
    done
    
    log "ERROR" "API extraction failed after $max_retries retries"
    return 1
}

# Function: Transform data
transform_data() {
    local csv_file="$1"
    local api_file="$2"
    
    log "INFO" "Starting data transformation"
    
    # Transform CSV data
    local transformed_csv="${DATA_DIR}/transformed_data.csv"
    
    # Example transformation: filter, clean, and format
    awk -F',' '
    NR==1 {print $0; next}  # Keep header
    $3 != "" && $4 > 0 {    # Basic validation
        gsub(/^[ \t]+|[ \t]+$/, "", $0)  # Trim whitespace
        print $0
    }
    ' "$csv_file" > "$transformed_csv"
    
    # Transform API data using jq
    local transformed_api="${DATA_DIR}/transformed_api.json"
    if [[ -f "$api_file" ]]; then
        jq 'map({
            id: .id,
            name: .name,
            email: .email,
            processed_at: now | strftime("%Y-%m-%d %H:%M:%S")
        })' "$api_file" > "$transformed_api"
    fi
    
    log "INFO" "Data transformation completed"
    echo "$transformed_csv,$transformed_api"
}

# Function: Load data into database
load_data() {
    local transformed_files="$1"
    IFS=',' read -r csv_file api_file <<< "$transformed_files"
    
    log "INFO" "Starting data loading"
    
    # Initialize SQLite database
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stage TEXT NOT NULL,
    status TEXT NOT NULL,
    record_count INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
    
    # Load CSV data
    if [[ -f "$csv_file" ]]; then
        local csv_records=$(sqlite3 "$DB_FILE" <<EOF
.mode csv
.import "$csv_file" users
SELECT COUNT(*) FROM users;
EOF
)
        log "INFO" "Loaded $csv_records records from CSV"
    fi
    
    # Load API data
    if [[ -f "$api_file" ]]; then
        local api_records=$(jq length "$api_file")
        log "INFO" "Processed $api_records records from API"
    fi
    
    # Log pipeline execution
    sqlite3 "$DB_FILE" <<EOF
INSERT INTO pipeline_log (stage, status, record_count)
VALUES ('load', 'success', $(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users"));
EOF
    
    log "INFO" "Data loading completed"
}

# Function: Validate data quality
validate_data() {
    log "INFO" "Starting data validation"
    
    # Check data quality metrics
    local total_records=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users")
    local null_emails=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE email IS NULL OR email = ''")
    local duplicates=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) - COUNT(DISTINCT email) FROM users WHERE email IS NOT NULL")
    
    log "INFO" "Validation results:"
    log "INFO" "  Total records: $total_records"
    log "INFO" "  Null emails: $null_emails"
    log "INFO" "  Duplicate emails: $duplicates"
    
    # Calculate quality score
    local quality_score=$(echo "scale=2; (1 - ($null_emails + $duplicates) / $total_records) * 100" | bc -l)
    log "INFO" "  Data quality score: $quality_score%"
    
    # Log validation results
    sqlite3 "$DB_FILE" <<EOF
INSERT INTO pipeline_log (stage, status, record_count)
VALUES ('validation', 'success', $total_records);
EOF
    
    echo "$quality_score"
}

# Function: Generate pipeline report
generate_report() {
    local quality_score="$1"
    
    log "INFO" "Generating pipeline report"
    
    local report_file="${LOG_DIR}/pipeline_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" <<EOF
Pipeline Execution Report
========================
Execution Time: $(date)
Data Quality Score: $quality_score%

Database Statistics:
$(sqlite3 "$DB_FILE" <<EOF
SELECT 'Total Users: ' || COUNT(*) FROM users;
SELECT 'Pipeline Runs: ' || COUNT(*) FROM pipeline_log;
SELECT 'Last Run: ' || MAX(timestamp) FROM pipeline_log;
EOF
)

Recent Pipeline Activity:
$(sqlite3 "$DB_FILE" <<EOF
SELECT stage, status, record_count, timestamp 
FROM pipeline_log 
ORDER BY timestamp DESC 
LIMIT 10;
EOF
)
EOF
    
    log "INFO" "Report generated: $report_file"
}

# Main pipeline execution
main() {
    log "INFO" "=== Starting ETL Pipeline ==="
    
    # Extract phase
    local csv_file=$(extract_csv)
    local api_file=$(extract_api)
    
    # Transform phase
    local transformed_files=$(transform_data "$csv_file" "$api_file")
    
    # Load phase
    load_data "$transformed_files"
    
    # Validation phase
    local quality_score=$(validate_data)
    
    # Reporting phase
    generate_report "$quality_score"
    
    # Cleanup
    rm -f "${DATA_DIR}"/temp_*
    
    log "INFO" "=== ETL Pipeline Completed Successfully ==="
    log "INFO" "Final data quality score: $quality_score%"
}

# Execute pipeline
main "$@"
