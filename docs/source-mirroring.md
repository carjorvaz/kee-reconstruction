# Source Mirroring

The repository keeps citations and checks in git, but the raw research
material should stay in a local, gitignored mirror unless redistribution
rights are clear.

Default mirror path:

```sh
.research-mirror/sources/
```

Refresh the mirror:

```sh
scripts/mirror-research-sources.sh
```

The script extracts URLs from `docs/research-dossier.md` and
`docs/artifacts.md`, derives direct NTRS PDF download URLs from NASA citation
pages, downloads each reachable public source, optionally copies listed
private local-corpus leads, and writes:

- `.research-mirror/sources/manifest.tsv` with source, local path, byte count,
  content type, retrieval time, and SHA-256 digest.
- `.research-mirror/sources/failures.tsv` with URLs or corpus paths that could
  not be mirrored during that run.
- `.research-mirror/sources/source-urls.txt` and
  `.research-mirror/sources/local-corpus-paths.txt` with the extracted input
  lists.

Use a different destination when desired:

```sh
KEE_SOURCE_MIRROR=/path/to/private/kee-source-mirror scripts/mirror-research-sources.sh
```

If you have a private local corpus matching the relative paths listed in the
dossier, point the mirror at it with `KEE_LOCAL_CORPUS_ROOT`. The value can be a
local directory or an `scp`-style remote root:

```sh
KEE_LOCAL_CORPUS_ROOT=/path/to/lisp-corpus scripts/mirror-research-sources.sh
KEE_LOCAL_CORPUS_ROOT=user@example:/path/to/lisp-corpus scripts/mirror-research-sources.sh
```

When `KEE_LOCAL_CORPUS_ROOT` is unset, the script still mirrors public URLs and
records local-corpus entries as `remote-unconfigured` if they are not already
present in the private mirror.

Force a fresh download of already mirrored URLs:

```sh
KEE_MIRROR_REFRESH=1 scripts/mirror-research-sources.sh
```

Print a current generated audit summary:

```sh
scripts/audit-source-mirror.sh
```

Some high-value sources are reachable in a normal browser but not through
`curl` because of Cloudflare, publisher bot checks, or old repository
front-ends. Save those manually into a temporary/downloads folder, then register
the saved file in the same private mirror:

```sh
scripts/register-manual-source.sh \
  'https://example.invalid/source' \
  ~/Downloads/source.pdf \
  short-source-label
```

Manual captures are copied into `.research-mirror/sources/manual/` with a
sidecar `.source.tsv` recording the source URL, local path, byte count, content
type, retrieval time, and SHA-256 digest.

`docs/mirror-audit.md` keeps the current hand-written audit, including partial
captures and manual fallback work.

Do not commit `.research-mirror/`. If a source later has clear redistribution
permission and is worth keeping in git, add it deliberately with a provenance
note instead of moving the whole mirror into the repository.
