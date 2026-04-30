# Day 30 - Linux Automation Toolkit (Capstone)

## Objective

Build a personal automation toolkit that combines the most useful skills from the past 30 days into reusable scripts, aliases, and workflows.

---

## What I Learned

- How to structure a modular shell script library
- Combining `cron`, `systemd`, and shell scripts for automation
- Creating a portable dotfiles and alias setup
- Building a system health check dashboard in pure bash

---

## What I Built / Practiced

- `syshealth.sh` — a one-shot system health report (CPU, memory, disk, load, top processes)
- `backup.sh` — a configurable rsync backup wrapper with logging
- `setup_aliases.sh` — a script to install my custom aliases and functions
- Practiced packaging everything into a `~/bin` directory and adding it to `$PATH`

---

## Challenges Faced

- Deciding which tools from the past 30 days were most worth keeping
- Making scripts robust across different Linux distributions
- Keeping the toolkit simple enough to maintain long-term

---

## Key Takeaways

- Automation is about consistency, not complexity — start small and iterate
- A well-organized `~/bin` and a few aliases save hours over time
- Documenting scripts with `--help` makes them actually reusable

---

## Resources

- `man bash` — for built-ins and parameter expansion
- [Linuxize - Bash scripting guide](https://linuxize.com/tag/bash/)
- `shellcheck` — for linting scripts

---

## Output

- Toolkit location: `~/bin/30-day-toolkit/`
- Scripts: `syshealth.sh`, `backup.sh`, `setup_aliases.sh`
- Config: `.aliases_30day` sourced from `.bashrc`
