# Day 10 - sed: Stream Editing for Data Cleaning

## Objective

Learn how to use `sed` (Stream EDitor) to clean messy CSV headers and data
by applying substitutions, deletions, and in-place edits — a core skill for
any data engineering pipeline running on Linux.

---

## What I Learned

### 1. What is `sed`?

`sed` reads input **line by line**, applies editing commands, and writes
to stdout. It does NOT modify the original file unless you use `-i`.

```
sed 'COMMAND' file.csv
```

---

### 2. Substitution — `s/old/new/`

The most-used `sed` command. Syntax:

```
sed 's/pattern/replacement/flags' file
```

| Flag | Meaning                              |
|------|--------------------------------------|
| _(none)_ | Replace **first** match on each line |
| `g`  | Replace **all** matches on the line  |
| `I`  | Case-**insensitive** match           |
| `2`  | Replace only the **2nd** match       |

**Examples to try (do NOT copy-paste — type them yourself):**

```bash
# Remove ALL leading/trailing spaces around the header fields
# Hint: match spaces before a comma or end of line, and after comma or start of line
sed 's/ *, */,/g' dirty_orders.csv

# Lowercase the entire header row (line 1 only)
# Hint: use 1s to target only line 1, and tr inside a pipe
sed -n '1p' dirty_orders.csv | tr 'A-Z' 'a-z'

# Remove spaces and parentheses from the header "Order Value (USD)"
# Hint: use substitution to replace " (USD)" with nothing
sed '1s/ (USD)//' dirty_orders.csv

# Normalise the Status column: make every value lowercase
# Hint: use the -e flag to chain multiple substitutions, or use /I flag
```

---

### 3. Deletion — `d`

Delete lines matching a pattern:

```
sed '/pattern/d' file
```

**Examples to try:**

```bash
# Delete blank/empty lines
sed '/^$/d' dirty_orders.csv

# Delete the header row (line 1)
sed '1d' dirty_orders.csv

# Delete all rows where Status is "failed" or "Failed"
# Hint: use /pattern/Id for case-insensitive delete
```

---

### 4. Address Ranges

You can target `sed` commands to specific lines or ranges:

```
sed '1s/old/new/'       # only line 1
sed '2,5s/old/new/'     # lines 2 to 5
sed '/start/,/end/d'    # from matching line to another
```

---

### 5. In-Place Editing — `-i`

`-i` edits the file directly (no stdout output).  
Always test without `-i` first, then add it when you are confident.

```bash
# Safe: preview first
sed 's/ *, */,/g' dirty_orders.csv

# Destructive: write changes back to file
sed -i 's/ *, */,/g' dirty_orders.csv

# Safe backup: -i.bak creates dirty_orders.csv.bak before editing
sed -i.bak 's/ *, */,/g' dirty_orders.csv
```

> **Rule of thumb:** Always use `-i.bak` in production pipelines!

---

### 6. Chaining Commands with `-e`

```bash
sed -e 's/pattern1/replace1/' -e 's/pattern2/replace2/' file
```

Or use a semicolon inside one expression:

```bash
sed 's/pattern1/replace1/; s/pattern2/replace2/' file
```

---

## What I Built / Practiced

- Cleaned messy CSV headers from `dirty_orders.csv` using `sed`
- Removed extra spaces around delimiters
- Normalised inconsistent casing in the Status column
- Deleted blank and unwanted rows
- Used `-i.bak` to safely edit in-place with a backup

---

## Exercises (Try These Yourself)

Work through these on `dirty_orders.csv`. Do NOT look at answers — 
figure out the `sed` command yourself first.

1. **Strip all leading/trailing whitespace** from every field on every line.
2. **Rename** the header `Order Value (USD)` → `order_value_usd` (no spaces, no caps).
3. **Lowercase** all values in the Status column (column 5).
4. **Delete** all rows where Status is `failed` (case-insensitive).
5. **In-place edit** — apply all the above to produce a clean `clean_orders.csv`.
6. **Bonus:** Use `sed` to add a new column header `currency` after `order_value_usd`.

---

## Challenges Faced

- 

---

## Key Takeaways

- `sed` operates line-by-line — you must think in patterns, not cells
- Always test **without** `-i` first to preview output
- Chain commands with `-e` to apply multiple edits in one pass
- `-i.bak` is your safety net in any production script

---

## Resources

- `man sed`
- https://www.gnu.org/software/sed/manual/sed.html
- https://sed.sourceforge.io/sed1line.txt  ← 1-liners cheat sheet

---

## Output

(Paste your final cleaned header and a few rows of `clean_orders.csv` here)
