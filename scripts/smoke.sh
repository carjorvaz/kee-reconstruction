#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cd "$repo_root"

"$repo_root/scripts/check-docs.sh"
sbcl --script test/run-tests.lisp
sbcl --noinform --disable-debugger \
  --eval '(require :asdf)' \
  --eval "(asdf:load-asd #p\"$repo_root/kee-core.asd\")" \
  --eval '(asdf:load-system :kee-core)' \
  --eval '(sb-ext:exit)'

"$repo_root/scripts/render-demo.sh" "$tmpdir/kee-viewer.html"
perl -0ne 'print $1 if m{<script>\n(.*)</script>\n</body>}s' \
  "$tmpdir/kee-viewer.html" > "$tmpdir/kee-viewer.js"
node --check "$tmpdir/kee-viewer.js"
"$repo_root/scripts/check-viewer.sh"
"$repo_root/scripts/render-demo-dump.sh" "$tmpdir/delivery.kdump"
cmp -s "$tmpdir/delivery.kdump" "$repo_root/docs/assets/dumps/delivery.kdump"

sbcl --script examples/veg-rule-mini.lisp
sbcl --script examples/kb-dump-mini.lisp
sbcl --script examples/active-image-mini.lisp
sbcl --script examples/hamburg-puzzle-mini.lisp
