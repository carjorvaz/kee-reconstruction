# GUI Fidelity Matrix

This matrix is a reviewer aid. It maps recovered public evidence about KEE's
GUI and debugging environment to the current reconstruction, then names the
next question or implementation target.

Status meanings:

- `implemented` - present as runnable behavior in this repo
- `approximated` - present in spirit, but not yet historically faithful
- `missing` - not implemented yet
- `unknown` - evidence is too thin to claim behavior

| Area | Evidence | Current status | Reviewer question | Next action |
| --- | --- | --- | --- | --- |
| Knowledge-base browser | NASA VEG describes a KB menu, Current KB box, top-level unit menu, hierarchy browsing, slot display, and broader KEE desktop/window vocabulary. | `approximated` | Did KEE's browser feel pane-oriented, menu-oriented, graph-oriented, desktop-window-oriented, or some combination? | Refine viewer/browser pane layout around remembered browser workflows, including the reconstructed Desktop and session transcript panes. |
| Class/member hierarchy | CLOS-on-KEE and NASA VEG expose class/subclass/member idioms and browsing. | `implemented` | Are relation names and displayed hierarchy directions right? | Add relation-specific filters and parent/child jump affordances if confirmed. |
| Slot/facet inspection | Patent and application reports emphasize local, inherited, and combined values plus facets. | `implemented` | Are the local/inherited/combined/facet columns historically plausible? | Adjust column labels, ordering, or facet expansion after reviewer feedback. |
| Common Windows | ASKE and local Lisp history identify Common Windows as IntelliCorp/KEE UI substrate. | `missing` | Which Common Windows concepts were visible to application developers? | Collect API names and decide whether McCLIM or browser layout should model pane/window concepts. |
| KEEpictures | AIAI and NASA TEXSYS/MTK describe mouse/menu graphics, graphical model-building, and slot-driven animation. | `approximated` | What did editing a KEEpicture look like? | Grow the object-backed picture model from viewport/windowpane and mouse-event traces toward editor behavior after reviewer feedback. |
| ActiveImages | AIAI describes two-way graphics: object updates redraw graphics, mouse changes update objects. | `approximated` | Which widgets were common, and how were mouse edits represented in slots? | Expand from HTML widgets to object-backed picture items with event traces. |
| ActiveValues | Hamburg slides and existing implementation support read/write/add/remove hooks. | `implemented` | Were hook names and ordering visible or mostly internal? | Add delete/copy/rename demons after evidence improves. |
| Rule agenda/conflict-set viewer | AIAI explicitly lists an agenda viewer and debugging information. | `approximated` | What columns, controls, and ordering did the real agenda viewer use? | Replace compact reconstructed agenda with a more faithful table/pane if details emerge. |
| Textual traces | AIAI lists textual traces. | `implemented` | What trace terms or event names are historically wrong? | Rename reconstructed trace labels only when evidence supports it. |
| Lisp Listener / Typescript / Prompt | Bielefeld describes a desktop with Lisp Listener, Typescript, and Prompt windows. | `approximated` | Which prompts, transcript behavior, and window roles are historically wrong or missing? | Replace the static transcript pane with a more faithful listener/typescript model after expert feedback or manual evidence. |
| Graphic traces | AIAI lists dynamic graphic traces for rules/worlds. | `approximated` | Did graphic traces emphasize rules, worlds, dependencies, or object graphics? | Use reviewer feedback to choose trace-map versus dependency-graph direction. |
| Rule cross-referencer | AIAI lists a rule cross-referencer. | `approximated` | Was it organized by rule, slot, unit, rule class, or all of these? | Add cross-reference views that match remembered organization. |
| KEEworlds UI | Hamburg slides and patents describe worlds, assumptions, nondeletion/deletion assumptions, nogoods, and ATMS behavior. | `approximated` | How did users inspect worlds, assumptions, and contradictions? | Finish active nogood/retraction behavior and improve world-detail panes. |
| TellAndAsk / RuleSystem syntax | Hamburg slides and NASA VEG reports show rule forms, `external.form`, `parse`, and `BELIEVE FALSE`. | `approximated` | Which syntax variants are missing or wrong? | Grow parser from the recovered examples outward. |
| Lisp Machine feel | User goal includes TI Lisp Machine and KEE first-hand review. | `unknown` | What interaction style is TI-specific rather than generic KEE? | Add a dated notes section after expert feedback. |

## Current Demo Coverage

The standalone Hamburg puzzle viewer now opens on a generated inconsistent
world. It intentionally foregrounds:

- KEEworlds branching
- local world facts
- support labels and active assumptions
- nogood explanations
- rule agenda reconstruction
- trace map and causality graph

The Review Tour controls in the viewer jump among units, rules, worlds, agenda
traces, rule cross-references, and ActiveImages when those targets exist in the
loaded demo.

The compact Desktop roster now also switches between reconstructed Lisp
Listener, Typescript, and Prompt transcript panes for the generated session.

## Highest-Value Reviewer Corrections

- Which visible panes are missing from the first impression?
- Which labels are modern inventions and should be renamed?
- Which interactions should be mouse/menu operations instead of graph clicks?
- Which parts of the current viewer feel actively unlike KEE?
- What small demo would best evoke a real KEE work session?
