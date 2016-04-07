#!/bin/sh -e
FILES="$(git diff "$(git merge-base origin/HEAD HEAD).." --name-only)"
if [ -n "$FILES" ]; then
  echo "$FILES" | sort -u
fi
