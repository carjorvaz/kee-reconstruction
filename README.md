# KEE Reconstruction

An evidence-first reconstruction of IntelliCorp's Knowledge Engineering
Environment (KEE).

This project is deliberately split into two tracks:

- `docs/`: provenance, recovered API notes, and design decisions.
- `src/` and `test/`: a Common Lisp reconstruction, starting with the KEE
  object/slot/message core.

`docs/gui-reconstruction.md` tracks the recovered KEE browser, Common Windows,
KEEpictures, ActiveImages, and trace/debugging evidence that guides the GUI
work.

The rule here is simple: public evidence first, implementation second. When
the original behavior is unknown, we record the uncertainty instead of quietly
inventing history.

## Current Scope

The first implementation target is `kee-core`:

- knowledge bases
- units with `subclass` and `member` parent links
- slots with local, inherited, and combined values
- basic inherited value propagation
- KEE-style API names such as `create.unit`, `get.value`, `put.value`,
  `unit.parents`, `unit.children`, and `unitmsg`
- method slots with `:before`, `:primary`, and `:after` contributions
- textual method trace events for `unitmsg` dispatch, contribution calls, and
  returns
- first-pass ActiveValue hooks on slot read/write/add/remove
- first-pass ActiveImage units bound to ordinary unit slots, with HTML
  fragments for button, gauge/thermometer, switch, histogram, and plot widgets
  plus optional write-back through `put.value`
- value-class and cardinality facets such as `(one.of ...)`,
  `min.cardinality`, and `max.cardinality`
- a tiny RuleSystem subset with rule units, `external.form`, `parse`,
  `parse.errors`, `THE`/`OF`/`IS`, `LISP`, `THEN`, `IN.NEW.WORLD`, and
  `forward.chain`
- a tiny KEEworlds subset with world overlays and `BELIEVE FALSE`
- small world-search helpers: `cant.find`, `find.any`, `run.world.agenda`, and
  effective-fact deduplication for generated worlds
- structured trace events for world creation, slot writes, agenda passes, rule
  matches/firings, branch creation, nogoods, and contradictions through
  `trace.events` and `clear.trace.events`
- a first static rule cross-referencer through `rule.references` and
  `rule.reference.index`, covering `THE`, common slot accessor/mutator calls,
  `IN.NEW.WORLD`, and `BELIEVE`
- structured inspector helpers and a compact terminal browser, including
  `list.kbs`, `list.units`, `inspect.unit`, `inspect.slot`, `inspect.world`,
  `inspect.world.tree`, `print.browser`, `browser.command`, and `browse`
- structured unit/world graph exports and Graphviz DOT renderers, including
  `unit.graph`, `world.graph`, `unit.graph.dot`, and `world.graph.dot`
- standalone HTML/SVG graph viewer generation through `kee.viewer.html` and
  `write.kee.viewer.html`, with visible current-KB state, loaded-KB chips, a
  class/member hierarchy browser, synchronized slot table, embedded
  ActiveImage controls with local static-page updates, searchable node browser,
  and a clickable inspector for slots, facets, facts, nogood explanations, and
  in-graph references, rule cross-reference panes with operation/slot/target
  filters, plus trace panes filterable by family, event kind, selected-node
  scope, and search text, with previous/next trace jumps, clickable trace
  references, and a compact trace graph

Later phases broaden RuleSystem/TellAndAsk, grow the KEEworlds/ATMS model, and
add the Common Windows / KEEpictures / ActiveImages GUI layer.

## Examples

`examples/veg-mini.lisp` is a small executable specimen inspired by the NASA
VEG listings. It creates a `veg` KB, a `target.data` class, sample/wavelength
units, and a method invoked with `unitmsg`.

`examples/veg-rule-mini.lisp` adds a VEG-style rule that selects a technique
for a wavelength unit using `forward.chain`.

`examples/hamburg-puzzle-mini.lisp` demonstrates KEE 3.0 training-slide-style
constraints and hypothesis search. It marks impossible worlds inconsistent,
prints a nogood reason, branches missing sports/phobias with `IN.NEW.WORLD`,
and lists complete consistent candidate worlds.

`examples/kee-browser.lisp` prints a small terminal browser view over the
Hamburg puzzle KB: selected units, slot/facet summaries, generated worlds, and
contradiction reasons. This is the first foundation for reconstructing the
KEE browser/GUI layer.

`examples/kee-browser-shell.lisp` sets up the same puzzle and opens a small
form-oriented browser shell. Useful commands include `(help)`, `(kbs)`,
`(units puzzle)`, `(unit tom)`, `(slot tom sport)`, `(worlds 8)`, and `(quit)`.

`examples/kee-graph-dot.lisp` emits DOT graphs for the Hamburg puzzle's unit
hierarchy and generated worlds. The browser shell can also print DOT with
`(unit-graph)` and `(world-graph 20)`.

`examples/kee-graph-viewer.lisp` emits a standalone HTML/SVG graph browser for
the Hamburg puzzle. The browser shell can also print one with `(viewer 40)`.

`examples/active-image-mini.lisp` creates a slot-bound ActiveImage gauge,
renders it as a small HTML fragment, and updates the target slot through the
ActiveImage so ActiveValue write hooks still run.

## Running Tests

```sh
sbcl --script test/run-tests.lisp
```

If `sbcl` is not installed:

```sh
nix shell nixpkgs#sbcl --command sbcl --script test/run-tests.lisp
```
