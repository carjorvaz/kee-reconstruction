#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "README.md"
  "AGENTS.md"
  "docs/artifacts.md"
  "docs/provenance-policy.md"
  "docs/reviewer-packet.md"
  "docs/gui-reconstruction.md"
  "docs/gui-fidelity-matrix.md"
  "docs/demo.md"
  "docs/assets/screenshots/hamburg-viewer-review.png"
)

artifact_terms=(
  "IntelliCorp KEE source or binary distributions"
  "KEE 3.0/3.1/4.0 manuals as scans"
  "K3.1-UG1"
  "K3.1-IRM-1"
  "K3.1-CRM-2"
  "3.1-TAA-2"
  "K3.1-RS3-2"
  "K3.1-KW-3"
  "K3.1-KP-2"
  "CWM-2"
  "K4.0-RN-UNIX-1"
  "K4.0-UK-UNIX-1"
  "3X3IMPLEM1.U"
  "docs/assets/screenshots/hamburg-viewer-review.png"
)

review_terms=(
  "clean-room"
  "not original IntelliCorp KEE source"
  "Texas Instruments Lisp"
  "Common Windows"
  "KEEpictures"
  "ActiveImages"
  "KEEworlds"
)

for path in "${required_files[@]}"; do
  test -e "$repo_root/$path"
done

for term in "${artifact_terms[@]}"; do
  rg -F --quiet "$term" "$repo_root/docs/artifacts.md"
done

for term in "${review_terms[@]}"; do
  rg -F --quiet "$term" "$repo_root/docs/reviewer-packet.md" "$repo_root/docs/provenance-policy.md" "$repo_root/docs/expert-review.md"
done

printf 'Documentation harness checks passed.\n'
