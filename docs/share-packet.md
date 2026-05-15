# Share Packet

This note is the short handoff for someone with first-hand experience of Texas
Instruments Lisp Machines, Symbolics machines, IntelliCorp KEE, or professional
KEE applications.

## What This Repository Is

This is an evidence-first, clean-room reconstruction of selected KEE behavior.
It is not original IntelliCorp source, not a binary distribution, and not a
claim that the historical system has been recovered.

The work was developed collaboratively by Carlos Vaz and OpenAI Codex. Codex
generated substantial implementation, documentation, scripts, and tests under
human direction; the standard for keeping material here is evidence plus
verification, not hand-authorship.

## Best First Look

Run:

```sh
nix develop --command scripts/render-reviewer-demos.sh
```

Open:

```text
demo/hamburg-viewer.html
demo/auv-panel-workflow.html
demo/aske-common-windows.html
```

Start with the ASKE demo if your memory is mainly TI Explorer / Common Windows.
Start with the Hamburg viewer if your memory is mainly KEE units, slots, rules,
worlds, traces, and browser/debugger behavior. Start with the AUV workflow if
your memory is mainly KEEpictures, ActiveImages, and application panels.

## Strongest Evidence Preserved

- Public CLOS-on-KEE code exposing real KEE API names such as `create.unit`,
  `create.slot`, `get.value`, `put.value`, and `unitmsg`.
- IntelliCorp-authored paper metadata for the 1984 AI Magazine KEE paper, plus
  a direct AITopics document page preserving title, authors, date, abstract,
  and tags while the AAAI/OJS page is currently broken from this environment.
- Hamburg KEE 3.0 training slides covering units, slots, rules, TellAndAsk,
  ActiveValues, ActiveImages, KEEpictures, KEEworlds, and a 3-by-3 puzzle.
- NASA/NPS/ASKE public application evidence for KEE on Symbolics, TI Explorer,
  Unisys Explorer, and Sun-style workstation settings.
- Bielefeld 1993 KEE evaluation with platform list, desktop/window behavior,
  ActiveValues, architecture figure source, and a KEE manual bibliography.
- IBM System/370 bibliography entries for KEE manuals, including publication
  numbers for TellAndAsk, KEEpictures, KEEworlds, RuleSystem3, and the
  Interface Reference Manual.

The raw mirrored sources are kept in a private, gitignored `.research-mirror/`
archive. The repo records provenance and hashes in `docs/mirror-audit.md`
without committing raw PDFs, scans, or publisher files.

## Known Missing Pieces

- Original IntelliCorp KEE source tree or binary distribution.
- Full KEE 2.x/3.x/4.x manual scans.
- The full 1984 AI Magazine PDF; only metadata and AITopics fallback pages are
  currently preserved.
- KEEtutor media, modules, and puzzle files such as `3X3IMPLEM1.U`.
- Product sheets or manuals for KEEconnection, RunTime KEE, KEE/C, KEEspy,
  J-KEE, KEEtutor, and related late product-family material.
- Raw application files mentioned by NASA VEG and NPS AUV reports.

## What We Most Need From A Reviewer

- What feels unlike real KEE, especially in the browser, Common Windows,
  KEEpictures, ActiveImages, image panels, tracing, and KEEworlds areas?
- Which window names, panes, menus, and daily workflows are missing or wrong?
- Did TI Explorer KEE feel materially different from Symbolics or Sun/Lucid KEE?
- Are the reconstructed Lisp Listener, Typescript, Prompt, rule agenda, trace,
  and explanation surfaces plausible review cues?
- Which API names, argument conventions, slot/facet idioms, or rule syntax
  look wrong?
- Which single demo or missing feature would most improve the feeling of
  meeting the real environment again?

## Deeper Reading

- `docs/reviewer-packet.md` is the guided demo path.
- `docs/expert-review.md` is the interview/question sheet.
- `docs/artifacts.md` is the evidence ledger and missing-artifact list.
- `docs/research-dossier.md` is the broad reachable-source inventory.
- `docs/gui-reconstruction.md` and `docs/gui-fidelity-matrix.md` track GUI
  evidence and reconstruction status.
- `docs/source-mirroring.md` and `docs/mirror-audit.md` explain what has been
  privately preserved and what remains blocked.
