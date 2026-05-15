#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

required_artifacts=(
  "$repo_root/docs/assets/screenshots/hamburg-viewer-review.png"
  "$repo_root/docs/assets/screenshots/hamburg-viewer-kee-picture.png"
  "$repo_root/docs/assets/screenshots/hamburg-viewer-panels.png"
  "$repo_root/docs/assets/screenshots/auv-panel-workflow.png"
  "$repo_root/docs/assets/dumps/delivery.kdump"
)

for path in "${required_artifacts[@]}"; do
  test -s "$path"
done

"$repo_root/scripts/render-reviewer-demos.sh" "$tmpdir"

perl -0ne 'print $1 if m{<script>\n(.*)</script>\n</body>}s' \
  "$tmpdir/hamburg-viewer.html" > "$tmpdir/hamburg-viewer.js"
node --check "$tmpdir/hamburg-viewer.js"

perl -0ne 'print $1 if m{<script>\n(.*)</script>\n</body>}s' \
  "$tmpdir/auv-panel-workflow.html" > "$tmpdir/auv-panel-workflow.js"
node --check "$tmpdir/auv-panel-workflow.js"

perl -0ne 'print $1 if m{<script>\n(.*)</script>\n</body>}s' \
  "$tmpdir/aske-common-windows.html" > "$tmpdir/aske-common-windows.js"
node --check "$tmpdir/aske-common-windows.js"

rg -F --quiet "Mission Selection Panel" "$tmpdir/auv-panel-workflow.html"
rg -F --quiet "Parameter Entry Panel" "$tmpdir/auv-panel-workflow.html"
rg -F --quiet "Mission Monitoring Panel" "$tmpdir/auv-panel-workflow.html"
rg -F --quiet "\"kind\":\"PANEL-CLOSE\"" "$tmpdir/auv-panel-workflow.html"
rg -F --quiet "Aske Interface Panel" "$tmpdir/aske-common-windows.html"
rg -F --quiet "Rulemaker Interface Panel" "$tmpdir/aske-common-windows.html"
rg -F --quiet "Rule Editing Window" "$tmpdir/aske-common-windows.html"
rg -F --quiet "\"kind\":\"PICTURE-MOUSE\"" "$tmpdir/aske-common-windows.html"

"$repo_root/scripts/check-viewer.sh"
"$repo_root/scripts/check-auv-panel-demo.sh"
"$repo_root/scripts/check-aske-demo.sh"
