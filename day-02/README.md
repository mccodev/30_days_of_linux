# Day 02 - Linux commands 

## Objective

What was the goal for today?
- learn file operations in linux
- Linux commands: cp, mv, rm, mkdir, touch, ln -s
- Managing raw/staging/processed folders

---

## What I Learned

- How to copy files and folders using cp command.
- How to move files and folders using mv command.
- How to remove files and folders using rm command.
- How to create folders using mkdir command.
- How to create files using touch command.
- How to create symbolic links using ln -s command.
- -p flag in mkdir command to make directory creation indempotent and creates parent directories if not exist
- Using mkdir -p ensures that your script won't break regardless of whether it's the first time you're processing data for that year or the hundredth
---

## What I Built / Practiced
- Local Data Pipeline Orchestrator
- Simulated a data pipeline with raw, staging, processed, and backups folders
- Used cp, mv, rm, mkdir, touch, ln -s commands to manage files and folders
- ls -R command to view the directory tree
- chmod +x command to make a script executable


---

## Challenges Faced

- Understanding the difference between `cp` (copies the original, leaves it in place) and `mv` (moves/renames, removes from source) — easy to mix up when building pipelines.
- Remembering that `rm` is permanent with no recycle bin safety net, which required careful scripting to avoid deleting the wrong files.

---

## Key Takeaways

- Always use `mkdir -p` in scripts — it makes directory creation idempotent and prevents errors on re-runs.
- A simple bash script (`script.sh`) can simulate a real data pipeline: ingest → stage → process → backup, using only core Linux commands.
- Symbolic links (`ln -s`) are a clean way to give consumers a stable path to the latest data without moving files around.

---

## Resources

- [GNU Coreutils Manual](https://www.gnu.org/software/coreutils/manual/coreutils.html) — reference for `cp`, `mv`, `rm`, `mkdir`, `touch`, `ln`
- `man <command>` — e.g. `man mkdir`, `man ln` for flags and usage details

---

## Output

```
data/
├── raw/          # landing zone for incoming files
├── staging/      # cleaned/moved CSV files ready for processing
├── processed/    # final output folder
└── backups/      # archive copies
latest_results -> data/processed  # symlink for quick access

Pipeline complete!
```
