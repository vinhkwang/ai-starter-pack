# Agentic Loop Protocol

The single source of truth for the orchestrator-worker loop. When a task runs, this document overrides the manual workflow in AGENTS.md.

## Roles

The orchestrator is the main thread (Claude Code) or a primary agent (opencode). Workers are leaf subagents and cannot spawn other subagents. In Claude Code, a leaf worker omits `Agent` from its `tools`. In opencode, a leaf worker sets `permission.task` to deny.

| Role | Responsibility | Inputs | Outputs | Allowed verdicts |
| --- | --- | --- | --- | --- |
| orchestrator | Owns state.json, delegates to workers, applies transitions, runs post-condition check, commits and pushes | state.json, handoff files | state.json updates, commits, final message | none (applies worker verdicts) |
| ba | Writes the spec and subtask list from the request | 00-request.md | 01-spec.md, 02-subtasks.md | SPEC_READY, SPEC_REVISED, NEEDS_CLARIFICATION, BLOCKED |
| dev | Implements one subtask | 02-subtasks.md, 01-spec.md | 03-dev-log.md, source edits | IMPLEMENTED, BLOCKED |
| reviewer | Reviews one subtask read-only | 03-dev-log.md, source diff | 04-review.md | APPROVED, CHANGES_REQUESTED |
| tester | Tests one subtask read-only | 01-spec.md, 04-review.md, source | 05-test-report.md, test files | PASS, BUG_CODE, BUG_SPEC |

### Permission matrix

| Capability | orchestrator | ba | dev | reviewer | tester |
| --- | --- | --- | --- | --- | --- |
| Read source and task files | yes | yes | yes | yes | yes |
| Edit docs/ai/tasks/ | yes | yes | no | no | no |
| Edit source files | no | no | yes | no | no |
| Edit test directories | no | no | yes | no | yes |
| Run read-only git (status/diff/log/show) | yes | yes | yes | yes | yes |
| Run tests and verification commands | yes | no | yes | no | yes |
| git add / commit / push | yes | no | no | no | no |
| Spawn subagents | yes | no | no | no | no |

## Task folder layout

`docs/ai/tasks/<task-id>/` with the task id in the form `<yyyy-mm-dd>-<slug>`.

| File | Owner | Purpose |
| --- | --- | --- |
| 00-request.md | orchestrator | The user's original request |
| state.json | orchestrator | Single source of truth; any new session resumes from it alone |
| 01-spec.md | ba | Spec with acceptance criteria AC-1..AC-n |
| 02-subtasks.md | ba | Ordered subtask list |
| 03-dev-log.md | dev | Per-subtask implementation log |
| 04-review.md | reviewer | Per-round review findings |
| 05-test-report.md | tester | Per-round test report |
| history.log | orchestrator | One appended line per loop iteration |

## State schema

state.json holds the following fields.

| Field | Type | Meaning |
| --- | --- | --- |
| status | enum | One of the allowed status values |
| autonomy | enum | `gate_after_spec` or `full` |
| current_subtask | string or null | Id of the subtask being worked on |
| subtasks | array | One object per subtask: `id`, `title`, `status`, `review_rounds`, `test_rounds`, `commit_message` |
| counters | object | `total_iterations`, `bug_spec_count` |
| limits | object | `max_review_rounds`, `max_test_rounds`, `max_total_iterations`, `max_bug_spec` |
| last_verdict | string or null | Last worker verdict applied |
| blocked_reason | string or null | Set when status is BLOCKED |

Allowed status values: `SPECIFYING`, `AWAITING_APPROVAL`, `IMPLEMENTING`, `IN_REVIEW`, `IN_TEST`, `FINAL_TEST`, `DONE`, `BLOCKED`.

Subtask status values: `pending`, `in_progress`, `done`, `blocked`.

## Verdicts per role

| Role | Verdict | Meaning |
| --- | --- | --- |
| ba | SPEC_READY | Spec and subtasks are complete and consistent |
| ba | SPEC_REVISED | Spec changed, acceptance criteria unchanged |
| ba | NEEDS_CLARIFICATION | Spec is missing or ambiguous input |
| ba | BLOCKED | Cannot proceed |
| dev | IMPLEMENTED | Subtask implemented, dev log written |
| dev | BLOCKED | Cannot implement |
| reviewer | APPROVED | No blocking findings |
| reviewer | CHANGES_REQUESTED | At least one blocking finding |
| tester | PASS | All criteria for the subtask verified |
| tester | BUG_CODE | Spec is clear and the implementation deviates |
| tester | BUG_SPEC | Expected behavior is missing, ambiguous, or contradictory |

## Transition table

| From | Event / verdict | To | Side effect |
| --- | --- | --- | --- |
| SPECIFYING | ba SPEC_READY and autonomy is full | IMPLEMENTING | first pending subtask becomes current |
| SPECIFYING | ba SPEC_READY and autonomy is gate_after_spec | AWAITING_APPROVAL | wait for human approve |
| SPECIFYING | ba SPEC_REVISED | SPECIFYING | re-run ba |
| SPECIFYING | ba NEEDS_CLARIFICATION or BLOCKED | BLOCKED | set blocked_reason |
| AWAITING_APPROVAL | human approve | IMPLEMENTING | first pending subtask becomes current |
| IMPLEMENTING | dev IMPLEMENTED | IN_REVIEW | reviewer runs |
| IMPLEMENTING | dev BLOCKED | BLOCKED | set blocked_reason |
| IN_REVIEW | reviewer APPROVED | IN_TEST | tester runs |
| IN_REVIEW | reviewer CHANGES_REQUESTED | IMPLEMENTING | review_rounds incremented |
| IN_TEST | tester PASS | next subtask or FINAL_TEST | commit and push the subtask first |
| IN_TEST | tester BUG_CODE | IMPLEMENTING | test_rounds incremented |
| IN_TEST | tester BUG_SPEC | SPECIFYING | bug_spec_count incremented |
| FINAL_TEST | tester PASS | DONE | final commit and push |
| FINAL_TEST | tester BUG_CODE | IMPLEMENTING | create a `final-fix` subtask |
| any | any worker BLOCKED | BLOCKED | set blocked_reason |

On IN_TEST PASS: commit and push the current subtask with its `commit_message`, mark the subtask done, then move to the next pending subtask or to FINAL_TEST when none remain.

## Orchestrator procedure

1. Read state.json.
2. Stop if status is DONE, BLOCKED, or AWAITING_APPROVAL (a gate).
3. Increment `counters.total_iterations`; stop and set BLOCKED if it exceeds `max_total_iterations`.
4. Append one line to history.log.
5. Delegate to the worker for the current status with file paths and ids only, never pasted content.
6. Run the post-condition check after ba, reviewer, and tester return.
7. Apply the transition from the worker's verdict.
8. Persist state.json before the next delegation.

The post-condition check: `git status` must show changes only under `docs/ai/tasks/` after ba and reviewer return, and only under `docs/ai/tasks/` plus test directories after tester returns. Otherwise revert the unexpected files and set status BLOCKED with a blocked_reason.

## Limits and escalation

| Counter | Limit | On exceed |
| --- | --- | --- |
| review_rounds | max_review_rounds | BLOCKED |
| test_rounds | max_test_rounds | BLOCKED |
| total_iterations | max_total_iterations | BLOCKED |
| bug_spec_count | max_bug_spec | BLOCKED |

Escalation rules:

- Only blocking review findings force rework. `should-fix` and `nit` findings are recorded but never block.
- A repeated identical blocking finding or failing criterion across two consecutive rounds escalates to BLOCKED.
- Any worker may return BLOCKED at any time.

Final message to the human, at most 10 lines, ending with exactly one line `VERDICT: <value>`:

```
Task <id>: <one-line summary>
Subtasks: <n> done / <m> total
Status: <status>
<blocked_reason if BLOCKED>
<remaining findings or notes, up to 5 lines>
VERDICT: <value>
```

## Commit rules

- Only the orchestrator commits and pushes.
- One commit per subtask, after the tester returns PASS, using the subtask's planned Conventional Commit message.
- Push immediately after each commit, never to the default branch and never with `--force`.

## Resume rule

Any new session resumes a task by reading state.json alone. It reconstructs the loop position from `status`, `current_subtask`, and the handoff files, then continues at step 1 of the orchestrator procedure.

## Review severity

- `blocking`: must be fixed before the subtask can proceed; forces rework.
- `should-fix`: should be fixed but does not block; recorded only.
- `nit`: optional style or naming; recorded only.

## Test classification

- BUG_CODE: the spec states the expected behavior clearly and the implementation deviates. The report must cite the failing criterion id.
- BUG_SPEC: the expected behavior is missing, ambiguous, or contradictory. The report must cite the criterion id and describe the ambiguity.
