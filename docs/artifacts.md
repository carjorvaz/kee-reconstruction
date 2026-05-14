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

## Strong Evidence

| Artifact | Why it matters | Source |
| --- | --- | --- |
| CLOS-on-KEE | Public Lisp code that runs on KEE and exposes real API names such as `create.unit`, `create.slot`, `get.value`, `put.value`, `unitmsg`, and relation functions. | https://www.cs.cmu.edu/afs/cs/project/ai-repository/ai/lang/lisp/oop/clos/kee/0.html |
| NASA VEG report B921020-U-2R00 | Large appendix listings from a real KEE application: dynamic unit creation, file import/export, ActiveImages panes, custom browser, rules, and `unitmsg` usage. | https://ntrs.nasa.gov/citations/19930007502 |
| NASA VEG report C931021-U-2R07 | Add-techniques interface. Shows KEE rule creation, `external.form`, parse checks, and user-driven extension of a KEE app. | https://ntrs.nasa.gov/citations/19930015965 |
| NASA VEG report C931033-U-2R00 | Later VEG summary. Confirms `veg4.u`, `veg-methods.lisp`, extra Lisp files, Help System, and delivery on Sun cartridge tape. | https://ntrs.nasa.gov/citations/19940015811 |
| Hamburg KEE 3.0 slides | Training slides for KEE concepts, including units, slots, rules, TellAndAsk, ActiveValues, ActiveImages, KEEpictures, KEEworlds, and a 3-by-3 puzzle example. | https://www.chai.uni-hamburg.de/~moeller/symbolics-info/kee.html |
| US4675829A | IntelliCorp patent for KEE-style slot inheritance using local, inherited, and combined values. | https://patents.google.com/patent/US4675829A/en |
| US4918621A | IntelliCorp patent for representing a DAG of worlds using an ATMS. | https://patents.google.com/patent/US4918621A |
| SimKit WSC 1989 paper | Describes an application framework built in/on KEE, especially the graphics/model-builder pattern. | https://repository.lib.ncsu.edu/items/461ffbbe-1936-47f6-8f33-66309300547b |
| AIAI expert-system toolkit survey | Describes KEE's development environment: schema/KB browser, mouse/menu KEEpictures graphics, ActiveImages, TellAndAsk, agenda viewer, graphic traces, textual traces, and rule cross-referencer. | https://www.aiai.ed.ac.uk/publications/documents/1990-PRE/88-esmed-toolkits.pdf |
| AIAI user-interface paper | Describes KEEpictures and ActiveImages as a two-way graphical specification mechanism: mouse changes update objects and object updates reflect in graphics. | https://www.aiai.ed.ac.uk/publications/documents/1992/92-bcs-user-interfaces.pdf |
| ASKE thesis | KEE 3.1 application evidence for Common Windows interfaces with icons, interaction/display windows, notebook, rulemaker, context/class/rule display windows, and rule editing window. | https://oro.open.ac.uk/64573/1/27758423.pdf |
| NASA TEXSYS/MTK conference paper | Application evidence for KEE v2/v3 on Symbolics, KEEpictures as flexible graphics, KEEworlds for temporal/hypothetical states, and graphical model-building. | https://ntrs.nasa.gov/api/citations/19880014804/downloads/19880014804.pdf |
| NASA KATYDID / KEE-to-Ada paper | Primary NASA/IntelliCorp evidence for KEE delivery concerns: a KEE object-structure runtime library for Ada, knowledge-structure translation, rules translation, Lisp-to-Ada translation, and a knowledge-base dumper. Useful for reconstruction boundaries, though not original KEE source. | https://ntrs.nasa.gov/citations/19900018018 |
| Bielefeld hybrid expert-system tools evaluation | 1993 public evaluation with a KEE chapter. Records architecture from the KEE User's Guide, supported Unix platforms, desktop/window behavior, ActiveValues slot-operation triggers, and a useful KEE manual bibliography. | https://doczz.net/doc/5911786/evaluation-hybrider-expertensystemtools |
| IBM System/370 bibliography, January 1990 | IBM publication catalog entries for IBM KEE manuals. Confirms IBM publication numbers, page counts, and concise descriptions for TellAndAsk, KEEpictures, KEEworlds, and RuleSystem3. | https://chiclassiccomp.org/docs/content/computing/IBM/Mainframe/AppSoftware/GC20-0370-7_System370-30xx-4300-9370BibliographySystem%26AppPrograms_Jan90.pdf |

## Manual Targets

No full scans found yet. These identifiers make the search precise.

| Manual | Identifier | External evidence |
| --- | --- | --- |
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
- `docs/reviewer-packet.md` - short guided path for first-hand KEE and Lisp
  Machine reviewers.
- `docs/demo.md` - reproducible commands for generating the interactive HTML
  demo and screenshot.
- `docs/expert-review.md` - prompts for collecting first-hand review from KEE
  and Lisp Machine users.

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
