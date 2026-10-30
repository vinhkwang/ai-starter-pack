# Task folders

Each agentic task lives in its own folder: `docs/ai/tasks/<yyyy-mm-dd>-<slug>/`.

## Start a task

Run `/run-task <request>` to create the folder, write `00-request.md`, initialize `state.json` from `_template/state.json`, and drive the loop as the orchestrator until `AWAITING_APPROVAL`, `DONE`, or `BLOCKED`.

## Approve a task

Run `/resume-task <task-id> approve` after reviewing `01-spec.md` and `02-subtasks.md`. The loop then implements the subtasks in order.

## Resume a task

Run `/resume-task <task-id>` (without `approve`) to show the spec and subtask summary and stop, or to continue the loop from the current state. Any new session resumes from `state.json` alone.

## Run headlessly

`scripts/ai/run-loop.sh <task-id> [max-runs] [claude|opencode]` repeatedly resumes the task through the configured tool until `DONE`, `AWAITING_APPROVAL`, or `BLOCKED`.

## Validate state

`scripts/ai/validate-task-state.sh <task-id>` checks that `state.json` exists, parses, has an allowed status, has counters and limits within bounds, and that every subtask has the required fields. Requires `jq`.

## Files

See `docs/ai/workflow/loop-protocol.md` for roles, the state schema, and the transition table, and `docs/ai/workflow/handoff-formats.md` for the format of each file in a task folder.
