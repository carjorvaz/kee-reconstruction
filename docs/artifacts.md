# Artifact Ledger

This ledger tracks evidence for reconstructing KEE. It separates original
IntelliCorp artifacts, public code built on KEE, public application code, and
secondary descriptions.

## Ground Rules

- Do not call something "original KEE source" unless it is an IntelliCorp
  distribution or source tree.
- Prefer exact URLs, report numbers, manual numbers, and local filenames.
- Keep the repo-local record in this ledger even when the underlying artifact
  cannot be redistributed here.
- Keep implementation code clean-room: use public behavior descriptions and
  public API evidence, not copied proprietary source.
- Short code fragments from public reports are useful as tests, but large
  transcriptions belong in a private research note, not in source files.
- See `docs/provenance-policy.md` before adding raw PDFs, scans, binaries, or
  recovered source.
- See `docs/research-dossier.md` for the broad reachable-source inventory and
  dated search trail.

## Strong Evidence

| Artifact | Why it matters | Source |
| --- | --- | --- |
| CLOS-on-KEE | Public Lisp code that runs on KEE and exposes real API names such as `create.unit`, `create.slot`, `get.value`, `put.value`, `unitmsg`, and relation functions. | https://www.cs.cmu.edu/afs/cs/project/ai-repository/ai/lang/lisp/oop/clos/kee/0.html |
| AI Magazine 1984 KEE paper | Primary IntelliCorp-authored description of KEE as a hybrid environment combining frames, rules, Lisp, interactive graphics, and active values. | https://ojs.aaai.org/aimagazine/index.php/aimagazine/article/view/447; metadata/text fallbacks: https://dblp.org/rec/journals/aim/KunzKW84, https://doi.org/10.1609/aimag.v5i3.447, https://api.openalex.org/works/W2736597073, https://aitopics.org/doc/journals:D1F88CDE, https://aitopics.org/search?cdid=news%3AE8758EAD&dimension=concept-tags&filters=modified%3A%5B1980-01-01T00%3A00%3A00Z+TO+1985-01-01T00%3A00%3A00Z%7D&start=20 |
| Fikes/Kehler CACM 1985 frame paper | Primary IntelliCorp-authored conceptual source for KEE frames/units, methods, active values, and rules represented as frames. | https://dblp.org/rec/journals/cacm/FikesK85 |
| Filman CACM 1988 worlds paper | Primary source for KEEworlds and truth maintenance in KEE. | https://cacm.acm.org/research/reasoning-with-worlds-and-truth-maintenance-in-a-knowledge-based-programming-environment/; metadata fallbacks: https://dblp.org/rec/journals/cacm/Filman88, https://doi.org/10.1145/42404.42405, https://api.openalex.org/works/doi:10.1145/42404.42405 |
| NASA VEG report B921020-U-2R00 | Large appendix listings from a real KEE application: dynamic unit creation, file import/export, ActiveImages panes, custom browser, rules, and `unitmsg` usage. | https://ntrs.nasa.gov/citations/19930007502 |
| NASA VEG task-report family | Adds reachable VEG reports for learning, historical database files, add-techniques UI, atmospheric techniques, Help System, and workbench summaries. | https://ntrs.nasa.gov/citations/19930007498 |
| NASA VEG report C931021-U-2R07 | Add-techniques interface. Shows KEE rule creation, `external.form`, parse checks, and user-driven extension of a KEE app. | https://ntrs.nasa.gov/citations/19930015965 |
| NASA VEG report C931033-U-2R00 | Later VEG summary. Confirms `veg4.u`, `veg-methods.lisp`, extra Lisp files, Help System, and delivery on Sun cartridge tape. | https://ntrs.nasa.gov/citations/19940015811 |
| Hamburg KEE 3.0 slides | Training slides for KEE concepts, including units, slots, rules, TellAndAsk, ActiveValues, ActiveImages, KEEpictures, KEEworlds, and a 3-by-3 puzzle example. | https://www.chai.uni-hamburg.de/~moeller/symbolics-info/kee.html |
| US4675829A | IntelliCorp patent for KEE-style slot inheritance using local, inherited, and combined values. | https://patents.google.com/patent/US4675829A/en |
| US4918621A | IntelliCorp patent for representing a DAG of worlds using an ATMS. | https://patents.google.com/patent/US4918621A |
| US4930071A | IntelliCorp patent for mapping arbitrary relational databases to knowledge-base classes, slots, and units; likely KEEconnection-family evidence. | https://patents.google.com/patent/US4930071A/en |
| SimKit WSC 1989 paper | Describes an application framework built in/on KEE, especially the graphics/model-builder pattern. | https://repository.lib.ncsu.edu/server/api/core/bitstreams/cb002efb-ed92-4043-be36-e73391aaa704/content |
| AIAI expert-system toolkit survey | Describes KEE's development environment: schema/KB browser, mouse/menu KEEpictures graphics, ActiveImages, TellAndAsk, agenda viewer, graphic traces, textual traces, and rule cross-referencer. | https://www.aiai.ed.ac.uk/publications/documents/1990-PRE/88-esmed-toolkits.pdf |
| AIAI user-interface paper | Describes KEEpictures and ActiveImages as a two-way graphical specification mechanism: mouse changes update objects and object updates reflect in graphics. | https://www.aiai.ed.ac.uk/publications/documents/1992/92-bcs-user-interfaces.pdf |
| ASKE thesis | "Automatic Acquisition of Knowledge" thesis and KEE 3.1 application evidence for Unisys/TI Explorer Common Windows interfaces with icons, interaction/display windows, notebook, rulemaker, context/class/rule display windows, and rule editing window. | https://oro.open.ac.uk/64573/1/27758423.pdf |
| NASA TEXSYS/MTK conference paper | Application evidence for KEE v2/v3 on Symbolics, KEEpictures as flexible graphics, KEEworlds for temporal/hypothetical states, and graphical model-building. | https://ntrs.nasa.gov/api/citations/19880014804/downloads/19880014804.pdf |
| NASA SLED papers | TI Explorer + KEE 2.1 evidence for KEE units, KEE-Bitmaps, electrical schematics, ActiveValues, mouse-driven explanation/recovery windows, and non-programmer authoring tools. | https://ntrs.nasa.gov/api/citations/19890017222/downloads/19890017222.pdf |
| NASA KATYDID / KEE-to-Ada paper | Primary NASA/IntelliCorp evidence for KEE delivery concerns: a KEE object-structure runtime library for Ada, knowledge-structure translation, rules translation, Lisp-to-Ada translation, and a knowledge-base dumper. Useful for reconstruction boundaries, though not original KEE source. | https://ntrs.nasa.gov/citations/19900018018 |
| NPS AUV mission-planning thesis | Public KEE application evidence on a Symbolics 3675 Lisp machine, with mouse-driven KEE graphics panels, a KEE knowledge-base figure, Symbolics/SGI integration, appendix source listings, and a planned TI Micro-Explorer delivery configuration. | https://upload.wikimedia.org/wikipedia/commons/8/8b/A_Mission_Planning_Expert_System_with_Three-Dimensional_Path_Optimization_for_the_NPS_Model_2_Autonomous_Underwater_Vehicle_%28IA_amissionplanning1094523457%29.pdf |
| Bielefeld hybrid expert-system tools evaluation | 1993 public evaluation with a KEE chapter. Records architecture from the KEE User's Guide, supported Unix platforms, desktop/window behavior, ActiveValues slot-operation triggers, and a useful KEE manual bibliography. | https://doczz.net/doc/5911786/evaluation-hybrider-expertensystemtools |
| IBM System/370 bibliography, January 1990 | IBM publication catalog entries for IBM KEE manuals. Confirms IBM publication numbers, page counts, and concise descriptions for TellAndAsk, KEEpictures, KEEworlds, and RuleSystem3. | https://chiclassiccomp.org/docs/content/computing/IBM/Mainframe/AppSoftware/GC20-0370-7_System370-30xx-4300-9370BibliographySystem%26AppPrograms_Jan90.pdf |
| Computer Chronicles 1984 AI episode | Public video lead for KEE demonstration feel. Archive metadata names Tom Kehler of IntelliGenetics; Kehler's public page identifies the segment as a KEE demo. | https://archive.org/download/CC1024_artificial_intelligence/CC1024_artificial_intelligence.mp4 |

## Manual Targets

No full scans found yet. These identifiers make the search precise.

| Manual | Identifier | External evidence |
| --- | --- | --- |
| KEE Software Development System User's Manual, KEE 2.1 | unknown | Cambridge Knowledge Engineering Review bibliography cites this 1985 IntelliCorp manual. |
| KEE Software Development System User's Manual, KEE 3.0 | `3.0-U-1` | Simulation literature and patent bibliographies cite the 1986 User's Manual; Xerox US5072412 cites July 25, 1986 pages 2-19 to 2-23. |
| KEE User's Guide, KEE 3.1 | `K3.1-UG1` | Bielefeld bibliography. |
| KEE Interface Reference Manual | `K3.1-IRM-1`, IBM `SC26-4545` | Bielefeld and IBM bibliography. |
| KEE Core Reference Manual | `K3.1-CRM-2` | Bielefeld bibliography; also cited in later database/rule literature. |
| TellAndAsk Reference Manual | `3.1-TAA-2`, IBM `SC26-4549` | IBM bibliography lists a 212-page programmer manual for the TellAndAsk language. |
| RuleSystem3 Reference Manual | `K3.1-RS3-2`, IBM `SC26-4548` | IBM bibliography lists a 188-page programmer manual for forward/backward chaining and debugging. |
| Rule Compiler Reference Manual | `K3.1-RC-4` | Bielefeld bibliography. |
| KEEworlds Reference Manual | `K3.1-KW-3`, IBM `SC26-4547` | IBM bibliography lists a 208-page programmer manual for KEEworlds and ATMS. |
| ActiveImages3 Reference Manual | `3.0-R-A3` | Bielefeld bibliography. |
| KEEpictures Reference Manual | `K3.1-KP-2`, IBM `SC26-4546` | IBM bibliography lists a 390-page programmer manual for the object-oriented KEEpictures graphics toolkit. |
| Common Windows Manual | `CWM-2` | Bielefeld bibliography; local Common Windows citation trails also identify an IntelliCorp 1986 manual. |
| System Indices | `K3.1-SI-1` | Bielefeld bibliography. |
| KEE 4.0 UNIX release notes | `K4.0-RN-UNIX-1` | Bielefeld bibliography. |
| Using KEE 4.0 on UNIX | `K4.0-UK-UNIX-1` | Bielefeld bibliography. |
| KEEtutor modules | `KT-Mods1&2-Sun-3` | Bielefeld bibliography. |

## High-Value Missing Artifacts

- IntelliCorp KEE source or binary distributions.
- KEE 3.0/3.1/4.0 manuals as scans.
- NASA VEG files: `veg4.u`, `veg-methods.lisp`, and extension Lisp files.
- The NASA GSFC Sun cartridge tape mentioned in the VEG reports.
- KEEconnection, IntelliScope/KEEscope, RunTime KEE, PC-Host, KEE/C
  Integration Kit, J-KEE, and KEEspy product sheets or manuals.
- Raw NPS AUV MPES files if separately recoverable from the thesis listing:
  `mpexpert.u`, the `auv-mpes` desktop, `mission3.lisp`, `missions.lisp`, and
  related Symbolics/IRIS communication files.
- KEEtutor materials and puzzle files such as `3X3IMPLEM1.U`.
- KATYDID translator/runtime source or generated Ada examples, if any public
  copies survived outside the NASA paper.

## Repository-Held Artifacts

These are generated or authored inside this repository and are safe to
redistribute with it.

- `docs/assets/screenshots/hamburg-viewer-review.png` - generated screenshot of
  the current standalone Hamburg puzzle viewer, including the reconstructed
  Desktop roster, session transcript pane, and GUI reconstruction surfaces.
- `docs/assets/screenshots/hamburg-viewer-kee-picture.png` - generated
  screenshot of the KEEpicture Review Tour target with viewport/windowpane and
  embedded ActiveImage surfaces visible.
- `docs/assets/screenshots/hamburg-viewer-panels.png` - generated screenshot
  of the Panels Review Tour target with reconstructed image-panel state and
  linked KEEpicture preview visible.
- `docs/assets/screenshots/auv-panel-workflow.png` - generated screenshot of
  the AUV-style panel workflow demo.
- `docs/assets/screenshots/aske-common-windows.png` - generated screenshot of
  the ASKE-style Common Windows / TI Explorer reviewer demo.
- `docs/assets/dumps/delivery.kdump` - generated readable reconstructed KB dump
  for the delivery mini-example; useful for inspecting and loading the
  clean-room dump format.
- `docs/research-dossier.md` - broad reachable-source inventory and dated
  search trail covering web, archive, NTRS, patent, and local-corpus leads.
- `docs/reviewer-packet.md` - short guided path for first-hand KEE and Lisp
  Machine reviewers.
- `docs/demo.md` - reproducible commands for generating the interactive HTML
  demo and screenshot.
- `docs/expert-review.md` - prompts for collecting first-hand review from KEE
  and Lisp Machine users.
- `examples/kb-dump-mini.lisp` - generated reconstruction example inspired by
  KATYDID/VEG delivery evidence; demonstrates readable KB dump/load, not an
  original KEE file format.
- `scripts/render-demo-dump.sh` - regenerates
  `docs/assets/dumps/delivery.kdump` from the same example.

## Local Corpus Leads

These are not original KEE distributions, but they are useful leads in
`/persist/lisp-corpus`:

- `forums/comp.lang.lisp/derived/threads/1992/request-for-info-on-intellicorp-s-kee-tm-97b30a6e2467ffab.md`
  reports that KEE was strong for UI prototyping but difficult for producing a
  standard production-style UI.
- `forums/comp.lang.lisp/derived/threads/1991/lisp-programming-in-kee-toolkit-for-graphics-c-integration-a25c92aa4b91613e.md`
  asks about KEE on a DEC VAXStation 3100 under DEC Windows, KeePictures, and
  VMS or Ultrix C integration.
- `forums/comp.lang.lisp/derived/threads/1989/kee-commonlisp-profiler-46798607fe8af73a.md`
  identifies KEEspy as a paid IntelliCorp profiler derived from an in-house
  Lisp Machine profiling tool.
- `forums/comp.lang.lisp/derived/threads/1993/lucid-kee-under-solaris-2-2-7d09a7e8d669b896.md`
  includes an IntelliCorp reply about KEE 4.1 alpha on Lucid Lisp 4.1Beta
  under Solaris 2.1 and KEE 4.1 for SunOS 4.1.3 on LCL 4.1.
- `forums/comp.lang.lisp/derived/threads/1995/faq-lisp-window-systems-and-guis-7-7-872bbbc758d59cc9.md`
  records that KEE 4.0 shipped with Common Windows on Lucid Lisp for Sun, HP,
  and IBM workstations.
- `forums/comp.lang.lisp/derived/threads/1995/q-how-reliable-is-kee-on-solaris-2-x-2b90f4f1ed8fca02.md`
  includes an IntelliCorp reply about KEE 4.1 on Harlequin/Lucid Lisp 4.1.2
  under Solaris 2.3.
- `forums/comp.lang.lisp/derived/threads/1998/common-windows-4ee975ab0b388b6d.md`
  quotes the KEE for Symbolics manual set about the 1986 IntelliCorp Common
  Windows Manual, its designers, and its Interlisp-D/ZetaLisp lineage.
- `books/derived/text/object-oriented-programming-the-clos-perspective.pymupdf.txt`
  cites the IntelliCorp Common Windows Manual, 1986.
- `code/mcclim/Documentation/Guided-Tour/guided-tour.bib` and the Quicklisp
  mirror of the same file cite the IntelliCorp Common Windows Manual, 1986.
- `articles/gabriel/dreamsongs.com-derived/pdf-text/Files/HOPL2-Uncut.pymupdf.txt`
  identifies Common Windows as a window system produced by IntelliCorp.
- `articles/lisp-pointers-derived/pdf-extracts/text/pub__scheme__doc__lisp-pointers__v1i3__p43-foderaro.pymupdf.txt`
  discusses IntelliCorp's Common Windows specification in the context of X,
  NeWS, color, and networked window systems.
