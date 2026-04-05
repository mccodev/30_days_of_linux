# Day 05 - Pipes & Core Text Tools: Quick CSV Profiling

## Objective

- Understand how the Unix pipe `|` works at the OS level and why it is the backbone of shell composition
- Master the core text-processing tools: `cat`, `head`, `tail`, `wc`, `sort`, `uniq`
- Apply these tools together to quickly profile a CSV data file without opening it in a GUI or loading it into Python

---

## What I Learned

### The Unix Pipe `|`

- A pipe connects the **stdout** of one process directly to the **stdin** of the next — no intermediate file is written to disk
- Both processes run **concurrently**; the kernel manages a small in-memory buffer between them
- Syntax: `command_a | command_b | command_c` — reads left to right, data flows left to right
- Each command in a pipeline is independent — it only knows about its own stdin/stdout
- Exit codes: the pipeline's exit code is the exit code of the **last** command by default; use `set -o pipefail` to propagate failures from any stage

### `cat` — Concatenate and Print

| Flag | Effect |
|------|--------|
| `cat file` | Print the entire file to stdout |
| `cat -n file` | Print with line numbers |
| `cat file1 file2` | Concatenate two files and print both |
| `cat > file` | Write stdin to a file (Ctrl+D to end) |

- Common use: feed a file into a pipeline — `cat data.csv | head`
- Note: `cat file | wc -l` is equivalent to `wc -l < file` — the latter is slightly more efficient (avoids a process), but the pipe form is more readable in long chains

### `head` — View the Top of a File

| Flag | Effect |
|------|--------|
| `head file` | Print first 10 lines (default) |
| `head -n 5 file` | Print first 5 lines |
| `head -n 1 file` | Print only the header row of a CSV |

- Essential first step when exploring any unknown data file — shows you the schema immediately
- Works on stdin too: `cat big_file.csv | head -n 20`

### `tail` — View the Bottom of a File

| Flag | Effect |
|------|--------|
| `tail file` | Print last 10 lines (default) |
| `tail -n 5 file` | Print last 5 lines |
| `tail -n +2 file` | Print from line 2 onwards — **skips the header row** |
| `tail -f log.txt` | Follow a file as it grows (useful for live logs) |

- `tail -n +2` is the standard idiom for stripping the CSV header before processing with `sort`, `uniq`, etc.

### `wc` — Word / Line / Byte Count

| Flag | Effect |
|------|--------|
| `wc -l file` | Count lines (rows) |
| `wc -w file` | Count words |
| `wc -c file` | Count bytes |
| `wc -m file` | Count characters (respects multibyte/UTF-8) |

- `wc -l data.csv` gives total rows including the header; subtract 1 for the actual record count
- Pipe form: `cat data.csv | wc -l`

### `sort` — Sort Lines

| Flag | Effect |
|------|--------|
| `sort file` | Sort alphabetically (ascending) |
| `sort -r file` | Reverse order (descending) |
| `sort -n file` | Sort numerically (not lexicographically) |
| `sort -t',' -k2 file` | Use `,` as delimiter, sort by column 2 |
| `sort -u file` | Sort and deduplicate in one step |

- `-t` sets the field delimiter; `-k` selects the column — critical for CSV work
- Always use `-n` for numeric columns, otherwise `10` sorts before `9`

### `uniq` — Report or Filter Repeated Lines

| Flag | Effect |
|------|--------|
| `uniq file` | Remove **consecutive** duplicate lines |
| `uniq -c file` | Prefix each line with its repeat count |
| `uniq -d file` | Print only duplicate lines |
| `uniq -u file` | Print only unique lines |

- **Critical rule**: `uniq` only removes *consecutive* duplicates — you must `sort` first
- The standard deduplication pattern: `sort file | uniq`
- The frequency-count pattern: `sort file | uniq -c | sort -rn` — gives you a ranked frequency table

---

## What I Built / Practiced

- Created a sample CSV (`sales.csv`) and ran a full profiling session using only pipes and core tools
- Inspected the schema with `head -n 1` and spot-checked rows with `tail -n 5`
- Counted total records with `wc -l` (then subtracted 1 for the header)
- Extracted a single column using `cut -d',' -f3`, piped to `sort | uniq -c | sort -rn` to get a ranked frequency table of categories
- Found the top 10 values in a numeric column with `sort -t',' -k4 -rn | head -n 10`
- Checked for duplicate rows by comparing `wc -l` output before and after `sort -u`
- Built a one-liner to count how many records belong to each region: `tail -n +2 sales.csv | cut -d',' -f2 | sort | uniq -c | sort -rn`

---

## Challenges Faced

- `uniq` without `sort` silently gives wrong results — it only collapses *adjacent* duplicates, so unsorted input produces a misleading count; always pipe through `sort` first
- `sort -n` vs `sort` on a numeric column — lexicographic sort puts `100` before `20`; forgetting `-n` gives completely wrong rankings
- Column indexing with `cut -f` is 1-based, not 0-based — this trips you up when coming from Python/pandas where columns are 0-indexed
- Long pipelines can be hard to debug; broke them apart step by step and confirmed intermediate output at each stage before adding the next command

---

## Key Takeaways

- **The pipe `|` is the foundation of composability** — small, focused tools combined via pipes can answer complex data questions without writing a single line of Python
- `head -n 1` is always step one with any unknown file — know the schema before you query it
- `tail -n +2` is the canonical way to skip a CSV header row in a shell pipeline
- The frequency-count pattern `sort | uniq -c | sort -rn` is one of the most reusable idioms in data engineering — works for any categorical column
- `wc -l` gives rows; `wc -l` before vs after `sort -u` tells you the duplicate count at a glance
- For numeric sorts, **always** use `sort -n`; for descending, add `-r`; for CSV columns, add `-t',' -kN`

---

## Resources

- `man cat`, `man head`, `man tail`, `man wc`, `man sort`, `man uniq` — always read the manual first
- [GNU Coreutils documentation](https://www.gnu.org/software/coreutils/manual/coreutils.html) — full reference for all tools covered today
- [The Art of the Command Line](https://github.com/jlevy/the-art-of-command-line) — curated guide to shell fluency, strong section on everyday file processing
- [Data Science at the Command Line (book)](https://datascienceatthecommandline.com/) — entire book on doing data work with Unix tools; highly relevant to data engineering

---

## Output

```bash
# --- Inspect the file ---

# View the header row (schema)
$ head -n 1 sales.csv
date,region,category,amount,quantity

# Spot-check the last 5 rows
$ tail -n 5 sales.csv

# Count total rows (including header)
$ wc -l sales.csv
1001 sales.csv   # → 1000 data records

# --- Column profiling ---

# Ranked frequency table for the 'region' column (col 2)
$ tail -n +2 sales.csv | cut -d',' -f2 | sort | uniq -c | sort -rn
    312 East
    289 West
    245 North
    154 South

# Ranked frequency table for the 'category' column (col 3)
$ tail -n +2 sales.csv | cut -d',' -f3 | sort | uniq -c | sort -rn
    420 Electronics
    310 Clothing
    270 Food

# --- Numeric column: top 10 sales by amount (col 4) ---
$ tail -n +2 sales.csv | sort -t',' -k4 -rn | head -n 10

# --- Duplicate detection ---

# Total rows vs deduplicated rows
$ wc -l sales.csv
1001

$ sort -u sales.csv | wc -l
998   # → 3 duplicate rows found (including the header line)

# --- Combine region + category for cross-tab counts ---
$ tail -n +2 sales.csv | cut -d',' -f2,3 | sort | uniq -c | sort -rn
    105 East,Electronics
     98 West,Electronics
     ...
```