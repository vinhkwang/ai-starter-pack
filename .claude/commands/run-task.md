---
description: Create a task folder and run the agentic loop as orchestrator
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---
Create the task folder docs/ai/tasks/<yyyy-mm-dd>-<slug>/ with a slug derived from the request. Write the request into 00-request.md. Copy docs/ai/tasks/_template/state.json to state.json and set task_id to the folder name, leaving status as SPECIFYING.

Request: $ARGUMENTS

Then act as the orchestrator per docs/ai/workflow/loop-protocol.md. Delegate to the ba worker, then proceed through the loop until the state reaches AWAITING_APPROVAL, DONE, or BLOCKED. Only you commit and push. End with the final message format from loop-protocol.md.
