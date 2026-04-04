# Day 04 - I/O Redirection & Logging Pipeline Output to Files

## Objective

- Deepen understanding of all five I/O redirection operators: `>`, `>>`, `<`, `2>`, and `tee`
- Learn how to structure pipeline logging properly — separating stdout, stderr, and combined logs
- Practice real-world patterns for logging long-running data pipeline runs to files

---

## What I Learned

### The Five Redirection Operators

| Operator | Meaning |
|----------|---------|
| `>`      | Redirect stdout to a file — **overwrites** the file |
| `>>`     | Redirect stdout to a file — **appends** to the file |
| `<`      | Feed a file as **stdin** to a command |
| `2>`     | Redirect **stderr** (file descriptor 2) to a file |
| `tee`    | Read from stdin, write to **both** stdout and a file simultaneously |

### File Descriptors
- Every process has three standard streams: **0** (stdin), **1** (stdout), **2** (stderr)
- `2>&1` merges stderr into stdout — meaning both streams go to the same destination
- Order matters: `command > file.log 2>&1` works; `command 2>&1 > file.log` does **not** merge as expected

### Separating stdout and stderr
- `command > out.log 2> err.log` — cleanest pattern for pipelines; errors and output never mix
- Separating them makes post-run debugging much easier — you grep `err.log` first, then `out.log`

### Appending vs Overwriting
- `>` is destructive — running a pipeline twice with `>` wipes the previous log
- `>>` is safe for long-running or scheduled pipelines (e.g. cron jobs) where you want a cumulative log
- Common pattern: clear the log at the start of a job (`> pipeline.log`), then append throughout (`>> pipeline.log`)

### `tee` — Log and Watch Simultaneously
- `command | tee output.log` — you see output in the terminal **and** it's saved to the file
- `command | tee -a output.log` — append mode, same as `>>`
- To capture both stdout and stderr with `tee`: `command 2>&1 | tee output.log`

### `/dev/null` — Silencing Output
- `/dev/null` is a special file that discards everything written to it
- `command > /dev/null` — suppress stdout (useful in cron jobs where you only care about errors)
- `command > /dev/null 2>&1` — suppress everything completely

### Here-Documents (`<<`) and Here-Strings (`<<<`)
- `<<EOF ... EOF` — feeds a block of text as stdin to a command; useful in scripts
- `<<<` — feeds a single string as stdin: `wc -w <<< "hello world"` → `2`

---

## What I Built / Practiced

- Wrote a simulated pipeline script that redirects stdout to `pipeline.log` and stderr to `pipeline_errors.log`
- Used `tee -a` to both log and monitor a running pipeline in real time
- Practiced `2>&1` merging to send all output through a single `tee` log stream
- Used `< input.csv` to feed a data file as stdin into a processing command
- Silenced noisy cron job output with `> /dev/null 2>&1` while keeping error alerts active
- Experimented with `>>` for cumulative daily job logs vs `>` for fresh-start logs

---

## Challenges Faced

- The ordering bug with `2>&1` — writing `command 2>&1 > file` feels logical but doesn't work; the redirection is evaluated left to right, so stderr is merged to the *current* stdout (terminal) before stdout is redirected to the file
- Knowing when to use `>` vs `>>` in scheduled jobs — appending forever means logs grow unbounded; need a rotation strategy (e.g. `logrotate`) for production
- `tee` only: it exits with 0 even when the piped command fails — had to use `pipefail` to catch real exit codes

---

## Key Takeaways

- **Always separate stdout and stderr in pipelines** — `> out.log 2> err.log` makes debugging dramatically faster
- `2>&1` must come *after* the `>` redirect — left-to-right evaluation means order is everything
- `tee -a` is the right default for observable, long-running pipelines — you get logs *and* live visibility
- `/dev/null` is not a hack — it's a deliberate choice for suppressing noise in automated jobs
- For scheduled/cron pipelines: use `>>` with timestamps in log lines so you can track runs over time
- Set `set -o pipefail` in bash scripts so a failed command in a pipe actually fails the script

---

## Resources

- `man tee`, `man bash` (search `/Redirections`) — built-in manual pages
- [Bash Redirections Cheat Sheet](https://www.gnu.org/software/bash/manual/bash.html#Redirections) — official GNU Bash docs
- [Understanding /dev/null](https://www.digitalocean.com/community/tutorials/dev-null-in-linux) — DigitalOcean explainer
- [pipefail explained](https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/) — why `set -o pipefail` matters in pipeline scripts

---

## Output

```bash
# Redirect stdout and stderr to separate log files
$ ./run_pipeline.sh > logs/pipeline.log 2> logs/pipeline_errors.log

# Append mode — safe for cron/scheduled jobs
$ ./run_pipeline.sh >> logs/pipeline.log 2>> logs/pipeline_errors.log

# Merge stderr into stdout, then log everything with tee (live + file)
$ ./run_pipeline.sh 2>&1 | tee -a logs/pipeline.log

# Feed a CSV file as stdin to a processing command
$ ./process_data.sh < data/input.csv

# Suppress all output (silent cron job)
$ ./run_pipeline.sh > /dev/null 2>&1

# Show only errors, suppress normal output
$ ./run_pipeline.sh > /dev/null 2> logs/pipeline_errors.log

# Timestamp each log line for scheduled runs
$ ./run_pipeline.sh 2>&1 | while IFS= read -r line; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') $line"
  done | tee -a logs/pipeline.log

# Enable pipefail so a broken pipe command fails the whole script
$ set -o pipefail
$ ./run_pipeline.sh 2>&1 | tee -a logs/pipeline.log
echo "Exit code: $?"
```
