# Demo

The most useful current demo is the standalone Hamburg puzzle viewer. It is not
the historical KEE GUI, but it exercises reconstructed KEE concepts in one
place: units, slots, rule classes, generated worlds, trace events, fact labels,
world assumptions, nogood explanations, a reconstructed KEEpicture, an
image/workflow panel, and slot-bound ActiveImages.

The generated page opens on the Worlds tab with an inconsistent generated world
selected. This is intentional: it gives reviewers a concrete first view of
KEEworlds-style branching, assumptions, support labels, nogoods, and rule trace
explanations instead of a blank or generic hierarchy view. The Browser pane also
includes Review Tour controls that jump to representative units, rules, worlds,
agenda traces, rule cross-references, KEEpictures, panels, and ActiveImages when
available. It also shows a compact Desktop roster using recovered KEE window
vocabulary, plus a small Listener/Typescript/Prompt transcript for the
generated session.

## Run

With Nix:

```sh
nix develop --command scripts/render-demo.sh
```

Then open:

```text
demo/hamburg-viewer.html
```

The HTML is self-contained and can be opened directly in a browser.

The AUV panel workflow demo focuses on reconstructed GUI/application panels:

```sh
nix develop --command scripts/render-auv-panel-demo.sh
```

Then open:

```text
demo/auv-panel-workflow.html
```

This page builds mission-selection, parameter-entry, and monitoring panels,
drives them with `open-panel!`/`close-panel!`, and records picture mouse events
that write through ActiveImages into `mission.state`.

Without Nix, install SBCL and run:

```sh
scripts/render-demo.sh
```

## Screenshot

The README screenshot is generated, not hand-edited:

```sh
nix develop --command scripts/screenshot-demo.sh
```

The command writes:

```text
docs/assets/screenshots/hamburg-viewer-review.png
```

The KEEpicture tour screenshot uses the same generated demo:

```sh
KEE_DEMO_TOUR=kee-pictures nix develop --command scripts/screenshot-demo.sh docs/assets/screenshots/hamburg-viewer-kee-picture.png
```

The Panels tour screenshot uses the reconstructed image/workflow panel target:

```sh
KEE_DEMO_TOUR=panels nix develop --command scripts/screenshot-demo.sh docs/assets/screenshots/hamburg-viewer-panels.png
```

The Panels tour also has static-page Open and Close controls. They update the
generated page's local panel state and append reconstructed panel trace events
for quick reviewer interaction.

The AUV panel workflow screenshot uses the alternate renderer:

```sh
KEE_DEMO_RENDERER=scripts/render-auv-panel-demo.sh KEE_DEMO_HTML=demo/auv-panel-workflow.html KEE_DEMO_TOUR=panels nix develop --command scripts/screenshot-demo.sh docs/assets/screenshots/auv-panel-workflow.png
```

## Interaction Check

Run the browser-level viewer check:

```sh
nix develop --command scripts/check-viewer.sh
```

It renders the demo into a temporary file, opens it with Playwright, and checks
the Review Tour controls, slot table, rule cross-reference, and agenda panes.

Run the AUV panel workflow browser check:

```sh
nix develop --command scripts/check-auv-panel-demo.sh
```

It renders the AUV workflow page, clicks through the three panel tabs, exercises
Open/Close, and checks that panel and picture traces are visible.

## KB Dump

The checked-in readable dump artifact is regenerated from the mini delivery KB:

```sh
nix develop --command scripts/render-demo-dump.sh
```

The command writes:

```text
docs/assets/dumps/delivery.kdump
```

It is not an original KEE file format; it is a clean-room reconstruction aid for
loading and inspecting portable KB data.

## Smoke Test

Run the full local check:

```sh
nix develop --command scripts/smoke.sh
```
