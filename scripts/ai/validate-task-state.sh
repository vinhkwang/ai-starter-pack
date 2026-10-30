#!/bin/bash
set -euo pipefail

task_id="${1:-}"
if [[ -z "$task_id" ]]; then
  printf 'usage: validate-task-state.sh <task-id>\n' >&2
  exit 1
fi

state_file="docs/ai/tasks/${task_id}/state.json"
if [[ ! -f "$state_file" ]]; then
  printf 'missing state file: %s\n' "$state_file" >&2
  exit 1
fi

if ! jq -e . "$state_file" >/dev/null 2>&1; then
  printf 'invalid JSON: %s\n' "$state_file" >&2
  exit 1
fi

allowed_status='["SPECIFYING","AWAITING_APPROVAL","IMPLEMENTING","IN_REVIEW","IN_TEST","FINAL_TEST","DONE","BLOCKED"]'

if ! jq -e --argjson allowed "$allowed_status" '
  (.status | IN($allowed[]))
  and (.counters | type == "object")
  and (.limits | type == "object")
  and (.counters.total_iterations | type == "number")
  and (.counters.bug_spec_count | type == "number")
  and (.limits.max_review_rounds | type == "number")
  and (.limits.max_test_rounds | type == "number")
  and (.limits.max_total_iterations | type == "number")
  and (.limits.max_bug_spec | type == "number")
  and (.counters.total_iterations <= .limits.max_total_iterations)
  and (.counters.bug_spec_count <= .limits.max_bug_spec)
  and (.subtasks | type == "array")
  and ([.subtasks[] | (has("id") and has("title") and has("status") and has("review_rounds") and has("test_rounds") and has("commit_message"))] | all)
' "$state_file" >/dev/null 2>&1; then
  printf 'invalid state: %s\n' "$state_file" >&2
  exit 1
fi

exit 0
