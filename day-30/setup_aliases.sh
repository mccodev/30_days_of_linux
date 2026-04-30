#!/usr/bin/env bash
set -euo pipefail

# setup_aliases.sh — installs custom aliases and functions
# Usage: ./setup_aliases.sh [--help]

ALIAS_FILE="$HOME/.aliases_30day"
BASHRC="$HOME/.bashrc"

show_help() {
    cat <<EOF
Usage: setup_aliases.sh [OPTIONS]

Installs a set of custom aliases and bash functions into ~/.aliases_30day
and ensures it is sourced from ~/.bashrc.

Options:
  -h, --help    Show this help message and exit
  --remove      Remove the alias file and its source line from ~/.bashrc
EOF
}

remove_aliases() {
    if [[ -f "$ALIAS_FILE" ]]; then
        rm "$ALIAS_FILE"
        echo "Removed: $ALIAS_FILE"
    fi

    if grep -q "# 30-day aliases" "$BASHRC" 2>/dev/null; then
        sed -i '/# 30-day aliases/d' "$BASHRC"
        echo "Removed source line from $BASHRC"
    fi

    echo "Aliases removed. Run 'source $BASHRC' to apply."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "${1:-}" == "--remove" ]]; then
    remove_aliases
    exit 0
fi

cat > "$ALIAS_FILE" <<'EOF'
# 30-day Linux learning aliases

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah --group-directories-first'
alias la='ls -A'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Utilities
alias h='history | tail -n 20'
alias ports='ss -tulanp 2>/dev/null || ss -tulan'
alias myip='curl -s https://ipinfo.io/ip || curl -s https://api.ipify.org'
alias disk='df -h -x tmpfs -x devtmpfs'
alias mem='free -h'

# Quick edits
alias bashrc='$EDITOR ~/.bashrc'
alias reload='source ~/.bashrc'

# Sysadmin helpers
alias topcpu='ps aux --sort=-%cpu | head -n 10'
alias topmem='ps aux --sort=-%mem | head -n 10'
alias logs='journalctl -xe'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# 30-day toolkit helpers
alias syshealth='$HOME/bin/30-day-toolkit/syshealth.sh'
alias backup='$HOME/bin/30-day-toolkit/backup.sh'
EOF

# Ensure source line exists in .bashrc
SOURCE_LINE="[ -f ~/.aliases_30day ] && source ~/.aliases_30day # 30-day aliases"
if ! grep -qF "$SOURCE_LINE" "$BASHRC" 2>/dev/null; then
    echo "" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
fi

echo "Aliases installed to: $ALIAS_FILE"
echo "Source line added to: $BASHRC"
echo "Run 'source $BASHRC' to activate now."
