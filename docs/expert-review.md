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
- Did the everyday KEE desktop look like a saved arrangement of Lisp Listener,
  Typescript, Prompt, knowledge-base, unit, slot, KEEpicture, and ActiveImage
  windows?
- How did KEEpictures and ActiveImages behave when objects changed?
- What did rule tracing, agenda/conflict-set views, and explanations look like?
- Do you remember KEEspy or other profiling/debugging tools around KEE?
- How visible were worlds, assumptions, nogoods, and contradictions in the UI?
- Which API names or idioms here feel right, wrong, or missing?
- Did Texas Instruments Lisp Machine usage differ materially from Symbolics,
  Sun/Lucid, or later workstation KEE usage?
- Do the ASKE interface names from the public thesis sound like ordinary
  KEE/Common Windows practice or a bespoke application interface: Aske,
  Rulemaker, Cerveau, Notebook, Display Window, Rule DW, Context DW, Class DW,
  Central Concepts Window?
- What demos would best evoke "real KEE" without pretending to be original KEE?

## Demo Path

Start with:

```sh
nix develop --command scripts/render-reviewer-demos.sh
```

Then open `demo/hamburg-viewer.html` and inspect:

- the Browser pane's Current KB, Review Tour, Desktop roster, and
  Listener/Typescript/Prompt transcript
- the class/member hierarchy
- rule units and parsed forms
- the Worlds tab
- selected world facts, support labels, assumptions, and nogoods
- the Trace pane, agenda view, causality graph, and trace map

Then open `demo/auv-panel-workflow.html` and inspect:

- the mission-selection, parameter-entry, and monitoring panels
- panel Open/Close behavior
- ActiveImage write-through into mission state
- picture mouse traces and panel trace events

## Notes From Review

Add dated notes here as conversations happen. Keep direct quotations short and
attributed only with permission.
