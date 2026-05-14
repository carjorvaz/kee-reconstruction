#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

if ! command -v playwright >/dev/null 2>&1; then
  printf 'playwright is required. Try: nix develop --command scripts/check-auv-panel-demo.sh\n' >&2
  exit 1
fi

html="$tmpdir/auv-panel-workflow.html"
"$repo_root/scripts/render-auv-panel-demo.sh" "$html"
unset FORCE_COLOR
unset NO_COLOR
KEE_AUV_PANEL_HTML="$html" \
  playwright test "$repo_root/test/auv-panel-workflow.spec.js" \
    --reporter=dot \
    --output "$tmpdir/playwright-output"
