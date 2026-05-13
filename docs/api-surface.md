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
- Lisp clauses substitute `?variables` and canonicalize calls such as
  `get.value` and `add.value` into the `kee` package

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
  `get.world.name`, `true.in.world`, and `world.inconsistent.p` exist
- `BELIEVE FALSE` marks the current world inconsistent
- `WHILE ... BELIEVE FALSE` rules can be used for puzzle-style constraints

Important uncertainty:

This is not yet an ATMS. It does not model justifications, environments,
nondeletion assumptions, deletion nogoods, or dependency-directed propagation.

## GUI Layer

Recovered layers:

- Common Windows
- KEEpictures
- ActiveImages

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
