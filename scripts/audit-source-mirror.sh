#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mirror_root="${KEE_SOURCE_MIRROR:-$repo_root/.research-mirror/sources}"
manifest="$mirror_root/manifest.tsv"
failures="$mirror_root/failures.tsv"
url_list="$mirror_root/source-urls.txt"
corpus_list="$mirror_root/local-corpus-paths.txt"

if [ ! -f "$manifest" ]; then
  printf 'No mirror manifest found at %s\n' "$manifest" >&2
  printf 'Run scripts/mirror-research-sources.sh first.\n' >&2
  exit 1
fi

count_lines() {
  local path="$1"
  if [ -f "$path" ]; then
    wc -l < "$path" | tr -d ' '
  else
    printf '0'
  fi
}

count_manifest_kind() {
  local kind="$1"
  awk -F '\t' -v kind="$kind" 'NR > 1 && $1 == kind { n++ } END { print n + 0 }' "$manifest"
}

sum_manifest_kind() {
  local kind="$1"
  awk -F '\t' -v kind="$kind" 'NR > 1 && $1 == kind { bytes += $3 } END { print bytes + 0 }' "$manifest"
}

human_bytes() {
  local bytes="$1"
  awk -v bytes="$bytes" '
    BEGIN {
      split("B KiB MiB GiB TiB", units, " ");
      value = bytes;
      idx = 1;
      while (value >= 1024 && idx < 5) {
        value = value / 1024;
        idx++;
      }
      if (idx == 1) {
        printf "%d %s", value, units[idx];
      } else {
        printf "%.1f %s", value, units[idx];
      }
    }'
}

mirror_size="$(
  if [ -d "$mirror_root" ]; then
    du -sh "$mirror_root" | awk '{print $1}'
  else
    printf '0'
  fi
)"

url_targets="$(count_lines "$url_list")"
corpus_targets="$(count_lines "$corpus_list")"
url_success="$(count_manifest_kind url)"
corpus_success="$(count_manifest_kind local-corpus)"
failure_count="$(
  if [ -f "$failures" ]; then
    awk 'NR > 1 { n++ } END { print n + 0 }' "$failures"
  else
    printf '0'
  fi
)"
url_bytes="$(sum_manifest_kind url)"
corpus_bytes="$(sum_manifest_kind local-corpus)"

printf '# Source Mirror Audit\n\n'
printf 'Generated from `%s`.\n\n' "${manifest#$repo_root/}"
printf '## Snapshot\n\n'
printf -- '- Mirror root: `%s`\n' "${mirror_root#$repo_root/}"
printf -- '- Mirror size: `%s`\n' "$mirror_size"
printf -- '- Source URL targets: `%s`\n' "$url_targets"
printf -- '- Local corpus targets: `%s`\n' "$corpus_targets"
printf -- '- Public URL successes: `%s` (`%s`)\n' "$url_success" "$(human_bytes "$url_bytes")"
printf -- '- Local corpus successes: `%s` (`%s`)\n' "$corpus_success" "$(human_bytes "$corpus_bytes")"
printf -- '- Failed targets: `%s`\n\n' "$failure_count"

printf '## Public File Types\n\n'
printf '| Content type | Count |\n'
printf '| --- | ---: |\n'
awk -F '\t' '
  NR > 1 && $1 == "url" {
    ct = $4;
    sub(/;.*/, "", ct);
    type[ct]++;
  }
  END {
    for (ct in type) {
      printf "%s\t%d\n", ct, type[ct];
    }
  }' "$manifest" |
  sort |
  awk -F '\t' '{ printf "| `%s` | %d |\n", $1, $2 }'

if [ -f "$failures" ]; then
  printf '\n## Failures\n\n'
  printf '| Kind | Status | Source |\n'
  printf '| --- | --- | --- |\n'
  awk -F '\t' 'NR > 1 { printf "| `%s` | `%s` | %s |\n", $1, $2, $3 }' "$failures"
fi
