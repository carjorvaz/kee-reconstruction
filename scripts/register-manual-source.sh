#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/register-manual-source.sh SOURCE_URL DOWNLOADED_FILE [LABEL]

Copies a browser-saved source into the private gitignored source mirror and
writes a small sidecar with URL, byte count, MIME type, and SHA-256 digest.
USAGE
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  usage
  exit 2
fi

source_url="$1"
input_file="$2"
label="${3:-}"

if [ ! -f "$input_file" ]; then
  printf 'Downloaded file not found: %s\n' "$input_file" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mirror_root="${KEE_SOURCE_MIRROR:-$repo_root/.research-mirror/sources}"
manual_dir="$mirror_root/manual"

mkdir -p "$manual_dir"

if command -v shasum >/dev/null 2>&1; then
  sha256_cmd=(shasum -a 256)
elif command -v sha256sum >/dev/null 2>&1; then
  sha256_cmd=(sha256sum)
else
  printf 'No SHA-256 command found; need shasum or sha256sum.\n' >&2
  exit 1
fi

sha256() {
  "${sha256_cmd[@]}" "$1" | awk '{print $1}'
}

clean_slug() {
  printf '%s' "$1" |
    sed -E 's#^https?://##; s#[^A-Za-z0-9._-]+#-#g; s#^-+##; s#-+$##' |
    cut -c 1-80
}

if [ -z "$label" ]; then
  label="$(basename "$input_file")"
fi

slug="$(clean_slug "$label")"
if [ -z "$slug" ]; then
  slug="$(clean_slug "$source_url")"
fi

base="$(basename "$input_file")"
ext="${base##*.}"
if [ "$ext" = "$base" ]; then
  ext="bin"
fi

stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
dest="$manual_dir/$stamp-$slug.$ext"
sidecar="$dest.source.tsv"

if [ -e "$dest" ] || [ -e "$sidecar" ]; then
  printf 'Refusing to overwrite existing manual source: %s\n' "$dest" >&2
  exit 1
fi

cp -p "$input_file" "$dest"

bytes="$(wc -c < "$dest" | tr -d ' ')"
digest="$(sha256 "$dest")"
mime_type="$(file -b --mime-type "$dest" 2>/dev/null || printf 'application/octet-stream')"
retrieved_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

{
  printf 'field\tvalue\n'
  printf 'source\t%s\n' "$source_url"
  printf 'local_path\t%s\n' "${dest#$mirror_root/}"
  printf 'bytes\t%s\n' "$bytes"
  printf 'content_type\t%s\n' "$mime_type"
  printf 'sha256\t%s\n' "$digest"
  printf 'retrieved_at\t%s\n' "$retrieved_at"
} > "$sidecar"

printf 'Registered manual source: %s\n' "${dest#$repo_root/}"
printf 'Sidecar: %s\n' "${sidecar#$repo_root/}"
