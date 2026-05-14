#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$repo_root/docs/assets/dumps/delivery.kdump}"

mkdir -p "$(dirname "$out")"
KEE_KB_DUMP_OUT="$out" sbcl --script "$repo_root/examples/kb-dump-mini.lisp"
