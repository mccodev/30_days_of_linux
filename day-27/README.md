# Day 27 - Data Compression, Archival & Storage Optimization

## Objective

- Understand compression algorithms and how they impact storage cost and pipeline performance in data engineering.
- Master the core Linux compression and archival tools: `gzip`, `bzip2`, `xz`, `zip`, and `tar`.
- Learn to read, search, and pipe compressed files *without* decompressing them to disk (`zcat`, `zgrep`, `zless`).
- Apply parallel compression (`pigz`) to speed up large-dataset archiving.
- Practice compressing real CSV/JSON datasets and measure compression ratios.

---

## What I Learned

### Why Compression Matters in Data Engineering

- **Storage cost:** Cloud object storage (S3, GCS, Azure Blob) charges per GB-month. Compressing a 10 GB CSV to 1 GB directly reduces storage cost by ~90%.
- **Transfer time:** Moving data across networks (API ingestion, cross-region sync, `rsync`) is bounded by bandwidth. Compression shrinks the payload.
- **Read performance:** Some formats (Parquet, ORC) are *self-compressing*, but raw CSV/JSON landing zones must be compressed manually.
- **Trade-offs:** `gzip` is fast with good ratios; `bzip2` compresses smaller but slower; `xz` yields the smallest files but is CPU-intensive.

### Core Compression Commands

| Command | Extension | Speed | Ratio | Typical Use |
|---------|-----------|-------|-------|-------------|
| `gzip`  | `.gz`     | Fast  | Good  | General-purpose, streaming |
| `bzip2` | `.bz2`    | Slow  | Better| Archival, not streaming |
| `xz`    | `.xz`     | Slowest| Best | Long-term cold storage |
| `zip`   | `.zip`    | Fast  | Good  | Cross-platform exchange |

- `gzip file.csv` → creates `file.csv.gz` and **removes** the original.
- `gzip -k file.csv` → compresses but **keeps** the original (`-k` = keep).
- `gzip -d file.csv.gz` or `gunzip file.csv.gz` → decompress.
- `bzip2 file.csv` / `bunzip2 file.csv.bz2` — same pattern as gzip.
- `xz file.csv` / `unxz file.csv.xz` — same pattern, strongest compression.
- `zip archive.zip file1.csv file2.json` — bundles multiple files into one `.zip`.
- `unzip archive.zip` — extracts all files from a `.zip` archive.

### Reading Compressed Files Without Decompressing

These tools stream the decompressed data to stdout, leaving the `.gz` file untouched:

| Tool | Purpose |
|------|---------|
| `zcat file.csv.gz` | Print entire decompressed content to stdout |
| `zgrep "ERROR" file.csv.gz` | Search inside compressed files |
| `zless file.csv.gz` | Paged viewing (like `less`) |
| `zdiff file1.csv.gz file2.csv.gz` | Compare two compressed files |
| `bzcat`, `bzgrep`, `bzless` | Same tools for `.bz2` files |
| `xzcat`, `xzgrep`, `xzless` | Same tools for `.xz` files |

This is critical for data pipelines: you can `zcat` a 5 GB `.gz` file and pipe it into `awk`, `sed`, or `jq` without ever writing the uncompressed version to disk.

### Archiving with `tar`

- `tar` bundles multiple files/directories into a single archive (`.tar`).
- It does **not** compress by default — combine with compression flags:
  - `tar -czvf archive.tar.gz data/` — create, gzip-compressed, verbose
  - `tar -cjvf archive.tar.bz2 data/` — create, bzip2-compressed
  - `tar -cJvf archive.tar.xz data/` — create, xz-compressed
- Extraction:
  - `tar -xzvf archive.tar.gz` — extract gzip archive
  - `tar -xjvf archive.tar.bz2` — extract bzip2 archive
  - `tar -xJvf archive.tar.xz` — extract xz archive
- List contents without extracting:
  - `tar -tzvf archive.tar.gz`

### Parallel Compression with `pigz`

- `pigz` (parallel gzip) uses multiple CPU cores. On a 4-core machine it can compress 3-4x faster than `gzip` at the same ratio.
- `pigz -k file.csv` → `file.csv.gz` (keeps original).
- `pigz -d file.csv.gz` → parallel decompression.
- `tar --use-compress-program=pigz -cvf archive.tar.gz data/` — parallel tar creation.
- Ideal for data engineering: large landing-zone datasets compressed on ingestion.

### Compression in Pipelines

- Compress stdout on the fly: `./generate_data.sh | gzip > output.csv.gz`
- Decompress and pipe to a processor: `zcat raw.csv.gz | awk -F',' '{sum+=$3} END {print sum}'`
- Parallel compress a stream: `./generate_data.sh | pigz > output.csv.gz`
- Compress a tar archive in one pass: `tar -czf - data/ | ssh remote "cat > backup.tar.gz"`

---

## What I Built / Practiced

### 1. Compressed a sample dataset and measured ratios

Created a realistic `sales.csv` (100,000 rows, ~5 MB) and compressed it with all three algorithms:

```bash
# Original size
ls -lh sales.csv

# gzip (default level 6)
gzip -k sales.csv
ls -lh sales.csv.gz

# bzip2
bzip2 -k sales.csv
ls -lh sales.csv.bz2

# xz (default level 6)
xz -k sales.csv
ls -lh sales.csv.xz
```

### 2. Built a pipeline that reads compressed CSV without extraction

```bash
# Sum the revenue column (field 4) directly from the gzipped file
zcat sales.csv.gz | awk -F',' 'NR > 1 {sum += $4} END {printf "Total Revenue: %.2f\n", sum}'

# Count records matching a region without writing uncompressed data
zgrep "North" sales.csv.gz | wc -l

# Stream-process a compressed JSONL file with jq
zcat events.jsonl.gz | jq -c 'select(.level == "ERROR")' > errors.jsonl
```

### 3. Created a compressed tarball of a data lake folder

```bash
# Archive the entire raw/ landing zone, compressed with pigz for speed
tar --use-compress-program=pigz -cvf landing_zone_$(date +%Y%m%d).tar.gz raw/

# Verify contents without extracting
tar -tzvf landing_zone_20260427.tar.gz | head -20
```

### 4. Wrote a benchmark script to compare compression speed and ratio

```bash
#!/bin/bash
# compress_benchmark.sh
set -euo pipefail

FILE="${1:-sales.csv}"
echo "Benchmarking: $FILE ($(stat -c '%s' "$FILE" | numfmt --to=iec))"
echo "------------------------------------------------"

for tool in gzip bzip2 xz; do
    printf "%-10s" "$tool"
    /usr/bin/time -f "  time: %e s  size: " sh -c "$tool -k -c '$FILE' > /dev/null" 2>&1
    ls -lh "$FILE.$tool" 2>/dev/null || ls -lh "$FILE.gz" 2>/dev/null || ls -lh "$FILE.bz2" 2>/dev/null || ls -lh "$FILE.xz" 2>/dev/null
done

echo ""
echo "pigz (parallel):"
/usr/bin/time -f "  time: %e s" sh -c "pigz -k -c '$FILE' > /dev/null" 2>&1
```

---

## Challenges Faced

- **Forgetting `-k` (keep):** `gzip file.csv` silently deletes the original. In a pipeline, losing the source file is catastrophic — always use `-k` or compress a copy.
- **xz is *very* slow:** Compressing a 500 MB log file with `xz` took several minutes. For hot/warm data, `gzip` or `pigz` is the pragmatic choice; reserve `xz` for cold archival.
- **Tar extraction path confusion:** `tar -xzf archive.tar.gz` extracts into the *current* directory. Had to verify with `tar -tzf` first to avoid polluting the working directory.
- **zgrep on `.bz2` files:** Tried `zgrep` on a `.bz2` file and got binary noise. Remembered `bzgrep` / `xzgrep` are the matching counterparts for each compression format.
- **Parallel `pigz` not installed by default:** Had to install it (`sudo apt install pigz`) — not part of coreutils on all distros.

---

## Key Takeaways

- **Never decompress to disk just to read.** `zcat`, `zgrep`, and `zless` let you stream-process compressed files directly, saving both disk space and I/O time.
- **Default to `gzip` for active pipelines** — it is fast, universally supported, and has excellent tooling. Upgrade to `pigz` when CPU cores are available.
- **Use `xz` for cold/long-term archival** where CPU time is cheaper than storage cost.
- **Always use `-k` (keep)** when compressing source data in a pipeline, or compress into a new file with `gzip -c file.csv > file.csv.gz`.
- **`tar` + compression is the standard idiom** for bundling and moving data lake partitions (e.g., `tar -czf raw_2024_q1.tar.gz raw/2024/Q1/`).
- **Compress at the end of your pipeline:** Raw landing data should be stored compressed; intermediate staging files can remain uncompressed if they are re-read frequently.
- **Cloud storage + compression:** Many object stores support *server-side* gzip decompression on download. Uploading `.gz` files to S3 and setting `Content-Encoding: gzip` can reduce egress costs significantly.

---

## Resources

- `man gzip`, `man bzip2`, `man xz`, `man tar`, `man pigz` — built-in manual pages
- [GNU Gzip Manual](https://www.gnu.org/software/gzip/manual/gzip.html)
- [pigz GitHub](https://github.com/madler/pigz) — parallel gzip implementation
- [AWS S3 Compression Best Practices](https://docs.aws.amazon.com/redshift/latest/dg/c_loading-data-compression.html) — how compression affects data loading
- [Linux Compression Comparison](https://www.rootusers.com/gzip-vs-bzip2-vs-xz-performance-comparison/) — benchmarks across algorithms

---

## Output

### Compression Ratio Comparison

```
Algorithm  Original    Compressed    Ratio    Time
---------------------------------------------------------
gzip       5.2 MB      1.1 MB        4.7x     0.4 s
bzip2      5.2 MB      0.9 MB        5.8x     1.2 s
xz         5.2 MB      0.7 MB        7.4x     4.8 s
pigz       5.2 MB      1.1 MB        4.7x     0.1 s  (4 cores)
```

### Pipeline One-Liner: Compressed JSONL → Filtered Output

```bash
zcat events_2026.jsonl.gz \
  | jq -c 'select(.timestamp >= "2026-04-01")' \
  | gzip > april_events.jsonl.gz
```

This reads the entire compressed history, filters for April records with `jq`, and writes a new compressed subset — never touching uncompressed files on disk.

### Archive Command for Daily Data Lake Backup

```bash
#!/bin/bash
BACKUP_DIR="/backups/data_lake"
DATA_DIR="/data/lake/raw"
DATE=$(date +%Y%m%d)

tar --use-compress-program=pigz -cvf "$BACKUP_DIR/raw_${DATE}.tar.gz" -C "$DATA_DIR" .
```

---

## Mini Project — Compression Lab

All scripts live in the [`project/`](./project/) directory.

### 1. `generate_data.sh` — Build a Realistic Dataset

```bash
cd day-27/project
./generate_data.sh 500000 sales.csv
```

Generates a CSV with columns: `order_id`, `date`, `region`, `category`, `product`, `quantity`, `unit_price`, `discount_pct`.

### 2. `compress_benchmark.sh` — Race the Algorithms

```bash
./compress_benchmark.sh sales.csv
```

Compresses the file with `gzip`, `bzip2`, `xz`, and `pigz` (if installed), then prints a table comparing **size**, **compression ratio**, **time**, and **throughput**. Clean up artifacts with `rm -f sales.csv.gz sales.csv.bz2 sales.csv.xz`.

### 3. `stream_process.sh` — Read Compressed Data Without Extracting

```bash
# Compress first
gzip -k sales.csv

# Then stream-process directly from the .gz file
./stream_process.sh sales.csv.gz
```

Demonstrates `zcat`, `zgrep`, and AWK pipelines that process the data **without ever writing an uncompressed file to disk**. Also shows extracting a high-value subset and re-compressing it in one pipeline.

### 4. `archive_backup.sh` — Archive a Folder Like a Data Lake Partition

```bash
mkdir -p sample_lake/raw sample_lake/processed
cp sales.csv sample_lake/raw/
./archive_backup.sh sample_lake ./backups
```

Uses `tar` + `pigz` (falls back to `gzip`) to create a dated `.tar.gz` archive, generates a manifest, verifies integrity, and reports compression stats.

### Try These Yourself

1. Run the benchmark on a 1-million-row dataset. Which algorithm wins on your machine?
2. Use `zcat` + `awk` to compute total revenue per category *directly* from `sales.csv.gz`.
3. Archive your `sample_lake/` folder, then list its contents with `tar -tzf` without extracting.
4. Chain compression into a live pipeline: `./generate_data.sh 100000 - | pigz | ssh remote "cat > /backups/stream.csv.gz"`.
