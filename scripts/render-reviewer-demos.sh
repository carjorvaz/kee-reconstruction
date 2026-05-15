#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="${1:-$repo_root/demo}"

mkdir -p "$out_dir"
"$repo_root/scripts/render-demo.sh" "$out_dir/hamburg-viewer.html"
"$repo_root/scripts/render-auv-panel-demo.sh" "$out_dir/auv-panel-workflow.html"
"$repo_root/scripts/render-aske-demo.sh" "$out_dir/aske-common-windows.html"

printf 'Reviewer demos written under %s\n' "$out_dir"
