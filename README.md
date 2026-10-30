# ai-starter-pack

AI project harness with a base workflow (AGENTS.md, docs/ai/rules/) plus an agentic loop: an orchestrator coordinating ba, dev, reviewer, and tester workers through file-based handoffs until a task is done or blocked.

## Agentic loop

The loop runs the orchestrator as the main thread (Claude Code) or a primary agent (opencode). Workers are leaf subagents that communicate only through files in a task folder. `state.json` is the single source of truth, so any session can resume a task from it alone. Only the orchestrator commits and pushes.

Key files:

- docs/ai/workflow/loop-protocol.md — roles, permission matrix, state schema, transition table, limits and escalation.
- docs/ai/workflow/handoff-formats.md — templates for every task folder file.
- docs/ai/tasks/ — task folders and the initial state template.
- scripts/ai/validate-task-state.sh — validate a task's state.json.
- scripts/ai/run-loop.sh — headless outer loop.

## Commands

- `/run-task <request>` — create a task folder and drive the loop until AWAITING_APPROVAL, DONE, or BLOCKED.
- `/resume-task <id>` — show the spec and subtask summary and stop.
- `/resume-task <id> approve` — approve the gate and continue the loop.

## Requirements

- `jq` on PATH (used by both scripts).

## Deferred

Agent definition files for orchestrator, ba, dev, reviewer, and tester are created in a later step from the permission matrix in loop-protocol.md.
