# Day 23 - Network Monitoring & Troubleshooting for Data Engineers

## Objective

Master essential Linux network monitoring and troubleshooting tools to diagnose connectivity issues, monitor data transfers, and ensure reliable pipeline operations across distributed systems.

---

## What I Learned

### 1. Network Interface Basics

- **Network Interfaces:** `eth0`, `wlan0`, `lo` (loopback) - different physical and virtual network adapters
- **IP Addressing:** IPv4 vs IPv6, private vs public addresses, subnet masks
- **MAC Addresses:** Hardware-level identification for network devices
- **DNS Resolution:** Domain name to IP address mapping and caching

### 2. Essential Network Commands

#### `ip` - Modern Network Configuration
```bash
# Show all network interfaces
ip addr show

# Show routing table
ip route show

# Show network statistics
ip -s link show
```

#### `ss` - Socket Statistics (modern `netstat`)
```bash
# Show all listening ports
ss -tlnp

# Show established connections
ss -tnp

# Show UDP sockets
ss -ulpn
```

#### `ping` - Connectivity Testing
```bash
# Basic connectivity test
ping google.com

# Send 5 packets then stop
ping -c 5 8.8.8.8

# Flood ping (stress test)
ping -f localhost
```

#### `traceroute` - Path Tracing
```bash
# Trace route to destination
traceroute google.com

# Use TCP instead of ICMP
traceroute -T google.com
```

#### `netstat` - Legacy Network Statistics
```bash
# Show all connections
netstat -tulnp

# Show interface statistics
netstat -i
```

### 3. Bandwidth Monitoring

#### `iftop` - Real-time Bandwidth Usage
```bash
# Monitor interface eth0
sudo iftop -i eth0

# Show port numbers instead of names
sudo iftop -n
```

#### `nload` - Network Load Monitor
```bash
# Monitor all interfaces
nload

# Monitor specific interface
nload eth0
```

### 4. Connection Debugging

#### `telnet` & `nc` (netcat) - Port Testing
```bash
# Test if port is open
telnet google.com 80

# Netcat port scanning
nc -zv localhost 22-25
```

#### `curl` - HTTP/HTTPS Debugging
```bash
# Test HTTP endpoint with timing
curl -w "@curl-format.txt" -o /dev/null -s http://api.example.com

# Test HTTPS with certificate info
curl -v https://api.example.com
```

### 5. DNS Troubleshooting

#### `dig` - DNS Lookup Utility
```bash
# Basic DNS lookup
dig google.com

# Trace DNS resolution
dig +trace google.com

# Query specific DNS server
dig @8.8.8.8 google.com
```

#### `nslookup` - Simple DNS Query
```bash
# Basic lookup
nslookup google.com

# Reverse lookup
nslookup 8.8.8.8
```

### 6. Advanced Network Tools

#### `tcpdump` - Packet Capture
```bash
# Capture on interface eth0
sudo tcpdump -i eth0

# Filter by port
sudo tcpdump -i eth0 port 80

# Save to file
sudo tcpdump -i eth0 -w capture.pcap
```

#### `nmap` - Network Scanning
```bash
# Basic port scan
nmap localhost

# Service version detection
nmap -sV localhost

# OS detection
nmap -O localhost
```

---

## What I Built / Practiced

### Network Diagnostic Script (`network_diag.sh`)
Created comprehensive network health check script:
- Interface status monitoring
- DNS resolution testing
- Connectivity checks to critical services
- Bandwidth usage reporting
- Automated troubleshooting recommendations

### API Connectivity Monitor (`api_monitor.sh`)
Built monitoring tool for data pipeline APIs:
- HTTP endpoint availability testing
- Response time tracking
- SSL certificate validation
- Connection timeout detection
- Historical performance logging

### Network Performance Benchmark (`net_benchmark.sh`)
Developed performance testing suite:
- Download/upload speed testing
- Latency measurement to multiple endpoints
- Packet loss detection
- Concurrent connection testing
- Network quality scoring

---

## Challenges Faced

- **Permission Issues:** Many network tools require `sudo` access - learned to check privileges and use appropriate escalation
- **Command Variations:** Different Linux distributions use different tools (`ip` vs `ifconfig`, `ss` vs `netstat`) - discovered the importance of knowing both legacy and modern tools
- **Interpreting Output:** Network command output can be cryptic - spent time understanding TCP states, UDP statistics, and interface metrics
- **Firewall Interference:** Local firewalls blocking diagnostic tests - learned to check `ufw`/`iptables` rules during troubleshooting
- **DNS Caching:** Local DNS caching causing stale results - learned to flush caches with `systemd-resolve --flush-caches`

---

## Key Takeaways

- **Network visibility is critical:** Data engineers must understand network behavior to debug pipeline issues
- **Start simple, then go deep:** Use `ping` and `curl` before diving into packet captures
- **Know your tools:** Modern (`ip`, `ss`) vs legacy (`ifconfig`, `netstat`) commands
- **Monitor proactively:** Don't wait for failures - implement continuous network monitoring
- **Document network topology:** Keep records of service endpoints, ports, and dependencies
- **Test from multiple perspectives:** Check connectivity from both client and server sides
- **Understand the layers:** Application (HTTP), transport (TCP/UDP), network (IP), and link layers each need different tools

---

## Resources

- `man ip`, `man ss`, `man tcpdump`, `man nmap`
- [Linux Network Administration Guide](https://tldp.org/LDP/nag2/)
- [Network Troubleshooting Cheat Sheet](https://github.com/donnemartin/devops-cheatsheets/blob/master/troubleshooting.md)
- [TCP/IP Guide](http://www.tcpipguide.com/free/t_TCPIPInternetProtocolArchitectureandIP.htm)
- [Wireshark Network Analysis](https://www.wireshark.org/docs/)

---

## Output

### Network Diagnostic Script (`network_diag.sh`)
```bash
#!/bin/bash

echo "=== Network Diagnostic Report ==="
echo "Generated: $(date)"
echo

# Interface status
echo "Network Interfaces:"
ip addr show | grep -E "^[0-9]+:|inet " | sed 's/^[ ]*//'
echo

# DNS resolution test
echo "DNS Resolution Test:"
if dig +short google.com >/dev/null 2>&1; then
    echo "✓ DNS resolution working"
else
    echo "✗ DNS resolution failed"
fi
echo

# Connectivity tests
echo "Connectivity Tests:"
ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "✓ Google DNS reachable" || echo "✗ Google DNS unreachable"
ping -c 1 google.com >/dev/null 2>&1 && echo "✓ Internet connectivity OK" || echo "✗ Internet connectivity failed"
echo

# Listening ports
echo "Listening Ports:"
ss -tlnp | grep LISTEN | head -10
```

### API Monitor Configuration (`api_config.json`)
```json
{
  "endpoints": [
    {
      "name": "User API",
      "url": "https://api.example.com/users",
      "timeout": 10,
      "expected_status": 200
    },
    {
      "name": "Data Pipeline",
      "url": "https://pipeline.example.com/health",
      "timeout": 5,
      "expected_status": 200
    }
  ],
  "monitoring": {
    "interval": 60,
    "alert_threshold": 3,
    "log_file": "/var/log/api_monitor.log"
  }
}
```

### Sample Network Performance Report
```
=== Network Performance Benchmark ===
Date: 2024-01-23 10:30:00

Download Speed: 45.2 Mbps
Upload Speed: 12.8 Mbps
Latency (avg): 23ms
Packet Loss: 0.1%

Endpoints Tested:
- google.com: 22ms ✓
- cloudflare.com: 18ms ✓
- aws.amazon.com: 45ms ✓

Network Quality Score: 92/100
```
