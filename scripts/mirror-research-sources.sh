#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mirror_root="${KEE_SOURCE_MIRROR:-$repo_root/.research-mirror/sources}"
files_dir="$mirror_root/files"
corpus_dir="$mirror_root/local-corpus"
url_list="$mirror_root/source-urls.txt"
corpus_list="$mirror_root/local-corpus-paths.txt"
manifest_tmp="$mirror_root/manifest.tsv.tmp"
manifest="$mirror_root/manifest.tsv"
failures_tmp="$mirror_root/failures.tsv.tmp"
failures="$mirror_root/failures.tsv"
timeout="${KEE_MIRROR_TIMEOUT:-180}"
refresh="${KEE_MIRROR_REFRESH:-0}"
ua="${KEE_MIRROR_USER_AGENT:-Mozilla/5.0}"

mkdir -p "$files_dir" "$corpus_dir"
rm -f "$files_dir"/*.tmp "$files_dir"/*.headers.tmp

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

url_hash() {
  printf '%s' "$1" | "${sha256_cmd[@]}" | awk '{print substr($1, 1, 16)}'
}

clean_slug() {
  printf '%s' "$1" |
    sed -E 's#^https?://##; s#[^A-Za-z0-9._-]+#-#g; s#^-+##; s#-+$##' |
    cut -c 1-96
}

extension_for() {
  local url="$1"
  local headers="$2"
  local content_type lower_content_type
  content_type="$(
    { grep -i '^content-type:' "$headers" || true; } | tail -n 1 |
      sed -E 's/^[Cc]ontent-[Tt]ype:[[:space:]]*//; s/[[:space:]]*$//'
  )"
  lower_content_type="$(printf '%s' "$content_type" | tr '[:upper:]' '[:lower:]')"
  case "$lower_content_type" in
    application/pdf*) printf 'pdf' ;;
    text/plain*) printf 'txt' ;;
    text/markdown*) printf 'md' ;;
    text/html*|application/xhtml*) printf 'html' ;;
    text/xml*|application/xml*) printf 'xml' ;;
    application/json*) printf 'json' ;;
    image/png*) printf 'png' ;;
    image/jpeg*) printf 'jpg' ;;
    video/mp4*) printf 'mp4' ;;
    video/*) printf 'video' ;;
    *)
      case "${url%%\?*}" in
        *.pdf|*.PDF) printf 'pdf' ;;
        *.txt|*.TXT) printf 'txt' ;;
        *.md|*.MD) printf 'md' ;;
        *.html|*.HTML|*.htm|*.HTM) printf 'html' ;;
        *.png|*.PNG) printf 'png' ;;
        *.jpg|*.JPG|*.jpeg|*.JPEG) printf 'jpg' ;;
        *) printf 'bin' ;;
      esac
      ;;
  esac
}

extract_urls() {
  {
    rg --pcre2 --no-filename --only-matching 'https?://[^\s\]\[<>()|`"]+' \
      "$repo_root/docs/research-dossier.md" \
      "$repo_root/docs/artifacts.md"
    rg --pcre2 --no-filename --only-matching 'https://ntrs\.nasa\.gov/citations/[0-9]+' \
      "$repo_root/docs/research-dossier.md" \
      "$repo_root/docs/artifacts.md" |
      sed -E 's#https://ntrs\.nasa\.gov/citations/([0-9]+)#https://ntrs.nasa.gov/api/citations/\1/downloads/\1.pdf#'
  } | sed -E 's/[.,;:]+$//' |
    sort -u
}

extract_corpus_paths() {
  rg --no-filename --only-matching '`(forums|books|code|articles)/[^`]+`' \
    "$repo_root/docs/research-dossier.md" \
    "$repo_root/docs/artifacts.md" |
    sed -E 's/^`//; s/`$//' |
    sort -u
}

download_url() {
  local url="$1"
  local hash slug tmp headers ext dest bytes digest content_type retrieved_at
  hash="$(url_hash "$url")"
  slug="$(clean_slug "$url")"
  tmp="$files_dir/$hash.tmp"
  headers="$files_dir/$hash.headers.tmp"

  if [ "$refresh" != "1" ] &&
    existing="$(find "$files_dir" -type f -name "$hash-*" ! -name '*.headers' -print -quit)" &&
    [ -n "$existing" ]; then
    dest="$existing"
    headers="${existing}.headers"
    bytes="$(wc -c < "$dest" | tr -d ' ')"
    digest="$(sha256 "$dest")"
    content_type="$(
      if [ -f "$headers" ]; then
        { grep -i '^content-type:' "$headers" || true; } | tail -n 1 |
          sed -E 's/^[Cc]ontent-[Tt]ype:[[:space:]]*//; s/[[:space:]]*$//'
      fi
    )"
    retrieved_at="already-present"
  else
    if ! curl -fsSL --retry 3 --connect-timeout 20 --max-time "$timeout" \
      --compressed -A "$ua" -D "$headers" -o "$tmp" "$url"; then
      printf 'url\tfailed\t%s\n' "$url" >> "$failures_tmp"
      rm -f "$tmp" "$headers"
      return 0
    fi
    ext="$(extension_for "$url" "$headers")"
    dest="$files_dir/$hash-$slug.$ext"
    mv "$tmp" "$dest"
    mv "$headers" "${dest}.headers"
    bytes="$(wc -c < "$dest" | tr -d ' ')"
    digest="$(sha256 "$dest")"
    content_type="$(
      { grep -i '^content-type:' "${dest}.headers" || true; } | tail -n 1 |
        sed -E 's/^[Cc]ontent-[Tt]ype:[[:space:]]*//; s/[[:space:]]*$//'
    )"
    retrieved_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  fi

  printf 'url\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$digest" "$bytes" "$content_type" "$retrieved_at" "${dest#$mirror_root/}" "$url" >> "$manifest_tmp"
}

mirror_corpus_path() {
  local rel="$1"
  local dest="$corpus_dir/$rel"
  local digest bytes retrieved_at
  mkdir -p "$(dirname "$dest")"

  if [ ! -s "$dest" ]; then
    if ! scp -p "root@pius:/persist/lisp-corpus/$rel" "$dest" >/dev/null 2>&1; then
      printf 'local-corpus\tfailed\t%s\n' "/persist/lisp-corpus/$rel" >> "$failures_tmp"
      return 0
    fi
    retrieved_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  else
    retrieved_at="already-present"
  fi

  bytes="$(wc -c < "$dest" | tr -d ' ')"
  digest="$(sha256 "$dest")"
  printf 'local-corpus\t%s\t%s\ttext/markdown\t%s\t%s\t%s\n' \
    "$digest" "$bytes" "$retrieved_at" "${dest#$mirror_root/}" "/persist/lisp-corpus/$rel" >> "$manifest_tmp"
}

extract_urls > "$url_list"
extract_corpus_paths > "$corpus_list"

printf 'kind\tsha256\tbytes\tcontent_type\tretrieved_at\tlocal_path\tsource\n' > "$manifest_tmp"
printf 'kind\tstatus\tsource\n' > "$failures_tmp"

while IFS= read -r url; do
  [ -n "$url" ] || continue
  download_url "$url"
done < "$url_list"

if ssh -o BatchMode=yes -o ConnectTimeout=5 root@pius true >/dev/null 2>&1; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    mirror_corpus_path "$rel"
  done < "$corpus_list"
else
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    printf 'local-corpus\tssh-unavailable\t%s\n' "/persist/lisp-corpus/$rel" >> "$failures_tmp"
  done < "$corpus_list"
fi

mv "$manifest_tmp" "$manifest"
mv "$failures_tmp" "$failures"

printf 'Mirror root: %s\n' "$mirror_root"
printf 'URL list: %s\n' "$url_list"
printf 'Local corpus list: %s\n' "$corpus_list"
printf 'Manifest: %s\n' "$manifest"
printf 'Failures: %s\n' "$failures"
