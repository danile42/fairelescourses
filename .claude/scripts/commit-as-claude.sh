#!/bin/bash
# Commit script for Claude - signs commits with Claude as co-author
# Usage: ./.claude/scripts/commit-as-claude.sh "commit message"

if [ -z "$1" ]; then
  echo "Usage: $0 \"commit message\""
  exit 1
fi

commit_message="$1"

# Add co-author trailer
message_with_coauthor=$(printf "%s\n\nCo-authored-by: GitHub Copilot <copilot@github.com>" "$commit_message")

# Commit with the co-author trailer
git commit -m "$message_with_coauthor"

