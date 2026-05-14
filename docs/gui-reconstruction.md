# GUI Reconstruction Evidence

This note collects the current evidence for KEE's browser and graphical
interface layer. It is deliberately about behavior and vocabulary, not source
copying.

## Evidence Summary

KEE's GUI was not just a thin visualizer over frames. Public descriptions
consistently describe a development environment with browsers, mouse/menu
graphics, debugging views, and application-specific panels built on top of the
same unit/slot substrate.

Strongest recovered points:

- KEE included an Emacs editor, schema and knowledge-base browser, a graphics
  interface development package, TellAndAsk querying, debugging and trace
  information, an agenda/conflict-set viewer, dynamic graphic traces for
  rules/worlds, textual traces, a rule cross-referencer, and a Lisp debugger.
  Source: AIAI 1990 toolkit survey,
  `https://www.aiai.ed.ac.uk/publications/documents/1990-PRE/88-esmed-toolkits.pdf`.
- The graphics package was mouse/menu based and built around KEEpictures.
  Graphic items could be defined using units and animated by changing slot
  values. Listed examples include histograms, gauges, switches, and
  thermometers. Source: same AIAI 1990 survey.
- ActiveImages were interactive KEEpictures: mouse changes on the graphic
  updated the underlying object, and object updates reflected back in the
  graphic. Source: AIAI 1992 user-interface paper,
  `https://www.aiai.ed.ac.uk/publications/documents/1992/92-bcs-user-interfaces.pdf`.
- ActiveImages could display slot values, signal when values reached a limit,
  and allow mouse-driven slot updates. Source: AIAI 1990 survey.
- NASA VEG had a KEE browser/toolbox for browsing the class/subclass/member
  hierarchy and displaying slot values. Its extended browser added a KB menu, a
  "Current KB" box, and a top-level unit menu excluding ActiveImage and
  ActiveValue units. Source: NASA NTRS `19930007502`,
  `https://ntrs.nasa.gov/citations/19930007502`.
- ASKE, a KEE 3.1 application on a TI/Unisys Explorer, used KEE's Common
  Windows toolkit. Its interface vocabulary included icons, an Interaction
  Window, Notebook, Display Window, Rulemaker interface, Rule Display Window,
  Context Display Window, Class Display Window, and Rule Editing Window.
  Source: Open University thesis,
  `https://oro.open.ac.uk/64573/1/27758423.pdf`.
- NASA TEXSYS/MTK used KEE v2/v3 on Symbolics. Its phase-II work says
  KEEpictures provided a flexible graphics interface and KEEworlds represented
  hypothetical or temporal states. It also argues that direct slot inspection
  is awkward for topology and that graphical interfaces can create component
  instances and define interactions. Source: NASA CP `19880014804`,
  `https://ntrs.nasa.gov/api/citations/19880014804/downloads/19880014804.pdf`.
- Common Windows was an IntelliCorp-produced/specification window system. The
  local corpus has Lisp-history and Lisp FAQ evidence that KEE 4.0 shipped with
  a Common Windows implementation for Lucid Lisp on Sun, HP, and IBM
  workstations. Local corpus sources:
  `/persist/lisp-corpus/articles/gabriel/dreamsongs.com-derived/pdf-text/Files/HOPL2-Uncut.pymupdf.txt`
  and
  `/persist/lisp-corpus/forums/comp.lang.lisp/derived/threads/1995/faq-lisp-window-systems-and-guis-7-7-872bbbc758d59cc9.md`.
- A 1992 comp.lang.lisp report praises KEE for rapid UI prototyping while
  warning that production, standard-style user interfaces were difficult. Local
  corpus source:
  `/persist/lisp-corpus/forums/comp.lang.lisp/derived/threads/1992/request-for-info-on-intellicorp-s-kee-tm-97b30a6e2467ffab.md`.

## Recovered Vocabulary

Likely original or application-visible names:

- Common Windows
- KEEpictures
- ActiveImages
- ActiveValues
- KEEworlds
- schema browser
- knowledge-base browser
- agenda viewer
- graphic traces
- rule cross-referencer
- Display Window, Interaction Window, Rule Display Window
- Context Display Window, Class Display Window, Rule Editing Window
- Notebook
- Current KB

Recovered or public-code object/message names already tracked:

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

## Reconstruction Implications

The standalone browser should keep moving toward the recovered KEE structure:

- Keep the first-class visible current-KB state and loaded-KB list.
- Keep a hierarchy pane that can browse class/subclass/member trees up and
  down, with top-level-unit selection when reaching a tree boundary.
- Keep slot values inspectable beside the hierarchy, rather than hiding them
  only inside clicked graph nodes.
- Preserve the graph view, but treat it as one pane among browser, slot, rule,
  world, and trace panes.
- Add an ActiveImage abstraction before adding many widgets: a display object
  should bind to `(unit slot facet?)`, render a value, and optionally push a
  new value back through ordinary KEE mutators.
- Start with simple ActiveImage widgets that match the evidence: button,
  gauge/thermometer, switch, histogram/plot.
- Design tracing views around the recovered categories: rule agenda/conflict
  set, forward/backward/world graphic traces, text traces, and rule
  cross-reference.

## Open Questions

- Exact KEE browser menus and pane layout from the KEE User's Guide.
- Exact KEEpictures object hierarchy and constructor API.
- Exact ActiveImages unit/slot layout and event names.
- Exact Common Windows pane/window APIs used by KEE.
- Whether any original KEE distribution or manual scans survive outside the
  public references and secondary bibliographies found so far.

## Implemented Browser Increment

The standalone HTML/SVG viewer now implements the NASA VEG browser target at a
prototype level:

- shows `Current KB`
- lists loaded KBs as chips
- lists top-level units, excluding ActiveImage and ActiveValue-like units
- browses class parents, member parents, subclass children, and member
  children
- keeps a slot table synchronized with the selected unit
- keeps graph focus synchronized with hierarchy selection

## Implemented ActiveImage Increment

The reconstruction now has a first ActiveImage primitive:

- ActiveImages are ordinary KEE units under `active.images`
- each ActiveImage binds to `(unit slot facet?)`
- supported widgets are button, gauge/thermometer, switch, histogram/plot, and
  value display
- `set.active.image.value` writes target slots through `put.value`, preserving
  ActiveValue hooks
- `active.image.html` renders small HTML fragments for early browser and
  documentation experiments
- the standalone viewer embeds ActiveImage reports and shows slot-bound
  controls beside the selected unit's slot table
- generated controls can update the standalone page's local JSON copy, while
  Lisp-side writes continue to use ordinary KEE mutators

## Implemented Trace Increment

The reconstruction now has a first trace layer for rule/world debugging:

- `trace.events` returns structured chronological events
- `clear.trace.events` clears the trace log and participates in `reset-kee`
- recorded events include world creation, world slot writes, agenda passes,
  rule matches/firings, generated branches, nogoods, and contradictions
- the standalone viewer includes a Trace pane beside the selected unit or
  world detail
- trace panes can filter by event kind and selected-node scope
- trace panes can also isolate method, rule, world, and problem event families
- trace panes include search text plus previous/next jump controls, with the
  focused trace highlighted
- focused traces show a compact normalized event-detail drilldown
- focused traces highlight referenced units or worlds in the visible SVG graph
- focused trace detail exposes clickable unit/world graph targets
- trace rows expose clickable unit/world references
- a spatial trace map lays out recent agenda/rule/world/problem events in
  lanes
- focused trace-map events emphasize adjacent chronological path segments
- trace-map replay controls step or play through filtered map events, with
  speed, loop, and current-position controls for larger demos
- a compact trace graph summarizes agenda/rule/world/contradiction flow
- textual method traces now record `unitmsg` dispatch, before/primary/after
  method contribution calls, and returns

## Implemented Rule Cross-Reference Increment

The reconstruction now has a first static rule cross-referencer:

- `rule.references` reports a rule's classes, slot reads, slot writes, and
  assertions
- `rule.reference.index` indexes reconstructed rule references for a KB or
  rule class
- the standalone viewer embeds a global rule-reference index
- selected rule units show a Rule Xref pane with reads, writes, and assertions
- selected ordinary units show rules that literally mention that unit or use it
  as a rule class
- Rule Xref panes can filter by operation, slot, and selected/variable/concrete
  targets

## Next Build Target

Expand the debugging tools around the first trace and xref panes:

- richer branch/path emphasis over rule firings, generated worlds, and
  contradictions
