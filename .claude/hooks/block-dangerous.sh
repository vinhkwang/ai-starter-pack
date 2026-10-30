#!/bin/bash
input=$(cat)
dangerous='git push[^|]*(--force|-f([^[:alnum:]]|$))|--no-verify|git reset[^|]*--hard|rm -rf[[:space:]]+(\/|\/\*|~|\$HOME)([[:space:]"\\]|$)'
if printf '%s' "$input" | grep -Eq "$dangerous"; then
  printf 'Blocked: destructive or disallowed git command\n' >&2
  exit 2
fi
if printf '%s' "$input" | grep -Eq 'git push' && printf '%s' "$input" | grep -Eq '([[:space:]]|:)(main|master)([[:space:]"\\]|$)'; then
  printf 'Blocked: direct push to the default branch\n' >&2
  exit 2
fi
exit 0
