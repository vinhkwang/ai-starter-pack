# Agentic Loop Protocol

The single source of truth for the orchestrator-worker loop. When a task runs, this document overrides the manual workflow in AGENTS.md.

## Roles

The orchestrator is the main thread (Claude Code) or a primary agent (opencode). Workers are leaf subagents and cannot spawn other subagents. In Claude Code, a leaf worker omits `Agent` from its `tools`. In opencode, a leaf worker sets `permission.task` to deny.

| Role | Responsibility | Inputs | Outputs | Allowed verdicts |
| --- | --- | --- | --- | --- |
| orchestrator | Owns state.json, delegates to workers, applies transitions, runs post-condition check, commits and pushes | state.json, handoff files | state.json updates, commits, final message | none (applies worker verdicts) |
| ba | Writes the spec and draft subtask list from the request, resolves spec disputes | 00-request.md | 01-spec.md, 02-subtasks.md | SPEC_READY, SPEC_REVISED, NEEDS_CLARIFICATION, BLOCKED |
| architect | Designs the technical solution, finalizes atomic subtasks, revises the design | 01-spec.md, 02-subtasks.md | 01b-design.md, 02-subtasks.md | DESIGN_READY, DESIGN_REVISED, SPEC_ISSUE, NEEDS_CLARIFICATION, BLOCKED |
| dev | Implements one subtask | 02-subtasks.md, 01-spec.md, 01b-design.md | 03-dev-log.md, source edits | IMPLEMENTED, DESIGN_ISSUE, BLOCKED |
| reviewer | Reviews one subtask read-only | 03-dev-log.md, source diff | 04-review.md | APPROVED, CHANGES_REQUESTED |
| tester | AI-Native TDD tester: writes unit tests and test cases before source (red), then tests after review including Playwright e2e (green) | 01-spec.md, 01b-design.md, source | 05-test-cases.md, 05-test-report.md, test files | TESTS_READY, PASS, BUG_CODE, BUG_SPEC, BLOCKED |

### Permission matrix

| Capability | orchestrator | ba | architect | dev | reviewer | tester |
| --- | --- | --- | --- | --- | --- | --- |
| Read source and task files | yes | yes | yes | yes | yes | yes |
| Edit docs/ai/tasks/ | yes | yes (01-spec, 02-subtasks) | yes (01b-design, 02-subtasks) | yes (03-dev-log) | yes (04-review) | yes (05-test-cases, 05-test-report) |
| Edit source files | no | no | no | yes | no | no |
| Edit test directories | no | no | no | yes | no | yes |
| Run read-only git (status/diff/log/show) | yes | yes | yes | yes | yes | yes |
| Run tests and verification commands | yes | no | no | yes | no | yes |
| git add / commit / push | yes | no | no | no | no | no |
| Spawn subagents | yes | no | no | no | no | no |

## Task folder layout

`docs/ai/tasks/<task-id>/` with the task id in the form `<yyyy-mm-dd>-<slug>`.

| File | Owner | Purpose |
| --- | --- | --- |
| 00-request.md | orchestrator | The user's original request |
| state.json | orchestrator | Single source of truth; any new session resumes from it alone |
| 01-spec.md | ba | Spec with acceptance criteria AC-1..AC-n |
| 01b-design.md | architect | Technical design and design log |
| 02-subtasks.md | ba draft, architect final | Ordered subtask list |
| 03-dev-log.md | dev | Per-subtask implementation log |
| 04-review.md | reviewer | Per-round review findings |
| 05-test-cases.md | tester | Test cases designed before execution |
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

Allowed status values: `SPECIFYING`, `DESIGNING`, `AWAITING_APPROVAL`, `WRITING_TESTS`, `IMPLEMENTING`, `IN_REVIEW`, `IN_TEST`, `FINAL_TEST`, `DONE`, `BLOCKED`.

Subtask status values: `pending`, `in_progress`, `done`, `blocked`.

## Verdicts per role

| Role | Verdict | Meaning |
| --- | --- | --- |
| ba | SPEC_READY | Spec and draft subtasks are complete and consistent |
| ba | SPEC_REVISED | Spec changed, acceptance criteria unchanged |
| ba | NEEDS_CLARIFICATION | Spec is missing or ambiguous input |
| ba | BLOCKED | Cannot proceed |
| architect | DESIGN_READY | Design and subtask list are complete and consistent |
| architect | DESIGN_REVISED | Design changed, acceptance criteria unchanged |
| architect | SPEC_ISSUE | The spec cannot be implemented as written |
| architect | NEEDS_CLARIFICATION | Design needs input only the user can give |
| architect | BLOCKED | Cannot proceed |
| dev | IMPLEMENTED | Subtask implemented, dev log written |
| dev | DESIGN_ISSUE | The design cannot be implemented as written |
| dev | BLOCKED | Cannot implement |
| reviewer | APPROVED | No blocking findings |
| reviewer | CHANGES_REQUESTED | At least one blocking finding |
| tester | TESTS_READY | Unit tests and test cases for the subtask's criteria are written and cover each requirement |
| tester | PASS | All criteria for the subtask verified |
| tester | BUG_CODE | Spec is clear and the implementation deviates |
| tester | BUG_SPEC | Expected behavior is missing, ambiguous, or contradictory |
| tester | BLOCKED | Environment prevents verification |

## Transition table

| From | Event / verdict | To | Side effect |
| --- | --- | --- | --- |
| SPECIFYING | ba SPEC_READY | DESIGNING | architect runs in design mode |
| SPECIFYING | ba SPEC_REVISED | DESIGNING | architect runs in revise mode with reason spec-change |
| SPECIFYING | ba NEEDS_CLARIFICATION | SPECIFYING | set last_verdict, print questions, stop |
| SPECIFYING | ba BLOCKED | BLOCKED | set blocked_reason |
| DESIGNING | architect DESIGN_READY | AWAITING_APPROVAL or WRITING_TESTS | sync subtasks; gate, or WRITING_TESTS when autonomy is full |
| DESIGNING | architect DESIGN_REVISED | AWAITING_APPROVAL or WRITING_TESTS | sync subtasks; gate when approved decisions or criteria changed |
| DESIGNING | architect SPEC_ISSUE | SPECIFYING | bug_spec_count incremented; ba runs in revise mode |
| DESIGNING | architect NEEDS_CLARIFICATION | DESIGNING | set last_verdict, print questions, stop |
| DESIGNING | architect BLOCKED | BLOCKED | set blocked_reason |
| AWAITING_APPROVAL | human approve | WRITING_TESTS | first pending subtask becomes current; tester writes its tests |
| WRITING_TESTS | tester TESTS_READY | IMPLEMENTING | dev implements the current subtask against the tests |
| WRITING_TESTS | tester BUG_SPEC | SPECIFYING | bug_spec_count incremented; ba runs in revise mode |
| WRITING_TESTS | tester BLOCKED | BLOCKED | set blocked_reason |
| IMPLEMENTING | dev IMPLEMENTED | IN_REVIEW | reviewer runs |
| IMPLEMENTING | dev DESIGN_ISSUE | DESIGNING | bug_spec_count incremented; architect runs in revise mode with reason design-issue |
| IMPLEMENTING | dev BLOCKED | BLOCKED | set blocked_reason |
| IN_REVIEW | reviewer APPROVED | IN_TEST | tester runs |
| IN_REVIEW | reviewer CHANGES_REQUESTED | IMPLEMENTING | review_rounds incremented |
| IN_TEST | tester PASS | WRITING_TESTS or FINAL_TEST | commit and push the subtask first; next subtask starts with tests |
| IN_TEST | tester BUG_CODE | IMPLEMENTING | test_rounds incremented |
| IN_TEST | tester BUG_SPEC | SPECIFYING | bug_spec_count incremented |
| IN_TEST | tester BLOCKED | BLOCKED | set blocked_reason |
| FINAL_TEST | tester PASS | DONE | final commit and push |
| FINAL_TEST | tester BUG_CODE | WRITING_TESTS | create a `final-fix` subtask; tester writes its regression test first |
| FINAL_TEST | tester BUG_SPEC | SPECIFYING | bug_spec_count incremented |
| any | any worker BLOCKED | BLOCKED | set blocked_reason |

On IN_TEST PASS: commit and push the current subtask with its `commit_message`, mark the subtask done, then set WRITING_TESTS for the next pending subtask (its tests are written first) or FINAL_TEST when none remain.

On FINAL_TEST PASS: commit and push the remaining task and test artifacts, then move to DONE.

## Test-first ordering

Every subtask enters `WRITING_TESTS` before `IMPLEMENTING`. The tester writes the failing unit tests for the subtask's criteria first (red); the dev implements the minimum source to pass them (green); the reviewer reviews; the tester runs the full suite in `IN_TEST`. Rework that does not change behavior (`IN_REVIEW` CHANGES_REQUESTED, `IN_TEST` BUG_CODE) returns straight to `IMPLEMENTING` because the tests already exist.

## Orchestrator procedure

1. Read state.json.
2. Stop if status is DONE, BLOCKED, or AWAITING_APPROVAL (a gate).
3. Increment `counters.total_iterations`; stop and set BLOCKED if it exceeds `max_total_iterations`.
4. Append one line to history.log.
5. Delegate to the worker for the current status with file paths and ids only, never pasted content.
6. Run the post-condition check after ba, architect, reviewer, and tester return.
7. Apply the transition from the worker's verdict.
8. Persist state.json before the next delegation.

The post-condition check: `git status` must show changes only under `docs/ai/tasks/` after ba, architect, and reviewer return, and only under `docs/ai/tasks/` plus test directories after tester returns. Otherwise revert the unexpected files and set status BLOCKED with a blocked_reason.

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
