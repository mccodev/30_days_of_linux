# Day 07 — Data Lake Folder Audit Script

> **Week 1 Project | 30 Days of Linux for Data Engineering**  
> *Pure bash. No Python. No third-party tools.*

---

## Table of Contents

1. [The Problem This Solves](#1-the-problem-this-solves)
2. [Why This Matters in Data Engineering](#2-why-this-matters-in-data-engineering)
3. [Project Structure](#3-project-structure)
4. [How the Script Works](#4-how-the-script-works)
5. [Line-by-Line Breakdown](#5-line-by-line-breakdown)
6. [Design Decisions & The Whys](#6-design-decisions--the-whys)
7. [Running the Script](#7-running-the-script)
8. [Sample Output](#8-sample-output)
9. [Real-World Extensions](#9-real-world-extensions)
10. [Key Takeaways](#10-key-takeaways)
11. [Resources](#11-resources)

---

## 1. The Problem This Solves

Imagine you inherit a data lake — an S3 bucket synced locally, a shared NFS
mount, or a raw landing zone on a data platform. It has hundreds of folders,
dozens of teams dropping files in, and nobody documented what's in there.

Before you can build even a single pipeline on top of it, you need answers to
basic questions:

- What files exist and where?
- How large are they?
- How many records do they contain?
- Are there any files so large they'd blow up a pandas `read_csv()` call or
  exhaust an executor's memory on Spark?

A **folder audit** is the very first step a data engineer takes when
onboarding to a new data source. This script automates that step.

---

## 2. Why This Matters in Data Engineering

### 2.1 Data Discovery Before Ingestion

In any ingestion workflow — whether you're loading into BigQuery, Snowflake,
a Postgres data warehouse, or even a Delta Lake — you need to know what you're
dealing with *before* you write a single `INSERT` or `COPY` statement.
Running an audit first prevents:

- **OOM (Out of Memory) errors** — a 10 GB CSV passed to `pd.read_csv()`
  without chunking will crash a 16 GB machine.
- **Surprise costs** — cloud data warehouses charge per byte scanned. Landing
  unexpectedly large files drives up compute bills.
- **Schema mismatches** — knowing a file has 5 000 lines vs 5 000 000 lines
  changes how you validate and sample it.

### 2.2 Observability and Data Ops

Mature data teams run audit scripts on a schedule (daily cron jobs, Airflow
tasks, etc.) and diff the reports over time to detect:

- **Sudden growth spikes** — a file doubling overnight can mean a bug in an
  upstream system sending duplicate records.
- **Missing files** — if `q3.csv` didn't appear by Monday morning, something
  upstream broke.
- **Stale data** — files that haven't changed in 30 days may indicate a
  broken producer.

### 2.3 Why Bash, Not Python?

Python is the dominant language in data engineering — but bash fills a
specific, irreplaceable role:

| Situation | Why bash wins |
|---|---|
| No Python available (minimal Docker image, jump host, prod server) | Bash is always there |
| You need to run a quick check without spinning up a venv | Zero setup cost |
| The script is part of a CI/CD pipeline or cron job | Shell scripts compose naturally with other shell tools |
| You're auditing a filesystem — not transforming data | OS-level tools (`find`, `stat`, `wc`) are faster than Python's `os.walk` for pure I/O tasks |

Bash scripts are also easier to hand off to infrastructure teams who may not
know Python but can read and modify a shell script.

---

## 3. Project Structure

```
day-07/
├── audit.sh              # The audit script (entry point)
├── audit_report.txt      # Auto-generated report (do not edit manually)
├── README.md             # This file
└── data/                 # Sample data lake (for testing)
    ├── logs/
    │   └── events.csv    # Small event log (51 lines)
    ├── raw/
    │   └── dump.csv      # Larger raw dump (5 001 lines)
    └── sales/
        └── 2024/
            ├── q1.csv    # Q1 sales data (201 lines)
            └── q2.csv    # Q2 sales data (151 lines)
```

The `data/` tree deliberately mirrors how a real landing zone is structured —
data partitioned by domain (`logs/`, `sales/`) and then by time (`2024/`).
This is the kind of structure you find in S3, GCS, and Azure Data Lake Storage.

---

## 4. How the Script Works

At a high level the script does five things in sequence:

```
1. Validate  →  Is the target directory reachable?
2. Find      →  Locate every .csv file recursively
3. Measure   →  Get size (bytes) and line count for each file
4. Flag      →  Mark any file exceeding the size threshold
5. Report    →  Write structured output to stdout AND a file
```

The entire measurement + reporting block is wrapped in a group command
`{ ... }` and piped through `tee`, which is what lets it write to
`audit_report.txt` and the terminal simultaneously — no duplication of code.

---

## 5. Line-by-Line Breakdown

### 5.1 Safety header

```bash
set -euo pipefail
```

| Flag | What it does | Why it matters |
|---|---|---|
| `-e` | Exit immediately if any command returns a non-zero exit code | Without this, the script silently continues after a failed `stat` or `find` and produces a corrupt report |
| `-u` | Treat unset variables as errors | Prevents `$DATDIR` (typo) from silently expanding to an empty string and running `find /` |
| `-o pipefail` | A pipeline fails if *any* command in it fails, not just the last | Without this, `find /bad/path \| sort` would return exit code 0 because `sort` succeeded |

This trio is the minimum safety net for any bash script that touches
production data.

---

### 5.2 Configuration block

```bash
DATA_DIR="${1:-./data}"
REPORT="audit_report.txt"
LARGE_THRESHOLD_MB=100
```

All tuneable values live at the top, named as variables — not scattered
as magic numbers through the code. This is the same principle as environment
variables in a 12-factor app: **separate config from logic**.

`${1:-./data}` is bash parameter expansion. It reads: *"use the first
positional argument; if it's absent or empty, fall back to `./data`."*
This makes the script useful both interactively and when called from another
script or Airflow `BashOperator`.

---

### 5.3 The `bytes_to_human` helper

```bash
bytes_to_human() {
  local bytes="$1"
  if   (( bytes >= 1073741824 )); then printf "%.2f GB" "$(echo "scale=2; $bytes/1073741824" | bc)"
  elif (( bytes >= 1048576    )); then printf "%.2f MB" "$(echo "scale=2; $bytes/1048576"    | bc)"
  elif (( bytes >= 1024       )); then printf "%.2f KB" "$(echo "scale=2; $bytes/1024"       | bc)"
  else                                 printf "%d  B"   "$bytes"
  fi
}
```

Bash only does integer arithmetic natively. For human-readable sizes you need
decimal points — so the division is delegated to `bc` (basic calculator),
which understands `scale=2` (two decimal places). The result is passed back
to `printf` for formatted output.

`local bytes` scopes the variable to the function — it won't clash with any
variable of the same name in the outer script.

---

### 5.4 Safe file iteration

```bash
while IFS= read -r -d '' csv_file; do
  ...
done < <(find "$DATA_DIR" -type f -name "*.csv" -print0 | sort -z)
```

This is the correct, production-safe pattern for iterating files in bash.
Here's why each piece is necessary:

| Part | Purpose |
|---|---|
| `find -type f` | Matches only regular files, not directories named `*.csv` |
| `find -name "*.csv"` | Glob filter — only CSV files |
| `-print0` | Separates filenames with a null byte `\0` instead of a newline |
| `sort -z` | Sorts the null-delimited list (so the report is always alphabetical) |
| `read -d ''` | Reads up to the null delimiter (pairs with `-print0`) |
| `IFS=` | Prevents `read` from stripping leading/trailing whitespace from filenames |
| `-r` | Prevents `read` from interpreting backslashes as escape sequences |

**Why does any of this matter?**  
The naive version — `for f in $(find ...)` — breaks the moment a filename
contains a space, newline, or tab. In a real data lake, filenames like
`sales report Q1 2024.csv` or `raw data (draft).csv` are common. The
null-byte pattern handles all of them correctly.

---

### 5.5 Measuring each file

```bash
file_bytes=$(stat -c '%s' "$csv_file")    # exact byte count
line_count=$(wc -l < "$csv_file")         # line count, no filename in output
```

**`stat -c '%s'`** reads the inode metadata directly — no need to open the
file. It's fast and exact.

**`wc -l < file`** vs `wc -l file`:

```bash
wc -l filename      # outputs:  5001 filename
wc -l < filename    # outputs:  5001
```

Redirecting via `<` sends the file as stdin. `wc` never sees a filename, so
it doesn't print one. This makes parsing or further processing of the output
trivial.

---

### 5.6 The large-file flag

```bash
file_mb=$(( file_bytes / 1048576 ))
if (( file_mb >= LARGE_THRESHOLD_MB )); then
  flag=" [LARGE]"
fi
```

Integer division: `1048576` = 1024² = 1 MB in bytes. This intentionally
truncates (floors) the result, which means a 99.9 MB file is *not* flagged.
That's the correct behaviour — the threshold is "at or over 100 MB complete".

In a real pipeline, files flagged `[LARGE]` would trigger a different
ingestion path — e.g., chunked reading, distributed processing, or an alert
to the on-call engineer.

---

### 5.7 `tee` — writing to file and stdout at once

```bash
{ ... all printf statements ... } | tee "$REPORT"
```

`tee` reads from stdin and writes to both stdout *and* the named file at the
same time. The group command `{ }` collects all output from the report-
building block into a single stream that gets handed to `tee`.

Without `tee` you'd have to choose: either see output on screen *or* write it
to a file. With `tee` you get both — essential for scripts that run in CI/CD
(where you want terminal output for logs) and also need a persistent artifact.

---

## 6. Design Decisions & The Whys

### Why not `du -sh`?

`du` (disk usage) reports the *allocated* disk space, which is a
multiple of the filesystem block size. A 1-byte file might show as `4.0K`
because the filesystem allocated a full 4 KB block for it. `stat -c '%s'`
gives the actual file *content* size — which is what matters for data
engineering decisions like "will this fit in memory?".

### Why not `ls -lh | grep .csv`?

Two reasons:
1. `ls` doesn't recurse into subdirectories safely.
2. Parsing `ls` output is explicitly discouraged in bash best practices
   because the format varies across OS versions and locales. `stat`, `find`,
   and `wc` produce machine-stable, locale-independent output.

### Why `realpath` in the report header?

```bash
printf "Directory : %s\n" "$(realpath "$DATA_DIR")"
```

If you pass `./data` as the argument, the report says
`/home/emangdev/30-days-of-learning/day-07/data` — the full absolute path.
This means when you open the report a week later (or share it with a
colleague) there's no ambiguity about *which* directory was scanned.

### Why sort the file list?

`find` returns files in filesystem order, which is essentially random and
varies by OS and inode allocation. A sorted list makes the report
reproducible — two runs on the same data produce the same report, making
diffing easy:

```bash
diff audit_report_monday.txt audit_report_tuesday.txt
```

---

## 7. Running the Script

### Prerequisites

```bash
bash --version   # any version >= 4.0
bc --version     # should be pre-installed on all Linux distros
stat --version   # part of GNU coreutils
```

### Make it executable (one-time)

```bash
chmod +x audit.sh
```

### Run against the sample data

```bash
./audit.sh ./data
```

### Run against any directory

```bash
./audit.sh /path/to/your/data/lake
```

### Change the size threshold

Edit line 19 in `audit.sh`:

```bash
LARGE_THRESHOLD_MB=100    # change to 50, 500, 1024, etc.
```

### Schedule it (cron example — daily at 06:00)

```bash
0 6 * * * /path/to/audit.sh /data >> /var/log/audit.log 2>&1
```

---

## 8. Sample Output

```
DATA LAKE FOLDER AUDIT REPORT
Generated : 2026-04-07 22:39:34
Directory : /home/emangdev/30-days-of-learning/day-07/data
Threshold : Files > 100MB are flagged as [LARGE]
----------------------------------------------------------------

File      : ./data/logs/events.csv
Size      : 1.78 KB (1823 bytes)
Lines     : 51

File      : ./data/raw/dump.csv
Size      : 235.58 KB (241240 bytes)
Lines     : 5001

File      : ./data/sales/2024/q1.csv
Size      : 7.37 KB (7549 bytes)
Lines     : 201

File      : ./data/sales/2024/q2.csv
Size      : 5.54 KB (5673 bytes)
Lines     : 151
----------------------------------------------------------------

SUMMARY
----------------------------------------------------------------
Total CSV files  : 4
Total size       : 250.27 KB
Total lines      : 5404
Large files (>100MB): 0
----------------------------------------------------------------
```

Full report is saved to [`audit_report.txt`](./audit_report.txt).

---

## 9. Real-World Extensions

This script is a foundation. Here's how a senior data engineer would evolve it:

### 9.1 Add schema sniffing

```bash
# Print the header row of each CSV
head -1 "$csv_file"
```

Knowing column names before ingestion lets you validate schema consistency
across files — critical when you're loading multiple CSVs into the same table.

### 9.2 Detect encoding issues

```bash
file "$csv_file"        # detects charset (UTF-8, ISO-8859-1, etc.)
```

Files with unexpected encodings (Latin-1 instead of UTF-8) will break most
database loaders silently or with cryptic errors.

### 9.3 Track changes over time

Run the script on a schedule and store each report with a timestamp:

```bash
./audit.sh /data > "reports/audit_$(date +%Y%m%d).txt"
```

Then diff consecutive reports:

```bash
diff reports/audit_20240406.txt reports/audit_20240407.txt
```

This is a primitive but effective form of **data observability** — the
practice of monitoring your data's health over time, the same way you'd
monitor CPU or memory.

### 9.4 JSON output for downstream tooling

Replace `printf` blocks with JSON-formatted output so the report can be
consumed by a dashboard, alerting system, or data catalog:

```bash
printf '{"file": "%s", "size_bytes": %d, "lines": %d}\n' \
  "$csv_file" "$file_bytes" "$line_count"
```

### 9.5 Integrate with an Airflow DAG

```python
audit_task = BashOperator(
    task_id="audit_data_lake",
    bash_command="/opt/scripts/audit.sh /data/landing",
    dag=dag,
)
```

The script's `set -e` guarantees Airflow sees a non-zero exit code if
anything goes wrong — which marks the task as failed and triggers alerts.

---

## 10. Key Takeaways

| Concept | Lesson |
|---|---|
| `set -euo pipefail` | Every production bash script starts here — fail fast, fail loud |
| `find -print0` + `read -d ''` | The only correct way to iterate filenames in bash |
| `stat -c '%s'` over `du -sh` | Use actual file size, not allocated disk blocks |
| `wc -l < file` over `wc -l file` | Redirect to suppress the filename from output |
| `tee` | Write to a file and stdout simultaneously — crucial for pipelines with logging |
| Variables at the top | Separate config from logic — the same principle as `.env` files |
| `realpath` | Always log absolute paths in reports for unambiguous traceability |
| Sorting file output | Reproducible output makes diffing and debugging trivial |
| The audit-before-ingestion habit | Never build a pipeline on data you haven't measured first |

---

## 11. Resources

- [`man find`](https://linux.die.net/man/1/find) — recursive file search, especially `-print0`
- [`man stat`](https://linux.die.net/man/2/stat) — inode metadata, `%s` for byte size
- [`man wc`](https://linux.die.net/man/1/wc) — word, line, and byte counts
- [`man tee`](https://linux.die.net/man/1/tee) — read from stdin, write to stdout and files
- [`man bc`](https://linux.die.net/man/1/bc) — arbitrary precision arithmetic in bash
- [BashFAQ/001 — Reading lines](https://mywiki.wooledge.org/BashFAQ/001) — the definitive guide to safe file iteration
- [Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/) — why `set -euo pipefail` matters
- [The Art of the Command Line](https://github.com/jlevy/the-art-of-command-line) — essential reading for data engineers on Linux
