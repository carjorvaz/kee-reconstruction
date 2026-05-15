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
- The ASKE thesis gives a concrete Common Windows application pattern, not just
  vocabulary. Chapter V describes an Aske interface with six top-left icons,
  an Interaction Window, Notebook, and Display Window for the current
  knowledge base; its Rulemaker interface has five icons, Rule DW, Context DW,
  Class DW, and a Rule Editing Window opened from Rule DW. The documented icon
  actions include New KB, Load KB, Save KB, Quit, Help, Rulemaker, Context,
  Class, Rule, and Aske. It also records hierarchical concept windows,
  Notebook pages, and left/middle mouse distinctions for rule-editing actions.
  This is currently the sharpest target for a KEE 3.1 / TI Explorer
  Common-Windows-inspired reconstruction.
- NASA TEXSYS/MTK used KEE v2/v3 on Symbolics. Its phase-II work says
  KEEpictures provided a flexible graphics interface and KEEworlds represented
  hypothetical or temporal states. It also argues that direct slot inspection
  is awkward for topology and that graphical interfaces can create component
  instances and define interactions. Source: NASA CP `19880014804`,
  `https://ntrs.nasa.gov/api/citations/19880014804/downloads/19880014804.pdf`.
- The NPS AUV mission-planning thesis describes a KEE application hosted on a
  Symbolics 3675 Lisp machine, developed entirely in KEE. It used KEE graphics
  image panels for mission selection, parameter entry, preview/monitoring
  workflows, and mouse-driven control; the thesis also records a planned
  delivery configuration using a Texas Instruments Micro-Explorer. Appendix
  listings expose application-level KEE APIs and panel messages such as
  `UNITMSG`, `PUT.VALUE`, `REMOVE.ALL.VALUES`, `ASSERT`, `open-panel!`, and
  `close-panel!`. Source: NPS thesis, `https://hdl.handle.net/10945/23457`.
- A 1993 Bielefeld evaluation reproduces the KEE architecture from the KEE
  User's Guide as Common Lisp plus TMS, Common Windows, Active Values,
  KEEworlds, Rulesystem, KEEpictures, ActiveImages, and object-oriented
  programming. It describes a desktop made of larger windows containing Lisp
  Listener, Typescript, Prompt, knowledge-base, unit, and slot windows; users
  could configure, save, and reload desktops with KEEpictures and ActiveImages.
  It also says ActiveValues/demons could trigger on nine slot operations,
  including read, write, delete, copy, and rename. Source:
  `https://doczz.net/doc/5911786/evaluation-hybrider-expertensystemtools`.
- Common Windows was an IntelliCorp-produced/specification window system. The
  local corpus has Lisp-history and Lisp FAQ evidence that KEE 4.0 shipped with
  a Common Windows implementation for Lucid Lisp on Sun, HP, and IBM
  workstations. Private local-corpus sources:
  `articles/gabriel/dreamsongs.com-derived/pdf-text/Files/HOPL2-Uncut.pymupdf.txt`
  and
  `forums/comp.lang.lisp/derived/threads/1995/faq-lisp-window-systems-and-guis-7-7-872bbbc758d59cc9.md`.
- A 1998 comp.lang.lisp thread quotes the KEE for Symbolics manual set about
  the 1986 IntelliCorp Common Windows Manual: principal designers at
  IntelliCorp and lineage from Interlisp-D and ZetaLisp window systems. Local
  corpus source:
  `forums/comp.lang.lisp/derived/threads/1998/common-windows-4ee975ab0b388b6d.md`.
- A 1991 comp.lang.lisp question asks about KEE on a DEC VAXStation 3100 under
  DEC Windows, KeePictures, and VMS or Ultrix C integration, which broadens the
  platform/graphics lead beyond Symbolics, TI, and Unix workstations. Local
  corpus source:
  `forums/comp.lang.lisp/derived/threads/1991/lisp-programming-in-kee-toolkit-for-graphics-c-integration-a25c92aa4b91613e.md`.
- A 1992 comp.lang.lisp report praises KEE for rapid UI prototyping while
  warning that production, standard-style user interfaces were difficult. Local
  corpus source:
  `forums/comp.lang.lisp/derived/threads/1992/request-for-info-on-intellicorp-s-kee-tm-97b30a6e2467ffab.md`.

## Recovered Vocabulary

Likely original or application-visible names:

- Common Windows
- KEEpictures
- ActiveImages
- ActiveValues
- KEEworlds
- Aske Interface
- Rulemaker Interface
- Cerveau
- schema browser
- knowledge-base browser
- agenda viewer
- graphic traces
- rule cross-referencer
- Display Window, Interaction Window, Rule Display Window
- Context Display Window, Class Display Window, Rule Editing Window
- Notebook
- Rule DW, Context DW, Class DW
- Central Concepts Window
- New KB, Load KB, Save KB, Quit, Help
- Current KB
- Desktop
- Lisp Listener
- Typescript Window
- Prompt Window
- image panels
- User Prompt Panel, Select Mission Panel, Mission Status Panel, AUV Status
  Panel
- KEEspy

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
- Treat the desktop as a review target, not just a browser skin: the Bielefeld
  evaluation suggests a saved/reloadable desktop composed of smaller
  functional windows inside larger KEE windows.
- Treat KEE graphics panels as workflow surfaces, not only pictures: the NPS
  AUV evidence shows prompt panels, selection panels, status panels, and
  ActiveImage-driven actions arranged around task phases.
- Keep the Lisp Listener, Typescript, and Prompt visible as session surfaces
  when a demo needs to evoke interactive use. The current pane is an annotated
  transcript, not evidence of the original window implementation.
- Design tracing views around the recovered categories: rule agenda/conflict
  set, forward/backward/world graphic traces, text traces, and rule
  cross-reference.

`docs/gui-fidelity-matrix.md` keeps the current status and reviewer questions
for these GUI areas in one place.

## Open Questions

- Exact KEE browser menus and pane layout from the KEE User's Guide.
- Exact KEEpictures object hierarchy and constructor API.
- Exact ActiveImages unit/slot layout and event names.
- Exact image-panel constructor, backing Common Windows objects, and lifecycle
  semantics behind `open-panel!` and `close-panel!`.
- Exact Common Windows pane/window APIs used by KEE.
- Whether ASKE's named windows and icons reflect normal KEE/Common Windows
  idioms, application-specific conventions, or a mixture of both.
- Exact desktop save/load model and window vocabulary across Lisp Machine,
  DEC Windows, and Unix/X11 versions.
- Whether KEEspy was commonly available to users or mostly an IntelliCorp
  support/profiling tool.
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
- keeps a slot table synchronized with the selected unit, separating local,
  inherited, combined, and facet values
- keeps graph focus synchronized with hierarchy selection

## Implemented KEEpicture Increment

The reconstruction now has a first object-backed KEEpicture primitive:

- KEEpictures are ordinary KEE units under `kee.pictures`
- picture items are ordinary KEE units contained by their owning picture
- supported item kinds are rectangle, text, slot-value display, and embedded
  ActiveImage reference
- reconstructed viewport and windowpane units can wrap a picture preview
- `picture.mouse.event` records KEEpicture mouse traces and can drive a
  writable embedded ActiveImage through ordinary KEE slot mutation
- `kee.picture.report` exposes a structured picture and current item values
- `kee.picture.svg` renders a small SVG preview for examples and reviewer
  demos
- the standalone viewer embeds KEEpicture reports and shows picture previews
  when a KB has reconstructed picture units

## Implemented Image Panel Increment

The reconstruction now has a first image/workflow panel primitive inspired by
the NPS AUV mission-planning evidence:

- panels are ordinary KEE units under `kee.panels`
- a panel can link to a KEEpicture, viewport, and windowpane
- `create.kee.panel` can wrap a picture in a first viewport/windowpane pair
  when a caller does not provide one
- panel units install `open-panel!`, `close-panel!`, `open!`, and `close!`
  message methods
- opening or closing a panel updates both the panel's `open.p` state and the
  linked windowpane's `open.p` state
- panel open/close messages record structured trace events with panel,
  picture, viewport, windowpane, action, and old/new state
- `kee.panel.report` exposes a structured panel report plus the linked
  picture SVG preview
- the standalone viewer has a Panels Review Tour/Desktop target, an
  image-panel window deck, panel tabs, local open/close controls, open/closed
  state display, SVG previews, and picture-family trace handling for
  `:panel-open` and `:panel-close`
- `examples/auv-panel-workflow.lisp` now provides a small reviewer-facing
  workflow with mission-selection, parameter-entry, and monitoring panels,
  using panel open/close messages, ActiveImage-backed mouse updates, and
  explicit Symbolics/TI provenance cues in the generated desktop context

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
- recorded events include world creation, world slot writes, support-label
  retractions, agenda passes, rule matches/firings, generated branches,
  nogoods, and contradictions
- agenda, activation, and fire provenance IDs connect agenda passes, rule
  matches/firings, and downstream effects
- the standalone viewer includes a Trace pane beside the selected unit or
  world detail
- generated viewer pages can specify an initial view, selected node, and trace
  scope so demos open on historically meaningful review states
- dense generated graphs default to selected-node relation edges, with
  explicit header controls for hiding edges or showing all relations, so
  reviewer screenshots keep structural context without becoming a tangled
  relation diagram
- graph lanes are spaced for relation-arrow readability, and the
  Browser/Inspector rail uses two visually framed scroll panes
- the browser pane includes Review Tour controls that jump to representative
  units, rules, worlds, agenda traces, rule cross-references, and ActiveImages
  when available
- the browser pane includes a compact reconstructed desktop context plus a
  Desktop roster using recovered window vocabulary such as Lisp Listener,
  Typescript, Prompt, KEEpictures, and ActiveImages
- the Lisp Listener, Typescript, and Prompt entries switch a small transcript
  pane so reviewers can see the generated demo as a KEE work session rather
  than only as static graph state
- trace panes can filter by event kind and selected-node scope
- trace panes can also isolate method, rule, world, and problem event families
- trace panes include search text plus previous/next jump controls, with the
  focused trace highlighted
- focused traces show a compact normalized event-detail drilldown
- trace panes include a compact agenda/conflict-set view reconstructed from
  agenda, rule-match, and rule-fire events
- agenda panes can jump among reconstructed candidates or actual fired-rule
  events
- agenda candidates show matched conditions and fired actions inline
- fired agenda candidates show immediate downstream effects such as slot
  writes, support-label retractions, generated branches, nogoods, and
  contradictions
- a provenance-backed causality graph renders agenda -> match -> fire -> effect
  flows
- selected world details render trace-backed why trails for world branches,
  local facts, nogoods, contradictions, and focused trace effects
- selected world details summarize the alternative-world assumptions along the
  selected world's ancestry
- world and nogood detail maps now embed first-pass explicit environment
  records rather than depending only on trace reconstruction
- world fact detail maps embed first-pass current support labels
- focused traces highlight referenced units or worlds in the visible SVG graph,
  including world ancestry paths for focused world/problem traces
- focused trace detail exposes clickable unit/world graph targets
- trace rows expose clickable unit/world references
- a spatial trace map lays out recent agenda/rule/world/problem events in
  lanes
- focused trace-map events emphasize adjacent chronological path segments
- trace-map replay controls step or play through filtered map events, with
  speed, loop, and current-position controls for larger demos
- trace-map events and links emphasize the focused world's generated branch
  path
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

- ATMS-style labels with dependency-directed propagation and retraction
