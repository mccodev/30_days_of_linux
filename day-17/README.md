# Day 17 - Remote Data Transfer & Sync (`scp`, `rsync`)

## Objective

Learn how to securely move datasets between machines, a critical skill when migrating data from an application server to a data lake or transferring logs. We will explore how to perform one-off secure copies (`scp`) and how to build efficient, incremental directory synchronizations (`rsync`).

---

## What I Learned

- **`scp` (Secure Copy Protocol):** Standard tool for copying files tightly integrated with `ssh`. Great for transferring a single CSV or archive across networks.
- **`rsync` (Remote Sync):** A far more powerful tool that compares source and destination files, only transferring the *deltas* (changes) rather than copying the entire file every time. Crucial for massive data engineering workloads.
- The meaning of `rsync` flags: `-a` (archive mode - preserves permissions, times, and descends recursively), `-v` (verbose), `-z` (compress data during transfer), and `--delete` (removes files in the destination that no longer exist in the source).
- How the presence or absence of a trailing slash (`/`) changes rsyc behavior: `rsync folder/ remote:` syncs the *contents* of the folder, whereas `rsync folder remote:` syncs the directory itself.

---

## What I Built / Practiced

**Exercises:**

1. **Simulated Remote Transfer (`scp`):** Created a mock 'remote' directory on the same machine to practice the syntax of `scp source_file user@host:/path`.
2. **First `rsync` Push:** Sent a directory full of raw API logs using `rsync -avz`.
3. **Incremental Update:** Added one new row to a CSV file and reran the `rsync` command, observing how `rsync` instantly scanned and only uploaded the single change rather than re-uploading everything.
4. **Mirror Deletions (`--delete`):** Deleted a log file locally and used the `--delete` flag in `rsync` to mirror that deletion over to the mock remote backup.


---

## Challenges Faced

- The trailing slash gotcha! I accidentally nested my sync directory inside itself (`/backup/folder/folder`) because I forgot the trailing slash on the source directory.
- Differentiating between `scp -r` (which brutally overrides everything) and `rsync -avz` (which elegantly checks for changes first).
- Remembering to set up ssh keys so my automated cron scripts can run `rsync` without prompting me for a password in the middle of the night.

---

## Key Takeaways

- For one-off, quick transfers: use `scp`.
- For regular backups, large data pipelines, or cron job syncing: **always use `rsync`**.
- `rsync --dry-run` is your best friend when crafting complex sync commands! It shows you exactly what it's going to delete or override without actually doing it.

---

## Resources

- `man scp`
- `man rsync`
- [rsync tutorial](https://linuxize.com/post/how-to-use-rsync-command/)

---


