#!/bin/bash
# Security-focused log monitoring

echo "=== Security Log Monitor ==="
echo "Generated: $(date)"
echo

# Check if auth.log exists
AUTH_LOG="/var/log/auth.log"
if [ ! -r "$AUTH_LOG" ]; then
    echo "❌ Error: Cannot read auth log $AUTH_LOG"
    echo "Try running with sudo"
    exit 1
fi

# Time window for analysis (last 24 hours)
SINCE=$(date -d "24 hours ago" +"%b %d %H")

# Failed login attempts
FAILED_LOGINS=$(grep "$SINCE" "$AUTH_LOG" | grep "Failed password" | wc -l)
echo "Failed login attempts (last 24h): $FAILED_LOGINS"

# SSH brute force detection
echo
echo "Top failed login sources:"
grep "$SINCE" "$AUTH_LOG" | grep "Failed password" | awk '{print $11}' | sort | uniq -c | sort -nr | head -5

# Check for potential brute force attacks
BRUTE_FORCE_THRESHOLD=10
BRUTE_FORCE_IPS=$(grep "$SINCE" "$AUTH_LOG" | grep "Failed password" | awk '{print $11}' | sort | uniq -c | awk -v threshold="$BRUTE_FORCE_THRESHOLD" '$1 > threshold {print $2}')

if [ ! -z "$BRUTE_FORCE_IPS" ]; then
    echo
    echo "⚠️  POTENTIAL BRUTE FORCE ATTACKS DETECTED:"
    for ip in $BRUTE_FORCE_IPS; do
        count=$(grep "$SINCE" "$AUTH_LOG" | grep "Failed password" | grep "$ip" | wc -l)
        echo "  $ip: $count failed attempts"
    done
    echo
    echo "Recommendation: Consider blocking these IPs with iptables or fail2ban"
fi

# Successful logins
SUCCESSFUL_LOGINS=$(grep "$SINCE" "$AUTH_LOG" | grep "Accepted password" | wc -l)
echo
echo "Successful logins (last 24h): $SUCCESSFUL_LOGINS"

# Sudo usage
SUDO_COMMANDS=$(grep "$SINCE" "$AUTH_LOG" | grep "sudo:" | wc -l)
echo "Sudo commands executed: $SUDO_COMMANDS"

# Recent sudo activity
if [ "$SUDO_COMMANDS" -gt 0 ]; then
    echo
    echo "Recent sudo activity:"
    grep "$SINCE" "$AUTH_LOG" | grep "sudo:" | tail -5 | awk '{print $1 " " $2 " " $3 " " $15 " " $16}'
fi

# Root login attempts
ROOT_ATTEMPTS=$(grep "$SINCE" "$AUTH_LOG" | grep "root" | wc -l)
echo
echo "Root login attempts: $ROOT_ATTEMPTS"

# Unusual user activity
echo
echo "Recent user activity:"
grep "$SINCE" "$AUTH_LOG" | grep "session opened" | awk '{print $1 " " $2 " " $3 " " $9}' | tail -5

# Summary
echo
echo "=== Security Summary ==="
if [ "$FAILED_LOGINS" -gt 0 ]; then
    echo "⚠️  $FAILED_LOGINS failed login attempts detected"
fi

if [ ! -z "$BRUTE_FORCE_IPS" ]; then
    echo "🚨 Potential brute force attacks from multiple IPs"
fi

if [ "$ROOT_ATTEMPTS" -gt 0 ]; then
    echo "🔒 $ROOT_ATTEMPTS root login attempts detected"
fi

if [ "$FAILED_LOGINS" -eq 0 ] && [ -z "$BRUTE_FORCE_IPS" ] && [ "$ROOT_ATTEMPTS" -eq 0 ]; then
    echo "✅ No significant security issues detected"
fi

echo
echo "=== End of Security Report ==="
