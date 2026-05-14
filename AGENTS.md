# Agent Notes

This repository is an evidence-led reconstruction of IntelliCorp KEE. Keep the
work legible to both humans and future agents.

## Map

- `README.md` is the front door for expert reviewers and casual demo users.
- `docs/artifacts.md` is the evidence ledger and missing-artifact list.
- `docs/provenance-policy.md` explains what can be checked in and what should
  remain a citation or private research note.
- `docs/reconstruction-plan.md` is the implementation roadmap.
- `docs/api-surface.md` records recovered API behavior and uncertainty.
- `docs/gui-reconstruction.md` tracks KEE browser, Common Windows,
  KEEpictures, ActiveImages, trace, and viewer evidence.
- `docs/gui-fidelity-matrix.md` maps recovered GUI evidence to current
  implementation status and reviewer questions.
- `docs/demo.md` explains how to generate and view the runnable demo.
- `docs/reviewer-packet.md` is the concise first-look packet for people who
  used KEE or Lisp machines professionally.
- `docs/expert-review.md` frames questions for people who used KEE or Lisp
  machines professionally.

## Working Rules

- Do not describe this as original KEE source. It is a clean-room,
  evidence-led reconstruction.
- Prefer small, verified commits with tests or generated-demo checks.
- Preserve uncertainty in docs instead of smoothing over unknown behavior.
- Keep `AGENTS.md` concise. Put detailed project knowledge in `docs/`.
- Do not commit proprietary manuals, source, binaries, or large copied excerpts
  unless redistribution rights are clear.

## Verification

Use the dev shell when possible:

```sh
nix develop
```

Common checks:

```sh
scripts/smoke.sh
scripts/render-demo.sh
scripts/screenshot-demo.sh
```
