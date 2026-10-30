# Changelog

## v2-agentic (loop infrastructure)

### Added

- docs/ai/workflow/loop-protocol.md: roles, permission matrix, state schema, transition table, limits and escalation, commit and resume rules.
- docs/ai/workflow/handoff-formats.md: templates for every task folder file.
- docs/ai/tasks/README.md and docs/ai/tasks/_template/state.json: task folder scaffold and initial state.
- scripts/ai/validate-task-state.sh and scripts/ai/run-loop.sh: state validation and headless outer loop.
- run-task and resume-task commands for Claude Code and opencode.
- Instruction merges: AGENTS.md "Agentic loop" section, CLAUDE.md import, opencode.json instructions.
- Permission additions for jq, the two scripts, and non-force git push.

### Deferred

- Agent definition files for orchestrator, ba, dev, reviewer, and tester.
- Agent-specific permission blocks and any skills.

### Next step

Create the five agent files from the permission matrix in docs/ai/workflow/loop-protocol.md.
