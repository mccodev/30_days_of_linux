# Day 03 - Linux Permissions & I/O Redirection

## Objective

- Understand Linux file permissions and how to manage them using `chmod`, `chown`, and `umask`
- Learn how groups work and how to assign users to groups
- Understand how to secure pipeline service accounts
- Master I/O redirection: `>`, `>>`, `<`, `2>`, and `tee`

---

## What I Learned
- chmod/chown/umask mechanics, group management, service account hardening, all 5 redirection operators and tee
### Permissions
- Every file/directory has three permission sets: **owner**, **group**, and **others** — each with read (`r`), write (`w`), and execute (`x`) bits
- `chmod` changes file permissions — can use symbolic (`chmod u+x file`) or octal notation (`chmod 755 file`)
- `chown` changes file ownership — `chown user:group file` sets both owner and group at once
- `umask` defines the **default permission mask** applied when new files/directories are created — a umask of `022` means new files get `644` and directories get `755`
- Groups are managed via `/etc/group`; `groupadd`, `usermod -aG`, and `groups` are the core tools

### Securing Pipeline Service Accounts
- Service accounts (non-human accounts) should be **locked** (`usermod -L`) so no one can log in with them directly
- They should own only the directories/files they need — applying the **principle of least privilege**
- Use a dedicated group per pipeline (e.g., `pipeline_svc`) and assign the service account to that group to scope access tightly
- Avoid giving service accounts `sudo` rights or write access to sensitive system directories

### I/O Redirection
- `>` — redirects stdout to a file, **overwriting** it if it exists
- `>>` — redirects stdout to a file, **appending** to it
- `<` — redirects a file as stdin input to a command
- `2>` — redirects stderr (file descriptor 2) to a file, keeping errors separate from regular output
- `tee` — reads from stdin and writes to both stdout **and** a file simultaneously, useful for logging while still seeing output in the terminal

---

## What I Built / Practiced

- Assigned permissions to a simulated pipeline directory using `chmod` and `chown`
- Created a `pipeline_svc` service account and locked it with `usermod -L`
- Created a `data_team` group and added users to it using `usermod -aG`
- Used `umask 027` in a pipeline script so new files are not world-readable
- Practiced redirecting pipeline logs: stdout to `pipeline.log`, stderr to `pipeline_errors.log`
- Used `tee` to pipe command output to a log file while still monitoring it live in the terminal

---

## Challenges Faced

- Octal permission notation (`chmod 755`) felt confusing at first — breaking it down as three separate binary digits (owner/group/others) made it click
- Understanding `umask` required thinking in reverse — it *masks out* bits from a base, rather than directly setting them
- Mixing up `>` (overwrite) and `>>` (append) early on — could easily wipe a log file by accident

---

## Key Takeaways

- **Least privilege is not optional** — service accounts should own only what they need; nothing more
- `umask 027` is a safer default for pipeline environments than the typical `022` because it blocks world read access on new files
- `2>` and `>` can be combined: `command > out.log 2> err.log` separates clean output from errors — essential for debugging pipelines
- `tee` is your best friend for observability — log *and* monitor at the same time without choosing one or the other
- File permissions are the first line of defense for any data pipeline handling sensitive information

---

## Resources

- `man chmod`, `man chown`, `man umask`, `man usermod` — built-in manual pages
- [Linux File Permissions Explained](https://linuxize.com/post/understanding-linux-file-permissions/) — clear breakdown of symbolic vs octal modes
- [tee command – Linux manual](https://man7.org/linux/man-pages/man1/tee.1.html)
- [Bash I/O Redirection](https://www.gnu.org/software/bash/manual/bash.html#Redirections) — official GNU Bash docs

---

## Output

```bash
# Setting up a secured pipeline directory
$ groupadd data_pipeline
$ useradd -r -s /usr/sbin/nologin pipeline_svc       # create locked service account
$ usermod -aG data_pipeline pipeline_svc
$ mkdir -p /opt/pipeline/{raw,staging,processed,logs}
$ chown -R pipeline_svc:data_pipeline /opt/pipeline
$ chmod -R 750 /opt/pipeline                          # owner=rwx, group=r-x, others=none

# Redirecting pipeline output
$ ./run_pipeline.sh > logs/pipeline.log 2> logs/pipeline_errors.log

# Log AND watch live with tee
$ ./run_pipeline.sh 2>&1 | tee logs/pipeline.log

# Checking default umask
$ umask
0022

# Safer umask for pipeline scripts
$ umask 027
```
