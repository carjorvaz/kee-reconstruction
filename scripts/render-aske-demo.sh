#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$repo_root/demo/aske-common-windows.html}"

mkdir -p "$(dirname "$out")"
sbcl --script "$repo_root/examples/aske-common-windows.lisp" > "$out"

printf 'Wrote %s\n' "$out"
printf 'Open file://%s in a browser.\n' "$out"
