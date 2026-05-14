#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

if ! command -v playwright >/dev/null 2>&1; then
  printf 'playwright is required. Try: nix develop --command scripts/check-viewer.sh\n' >&2
  exit 1
fi

html="$tmpdir/hamburg-viewer.html"
"$repo_root/scripts/render-demo.sh" "$html"
unset FORCE_COLOR
unset NO_COLOR
KEE_VIEWER_HTML="$html" \
  playwright test "$repo_root/test/viewer-tour.spec.js" \
    --reporter=dot \
    --output "$tmpdir/playwright-output"
