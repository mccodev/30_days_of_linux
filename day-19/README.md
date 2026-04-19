# Day 19 - System Monitoring & Performance Analysis

## Objective

Learn how to effectively monitor Linux systems, analyze performance metrics, and troubleshoot bottlenecks. Understanding system monitoring is crucial for maintaining healthy infrastructure and identifying issues before they become critical problems in production environments.

---

## What I Learned

### Core Monitoring Commands

- **`top` & `htop`:** Real-time process monitoring with CPU, memory, and resource usage
- **`ps`:** Process status reporting with various filtering options (`ps aux`, `ps -ef`)
- **`free`:** Memory usage statistics (`free -h` for human-readable format)
- **`df` & `du`:** Disk space usage and directory size analysis
- **`iostat`:** I/O and CPU statistics for storage performance monitoring
- **`vmstat`:** Virtual memory statistics and system activity reporting

### Performance Analysis Tools

- **`sar`:** System Activity Reporter for historical performance data
- **`netstat` & `ss`:** Network connections and socket statistics
- **`lsof`:** List Open Files to track file and network connections
- **`strace`:** System call tracing for debugging process behavior
- **`perf`:** Performance analysis tool for CPU profiling and bottleneck identification

### Log Analysis & Monitoring

- **`journalctl`:** Systemd journal filtering and analysis
- **`tail -f`:** Real-time log monitoring
- **`grep` with regex:** Pattern matching in log files
- **Log rotation:** Understanding `/etc/logrotate.conf` configuration

---

## What I Built / Practiced

### System Health Monitor Script

Created `system_monitor.sh` that:
- Collects key metrics (CPU, memory, disk, network) every 60 seconds
- Generates alerts when thresholds are exceeded
- Logs historical data for trend analysis
- Provides summary reports with performance recommendations

### Performance Baseline Analyzer

Built `baseline_analyzer.sh` featuring:
- System resource profiling during normal operation
- Automated baseline establishment for different time periods
- Comparison analysis to detect anomalies
- Performance regression detection

### Log Aggregation Tool

Developed `log_aggregator.sh` that:
- Consolidates logs from multiple sources
- Filters and categorizes log entries by severity
- Generates daily/weekly summary reports
- Identifies recurring error patterns

---

## Challenges Faced

- **Interpreting vmstat output:** Understanding the various columns and what they indicate about system health - solved by studying each metric and creating reference documentation
- **Setting appropriate thresholds:** Determining what constitutes "normal" vs "problematic" resource usage - addressed by establishing baselines during different load conditions
- **Performance impact of monitoring:** Monitoring tools themselves consuming resources - mitigated by using lightweight alternatives and scheduling monitoring during off-peak hours
- **Log file permissions:** Access restrictions preventing log analysis - resolved by understanding proper user permissions and sudo usage
- **Correlating metrics:** Connecting different performance indicators to identify root causes - improved by creating cross-reference charts and correlation matrices

---

## Key Takeaways

- **Establish baselines first:** You can't identify problems without knowing what "normal" looks like for your specific workload
- **Monitor holistically:** Don't focus on single metrics - look at the relationship between CPU, memory, I/O, and network
- **Historical data is valuable:** Trends over time are more informative than snapshots - enable `sar` and other logging tools
- **Automate alerts:** Set up proactive monitoring before problems become critical
- **Understand your tools:** Know when to use `top` vs `htop` vs `ps` - each has specific strengths
- **Context matters:** High CPU usage isn't always bad - understand what's normal for your applications
- **Document everything:** Keep records of performance issues and resolutions for future reference

---

## Resources

- `man top`, `man ps`, `man vmstat`, `man iostat` - Comprehensive command manuals
- [Linux Performance Analysis](http://www.brendangregg.com/linuxperf.html) - Brendan Gregg's excellent performance site
- [Linux Performance Monitoring Guide](https://www.systutorials.com/linux-performance-monitoring/)
- [Understanding /proc filesystem](https://www.kernel.org/doc/html/latest/filesystems/proc.html)
- [System Monitoring Best Practices](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/index)

---

## Output

(Include links, screenshots, code snippets, or results)
