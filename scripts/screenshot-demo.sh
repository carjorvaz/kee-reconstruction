#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
html="${KEE_DEMO_HTML:-$repo_root/demo/hamburg-viewer.html}"
out="${1:-$repo_root/docs/assets/screenshots/hamburg-viewer-review.png}"
tour="${KEE_DEMO_TOUR:-}"
renderer="${KEE_DEMO_RENDERER:-$repo_root/scripts/render-demo.sh}"
results_dir="$(mktemp -d)"

if ! command -v playwright >/dev/null 2>&1; then
  printf 'playwright is required. Try: nix develop --command scripts/screenshot-demo.sh\n' >&2
  exit 1
fi

"$renderer" "$html"
mkdir -p "$(dirname "$out")"
env -u NO_COLOR \
  KEE_DEMO_HTML="$html" \
  KEE_SCREENSHOT_OUT="$out" \
  KEE_DEMO_TOUR="$tour" \
  playwright test "$repo_root/test/demo-screenshot.spec.js" \
    --reporter=line \
    --workers=1 \
    --output "$results_dir"
printf 'Wrote %s\n' "$out"
