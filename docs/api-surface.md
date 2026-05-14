# Recovered API Surface

This is a working API inventory from public KEE application code, CLOS-on-KEE,
manual references, patents, and training material.

## Knowledge Bases

High confidence:

- `create.kb`
- `kb.exists.p`
- `goto.kb`
- `(kb)`

Likely object accessors:

- `kb.name`

## Units

High confidence:

- `create.unit`
- `unit`
- `unit.exists.p`
- `unit.name`
- `unit.kb`
- `rename.unit`
- `delete.unit`
- `unit.parents`
- `unit.children`
- `unit.ancestors`
- `unit.descendant.p`

Relations seen in public code:

- `subclass`
- `member`

`create.unit` appears to accept at least:

```lisp
(create.unit name kb subclass-parents member-parents
             &optional comment member-slots own-slots)
```

This is inferred from CLOS-on-KEE and NASA VEG examples.

## Slots and Values

High confidence:

- `create.slot`
- `delete.slot`
- `slot.exists.p`
- `unit.slot.names`
- `get.value`
- `get.values`
- `put.value`
- `put.values`
- `add.value`
- `add.values`
- `remove.all.values`
- `remove.all.facet.values`
- `put.facet.value`

Evidence suggests KEE slots distinguish local, inherited, and combined values.
The first implementation models this directly, but only supports simple
override-style inheritance so far.

Current value semantics:

- `add.value` and `add.values` treat slot values as set-like lists and do not
  duplicate an already-present value.
- This is a reconstruction choice that helps forward chaining converge. Exact
  duplicate-value semantics still need manual confirmation.
- Slot facets can declare value classes using `(one.of ...)`.
- Slot facets can declare `min.cardinality` and `max.cardinality`.
- Constraints are inherited through parent units.
- Constraint violations signal Common Lisp errors for now; original KEE's UI
  and condition behavior still need manual evidence.

## Messages and Methods

High confidence:

- `unitmsg`
- `unitmsg*`

Method bodies are stored in slots. CLOS-on-KEE uses KEE method combination and
wraps generic function calls as `unitmsg*`.

Current reconstruction:

- method slots are identified when a slot's inheritance or value type is
  `method`
- primary method values are ordinary function designators or lambda expressions
- before contributions are stored as `(before FUNCTION-DESIGNATOR)`
- after contributions are stored as `(after FUNCTION-DESIGNATOR)`
- local primary methods override inherited primary methods
- local before/after contributions run before inherited before/after
  contributions
- `add.method` is a reconstruction helper, not a recovered KEE primitive

Open behavior:

- exact before/body/after method slot layout in original KEE
- `wrapperbody`
- primary method conflict rules
- method lookup order across multiple parents

## ActiveValues

High confidence concept:

- ActiveValues are units attached to slots.
- ActiveValues contain methods that fire when values are added, removed, or
  accessed.

Current reconstruction:

- attach ActiveValue units by putting unit names in the slot facet
  `active.values` or `active-values`
- ActiveValue units may implement these method slots:
  - `value-read`
  - `value-written`
  - `value-added`
  - `values-removed`
- handlers receive `(self target-unit slot-name old-values new-values)`

Important uncertainty:

These operation slot names are reconstruction names. The concept is recovered;
the exact original KEE operation names still need manual evidence.

## ActiveImages

High confidence concept:

- ActiveImages are interactive KEEpictures bound to object state.
- They display slot values and can optionally push mouse-driven changes back
  into slots.

Current reconstruction:

- `create.active.image` creates an ActiveImage as an ordinary KEE unit under
  the reconstructed `active.images` class.
- ActiveImage units store target bindings in `target.unit`, `target.kb`,
  `target.slot`, and optional `target.facet` slots.
- `active.image.values`, `active.image.value`, and `active.image.report` read
  the target state.
- `set.active.image.value` writes through the target binding. Slot writes use
  `put.value`, so existing ActiveValue write hooks still fire.
- `active.image.html` and `write.active.image.html` render small HTML
  fragments for `:button`, `:gauge`, `:thermometer`, `:switch`,
  `:histogram`, `:plot`, and fallback value widgets.
- `list.active.images` lists ActiveImage units in a KB.
- The standalone viewer embeds ActiveImage reports in `details.activeImages`
  and renders controls next to the selected target unit's slot table. These
  generated controls update the static page's local JSON copy; Lisp-side
  writes still go through `set.active.image.value`.

Important uncertainty:

This is a reconstruction support API. The ActiveImage concept is recovered
from public descriptions; exact original constructor names, slot layout, and
event vocabulary still need manual evidence.

## Rules and TellAndAsk

High confidence syntax fragments:

```lisp
(IF (THE SLOT OF UNIT IS ?X)
    (LISP (...))
    THEN
    (LISP (...)))
```

```lisp
(WHILE (...)
       (...)
  BELIEVE FALSE)
```

High confidence functions or slots:

- `forward.chain`
- rule units
- rule classes
- `external.form`
- `parse`
- `parse.errors`

Current reconstruction:

- rule units store source rules in `external.form`
- `parse` stores a parsed plist in `internal.form`
- parse failures are stored as strings in `parse.errors`
- `forward.chain` runs member rules of a rule class until no slot values change
- supported conditions:
  - `(THE slot OF unit IS ?variable)`
  - `(LISP form)`
- supported actions:
  - `(LISP form)`
  - `(IN.NEW.WORLD (THE slot OF unit IS value) ...)`
- Lisp clauses substitute `?variables` and canonicalize calls such as
  `get.value` and `add.value` into the `kee` package
- `cant.find` returns true when a unit has no value for a slot in the current
  world
- `find.any` returns the first value of a slot in the current world
- `run.world.agenda` runs rule classes across consistent worlds until the world
  set and values stabilize

## KEEworlds and ATMS

Training and patent evidence supports:

- worlds as a directed acyclic graph
- additions and deletions per world
- world assumptions
- nondeletion assumptions
- deletion nogoods
- consistency checks through a `FALSE` assertion

Training syntax includes:

- `IN.NEW.WORLD`
- `TRUE.IN.WORLD`
- `BELIEVE FALSE`
- `$WORLDS`

Current reconstruction:

- worlds have names, optional parent worlds, overlay slot values, and an
  inconsistency flag
- normal `get.value`, `put.value`, `add.value`, and `remove.all.values` use the
  current world's overlay when a current world is active
- `create.world`, `goto.world`, `current.world`, `with-world`, `$worlds`,
  `get.world.name`, `true.in.world`, `world.facts`, and
  `world.inconsistent.p` exist
- `BELIEVE FALSE` marks the current world inconsistent
- `IN.NEW.WORLD` rules create reusable child worlds for the same rule/bindings
  branch instead of generating an unbounded stream of duplicates
- generated worlds are deduplicated by effective fact signature, so different
  rule orders can converge on the same candidate world
- `WHILE ... BELIEVE FALSE` rules can be used for puzzle-style constraints
- `world.justifications`, `world.nogoods`, and `why.false` expose a small
  reason trail for contradictions
- justifications currently record the rule name, variable bindings, conditions,
  action, and proposition

Important uncertainty:

This is not yet a real ATMS. It records justification-shaped evidence for
contradictions, but it does not yet model ATMS environments, nondeletion
assumptions, deletion nogoods, or dependency-directed propagation.

## Inspector and Browser

Current reconstruction:

- `list.kbs` returns known knowledge-base names.
- `list.units` returns unit objects in a KB.
- `inspect.slot` returns a plist with local, inherited, combined, and facet
  values for a slot.
- `inspect.unit` returns a plist with parent links, child links, and inspected
  slots.
- `inspect.world` returns a plist with parent, consistency, local facts, and
  nogood summaries for a world.
- `inspect.world.tree` returns inspected worlds sorted by name.
- `print.browser` prints a compact terminal browser view over KBs, units,
  slots, worlds, and contradiction reasons.
- `browser.commands` returns the supported terminal-browser command table.
- `browser.command` executes a single command form such as `(unit tom)`,
  `(slot tom sport)`, or `(worlds 8)`.
- `browse` runs a small interactive command loop over the same command forms.
- `unit.graph` and `world.graph` return structured graph plists for a KB's
  unit hierarchy and the current KEEworlds DAG.
- `unit.graph.dot`, `world.graph.dot`, `write.unit.graph.dot`, and
  `write.world.graph.dot` render those graphs as Graphviz DOT.
- `graph.viewer.html`, `kee.viewer.html`, `write.graph.viewer.html`, and
  `write.kee.viewer.html` render standalone HTML/SVG graph browsers.
- The standalone viewer embeds `inspect.unit` and `inspect.world` detail maps,
  so its Current KB strip, hierarchy browser, synchronized slot table,
  searchable node list, and clicked graph nodes can show slots, facets, world
  facts, nogoods, and navigable references to visible units or worlds.

This is a reconstruction support layer rather than a recovered KEE API. It is
intended to keep display logic separate from the object/rule/world core, so a
future McCLIM or browser-canvas UI can reuse the same structured reports.

## GUI Layer

Recovered layers:

- Common Windows
- KEEpictures
- ActiveImages

Recovered behavior:

- KEE provided a schema/knowledge-base browser as part of the development
  environment.
- Application browser evidence from NASA VEG includes a KB menu, visible
  current-KB state, top-level-unit selection, class/subclass/member hierarchy
  browsing, and slot-value display.
- KEEpictures graphics were represented with units and could be animated by
  changing slot values.
- ActiveImages displayed slot values, could alert at predefined limits, and
  could update slot values through mouse interaction.
- KEE debugging UI included an agenda/conflict-set viewer, dynamic graphic
  traces for rules and worlds, textual rule/method traces, and a rule
  cross-referencer.
- Common Windows was the underlying GUI toolkit for KEE 4.0 on Unix and for
  at least one documented KEE 3.1 application.

Recovered object names and messages:

- `viewport-*`
- `windowpane-*`
- `open-panel!`
- `close-panel!`
- `open!`
- `mouseleftfn`
- `mouseleftfn!`
- `create-kee-output-window`
- `graph-unit`
- `make-cascading-menu`
- `choose-from-menu`

See also `docs/gui-reconstruction.md` for the evidence map and next GUI build
target.
