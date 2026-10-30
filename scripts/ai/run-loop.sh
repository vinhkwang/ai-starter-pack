#!/bin/bash
set -euo pipefail

task_id="${1:-}"
max_runs="${2:-20}"
tool="${3:-${RUN_LOOP_TOOL:-claude}}"

if [[ -z "$task_id" ]]; then
  printf 'usage: run-loop.sh <task-id> [max-runs] [claude|opencode]\n' >&2
  exit 1
fi

state_file="docs/ai/tasks/${task_id}/state.json"
if [[ ! -f "$state_file" ]]; then
  printf 'missing state file: %s\n' "$state_file" >&2
  exit 1
fi

run=0
while [[ $run -lt $max_runs ]]; do
  status=$(jq -r '.status' "$state_file")

  case "$status" in
    DONE)
      printf 'task %s is DONE\n' "$task_id"
      exit 0
      ;;
    AWAITING_APPROVAL)
      printf 'task %s is AWAITING_APPROVAL\n' "$task_id"
      exit 0
      ;;
    BLOCKED)
      jq -r '.blocked_reason // "no blocked_reason"' "$state_file" >&2
      exit 2
      ;;
  esac

  case "$tool" in
    claude)
      claude -p --permission-mode acceptEdits "/resume-task ${task_id}"
      ;;
    opencode)
      opencode run --auto --command "resume-task ${task_id}"
      ;;
    *)
      printf 'unknown tool: %s\n' "$tool" >&2
      exit 1
      ;;
  esac

  run=$((run + 1))
done

printf 'task %s did not reach a terminal state after %s runs\n' "$task_id" "$max_runs" >&2
exit 1
