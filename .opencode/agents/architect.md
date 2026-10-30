---
description: Read-only exploration and planning for the project
mode: subagent
permission:
  edit: deny
  bash:
    "*": deny
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "git show*": allow
    "git branch*": allow
---
Explore the codebase read-only. Return affected files, proposed DTOs, interfaces, strategies, an atomic task list with verification steps, and risks. Never edit files.
