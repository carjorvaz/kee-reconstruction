# KEE Reconstruction

An evidence-first reconstruction of IntelliCorp's Knowledge Engineering
Environment (KEE).

This project is deliberately split into two tracks:

- `docs/`: provenance, recovered API notes, and design decisions.
- `src/` and `test/`: a Common Lisp reconstruction, starting with the KEE
  object/slot/message core.

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
- first-pass ActiveValue hooks on slot read/write/add/remove
- a tiny RuleSystem subset with rule units, `external.form`, `parse`,
  `parse.errors`, `THE`/`OF`/`IS`, `LISP`, `THEN`, and `forward.chain`
- a tiny KEEworlds subset with world overlays and `BELIEVE FALSE`

Later phases broaden RuleSystem/TellAndAsk, grow the KEEworlds/ATMS model, and
add the Common Windows / KEEpictures / ActiveImages GUI layer.

## Examples

`examples/veg-mini.lisp` is a small executable specimen inspired by the NASA
VEG listings. It creates a `veg` KB, a `target.data` class, sample/wavelength
units, and a method invoked with `unitmsg`.

`examples/veg-rule-mini.lisp` adds a VEG-style rule that selects a technique
for a wavelength unit using `forward.chain`.

`examples/hamburg-puzzle-mini.lisp` demonstrates a KEE 3.0 training-slide
style constraint: a world where Tom has both `sport = golf` and
`phobia = heights` is marked inconsistent by `WHILE ... BELIEVE FALSE`, with a
small reason trail showing the rule and bindings that produced the nogood.

## Running Tests

```sh
sbcl --script test/run-tests.lisp
```

If `sbcl` is not installed:

```sh
nix shell nixpkgs#sbcl --command sbcl --script test/run-tests.lisp
```
