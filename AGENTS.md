# ai-starter-pack

<ONE_LINE_DESCRIPTION>

## Language

Project documentation and code identifiers are written in English. Commit messages follow Conventional Commits.

## Stack and commands

- Stack: <STACK>
- Test: <TEST_COMMAND>
- Lint: <LINT_COMMAND>
- Typecheck: <TYPECHECK_COMMAND>
- Dev: <DEV_COMMAND>

Replace every placeholder above before the first implementation task.

## Specs

Requirements live in docs/specs/, one file per feature or endpoint, using docs/specs/_template.md. A spec must be approved before a plan turns it into atomic tasks. See docs/ai/rules/specs.md.

## Mandatory workflow

1. Explore the affected code read-only.
2. Write a plan using docs/ai/plans/_template.md and save it under docs/ai/plans/.
3. Stop and wait for the reply "APPROVED".
4. Execute exactly one atomic task at a time, in plan order.
5. Verify the task with its verification step.
6. Commit with the planned Conventional Commit message and push.
7. Report what changed and what comes next.

## Atomic task

One concern, at most about five files, one Conventional Commit. Never mix refactoring with features. If a change grows beyond one concern, split the plan before executing.

## Non-negotiable code rules

- No comments of any kind.
- Never invent APIs or dependencies; check the codebase and the plan first.
- Stay inside the approved plan; anything new goes back through planning.

See docs/ai/rules/ for the full rules.

## When uncertain

Ask one focused question. If you must proceed, state the assumption explicitly in the plan.
