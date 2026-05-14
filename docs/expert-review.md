# Expert Review Notes

This document is for conversations with people who used Texas Instruments Lisp
Machines, Symbolics systems, IntelliCorp KEE, or KEE-based applications
professionally.

## Framing

The repo is a reconstruction, not recovered KEE. The most useful feedback is
where the reconstruction feels unlike the real environment, especially in the
GUI, browser, rule/debugging, KEEpictures, ActiveImages, Common Windows, and
KEEworlds areas.

## Questions To Ask

- What did a normal KEE work session feel like?
- Which browser panes, menus, inspectors, or graphical tools were used every
  day?
- How did KEEpictures and ActiveImages behave when objects changed?
- What did rule tracing, agenda/conflict-set views, and explanations look like?
- How visible were worlds, assumptions, nogoods, and contradictions in the UI?
- Which API names or idioms here feel right, wrong, or missing?
- Did Texas Instruments Lisp Machine usage differ materially from Symbolics,
  Sun/Lucid, or later workstation KEE usage?
- What demos would best evoke "real KEE" without pretending to be original KEE?

## Demo Path

Start with:

```sh
nix develop --command scripts/render-demo.sh
```

Then open `demo/hamburg-viewer.html` and inspect:

- the class/member hierarchy
- rule units and parsed forms
- the Worlds tab
- selected world facts, support labels, assumptions, and nogoods
- the Trace pane, agenda view, causality graph, and trace map

## Notes From Review

Add dated notes here as conversations happen. Keep direct quotations short and
attributed only with permission.
