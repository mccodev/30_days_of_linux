# Day 09 - AWK Advanced: Conditionals & Aggregations

## Objective

Learn to use AWK conditionals (`if`, pattern filters) and aggregations (associative arrays, `END` block) to compute per-group statistics — specifically average order value per region — from a CSV dataset.

---

## What I Learned

- AWK `if / else` syntax and how pattern conditions act as row-level filters
- Using `NR > 1` to skip CSV headers inside AWK rules
- Associative arrays in AWK (e.g. `total[$2]`) to group and accumulate values by key
- The `END {}` block — runs once after all rows are processed, ideal for printing aggregated results
- Iterating over array keys with `for (key in array)`
- Using `printf` for formatted, aligned output with `%-10s` and `%15.2f` specifiers
- Combining multiple conditions with `&&` to filter before aggregating

---

## What I Built / Practiced

- Created `orders.csv` — a 15-row sales dataset with columns: `order_id`, `region`, `product`, `quantity`, `unit_price`
- Wrote AWK one-liners to:
  - Filter rows by region using a string conditional (`$2 == "East"`)
  - Compute `order_value = quantity × unit_price` inline inside AWK
  - Aggregate total revenue and order count per region using arrays
  - Calculate and print average order value per region in a formatted table
  - Apply a pre-aggregation filter (`$4 > 2`) to conditionally include rows

---

## Challenges Faced

- Remembering that AWK arrays are created automatically — no declaration needed
- `printf` format strings require care: `%s` for strings, `%.2f` for floats with 2 decimal places, `-` prefix for left-alignment
- The `END` block has no access to the current row (`$0` is empty), only to variables and arrays set during processing

---

## Key Takeaways

- AWK's associative arrays make per-group aggregation very natural — the group key is just the array index
- `NR > 1` is the idiomatic way to skip a header row in AWK
- Pattern conditions (before `{}`) are cleaner than `if` blocks when the filter applies to the whole rule
- `printf` beats `print` whenever alignment or decimal precision matters
- AWK processes rows in order, but `for (key in array)` in `END` does **not** guarantee sorted output — pipe to `sort` if order matters

---

## Resources

- `man awk` — built-in manual
- [GNU AWK User's Guide](https://www.gnu.org/software/gawk/manual/gawk.html)
- [AWK one-liners explained](https://catonmat.net/awk-one-liners-explained-part-one)

---

## Output

### Dataset: `orders.csv`

```
order_id,region,product,quantity,unit_price
1001,East,Widget,3,15.00
...
1015,North,Sprocket,5,40.00
```

### Average Order Value Per Region (formatted output)

```bash
awk -F',' '
  NR > 1 {
    order_value = $4 * $5
    total[$2]  += order_value
    count[$2]  += 1
  }
  END {
    printf "%-10s %15s %10s\n", "Region", "Total Revenue", "Avg Order"
    printf "%-10s %15s %10s\n", "------", "-------------", "---------"
    for (region in total) {
      avg = total[region] / count[region]
      printf "%-10s %15.2f %10.2f\n", region, total[region], avg
    }
  }
' orders.csv
```

Expected output:
```
Region        Total Revenue  Avg Order
------        -------------  ---------
East               390.00     97.50
West               500.00    125.00
North              410.00    136.67
South              490.00    163.33
```
