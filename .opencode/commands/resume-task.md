---
description: Approve or resume an agentic loop task
agent: orchestrator
---
Task id: $1
Approve flag: $2

Read docs/ai/tasks/$1/state.json. Then:

- If status is AWAITING_APPROVAL and the approve flag is "approve": set status to IMPLEMENTING, set current_subtask to the first pending subtask, persist state.json, then act as the orchestrator per docs/ai/workflow/loop-protocol.md until AWAITING_APPROVAL, DONE, or BLOCKED.
- If status is AWAITING_APPROVAL and approve is absent: show the spec and subtask summary and stop.
- Otherwise: act as the orchestrator per docs/ai/workflow/loop-protocol.md until AWAITING_APPROVAL, DONE, or BLOCKED.

Only you commit and push. End with the final message format from loop-protocol.md.
