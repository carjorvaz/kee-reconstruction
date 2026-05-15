# Source Mirror Audit

Last audited: 2026-05-15.

This note audits the private source mirror described in
`docs/source-mirroring.md`. It is intentionally a repo-committed summary of a
gitignored local archive, not the archive itself.

## Snapshot

- Mirror root: `.research-mirror/sources/`
- Mirror size: `316M`
- Source URL targets extracted: `80`
- Local corpus targets extracted: `15`
- Public URL successes: `70`
- Local corpus successes: `15`
- Failed URL targets: `10`
- Manifest: `.research-mirror/sources/manifest.tsv`
- Failure log: `.research-mirror/sources/failures.tsv`
- Manual browser captures: use `scripts/register-manual-source.sh` to place
  browser-saved files under `.research-mirror/sources/manual/`.
- Current manual captures: ASKE thesis, registered as
  `.research-mirror/sources/manual/20260515T101849Z-aske-thesis.pdf` with
  SHA-256 `852d02dc2cbf5e38020249fdc5fdab37cfafb19ba842d3df0ac7b95dfec1ed44`.

Public file types currently preserved:

| Content type | Count |
| --- | ---: |
| `application/json` | 3 |
| `application/pdf` | 30 |
| `text/html` | 35 |
| `text/plain` | 1 |
| `video/mp4` | 1 |

The local corpus mirror contributes 15 text/markdown files copied from
`root@pius:/persist/lisp-corpus`.

## High-Value Preserved Material

- DBLP and OpenAlex metadata fallbacks for the 1984 AI Magazine KEE paper and
  the 1988 Filman KEEworlds paper, including DOI metadata where reachable.
- Computer Chronicles 1984 "Artificial Intelligence" page, MP4, transcript,
  and metadata JSON.
- NASA/NTRS PDFs for KATYDID, SLED, TEXSYS/MTK, HITEX, the Space Station
  scheduler prototype, closed-loop life support simulation, PROTAIS, and the
  VEG task-report family where NTRS exposes a PDF.
- NASA/NTRS landing pages for the VEG reports and KATYDID, so metadata is
  still preserved even when a direct PDF is not exposed.
- CLOS-on-KEE public code page and OSTI report.
- IntelliCorp patents mirrored from Google Patents.
- IBM System/370 bibliography PDF with KEE manual publication numbers.
- AIAI toolkit/UI PDFs.
- NPS AUV thesis via Wikimedia/Internet Archive mirror, plus the NPS handle
  page.
- ASKE thesis via manual browser capture, preserving the KEE 3.1 /
  Unisys/TI Explorer Common Windows GUI evidence that curl could not retrieve.
- SimKit PDF via the NCSU DSpace bitstream.
- Trade/product pages for KEEconnection, RunTime KEE, J-KEE, Unisys/TI
  Explorer, Apollo AI pacts, and Kappa/ProKappa transition context.
- Local comp.lang.lisp and book/article corpus leads cited in the dossier.

## Bad Or Partial Successes

| Source | Mirror state | Next action |
| --- | --- | --- |
| AI Magazine 1984 KEE paper | The OJS URL produced a 98-byte server-side error page, not the paper. DBLP/OpenAlex/DOI metadata is now tracked, but no PDF has been captured. | Browser/manual capture or find a stable AAAI/Semantic Scholar/Internet Archive copy of "Applications Development Using a Hybrid Artificial Intelligence Development System." |
| AI Magazine DOI `10.1609/aimag.v5i3.447` | The DOI is now identified and mirrored as a URL target, but curl follows it to the same 98-byte AAAI/OJS error page. | Keep the DOI as metadata and rely on browser/manual capture for the paper itself. |
| NPS handle page | The handle URL mirrors only the DSpace shell page. | The Wikimedia/Internet Archive PDF mirror is preserved and should be treated as the useful local copy. |
| NTRS `19930063758` | Landing page preserved; derived direct PDF URL returns 404. | Keep the landing page. If the paper has no NTRS PDF, search conference proceedings or alternate NASA mirrors by title. |

Generated audit output now includes a "Suspicious Captures" table for tiny URL
captures. On the current mirror this catches the AAAI/OJS article and DOI
error pages plus the 755-byte NPS handle shell page.

## Manual Browser Queue

Use this queue only when the browser can actually see or download the content;
otherwise keep the URL in the failure list and move on.

| Priority | Source | Browser action |
| --- | --- | --- |
| High | `https://doczz.net/doc/5911786/evaluation-hybrider-expertensystemtools` | Save as PDF or complete HTML after the Cloudflare challenge. This preserves the Bielefeld KEE chapter and manual bibliography. |
| High | `https://doi.org/10.1609/aimag.v5i3.447` | Try from a browser; if the AI Magazine article or PDF loads, save it as the 1984 IntelliCorp KEE paper. |
| Medium | `https://doi.org/10.1145/42404.42405` | If ACM exposes the Filman KEEworlds PDF in-browser, save it. Metadata is already preserved through DBLP/OpenAlex. |
| Low | `https://journals.sagepub.com/doi/10.1177/089443939000800304` | Save only if convenient; it is a pricing/runtime context lead, not core API/GUI evidence. |

## Failure Queue

| Source | Why it matters | Likely reason | Next action |
| --- | --- | --- | --- |
| `https://cacm.acm.org/research/reasoning-with-worlds-and-truth-maintenance-in-a-knowledge-based-programming-environment/` | Primary Filman KEEworlds article page. | Cloudflare/publisher blocking curl. | Manual browser save or ACM export if accessible; DBLP DOI and OpenAlex metadata are enough for citation meanwhile. |
| `https://doi.org/10.1145/42404.42405` | DOI target for the Filman KEEworlds paper. | DOI/ACM path blocks non-browser fetch. | Browser save only if ACM exposes the PDF; DBLP and OpenAlex metadata are already mirrored. |
| `https://doi.org/10.1145/4284.4285` | DOI target for the Fikes/Kehler CACM paper. | Publisher/DOI path blocks non-browser fetch. | Low urgency because DBLP metadata is mirrored; use manual ACM export if needed. |
| CiteSeerX Filman PDF | Full KEEworlds article PDF. | CiteSeerX returns 403/404 intermittently. | Prefer ACM/DOI browser capture now that DBLP/OpenAlex confirm DOI `10.1145/42404.42405`; keep searching public mirrors by title. |
| CiteSeerX SPIKE Common Windows PDF | Source for SPIKE prototype GUI implemented in KEE Common Windows. | CiteSeerX returns 403/404. | Search by DOI hash, title text, and SPIKE/Hubble/KEE Common Windows phrases; keep NTRS SPIKE report as fallback. |
| CiteSeerX POLYMER PDF | KEE/ATMS/planner application lead. | CiteSeerX returns 403/404. | Search title/authors and POLYMER KEE ATMS phrases; preserve any alternate PDF. |
| `https://doczz.net/doc/5911786/evaluation-hybrider-expertensystemtools` | Bielefeld KEE evaluation and manual bibliography. | Curl cannot mirror page reliably, though browser/search access works. | Manual browser print/save or test doczz download iframe endpoint; this is high priority because the KEE chapter is unusually useful. |
| `https://journals.sagepub.com/doi/10.1177/089443939000800304` | Pricing/runtime lead for IBM/mainframe KEE. | Publisher blocks curl. | Low priority; manual browser save or library access later. |
| `https://oro.open.ac.uk/64573/1/27758423.pdf` | ASKE thesis with TI Explorer/Common Windows GUI evidence. | Cloudflare challenge blocks curl, although browser access works. | Resolved by manual browser capture on 2026-05-15; keep this row as explanation for the remaining curl failure entry. |

## Refresh Commands

Refresh the private mirror:

```sh
scripts/mirror-research-sources.sh
```

Force refetching already mirrored sources:

```sh
KEE_MIRROR_REFRESH=1 scripts/mirror-research-sources.sh
```

Print a current generated summary:

```sh
scripts/audit-source-mirror.sh
```

Do not commit `.research-mirror/`; use this audit and the manifest to make the
private archive legible without putting raw source material in git.
