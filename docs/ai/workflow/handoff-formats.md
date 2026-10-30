# Handoff Formats

Required fields and templates for every file in a task folder. Workers write files; the orchestrator moves paths and ids between them.

## 00-request.md

```
# Request: <task-id>

## Summary

<one paragraph describing what to build>

## Constraints

- <constraint>

## Out of scope

- <out of scope>
```

## 01-spec.md

```
# Spec: <task-id>

Revision: <n>

## Goal

<what and why>

## Acceptance criteria

- AC-1: <criterion>
- AC-2: <criterion>

## Edge cases

- <edge case>

## Assumptions

- <assumption>

## Revision log

- rev <n>: <what changed and why>
```

Every acceptance criterion has an id of the form `AC-<n>`. A revision that changes an acceptance criterion reopens the human gate when autonomy is `gate_after_spec`.

## 02-subtasks.md

```
# Subtasks: <task-id>

| id | title | covered criteria | expected files | verification | commit message |
| --- | --- | --- | --- | --- | --- |
| 1 | <title> | AC-1 | <files> | <command> | feat: <summary> |
```

Each subtask lists its covered criteria, the expected files it will touch, the verification command, and its planned Conventional Commit message.

## 03-dev-log.md

```
# Dev Log: <task-id>

## Subtask <id>

- <what was implemented>
- <files changed>
- <verification run and result>

Verdict: IMPLEMENTED
```

One section per subtask, appended as each subtask is implemented.

## 04-review.md

```
# Review: <task-id>

## Round <n>

- R<n>-F<m>: <severity> — <file>:<line> — <finding> — <fix suggestion>

Verdict: <APPROVED | CHANGES_REQUESTED>
```

Severity is `blocking`, `should-fix`, or `nit`. Finding ids are `R<round>-F<n>`, for example `R2-F3`.

## 05-test-report.md

```
# Test Report: <task-id>

## Round <n>

### Criterion table

| criterion | result | evidence |
| --- | --- | --- |
| AC-1 | pass/fail | <command output or file reference> |

### Classification

- <BUG_CODE | BUG_SPEC> — <reasoning>

### Reproduction steps

1. <step>

Verdict: <PASS | BUG_CODE | BUG_SPEC>
```

A BUG_CODE or BUG_SPEC verdict must cite the criterion id and include reasoning plus reproduction steps.

## history.log

One line per loop iteration, appended by the orchestrator:

```
<ISO-8601 timestamp> iteration=<n> status=<status> delegate=<role> verdict=<verdict or -> 
```

## Verdict line

Every worker ends its final message with a summary of at most 10 lines and exactly one final line:

```
VERDICT: <value>
```
