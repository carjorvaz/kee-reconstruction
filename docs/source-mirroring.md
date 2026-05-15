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
pages, downloads each reachable public source, copies the listed
`/persist/lisp-corpus` local leads from `root@pius`, and writes:

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

Force a fresh download of already mirrored URLs:

```sh
KEE_MIRROR_REFRESH=1 scripts/mirror-research-sources.sh
```

Do not commit `.research-mirror/`. If a source later has clear redistribution
permission and is worth keeping in git, add it deliberately with a provenance
note instead of moving the whole mirror into the repository.
