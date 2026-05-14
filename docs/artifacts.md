# Artifact Ledger

This ledger tracks evidence for reconstructing KEE. It separates original
IntelliCorp artifacts, public code built on KEE, public application code, and
secondary descriptions.

## Ground Rules

- Do not call something "original KEE source" unless it is an IntelliCorp
  distribution or source tree.
- Prefer exact URLs, report numbers, manual numbers, and local filenames.
- Keep implementation code clean-room: use public behavior descriptions and
  public API evidence, not copied proprietary source.
- Short code fragments from public reports are useful as tests, but large
  transcriptions belong in a private research note, not in source files.

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

## Manual Targets

No full scans found yet. These identifiers make the search precise.

| Manual | Identifier |
| --- | --- |
| KEE User's Guide, KEE 3.1 | `K3.1-UG1` |
| KEE Interface Reference Manual | `K3.1-IRM-1`, IBM `SC26-4545` |
| KEE Core Reference Manual | `K3.1-CRM-2` |
| TellAndAsk Reference Manual | `3.1-TAA-2`, IBM `SC26-4549` |
| RuleSystem3 Reference Manual | `K3.1-RS3-2`, IBM `SC26-4548` |
| Rule Compiler Reference Manual | `K3.1-RC-4` |
| KEEworlds Reference Manual | `K3.1-KW-3`, IBM `SC26-4547` |
| ActiveImages3 Reference Manual | `3.0-R-A3` |
| KEEpictures Reference Manual | `K3.1-KP-2`, IBM `SC26-4546` |
| Common Windows Manual | `CWM-2` |
| KEE 4.0 UNIX release notes | `K4.0-RN-UNIX-1` |
| Using KEE 4.0 on UNIX | `K4.0-UK-UNIX-1` |
| KEEtutor modules | `KT-Mods1&2-Sun-3` |

## High-Value Missing Artifacts

- IntelliCorp KEE source or binary distributions.
- KEE 3.0/3.1/4.0 manuals as scans.
- NASA VEG files: `veg4.u`, `veg-methods.lisp`, and extension Lisp files.
- The NASA GSFC Sun cartridge tape mentioned in the VEG reports.
- KEEtutor materials and puzzle files such as `3X3IMPLEM1.U`.

## Local Corpus Leads

These are not original KEE distributions, but they are useful leads in
`/persist/lisp-corpus`:

- `forums/comp.lang.lisp/derived/threads/1992/request-for-info-on-intellicorp-s-kee-tm-97b30a6e2467ffab.md`
  reports that KEE was strong for UI prototyping but difficult for producing a
  standard production-style UI.
- `forums/comp.lang.lisp/derived/threads/1995/faq-lisp-window-systems-and-guis-7-7-872bbbc758d59cc9.md`
  records that KEE 4.0 shipped with Common Windows on Lucid Lisp for Sun, HP,
  and IBM workstations.
- `forums/comp.lang.lisp/derived/threads/1995/q-how-reliable-is-kee-on-solaris-2-x-2b90f4f1ed8fca02.md`
  includes an IntelliCorp reply about KEE 4.1 on Harlequin/Lucid Lisp 4.1.2
  under Solaris 2.3.
- `articles/gabriel/dreamsongs.com-derived/pdf-text/Files/HOPL2-Uncut.pymupdf.txt`
  identifies Common Windows as a window system produced by IntelliCorp.
- `articles/lisp-pointers-derived/pdf-extracts/text/pub__scheme__doc__lisp-pointers__v1i3__p43-foderaro.pymupdf.txt`
  discusses IntelliCorp's Common Windows specification in the context of X,
  NeWS, color, and networked window systems.
