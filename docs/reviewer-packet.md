# Reviewer Packet

This packet is for someone who used IntelliCorp KEE, Texas Instruments Lisp
Machines, Symbolics machines, or KEE-based professional systems.

## What This Is

This is a clean-room Common Lisp reconstruction of selected KEE behavior. It is
guided by public evidence, small translated examples, patents, papers, NASA
reports, training slides, and implementation experiments.

It is not original IntelliCorp KEE source, not a binary distribution, and not a
claim of historical completeness.

## Quick Start

```sh
nix develop --command scripts/render-demo.sh
```

Open:

```text
demo/hamburg-viewer.html
```

The demo opens on the Worlds tab with an inconsistent generated world selected.
That first view is meant to show KEEworlds-style branching, local facts,
assumptions, support labels, nogoods, rule traces, agenda/conflict-set
reconstruction, and causality views in one place.

## What To Inspect

- The Units tab: class/member hierarchy, rule units, parsed rule forms, slots,
  facets, rule cross-references, and ActiveImage evidence.
- The Worlds tab: generated branch worlds, consistent versus inconsistent
  worlds, local world facts, support labels, assumptions, and nogoods.
- The Browser pane: Current KB state, Review Tour controls, the reconstructed
  Desktop roster, and Listener/Typescript/Prompt transcript panes.
- The KEEpictures tour target: a small reconstructed picture with viewport and
  windowpane metadata, an embedded writable ActiveImage, and a picture mouse
  trace.
- The Panels tour target: a reconstructed image/workflow panel layered over a
  KEEpicture/windowpane, with open/closed state and panel trace events.
- `docs/assets/dumps/delivery.kdump`: a small readable clean-room KB dump for
  loading from the browser shell with the `load-dump` command.
- The Trace pane: agenda passes, rule matches/fires, world branches, slot
  writes, contradictions, label retractions, why trails, and trace map.
- `examples/hamburg-puzzle-mini.lisp`: the small KEE 3.0 training-slide-style
  puzzle that drives the demo.
- `examples/veg-rule-mini.lisp`: a tiny NASA VEG-inspired rule example.

## What We Most Need Corrected

- Which GUI elements feel unlike KEE's browser, Common Windows, KEEpictures,
  image panels, ActiveImages, or tracing tools?
- Do the Lisp Listener, Typescript, and Prompt surfaces feel plausible as a
  first review cue, or do they suggest the wrong work rhythm?
- Which API names, argument conventions, or idioms look wrong?
- What did the rule agenda/conflict-set viewer actually expose?
- How did KEEworlds, assumptions, nogoods, and contradictions appear to users?
- What was specific to TI Lisp Machines versus Symbolics or Sun/Lucid KEE?
- Which missing feature would most improve the "yes, this evokes KEE" feeling?

## Evidence Map

- `docs/artifacts.md` - evidence ledger and missing artifact list.
- `docs/api-surface.md` - reconstructed API surface and known uncertainty.
- `docs/gui-reconstruction.md` - GUI, KEEpictures, ActiveImages, and trace
  evidence.
- `docs/gui-fidelity-matrix.md` - GUI evidence mapped to implementation
  status, reviewer questions, and next actions.
- `docs/provenance-policy.md` - what can be stored in this repository.
- `docs/expert-review.md` - notes and prompts for first-hand conversations.

## Running Checks

```sh
nix develop --command scripts/smoke.sh
```

The smoke script runs the documentation harness, Common Lisp regression tests,
ASDF load, viewer generation, viewer JavaScript syntax check, Playwright viewer
interaction check, and the current example scripts.
