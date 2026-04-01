# Day 01 - Linux Foundations for Data Engineering

## Objective

- Understand the basics of Linux, how it works under the hood, and the role it plays in the life of a data engineer.
- Understand Linux as a data system environment.
- Master core file and directory management:
    - Navigation
    - Listing and inspecting
    - Manipulation
    - Permissions

---

## What I Learned

- Linux is essential to a data engineer's toolkit; it underpins building, automation, and troubleshooting of data pipelines.
- Learned about the **kernel** and the **shell** and how they work together: the kernel manages hardware resources, while the shell provides the user interface to interact with it.
- Learned core navigation and file management commands:
    - `cd` — change directory
    - `ls`, `ls -la` — list directory contents, including hidden files and permissions
    - `pwd` — print working directory
    - `mkdir` — create directories
    - `touch` — create files
    - `cp`, `mv`, `rm` — copy, move, and remove files
    - `cat`, `less` — inspect file contents
    - `chmod` — change file permissions
    - `echo` — output text (used in shell scripts)
    - `date` — display the current date and time
- Understood Linux file permissions (`rwx`) and how they apply to owner, group, and others.
- Learned about the Linux filesystem hierarchy (e.g., `/bin`, `/etc`, `/home`, `/var`).

---

## What I Built / Practiced

- Scaffolded a mini **data platform project directory** (`data_platform/`) with a realistic folder structure:
    - `bin/` — executables and pipeline entry points
    - `data/` — raw data files (ignored by Git)
    - `logs/` — pipeline log output
    - `scripts/` — reusable shell scripts
- Wrote a basic **pipeline shell script** (`bin/pipeline.sh`) that initialises and timestamps a pipeline run.
- Practised navigating and building the directory tree entirely from the terminal.

---

## Challenges Faced

- Getting comfortable with the difference between **absolute** and **relative** paths — easy to get lost when `cd`-ing into nested directories.
- Understanding **permission bits** (`chmod 755` vs `chmod 644`) and when each is appropriate.
- Accidentally committed a large CSV file (333 MB) to Git history, causing `git push` to fail. Fixed by resetting to the last clean commit and adding a `.gitignore`.

---

## Key Takeaways

- The terminal is not just a tool — for a data engineer, it *is* the environment. Proficiency here unlocks everything else (Docker, Airflow, dbt, cloud CLIs).
- Shell scripts are a first-class automation tool. Even a simple `pipeline.sh` with `echo` and `date` shows the pattern for real pipeline orchestration.
- Good directory structure matters from day one — separating `bin/`, `data/`, `logs/`, and `scripts/` mirrors how production data platforms are organised.
- Always add a `.gitignore` before committing large or sensitive files.

---

## Resources

- Book: *Learn Enough Command Line to Be Dangerous* — Erik Tuttle
- [Linux Filesystem Hierarchy Standard (FHS)](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)
- `man` pages — e.g., `man ls`, `man chmod`

---

## Output

**Project directory structure built:**
```
data_platform/
├── bin/
│   └── pipeline.sh
├── data/        ← ignored by .gitignore (large files live here)
├── logs/
└── scripts/
```

**Pipeline script (`bin/pipeline.sh`):**
```bash
#!/bin/bash

echo "Starting pipeline..."
echo "Pipeline CLI initialised at $(date)"
```
