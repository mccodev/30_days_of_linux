# Day 15 - cron & Scheduling — Automating Data Pipelines

## Objective

Learn how to use `cron` and `crontab` to schedule and automate recurring tasks on a Linux system. Apply this to automate the data pipelines built over previous days — such as fetching API data with `curl`, transforming with `jq`, and cleaning with `awk`/`sed` — so they run unattended on a schedule.

---

## What I Learned

- How `cron` works as a time-based job scheduler daemon that runs in the background on Linux systems.
- The structure of a crontab entry: `minute hour day-of-month month day-of-week command`.
- Managing scheduled jobs with `crontab -e` (edit), `crontab -l` (list), and `crontab -r` (remove).
- The importance of using absolute paths in cron jobs, since cron runs with a minimal environment and does not load the user's shell profile.
- Redirecting cron job output to log files (`>> /path/to/log 2>&1`) for debugging and auditing.

---

## What I Built / Practiced

**Exercises:**

1. **List Current Crontab:** View any existing scheduled jobs for the current user.
2. **Schedule a Simple Job:** Create a cron job that appends the current date and time to a log file every minute for testing.
3. **Schedule a Pipeline Script:** Write a small shell script that uses `curl` and `jq` to fetch data from an API and save the output, then schedule it to run every hour using cron.
4. **Logging & Debugging:** Redirect both stdout and stderr from a cron job to a log file and verify the output after the job runs.

(Record the commands you used in the Output section below)

---

## Challenges Faced

- Cron jobs failing silently because commands like `curl` or `jq` were not found — cron does not inherit the user's `$PATH`, so full absolute paths (e.g., `/usr/bin/curl`) must be used.
- Forgetting to make the scheduled script executable with `chmod +x` before adding it to the crontab.
- Debugging timing issues: setting a job to run "every minute" (`* * * * *`) first to verify it works before changing to the actual desired schedule.

---

## Key Takeaways

- `cron` is the standard way to automate recurring tasks on Linux and is essential for any data engineering workflow that needs to run on a schedule.
- Always use absolute paths for both the script and any commands inside it when running under cron.
- Redirect output to a log file so you can audit and debug jobs that run unattended — cron does not display output to a terminal.

---

## Resources

- `man crontab`
- `man 5 crontab` (crontab file format)
- [Crontab Guru — Cron Schedule Expression Editor](https://crontab.guru/)

---


