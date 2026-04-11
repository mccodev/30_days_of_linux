# Day 11 - Sorting, Deduplication, and Joining Flat Files

## Objective

Master the core Linux utilities for sorting (`sort`), removing duplicates (`uniq`), and performing relational joins on flat files (`join`) to manipulate and structure raw data efficiently.

---

## What I Learned

- **`sort`:** How to order lines of text files alphanumerically, numerically (`-n`), and based on specific columns/fields (`-k`). Learned about reverse sorting (`-r`).
- **`uniq`:** How to filter out adjacent repeated lines. Discovered that input must be sorted first for `uniq` to work globally. Explored flags like `-c` (count occurrences), `-d` (print only duplicates), and `-u` (print only unique lines).
- **`join`:** How to combine two files based on a common field (relational join). Learned that both files *must* be sorted on the join field. Explored how to specify different join fields (`-1`, `-2`), custom delimiters (`-t`), and outer joins (`-a`).

---

## What I Built / Practiced

- Created an unordered CSV/text file of mock data and practiced sorting it by different columns.
- Built a pipeline to identify the most frequent occurrences in a dataset using `sort | uniq -c | sort -nr`.
- Created two separate files (e.g., `users.txt` with IDs and names, and `orders.txt` with IDs and amounts), sorted them, and used the `join` command to merge the records based on the common ID field.

---

## Challenges Faced

- **`uniq` not working as expected:** Initially tried to use `uniq` on unsorted data and realized it only removes *adjacent* duplicate lines.
- **`join` failures:** Encountered empty outputs or errors because I forgot to `sort` both input files on the exact join key before passing them to the `join` command.
- **Handling Delimiters:** Ensuring `sort` and `join` used the same delimiter (e.g., `,` for CSVs using `-t ','`) required careful command formatting.

---

## Key Takeaways

- `sort` and `uniq` are an iconic duo in data engineering for quick grouping and frequency counting (`sort | uniq -c`).
- `join` provides powerful, database-like relational joins right in the terminal, but requires strict preparation (input files must be sorted).
- Terminal data processing can often replace simple Python/Pandas scripts for quick exploratory data processing.

---

## Resources

- `man sort`, `man uniq`, `man join`
- [GNU Coreutils - sort invocation](https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html)
- [GNU Coreutils - uniq invocation](https://www.gnu.org/software/coreutils/manual/html_node/uniq-invocation.html)
- [GNU Coreutils - join invocation](https://www.gnu.org/software/coreutils/manual/html_node/join-invocation.html)

---

## Output

```bash
# Example frequency count pipeline
cat raw_logs.txt | cut -d',' -f2 | sort | uniq -c | sort -nr | head -n 5

# Example join
sort -t',' -k1 users.csv > sorted_users.csv
sort -t',' -k1 orders.csv > sorted_orders.csv
join -t',' -1 1 -2 1 sorted_users.csv sorted_orders.csv
```
