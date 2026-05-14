# Demo

The most useful current demo is the standalone Hamburg puzzle viewer. It is not
the historical KEE GUI, but it exercises reconstructed KEE concepts in one
place: units, slots, rule classes, generated worlds, trace events, fact labels,
world assumptions, and nogood explanations.

The generated page opens on the Worlds tab with an inconsistent generated world
selected. This is intentional: it gives reviewers a concrete first view of
KEEworlds-style branching, assumptions, support labels, nogoods, and rule trace
explanations instead of a blank or generic hierarchy view. The Browser pane also
includes Review Tour controls that jump to representative units, rules, worlds,
agenda traces, rule cross-references, and ActiveImages when available.

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

## Smoke Test

Run the full local check:

```sh
nix develop --command scripts/smoke.sh
```
