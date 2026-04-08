# Day 08 - AWK Basics: Fields, Patterns & Print

## Objective

Learn how AWK processes structured text files line by line, understand its field-splitting model, use patterns to filter records, and apply `END` blocks to aggregate data — specifically summing a revenue column in a CSV.

---

## What I Learned

- AWK processes input **one record (line) at a time**, splitting each line into fields automatically
- Fields are accessed as `$1`, `$2`, `$3` ... `$NF` (last field); `$0` is the whole line
- The field separator is set with `-F` (e.g. `-F','` for CSV files)
- An AWK program is made of `PATTERN { ACTION }` rules — the pattern is optional
- `BEGIN` runs once before any input is read; `END` runs once after all input is processed
- `NR` is the built-in variable for the current line number — useful for skipping headers (`NR > 1`)
- Variables like `sum` don't need to be declared; AWK initialises them to `0` automatically
- Pattern matching can use conditions (`$2 == "shoes"`) or regex (`/shoes/`)

---

## What I Built / Practiced

- Created a `sales.csv` with columns `date`, `product`, and `revenue`
- Used AWK to print specific columns from a CSV (`$1` and `$3`)
- Summed the revenue column across all rows while skipping the header with `NR > 1`
- Filtered rows by product category using a field condition pattern before aggregating
- Used `BEGIN` to print a header and `END` to print a formatted total

---

## Challenges Faced

- Initially forgot `-F','` and AWK treated the whole comma-separated line as one field (`$1`)
- Tried to skip the header with `NR != 1` — works, but `NR > 1` is the more idiomatic form
- Confused `NR` (line number across all files) with `NF` (number of fields in current line) at first

---

## Key Takeaways

- AWK is ideal for **column-based text processing** — especially CSVs and log files
- The `PATTERN { ACTION }` structure makes filtering + aggregating very expressive in one line
- `END` blocks are the AWK way to compute and print totals after scanning all rows
- AWK accumulator variables (`sum += $3`) work without initialisation — clean one-liners
- Combining `-F`, `NR`, field conditions, and `END` covers most data-summing tasks in pipelines

---

## Resources

- `man awk` — built-in manual page
- [GNU AWK User's Guide](https://www.gnu.org/software/gawk/manual/gawk.html)
- *The AWK Programming Language* — Aho, Weinberger, Kernighan (the original authors)

---

## Output

**Sample `sales.csv`:**
```
date,product,revenue
2024-01-01,shoes,1200
2024-01-02,bags,850
2024-01-03,shoes,2300
2024-01-04,hats,400
2024-01-05,bags,1100
```

**Print only date and revenue columns:**
```bash
awk -F',' 'NR > 1 { print $1, $3 }' sales.csv
```

**Sum total revenue (skip header):**
```bash
awk -F',' 'NR > 1 { sum += $3 } END { print "Total Revenue:", sum }' sales.csv
```

**Sum revenue for shoes only:**
```bash
awk -F',' '$2 == "shoes" { sum += $3 } END { print "Shoes Revenue:", sum }' sales.csv
```

**Formatted report with BEGIN and END:**
```bash
awk -F',' 'BEGIN { print "--- Revenue Report ---" } NR > 1 { sum += $3 } END { print "Total:", sum }' sales.csv
```
