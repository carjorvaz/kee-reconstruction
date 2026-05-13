# Reconstruction Plan

## Definition of "Proper"

The reconstruction should be:

- evidence-led: every major feature links back to recovered public behavior
- runnable: demos and tests should execute on current Common Lisp
- layered: core representation first, GUI and rules later
- honest: unknowns are tracked explicitly
- useful: the API should feel like KEE even where internals differ

## Phase 0: Project Memory

- Artifact ledger.
- API inventory.
- Glossary of KEE concepts.
- Minimal source tree and tests.

## Phase 1: KEE Core

Implement:

- knowledge bases
- units
- subclass and member relations
- slots and facets
- local, inherited, and combined values
- KEE-style accessors and mutators
- `unitmsg` and method slots

Faithfulness target:

- CLOS-on-KEE style examples should become plausible.
- NASA VEG snippets using `create.unit`, `put.value`, `add.value`, and
  `unit.children` should be easy to translate.

Status:

- Initial implementation exists.
- Method slots support before, primary, and after contributions.
- ActiveValue read/write/add/remove hooks exist, with reconstructed event names.

## Phase 2: ActiveValues and Methods

Implement:

- broader active value units
- demons on delete, copy, and rename operations
- enough `wrapperbody` behavior to support CLOS-on-KEE patterns

## Phase 3: RuleSystem and TellAndAsk

Implement:

- parser for the recovered TellAndAsk subset
- rule units with `external.form`, `parse`, and `parse.errors`
- forward chaining
- backward query path
- Lisp action clauses
- explanation hooks

First demos:

- Hamburg 3-by-3 puzzle constraints
- NASA VEG technique selection rules

Status:

- A first subset exists.
- It parses `external.form` on rule units.
- It supports `THE`/`OF`/`IS`, `LISP`, `THEN`, and stable `forward.chain`
  passes.
- The regression tests include a VEG-style technique-selection rule.

## Phase 4: KEEworlds and TMS

Implement:

- worlds DAG
- primitive assertions
- justifications
- world and nondeletion assumptions
- deletion nogoods
- consistency detection

Faithfulness target:

- Reproduce the training puzzle's world-branching behavior.

Status:

- A first world overlay model exists.
- `WHILE ... BELIEVE FALSE` can mark a world inconsistent.
- `why.false` reports the rule and bindings responsible for a contradiction.
- The regression tests and `examples/hamburg-puzzle-mini.lisp` cover a
  training-slide-style constraint.
- Full ATMS environments, assumptions, and dependency propagation are still
  future work.

## Phase 5: GUI Reconstruction

Two viable tracks:

- Common Lisp plus McCLIM for historical sympathy.
- Browser canvas for speed and easy screenshots.

Implement:

- KEE desktop metaphor
- KB browser
- unit/class browser
- slot browser
- graph view
- typescript/listener
- ActiveImage panels, viewports, and windowpanes

First demos:

- `FRED_HACKER` style unit browser.
- NASA VEG-style menu panels.
- Computer Chronicles reactor-control style panel.
