#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$repo_root/demo/auv-panel-workflow.html}"

mkdir -p "$(dirname "$out")"
sbcl --script "$repo_root/examples/auv-panel-workflow.lisp" > "$out"

printf 'Wrote %s\n' "$out"
printf 'Open file://%s in a browser.\n' "$out"
