#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
html="${KEE_DEMO_HTML:-$repo_root/demo/hamburg-viewer.html}"
out="${1:-$repo_root/docs/assets/screenshots/hamburg-viewer-review.png}"

if ! command -v playwright >/dev/null 2>&1; then
  printf 'playwright is required. Try: nix develop --command scripts/screenshot-demo.sh\n' >&2
  exit 1
fi

"$repo_root/scripts/render-demo.sh" "$html"
mkdir -p "$(dirname "$out")"
playwright screenshot --viewport-size=1440,1000 "file://$html" "$out"
printf 'Wrote %s\n' "$out"
