#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cd "$repo_root"

"$repo_root/scripts/check-docs.sh"
sbcl --script scripts/test.lisp
sbcl --noinform --disable-debugger \
  --eval '(require :asdf)' \
  --eval "(asdf:load-asd #p\"$repo_root/kee-core.asd\")" \
  --eval '(asdf:load-system :kee-core)' \
  --eval '(sb-ext:exit)'

"$repo_root/scripts/check-reviewer-demos.sh"
"$repo_root/scripts/render-demo-dump.sh" "$tmpdir/delivery.kdump"
cmp -s "$tmpdir/delivery.kdump" "$repo_root/docs/assets/dumps/delivery.kdump"

sbcl --script examples/veg-rule-mini.lisp
sbcl --script examples/kb-dump-mini.lisp
sbcl --script examples/active-image-mini.lisp
sbcl --script examples/auv-panel-workflow.lisp > "$tmpdir/auv-panel-workflow-example.html"
sbcl --script examples/aske-common-windows.lisp > "$tmpdir/aske-common-windows-example.html"
sbcl --script examples/hamburg-puzzle-mini.lisp
