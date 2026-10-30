# Security

- Never read, print, or commit env files, keys, or tokens.
- Validate external input at the controller boundary via DTOs.
- Parameterized queries only.
- Never log secrets.
- Justify every new dependency in the plan.
- Destructive commands need explicit confirmation.
