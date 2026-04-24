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



