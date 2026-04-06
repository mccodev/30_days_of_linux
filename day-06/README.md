# Day 06 - grep, cut, tr: Filtering Logs & Slicing CSV Columns

## Objective

- Understand how `grep` scans files line-by-line and what makes its regex engine useful for log triage
- Master `cut` as the fastest way to extract specific columns from delimited files in a pipeline
- Learn `tr` for character-level translation, case conversion, and delimiter swapping
- Combine all three tools with pipes to build real log-filtering and CSV-slicing workflows

---

## What I Learned

### `grep` — Search for Patterns in Text

| Flag | Effect |
|------|--------|
| `grep "pattern" file` | Print lines matching the pattern |
| `grep -i "pattern" file` | Case-insensitive match |
| `grep -v "pattern" file` | Invert — print lines that do **not** match |
| `grep -n "pattern" file` | Include line numbers in output |
| `grep -c "pattern" file` | Count matching lines (no text, just the number) |
| `grep -r "pattern" dir/` | Recurse into a directory |
| `grep -E "pat1\|pat2" file` | Extended regex — match either pattern |
| `grep -o "pattern" file` | Print only the matching part, not the whole line |
| `grep -A 3 "ERROR" file` | Print 3 lines **after** each match (context) |
| `grep -B 2 "ERROR" file` | Print 2 lines **before** each match |

- `grep` reads stdin when no file is given — ideal last stage of a pipeline
- The `-E` flag enables full ERE (extended regular expressions): `+`, `?`, `|`, `()` work without escaping
- For log triage the critical one-liner pattern is `grep "ERROR\|WARN" app.log | grep -v "healthcheck"` — match the bad stuff, then subtract the noise
- `grep -c` is faster than `grep | wc -l` for counting — grep handles it internally

### `cut` — Extract Fields from Delimited Lines

| Flag | Effect |
|------|--------|
| `cut -d',' -f1` | Use `,` as delimiter, extract field 1 |
| `cut -d',' -f2,4` | Extract fields 2 and 4 |
| `cut -d',' -f2-5` | Extract fields 2 through 5 (range) |
| `cut -d':' -f1` | Use `:` as delimiter (e.g., `/etc/passwd`) |
| `cut -c1-10` | Extract characters 1–10 (positional, no delimiter) |

- Field indices are **1-based** — field 1 is the first column, not field 0
- `cut` does not understand quoted CSV (e.g., a field containing `"hello, world"` will be split on the comma inside the quotes) — use `awk` or Python for quoted CSVs
- The fastest way to grab a single column from a large CSV: `cut -d',' -f3 data.csv`
- To skip the header and extract a column: `tail -n +2 data.csv | cut -d',' -f3`

### `tr` — Translate or Delete Characters

| Command | Effect |
|---------|--------|
| `tr 'a-z' 'A-Z'` | Convert lowercase to uppercase |
| `tr 'A-Z' 'a-z'` | Convert uppercase to lowercase |
| `tr ',' '\t'` | Replace commas with tabs (delimiter swap) |
| `tr -d '\r'` | Delete carriage returns (Windows → Unix line endings) |
| `tr -d '"'` | Strip all double-quote characters |
| `tr -s ' '` | Squeeze repeated spaces into a single space |
| `tr ':' ','` | Swap `:` for `,` — convert TSV-like formats |

- `tr` operates **character by character**, not word by word — it cannot replace multi-character strings (use `sed` for that)
- `tr` only reads from **stdin** — you cannot pass a filename as an argument
- `tr -d '\r'` is one of the most common fixes when a CSV was created on Windows and breaks pipeline tools with `^M` characters at line-ends
- Chaining `tr` with `cut`: `cat data.csv | tr ',' '\t' | cut -f3` — swap delimiter first, then cut by tab

---

## What I Built / Practiced

- Created a sample log file (`app.log`) and a CSV (`employees.csv`) to practice against
- Filtered `app.log` for `ERROR` and `WARN` lines using `grep -E`, then subtracted known-safe patterns with `grep -v`
- Used `grep -n` to find the exact line numbers of errors for quick navigation
- Used `grep -c` to count errors per log level without needing `wc`
- Sliced individual columns out of `employees.csv` with `cut -d',' -f` and combined with `sort | uniq -c | sort -rn` to profile categorical columns
- Used `tr 'a-z' 'A-Z'` to normalise a mixed-case department column before counting unique values
- Fixed a Windows-formatted CSV by stripping `\r` with `tr -d '\r'` before piping into `cut`
- Built a full log-triage one-liner: `grep -E "ERROR|WARN" app.log | grep -v "healthcheck" | cut -d' ' -f1,2,5- | sort | uniq -c | sort -rn`

---

## Challenges Faced

- `cut` does not handle quoted CSV fields — a field like `"New York, NY"` gets split on the inner comma, producing wrong column offsets for all subsequent fields; had to be aware of this limitation before applying `cut` to real-world data
- `tr` does not accept filenames — trying `tr 'a-z' 'A-Z' file.txt` silently ignores the filename and waits on stdin; always pipe into `tr` or use `< file.txt`
- `grep -E` vs `grep -P` — `-E` is extended regex (POSIX, portable), `-P` is Perl-compatible regex (more powerful but not available everywhere); sticking to `-E` keeps scripts portable across systems
- Character ranges in `tr` like `[a-z]` vs `a-z` — `tr '[a-z]' '[A-Z]'` includes the literal `[` and `]` characters in the translation set, which is a common mistake; the correct form is `tr 'a-z' 'A-Z'` without brackets

---

## Key Takeaways

- **`grep` is your first filter** — always narrow down the data at the earliest stage of the pipeline to keep downstream commands fast
- `grep -v` (invert match) is as important as `grep` itself — filtering out noise is often easier than trying to write a pattern that matches only the good lines
- `cut` is the right tool for **structured, delimiter-separated** data with no quoting; know its limits before applying it to CSV files from external sources
- `tr` excels at **character-level normalization** — stripping `\r`, swapping delimiters, and case conversion are all single-command operations
- **Combining the three**: `grep` → `cut` → `tr` is a natural left-to-right pipeline: find the rows you want, extract the columns you need, then clean the values
- Always check for Windows line endings (`\r\n`) when a CSV comes from outside your system — `tr -d '\r'` as the first pipe stage prevents subtle downstream breakage

---

## Resources

- `man grep`, `man cut`, `man tr` — always start with the manual
- [GNU grep manual](https://www.gnu.org/software/grep/manual/grep.html) — comprehensive reference including regex syntax
- [GNU coreutils: cut](https://www.gnu.org/software/coreutils/manual/coreutils.html#cut-invocation) — covers all flags including character-range mode
- [The Art of the Command Line](https://github.com/jlevy/the-art-of-command-line) — strong section on everyday text processing
- [Data Science at the Command Line](https://datascienceatthecommandline.com/) — Chapter 5 covers scrubbing data with `tr`, `cut`, and friends

---

## Output

```bash
# ── Sample files used ──────────────────────────────────────────────
# app.log  (fields: timestamp  level  service  message)
# employees.csv  (columns: id,name,department,salary,location)

# ── grep: filter logs ──────────────────────────────────────────────

# Find all ERROR lines
$ grep "ERROR" app.log
2026-04-06 08:12:03 ERROR auth     Invalid token received
2026-04-06 09:45:17 ERROR db       Connection timeout

# Case-insensitive match (catches "error", "ERROR", "Error")
$ grep -i "error" app.log

# Count how many ERROR lines exist
$ grep -c "ERROR" app.log
2

# Show line numbers for quick navigation
$ grep -n "ERROR" app.log
14:2026-04-06 08:12:03 ERROR auth  Invalid token received
37:2026-04-06 09:45:17 ERROR db    Connection timeout

# Match ERROR or WARN in one pass, then remove healthcheck noise
$ grep -E "ERROR|WARN" app.log | grep -v "healthcheck"

# Print 2 lines of context before each ERROR (useful for root-cause)
$ grep -B 2 "ERROR" app.log

# ── cut: slice CSV columns ─────────────────────────────────────────

# View just the header to know column positions
$ head -n 1 employees.csv
id,name,department,salary,location

# Extract the department column (col 3)
$ tail -n +2 employees.csv | cut -d',' -f3
Engineering
Marketing
Engineering
HR
...

# Ranked frequency table of departments
$ tail -n +2 employees.csv | cut -d',' -f3 | sort | uniq -c | sort -rn
     18 Engineering
     12 Marketing
      9 HR
      6 Finance

# Extract multiple columns (name + location)
$ tail -n +2 employees.csv | cut -d',' -f2,5

# ── tr: character-level cleanup ────────────────────────────────────

# Normalise department column to uppercase before counting
$ tail -n +2 employees.csv | cut -d',' -f3 | tr 'a-z' 'A-Z' | sort | uniq -c | sort -rn
     18 ENGINEERING
     12 MARKETING
      9 HR

# Fix Windows line endings before cutting columns
$ cat windows_export.csv | tr -d '\r' | cut -d',' -f3 | sort | uniq -c

# Swap comma delimiter to tab, then use cut with tab delimiter
$ cat employees.csv | tr ',' '\t' | cut -f3

# Strip all quote characters from a quoted CSV
$ cat quoted.csv | tr -d '"' | cut -d',' -f2

# ── Full log-triage one-liner ──────────────────────────────────────
# Filter errors, drop healthcheck noise, extract timestamp + message, rank by frequency
$ grep -E "ERROR|WARN" app.log \
    | grep -v "healthcheck" \
    | cut -d' ' -f1,2,5- \
    | sort | uniq -c | sort -rn
```
