#!/bin/bash
# Log management and rotation automation

LOG_DIR="/var/log/custom"
CONFIG_FILE="custom_logrotate.conf"
MAX_SIZE="100M"  # Rotate logs when they reach 100MB
RETENTION_DAYS=30

echo "=== Log Management Tool ==="
echo "Generated: $(date)"
echo

# Create custom log directory if it doesn't exist
if [ ! -d "$LOG_DIR" ]; then
    echo "Creating custom log directory: $LOG_DIR"
    sudo mkdir -p "$LOG_DIR"
    sudo chmod 755 "$LOG_DIR"
fi

# Function to check log sizes
check_log_sizes() {
    echo "Checking log sizes in $LOG_DIR:"
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "*.log" -exec ls -lh {} \; | awk '{print $9 ": " $5}'
    else
        echo "No custom log directory found"
    fi
}

# Function to create sample logs for testing
create_sample_logs() {
    echo "Creating sample log files for testing..."
    
    # Sample application log
    sudo tee "$LOG_DIR/app.log" > /dev/null << 'EOF'
2024-04-25 10:00:01 INFO Application started successfully
2024-04-25 10:00:02 INFO Database connection established
2024-04-25 10:15:23 WARN High memory usage detected
2024-04-25 10:30:45 ERROR Failed to process user request
2024-04-25 10:45:12 INFO Request processed successfully
2024-04-25 11:00:00 ERROR Database connection timeout
EOF

    # Sample access log
    sudo tee "$LOG_DIR/access.log" > /dev/null << 'EOF'
192.168.1.100 - - [25/Apr/2024:10:00:01 +0000] "GET /api/users HTTP/1.1" 200 1234
192.168.1.101 - - [25/Apr/2024:10:00:02 +0000] "POST /api/login HTTP/1.1" 401 567
192.168.1.102 - - [25/Apr/2024:10:00:03 +0000] "GET /api/data HTTP/1.1" 200 8901
192.168.1.100 - - [25/Apr/2024:10:00:04 +0000] "PUT /api/users/123 HTTP/1.1" 200 234
192.168.1.103 - - [25/Apr/2024:10:00:05 +0000] "DELETE /api/users/456 HTTP/1.1" 204 0
EOF

    echo "Sample logs created in $LOG_DIR"
}

# Function to create logrotate configuration
create_logrotate_config() {
    echo "Creating logrotate configuration..."
    
    cat > "$CONFIG_FILE" << EOF
# Custom log rotation configuration
$LOG_DIR/*.log {
    daily
    missingok
    rotate $RETENTION_DAYS
    compress
    delaycompress
    notifempty
    create 644 root root
    size $MAX_SIZE
    sharedscripts
    postrotate
        # Reload any services that need to be aware of log rotation
        # systemctl reload rsyslog 2>/dev/null || true
    endscript
}
EOF

    echo "Logrotate configuration created: $CONFIG_FILE"
}

# Function to test logrotate configuration
test_logrotate() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "Testing logrotate configuration..."
        sudo logrotate -d "$CONFIG_FILE"
    else
        echo "❌ Logrotate configuration file not found. Run with 'config' option first."
    fi
}

# Function to force log rotation
force_rotation() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "Forcing log rotation..."
        sudo logrotate -f "$CONFIG_FILE"
        echo "Log rotation completed."
        check_log_sizes
    else
        echo "❌ Logrotate configuration file not found. Run with 'config' option first."
    fi
}

# Function to clean old logs
cleanup_old_logs() {
    echo "Cleaning up logs older than $RETENTION_DAYS days..."
    if [ -d "$LOG_DIR" ]; then
        sudo find "$LOG_DIR" -name "*.log.*" -mtime +$RETENTION_DAYS -delete
        echo "Cleanup completed."
    else
        echo "No custom log directory found"
    fi
}

# Function to show disk usage
show_disk_usage() {
    echo "Disk usage for log directories:"
    echo "System logs: $(sudo du -sh /var/log 2>/dev/null | cut -f1)"
    if [ -d "$LOG_DIR" ]; then
        echo "Custom logs: $(sudo du -sh "$LOG_DIR" 2>/dev/null | cut -f1)"
    fi
}

# Main menu
case "${1:-help}" in
    "check")
        check_log_sizes
        ;;
    "create")
        create_sample_logs
        ;;
    "config")
        create_logrotate_config
        ;;
    "test")
        test_logrotate
        ;;
    "rotate")
        force_rotation
        ;;
    "cleanup")
        cleanup_old_logs
        ;;
    "usage")
        show_disk_usage
        ;;
    "help"|*)
        echo "Usage: $0 {check|create|config|test|rotate|cleanup|usage}"
        echo
        echo "Commands:"
        echo "  check   - Check sizes of custom log files"
        echo "  create  - Create sample log files for testing"
        echo "  config  - Create logrotate configuration"
        echo "  test    - Test logrotate configuration (dry run)"
        echo "  rotate  - Force log rotation"
        echo "  cleanup - Remove old log files"
        echo "  usage   - Show disk usage for log directories"
        ;;
esac

echo
echo "=== End of Log Management ==="
