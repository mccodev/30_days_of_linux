# Day 25 - Log Management & Analysis

## Objective

- Master Linux log management and analysis techniques for system troubleshooting
- Learn to navigate, search, and interpret system logs effectively
- Build automated log analysis tools for monitoring and alerting
- Understand log rotation, centralization, and security implications

---

## What I Learned

### 1. System Log Locations & Structure

- **Traditional Log Files**: `/var/log/syslog`, `/var/log/auth.log`, `/var/log/kern.log`
- **Systemd Journal**: `journalctl` - modern unified logging system
- **Application Logs**: `/var/log/apache2/`, `/var/log/nginx/`, `/var/log/mysql/`
- **Log Hierarchy**: Different facilities (auth, daemon, kern, mail, etc.)

### 2. Essential Log Commands

#### `journalctl` - Systemd Journal Control
```bash
# Show all logs
journalctl

# Follow logs in real-time
journalctl -f

# Show logs for specific service
journalctl -u nginx.service

# Show logs from last hour
journalctl --since "1 hour ago"

# Filter by priority level
journalctl -p err -b
```

#### Traditional Log Analysis
```bash
# View system log
tail -f /var/log/syslog

# Search for specific patterns
grep "error" /var/log/syslog

# Show recent auth attempts
tail -n 100 /var/log/auth.log
```

### 3. Log Analysis Tools

#### `grep`, `awk`, `sed` for Log Processing
```bash
# Count error occurrences
grep -c "ERROR" /var/log/application.log

# Extract IP addresses from access logs
awk '{print $1}' /var/log/nginx/access.log | sort | uniq

# Filter logs by date range
grep "2024-01-25" /var/log/syslog
```

#### `logrotate` Configuration
```bash
# View logrotate configuration
cat /etc/logrotate.conf

# Test logrotate configuration
logrotate -d /etc/logrotate.conf
```

### 4. Security Log Monitoring

- **Authentication Logs**: Track failed login attempts, sudo usage
- **Firewall Logs**: Monitor blocked/allowed connections
- **Process Monitoring**: Track suspicious process activity
- **File Access Logs**: Monitor critical file modifications

---

## What I Built / Practiced

### Log Analysis Script (`log_analyzer.sh`)
Created comprehensive log analysis tool:
- Real-time log monitoring with pattern matching
- Automated error detection and alerting
- Log statistics and trend analysis
- Security incident detection
- Custom report generation

### Security Log Monitor (`security_monitor.sh`)
Built security-focused log monitoring:
- Failed login attempt tracking
- SSH brute force detection
- Privilege escalation monitoring
- Anomalous activity alerts
- Automated blocking recommendations

### Log Rotation Manager (`log_manager.sh`)
Developed log management automation:
- Custom log rotation policies
- Compression and archival
- Disk space monitoring
- Retention policy enforcement
- Cleanup automation

---

## Challenges Faced

- **Log Volume**: Managing large log files without overwhelming system resources
- **Permission Issues**: Some logs require root access - learned proper privilege handling
- **Format Variations**: Different applications use different log formats - needed flexible parsing
- **Real-time Processing**: Balancing performance with real-time analysis requirements
- **Log Rotation**: Understanding when logs are rotated and how to handle missing data

---

## Key Takeaways

- **Logs are your forensic toolkit** - they tell the story of what happened on your system
- **Proactive monitoring beats reactive troubleshooting** - set up alerts before problems escalate
- **Standardize log formats** - consistent logging makes analysis much easier
- **Automate repetitive analysis** - manual log review doesn't scale
- **Security starts with logging** - you can't secure what you can't see
- **Retention policies matter** - balance storage needs with compliance requirements
- **Correlation is key** - combine logs from multiple sources for complete picture

---

## Resources

- `man journalctl`, `man logrotate`, `man rsyslog`
- [Linux Logging Guide](https://www.digitalocean.com/community/tutorials/how-to-view-and-manage-logfiles-on-linux)
- [ELK Stack Tutorial](https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-elastic-stack.html)
- [Security Log Analysis](https://www.sans.org/white-papers/1209/)

---

## Output

### Log Analysis Script (`log_analyzer.sh`)
```bash
#!/bin/bash
# Comprehensive log analysis and monitoring tool

LOG_FILE="${1:-/var/log/syslog}"
PATTERN="${2:-ERROR}"
ALERT_THRESHOLD=5

echo "=== Log Analysis Report ==="
echo "Analyzing: $LOG_FILE"
echo "Pattern: $PATTERN"
echo "Generated: $(date)"
echo

# Count pattern occurrences
COUNT=$(grep -c "$PATTERN" "$LOG_FILE" 2>/dev/null || echo "0")
echo "Total '$PATTERN' occurrences: $COUNT"

# Alert if threshold exceeded
if [ "$COUNT" -gt "$ALERT_THRESHOLD" ]; then
    echo "⚠️  ALERT: Pattern count exceeds threshold ($ALERT_THRESHOLD)"
fi

# Show recent occurrences
echo
echo "Recent occurrences:"
grep "$PATTERN" "$LOG_FILE" | tail -10

# Hourly breakdown
echo
echo "Hourly breakdown (last 24 hours):"
for hour in {23..0}; do
    hour_start=$(date -d "$hour hours ago" +"%b %d %H")
    count=$(grep "$hour_start" "$LOG_FILE" | grep -c "$PATTERN")
    echo "$(date -d "$hour hours ago" +"%H:00"): $count"
done
```

### Security Monitor Script (`security_monitor.sh`)
```bash
#!/bin/bash
# Security-focused log monitoring

echo "=== Security Log Monitor ==="
echo "Generated: $(date)"
echo

# Failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
echo "Failed login attempts (last 24h): $FAILED_LOGINS"

# SSH brute force detection
BRUTE_FORCE=$(grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -nr | head -5)
if [ ! -z "$BRUTE_FORCE" ]; then
    echo "⚠️  Potential brute force sources:"
    echo "$BRUTE_FORCE"
fi

# Sudo usage
SUDO_COMMANDS=$(grep "sudo:" /var/log/auth.log | wc -l)
echo "Sudo commands executed: $SUDO_COMMANDS"

# Recent sudo activity
echo
echo "Recent sudo activity:"
grep "sudo:" /var/log/auth.log | tail -5
```

### Sample Log Analysis Output
```
=== Log Analysis Report ===
Analyzing: /var/log/syslog
Pattern: ERROR
Generated: Fri Apr 25 10:30:00 EAT 2026

Total 'ERROR' occurrences: 12
⚠️  ALERT: Pattern count exceeds threshold (5)

Recent occurrences:
Apr 25 09:15:23 server nginx[1234]: ERROR: Connection timeout
Apr 25 09:45:12 server app[5678]: ERROR: Database connection failed
Apr 25 10:12:45 server nginx[1234]: ERROR: Upstream server unavailable

Hourly breakdown (last 24 hours):
00:00: 0
01:00: 1
02:00: 0
...
09:00: 8
10:00: 3
```

### Log Rotation Configuration (`custom_logrotate.conf`)
```
/var/log/custom/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload rsyslog
    endscript
}
```
