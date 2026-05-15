# KEE Reachable Source Dossier

Last audited: 2026-05-15.

This dossier is the broad source inventory for IntelliCorp's Knowledge
Engineering Environment (KEE). It is meant to answer: what can we actually
reach from public web sources, public archives, and a private local corpus, and
what still appears to be missing?

This is not a claim of completion. It is a dated search state. The important
result so far is that we have found a strong public behavioral record, many
application-level code listings and product references, and no original
IntelliCorp KEE source tree, binary distribution, or full manual scans.

## Confidence Key

- Confirmed artifact: primary public source, public code, patent, report, or
  local corpus item with enough metadata to revisit.
- Strong lead: public citation or trade report that identifies a target, but
  does not itself give the full artifact we want.
- Missing target: named artifact searched for but not found in redistributable
  form.

## Bottom Line

Confirmed:

- Public KEE-using Lisp code exists: CLOS-on-KEE.
- Public NASA and thesis appendices expose application-level KEE APIs, rule
  forms, ActiveValues, ActiveImages, KEEpictures, image panels, KEEworlds, and
  Common Lisp integration patterns.
- Public papers and patents describe KEE's frame/unit model, slot inheritance,
  procedural attachment, active values, rule representation, KEEworlds, ATMS,
  database mapping, and GUI/application surface.
- Public trade and newsgroup material covers platforms, product modules,
  runtime delivery, Common Windows, KEE/C, KEEspy, KEEtutor, and late KEE 4.x
  support.

Not found:

- Original IntelliCorp/IntelliGenetics KEE source.
- Original KEE binary media.
- Full KEE 2.x/3.x/4.x manual scans.
- KEEtutor media and files.
- NASA-delivered Sun cartridge tapes or raw `.u`/`.lisp` application files
  outside report appendices.

## Primary KEE Sources

| Source | Status | Why it matters |
| --- | --- | --- |
| CLOS-on-KEE | Confirmed artifact | Public Lisp source implementing a subset of CLOS on top of KEE. It exposes real KEE API names such as `create.unit`, `create.slot`, `get.value`, `put.value`, and `unitmsg`. Sources: https://www.cs.cmu.edu/afs/cs/project/ai-repository/ai/lang/lisp/oop/clos/kee/0.html and https://www.osti.gov/servlets/purl/6357501 |
| Kunz, Kehler, Williams, "Applications Development Using a Hybrid Artificial Intelligence Development System" | Confirmed artifact | AI Magazine 1984 paper by IntelliCorp authors. Describes KEE as a hybrid environment combining frames, rules, Lisp, interactive graphics, and active values. The AAAI/OJS article page is unstable to curl and to at least one browser path, but DBLP and OpenAlex preserve stable bibliographic metadata, OpenAlex records DOI `10.1609/aimag.v5i3.447`, and AITopics preserves a dedicated document page plus the issue/search entry and abstract. Sources: https://ojs.aaai.org/aimagazine/index.php/aimagazine/article/view/447, https://dblp.org/rec/journals/aim/KunzKW84, https://doi.org/10.1609/aimag.v5i3.447, https://api.openalex.org/works/W2736597073, https://aitopics.org/doc/journals:D1F88CDE, and https://aitopics.org/search?cdid=news%3AE8758EAD&dimension=concept-tags&filters=modified%3A%5B1980-01-01T00%3A00%3A00Z+TO+1985-01-01T00%3A00%3A00Z%7D&start=20 |
| Fikes and Kehler, "The Role of Frame-Based Representation in Reasoning" | Confirmed artifact | CACM 1985 paper by IntelliCorp authors. Describes KEE frames/units, methods, active values, and rules-as-frames in enough conceptual detail to guide reconstruction. Sources: https://dblp.org/rec/journals/cacm/FikesK85 and https://doi.org/10.1145/4284.4285 |
| Filman, "Reasoning with Worlds and Truth Maintenance in a Knowledge-Based Programming Environment" | Confirmed artifact | CACM 1988 article on extending KEE with worlds and truth maintenance. Good target for KEEworlds and ATMS behavior. DBLP records DOI `10.1145/42404.42405`; OpenAlex preserves metadata and reports an ACM PDF location, but ACM/Cloudflare blocks curl from this environment. Sources: https://cacm.acm.org/research/reasoning-with-worlds-and-truth-maintenance-in-a-knowledge-based-programming-environment/, https://dblp.org/rec/journals/cacm/Filman88, https://doi.org/10.1145/42404.42405, https://api.openalex.org/works/doi:10.1145/42404.42405, and https://citeseerx.ist.psu.edu/document?doi=3a6acacb32bbc48ff773481e45681824c5d14a32&repid=rep1&type=pdf |
| US4675829A | Confirmed artifact | IntelliCorp patent on KEE-style local, inherited, and combined slot values. Source: https://patents.google.com/patent/US4675829A/en |
| US4918621A | Confirmed artifact | IntelliCorp patent on representing a directed acyclic graph of worlds with an ATMS, including world assumptions, nondeletion assumptions, deletion nogoods, inconsistent worlds, and merged worlds. Source: https://patents.google.com/patent/US4918621A |
| US4930071A | Confirmed artifact | IntelliCorp patent for integrating a knowledge-based system with an arbitrary relational database. This appears to be the KEEconnection family of ideas: class maps, slot maps, translating KB queries to database queries, materializing database data as units, and writing KB changes back. Source: https://patents.google.com/patent/US4930071A/en |
| US5313636A | Strong lead | IntelliCorp patent on "mosaic objects" for optimizing object representation performance. It is later than classic KEE but names IntelliCorp object representation optimization and cites US4930071A. Source: https://patents.google.com/patent/US5313636A/en |
| Computer Chronicles, "Artificial Intelligence" episode | Confirmed artifact | 1984 public video. Archive metadata names Tom Kehler of IntelliGenetics and AI demonstrations; Thomas Kehler's public page identifies this as a KEE demonstration around the fourteen-minute mark. Useful for GUI/demo feel, not API details. Sources: https://archive.org/details/CC1024_artificial_intelligence, https://archive.org/metadata/CC1024_artificial_intelligence, https://archive.org/download/CC1024_artificial_intelligence/CC1024_artificial_intelligence.mp4, https://archive.org/download/CC1024_artificial_intelligence/CC1024_artificial_intelligence.autogenerated.txt, and https://thomaskehler.com/ |

## Manuals And Documentation Targets

No full scans have surfaced. These identifiers should stay searchable and
machine-readable in the repo.

| Target | Identifier or evidence | Status |
| --- | --- | --- |
| KEE Software Development System User's Manual, KEE 2.1 | IntelliCorp, 1985; cited by Space Station/NPS-style bibliographies | Missing target |
| KEE Software Development System User's Manual, KEE 3.0 | `3.0-U-1`; IntelliCorp, 1986; cited by simulation and patent literature | Missing target |
| KEE Users' Guide, KEE 3.1 | `K3.1-UG1`; May 1988; Bielefeld title form is `Users' Guide` | Missing target |
| KEE Interface Reference Manual | `K3.1-IRM-1`, IBM `SC26-4545` | Missing target |
| KEE Core Reference Manual | `K3.1-CRM-2`; 1986/1989 citations in literature | Missing target |
| TellAndAsk Reference Manual | `3.1-TAA-2`, IBM `SC26-4549` | Missing target |
| Rule System / RuleSystem3 Reference Manual | `K3.1-RS3-2`, IBM `SC26-4548` | Missing target |
| Rule Compiler Reference Manual | `K3.1-RC-4` | Missing target |
| KEEworlds Reference Manual | `K3.1-KW-3`, IBM `SC26-4547` | Missing target |
| ActiveImages3 Reference Manual | `3.0-R-A3`, November 1986 | Missing target |
| KEEpictures Reference Manual | `K3.1-KP-2`, IBM `SC26-4546` | Missing target |
| Common Windows Manual | `CWM-2`; 1986/1989 evidence | Missing target |
| System Indices | `K3.1-SI-1` | Missing target |
| KEE 4.0 Release Notes | `K4.0-RN-UNIX-1`, February 1991 | Missing target |
| Using KEE 4.0 on a UNIX Workstation | `K4.0-UK-UNIX-1`, February 1991 | Missing target |
| Wolf and Setzer, `Wissensverarbeitung mit KEE` | German KEE book; Oldenbourg, Munich/Vienna, 1991; ISBN `3-486-21407-1` / `978-3-486-21407-9` | Missing target |
| KEEtutor: A Basic Course (Module 1-12) | `KT-Mods1&2Sun-3`; KEEtutor for KEE 3.1 also reported in 1989 Canadian AI news as a $5,000 package with videotapes, software, and tutorial modules | Missing target |
| IBM KEE publication set | IBM bibliography lists `SC26-4545` through `SC26-4549` and `GC26-4578` for KEE licensed program specs | Missing target |

Manual evidence sources:

- Bielefeld 1993 KEE evaluation:
  https://doczz.net/doc/5911786/evaluation-hybrider-expertensystemtools
- IBM System/370 bibliography, January 1990:
  https://chiclassiccomp.org/docs/content/computing/IBM/Mainframe/AppSoftware/GC20-0370-7_System370-30xx-4300-9370BibliographySystem%26AppPrograms_Jan90.pdf
- KEEtutor news lead:
  https://www.caiac.ca/sites/default/files/shared/canai-archives/CAI%20Volume%2019%20-%20April%201989.pdf
- DNB catalog record for Wolf/Setzer `Wissensverarbeitung mit KEE`:
  https://services.dnb.de/sru/dnb?version=1.1&operation=searchRetrieve&query=tit%3D%22Wissensverarbeitung%20mit%20KEE%22&recordSchema=MARC21-xml&maximumRecords=10
- EMA-XPS literature page citing Wolf/Setzer:
  https://ema-xps.org/de/lit.html
- SLUB catalog search result listing Wolf/Setzer:
  https://katalog.slub-dresden.de/?tx_find_find%5Bq%5D%5Btopic%5D%5B0%5D=%22Expertensystem%22+%22Systementwicklung%22+

## Product Family And Platform Leads

| Product or platform | Status | Evidence |
| --- | --- | --- |
| KEE core development environment | Confirmed | Released in 1983 by IntelliCorp/IntelliGenetics according to multiple public references and Tom Kehler's page. |
| Lisp machine KEE | Confirmed | Symbolics evidence appears in NASA TEXSYS/MTK, PROTAIS, KATYDID, and NPS work. TI Explorer evidence appears in ASKE, SLED, Unisys/TI trade reports, and NPS delivery plans. Xerox D-machine support appears in trade/newsgroup leads. |
| Unix/X11 KEE 4.x | Confirmed | Bielefeld reports Sun SPARC, HP 700/800, HP 300/400, and IBM RS/6000 platforms. Local comp.lang.lisp posts report KEE 4.0/4.1 on Lucid Lisp, SunOS/Solaris, HP, and IBM. |
| IBM mainframe KEE | Confirmed lead | IBM bibliography lists KEE manual publication numbers and licensed program specifications. A 1990 social-science expert-system overview mentions MVS pricing and runtime licensing. |
| 80386 / PC delivery | Strong lead | 1987 and 1988 trade reports describe RunTime KEE on 80386 AT-class machines and PC-Host delivery. |
| KEEconnection | Confirmed lead | Trade reports, the US4930071A patent, and product ads describe mapping SQL relational databases to KEE units/classes/slots. |
| IntelliScope / KEEscope | Strong lead | Trade reports use both names around KEEconnection-era database browsing/analysis products. Treat the exact naming and chronology as unresolved until original product sheets are found. |
| SimKit | Confirmed | WSC 1989 and simulation literature describe a KEE-based simulation/model-building toolkit. Sources: https://repository.lib.ncsu.edu/items/461ffbbe-1936-47f6-8f33-66309300547b and https://repository.lib.ncsu.edu/server/api/core/bitstreams/cb002efb-ed92-4043-be36-e73391aaa704/content |
| KEE/C Integration Kit | Strong lead | 1987 DECUS/bitsavers trade report and 1989 IntelliCorp ad mention C integration for KEE applications. |
| KEEspy | Strong lead | Local 1989 comp.lang.lisp thread identifies KEEspy as a paid IntelliCorp profiler derived from an in-house Lisp Machine profiler. |
| J-KEE | Strong lead | 1988 CSK/IntelliCorp trade report mentions a Japanese version of KEE. |
| KEEtutor | Strong lead | Bielefeld and Canadian AI news identify a training package for KEE 3.1; no media found. |
| Common Windows | Confirmed | Bielefeld, local Common Windows threads, HOPL2 local corpus, and Lisp FAQ material tie Common Windows to IntelliCorp and KEE 4.0. |
| ActiveEquations, KEElink, ActiveGantt, Relations Editor | Strong lead | 1989 IntelliCorp ad lists these as product/services names; more evidence needed before modeling. |

Trade/product sources:

- KEEconnection and IntelliScope:
  https://www.techmonitor.ai/technology/intellicorp_marries_sql_query_language_to_its_kee
- CSK/J-KEE:
  https://www.techmonitor.ai/technology/intellicorp_extends_marketing_agreement_with_csk
- RunTime KEE on 80386:
  https://www.techmonitor.ai/technology/intellicorp_demonstrates_80386_version_of_knowledge_engineering_envirinment
- Unisys/TI Explorer/PC-Host:
  https://www.techmonitor.ai/technology/unisys_corp_adds_texas_explorer_ii_to_its_knowledge_systems_product_line
- Apollo/KEE marketing:
  https://www.techmonitor.ai/hardware/apollo_announces_eight_new_artificial_intelligence_pacts
- Kappa/ProKappa transition and KEE 4.0 color X Window note:
  https://www.techmonitor.ai/technology/intellicorps_kappa_ranges_will_take_it_into_the_corporate_case_market/
- DECUS 1987 bitsavers trade mention of Run-Time KEE and KEE/C:
  https://bitsavers.org/pdf/dec/decus/DECUS_SIG_Newsletters/DECUS_US_Chapters_SIG_Newsletters_V03_N01_Sep1987.pdf
- 1989 IntelliCorp product ad:
  https://citeseerx.ist.psu.edu/document?doi=3e62c45a2ef3c39120e1e7d5b8ece12364ce223e&repid=rep1&type=pdf
- 1990 pricing lead:
  https://journals.sagepub.com/doi/10.1177/089443939000800304

## GUI-Specific Evidence

The GUI is central, not decorative. KEE's historical appeal included live
browsers, KEEpictures, image panels, Common Windows, ActiveImages, trace
surfaces, and Lisp Machine interaction.

Confirmed sources:

- AIAI toolkit survey describes schema/KB browser, KEEpictures, ActiveImages,
  TellAndAsk, agenda viewer, graphic traces, textual traces, rule
  cross-referencer, Lisp debugger, Emacs, and mouse/menu graphics:
  https://www.aiai.ed.ac.uk/publications/documents/1990-PRE/88-esmed-toolkits.pdf
- AIAI user-interface paper describes ActiveImages as two-way graphical
  specification objects connecting graphics and object slots:
  https://www.aiai.ed.ac.uk/publications/documents/1992/92-bcs-user-interfaces.pdf
- Hamburg KEE 3.0 slides show training vocabulary for units, slots, rules,
  TellAndAsk, ActiveValues, ActiveImages, KEEpictures, KEEworlds, and a
  3-by-3 puzzle:
  https://www.chai.uni-hamburg.de/~moeller/symbolics-info/kee.html
- Bielefeld describes KEE's desktop as one or more large windows containing
  smaller functional windows: Lisp Listener, Typescript, Prompt, KB/unit/slot
  windows, configurable desktops, KEEpictures, ActiveImages, fonts, colors,
  save/reload behavior, and X11 issues:
  https://doczz.net/doc/5911786/evaluation-hybrider-expertensystemtools
- ASKE thesis gives KEE 3.1 / TI Explorer / Common Windows evidence with
  icons, Interaction Window, Notebook, Display Window, Rulemaker, Context,
  Class, Rule Display, and Rule Editing windows:
  https://oro.open.ac.uk/64573/1/27758423.pdf
- NPS AUV mission-planning thesis gives Symbolics 3675 and planned TI
  Micro-Explorer evidence for mouse-driven KEE graphics image panels,
  mission-selection panels, parameter-entry panels, status panels, and panel
  lifecycle messages:
  https://hdl.handle.net/10945/23457
- NASA SLED gives TI Explorer + KEE 2.1 evidence for KEE-Bitmaps, electrical
  schematics, ActiveValues, mouse-click information access, and tools for
  non-programmers to define diagnostic procedures and schematics:
  https://ntrs.nasa.gov/api/citations/19890017222/downloads/19890017222.pdf
- NASA TEXSYS/HITEX/MTK sources give Symbolics + KEE 2/3/3.1 evidence for
  KEEpictures, KEEworlds, ActiveValues, schematics, dynamic windows, and
  real-time data integration:
  https://ntrs.nasa.gov/api/citations/19880014804/downloads/19880014804.pdf
  and https://ntrs.nasa.gov/api/citations/19940009516/downloads/19940009516.pdf

Current reconstruction implication: screenshots in the README make sense, but
they should be presented as clean-room reviewer surfaces. The web UI itself no
longer needs to announce "reconstructed" in every panel; the README and
provenance docs carry that disclosure.

## Public Application Sources With KEE Evidence

These are the most useful non-manual sources because they expose concrete
applications, and several include appendices or code fragments.

### NASA VEG / VEGetation Workbench

VEG is currently the richest public application trail for KEE GUI and API
behavior. It used KEE units in `veg4.u`, Lisp methods in `veg-methods.lisp`,
additional extension Lisp files, browser extensions, rule creation, add-technique
interfaces, and Sun cartridge tape delivery.

Known public VEG sources:

| NASA ID | Report or paper | Why it matters |
| --- | --- | --- |
| `19930063758` | "New developments of a knowledge based system (VEG) for inferring vegetation characteristics" | 1992 conference overview: knowledge-based system, browsing/plotting/analyzing spectral data, learning/classification. https://ntrs.nasa.gov/citations/19930063758 |
| `19930007498` | "The learning system (tasks C and D)" | KEE-developed learning system, menu/window/mouse interface, file management, classification workflow. https://ntrs.nasa.gov/citations/19930007498 |
| `19930007502` | "An expert system shell for inferring vegetation characteristics" | Large appendix listing; confirms `veg4.u`, `veg-methods.lisp`, KEE units, learning, browser extension, interfaces, and Sun cartridge tape delivery. https://ntrs.nasa.gov/citations/19930007502 |
| `19930017883` | "Changes to the historical cover type database (Task F)" | External flat-file database interface; data loaded into KEE units; Sun cartridge tape with KEE/Common Lisp code. https://ntrs.nasa.gov/citations/19930017883 |
| `19930015965` | "Interface for the addition of techniques (Task H)" | Add-technique UI, user-provided Common Lisp functions, new rule units, parse checks, separate extension storage, Appendix A code. https://ntrs.nasa.gov/citations/19930015965 |
| `19940011058` | "Atmospheric techniques (Task G)" | New subgoal category and interface/framework for atmospheric techniques. https://ntrs.nasa.gov/citations/19940011058 |
| `19940006764` | "Prototype help system (Task I)" | HELP.SYSTEM loaded from toolbox menu; interactive help authoring tied to VEG screens. https://ntrs.nasa.gov/citations/19940006764 |
| `19940015811` | Later VEG summary | Consolidates second-year changes and repeats `veg4.u`, `veg-methods.lisp`, extension files, Help System, and Sun cartridge delivery. https://ntrs.nasa.gov/citations/19940015811 |
| `19940030553` | "VEG: An intelligent workbench for analysing spectral reflectance data" | 1994 conference summary of VEG's intelligent workbench framing, rule-based technique choice, interface, and learning system. https://ntrs.nasa.gov/citations/19940030553 |

Missing VEG targets:

- `veg4.u`
- `veg-methods.lisp`
- Add-techniques Lisp/rule files outside report appendices
- Historical database flat files
- Help System files
- NASA GSFC Sun cartridge tapes

### NASA / Space And Engineering Applications

| Source | Status | Why it matters |
| --- | --- | --- |
| TEXSYS / Model Toolkit | Confirmed | KEE v2/v3 on Symbolics; KEEpictures for graphics, KEEworlds for temporal/hypothetical states, ActiveValues for data access, model-building with topology objects. Sources: https://ntrs.nasa.gov/api/citations/19880014804/downloads/19880014804.pdf and https://ntrs.nasa.gov/api/citations/19880006115/downloads/19880006115.pdf |
| HITEX / Thermal Expert System | Confirmed | Symbolics Common Lisp Genera 7.2 + IntelliCorp KEE 3.1; Schematic Tool Kit, dynamic data display, runtime HITEX using color KEE pictures and dynamic windows. Source: https://ntrs.nasa.gov/api/citations/19940009516/downloads/19940009516.pdf |
| SLED / Spacelab Life Sciences electrical diagnostic system | Confirmed | TI Explorer + KEE 2.1; KEE units, KEE-Bitmaps, ActiveValues, mouse-driven schematics, multiple-fault windows, recovery procedures, user-facing explanation. Source: https://ntrs.nasa.gov/api/citations/19890017222/downloads/19890017222.pdf |
| KATYDID / KEE-to-Ada | Confirmed | Clean-room boundary source for KEE runtime semantics: object creation, inheritance links, slot values, active values, inheritance roles, KB dumping/translation, rule translation. Source: https://ntrs.nasa.gov/citations/19900018018 |
| PROTAIS | Confirmed lead | Symbolics + Common Lisp + KEE; units grouped as masters/problems/runs and KEE used for KBS data structures. Source: https://ntrs.nasa.gov/api/citations/19880016743/downloads/19880016743.pdf |
| Space Station scheduler prototype | Confirmed lead | Symbolics 3620 + KEE v2; frames, rules, graphics, object-oriented programming for payload scheduling. Source: https://ntrs.nasa.gov/api/citations/19910017492/downloads/19910017492.pdf |
| Closed-loop life support simulation model | Confirmed lead | KEE 3.0 on Symbolics 3640, ActiveImages, ActiveValues, mouse-sensitive pop-up menus, simulation objects. Source: https://ntrs.nasa.gov/api/citations/19880010622/downloads/19880010622.pdf |
| SPIKE / Hubble scheduling | Confirmed lead | TI Explorer workstations; KEE/ART investigated for scheduling and strategic decision support; later source says a prototype GUI was implemented in KEE Common Windows. Sources: https://ntrs.nasa.gov/api/citations/19900006547/downloads/19900006547.pdf and https://citeseerx.ist.psu.edu/document?doi=bd35919ba6e6b4a23c29b2b2c4ca022178a9071d&repid=rep1&type=pdf |
| POLYMER planner | Confirmed lead | KEE frames, ATMS, extended world hierarchy graph, Explorer trademark note, and Sun port note. Source: https://citeseerx.ist.psu.edu/document?doi=22444680d985565048593538aae6965cc01675d6b&repid=rep1&type=pdf |

### Academic And Industrial Application Leads

| Source | Status | Why it matters |
| --- | --- | --- |
| NPS AUV mission planning | Confirmed | Public thesis with appendix listings and GUI/image-panel evidence on Symbolics 3675 and planned TI Micro-Explorer delivery. Sources: https://hdl.handle.net/10945/23457 and https://upload.wikimedia.org/wikipedia/commons/8/8b/A_Mission_Planning_Expert_System_with_Three-Dimensional_Path_Optimization_for_the_NPS_Model_2_Autonomous_Underwater_Vehicle_%28IA_amissionplanning1094523457%29.pdf |
| ASKE thesis | Confirmed | "Automatic Acquisition of Knowledge" thesis with KEE 3.1 on Unisys/TI Explorer; Common Windows GUI vocabulary, Aske/Rulemaker screenshots, and rule-acquisition workflow. The PDF is visible in browser/search, but curl hits a bot challenge from this environment, so it is a top manual-mirror target. https://oro.open.ac.uk/64573/1/27758423.pdf |
| SIGNAL Expert System | Confirmed | IAAI 1996 report on a professional KEE application later reimplemented to avoid KEE runtime and platform costs; discusses KEE graphics vs Common Windows UI rewrite and KEE/PC maintenance ending. https://cdn.aaai.org/IAAI/1996/IAAI96-283.pdf |
| SimKit WSC paper | Confirmed | KEE-based simulation/model-building toolkit and graphics/model-builder pattern. https://repository.lib.ncsu.edu/items/461ffbbe-1936-47f6-8f33-66309300547b |
| Construction/process planning simulation | Confirmed lead | Cites SimKit manual and KEE Software Development System User's Manual; confirms KEE/SimKit use in resource-oriented simulation. https://www.iaarc.org/publications/fulltext/A_knowledge-based_simulation_system_for_construction_process_planning.PDF |
| Intelligent System Server | Confirmed lead | Cites KEE Core Reference Manual and a KEEConnection technical article; useful for database/KBS integration bibliography. https://ebiquity.umbc.edu/_file_directory_/papers/737.pdf |
| Fault diagnosis NPS/NASA thesis | Confirmed lead | Cites KEE Software Development System User's Manual and Symbolics user docs. https://upload.wikimedia.org/wikipedia/commons/f/fa/A_prototype_fault_diagnosis_system_for_NASA_Space_Station_Power_Management_and_Control._%28IA_prototypefaultdi00hest%29.pdf |

## Surveys, Evaluations, And Secondary Descriptions

| Source | Status | Notes |
| --- | --- | --- |
| AIAI expert-system toolkit survey | Confirmed | One of the strongest GUI/development-environment summaries. https://www.aiai.ed.ac.uk/publications/documents/1990-PRE/88-esmed-toolkits.pdf |
| AIAI UI paper | Confirmed | ActiveImages and two-way graphical interaction. https://www.aiai.ed.ac.uk/publications/documents/1992/92-bcs-user-interfaces.pdf |
| Bielefeld hybrid tools evaluation | Confirmed | Detailed KEE 1993 evaluation, architecture figure from User's Guide, platform list, GUI desktop description, support/maintenance notes, manual bibliography. https://doczz.net/doc/5911786/evaluation-hybrider-expertensystemtools |
| Laurent et al., "Comparative Evaluation of Three Expert System Development Tools: KEE, Knowledge Craft, ART" | Confirmed | Early comparative KEE evaluation in Knowledge Engineering Review. https://www.cambridge.org/core/services/aop-cambridge-core/content/view/008CC6CCEE4436E18688B26647753423/S0269888900000631a.pdf/comparative_evaluation_of_three_expert_system_development_tools_kee_knowledge_craft_art.pdf |
| Mettrey, "An Assessment of Tools for Building Large Knowledge-Based Systems" | Strong lead | AI Magazine 1987 survey cited by many KEE pages and surveys; use when full accessible source is convenient. |
| Expert System Shells FAQ | Confirmed | Lists KEE/ProKappa/Kappa on PCs, workstations, and Lisp machines; mentions ATMS, rule reasoning, OOP, IntelliCorp contact, and CACM worlds article. https://www.cs.cmu.edu/Groups/AI/html/faqs/ai/expert/part1/faq-doc-7.html |
| Lisp FTP Resources FAQ | Confirmed | Lists CLOS-on-KEE as publicly redistributable Lisp software. https://www.cs.cmu.edu/Groups/AI/html/faqs/lang/lisp/part6/faq-doc-3.html |
| DARPA Strategic Computing history | Strong lead | Historical narrative: IntelliGenetics, KEE launch in late 1983, company rename to IntelliCorp, DARPA funding. Treat as context until a stable source is pinned. |
| Enabling Technology for Knowledge Sharing | Confirmed | Names Richard Fikes as a principal architect of KEE. https://userpages.cs.umbc.edu/finin/papers/aim91/ |

## Local Corpus Leads

The private local corpus is useful for platform/product/support reality,
especially late-1980s and 1990s Lisp community memory. Paths below are relative
corpus paths.

Confirmed KEE-specific threads:

- `forums/comp.lang.lisp/derived/threads/1989/kee-commonlisp-profiler-46798607fe8af73a.md`
  identifies KEEspy as a paid IntelliCorp profiler.
- `forums/comp.lang.lisp/derived/threads/1989/query-windowing-environments-with-lisp-eb635414497cb8d9.md`
  says Intellicorp distributed Common Windows on Lisp machines and on top of
  Lucid Lisp window systems.
- `forums/comp.lang.lisp/derived/threads/1991/lisp-programming-in-kee-toolkit-for-graphics-c-integration-a25c92aa4b91613e.md`
  asks about KEE on DEC VAXStation 3100, DEC Windows, KEEpictures, and VMS or
  Ultrix C integration.
- `forums/comp.lang.lisp/derived/threads/1992/request-for-info-on-intellicorp-s-kee-tm-97b30a6e2467ffab.md`
  reports KEE as strong for rapid UI prototyping but hard for standard
  production-style UIs.
- `forums/comp.lang.lisp/derived/threads/1993/lucid-kee-under-solaris-2-2-7d09a7e8d669b896.md`
  includes an IntelliCorp reply about KEE 4.1 alpha on Lucid Lisp under
  Solaris/SunOS.
- `forums/comp.lang.lisp/derived/threads/1993/what-applications-have-been-written-in-lisp-4c344c19455b2847.md`
  includes an IntelliCorp post saying KEE is Common Lisp, had hundreds of
  applications, ran on workstations, IBM mainframes, and Symbolics, and had
  previously run on 386/SCO Unix, TI, and Xerox D machines.
- `forums/comp.lang.lisp/derived/threads/1993/faq-lisp-window-systems-and-guis-7-7-bcfb0b76aad1cb8d.md`
  records KEE 4.0 Common Windows on Lucid 4.0 for Sun, HP, and IBM
  workstations.
- `forums/comp.lang.lisp/derived/threads/1995/q-how-reliable-is-kee-on-solaris-2-x-2b90f4f1ed8fca02.md`
  includes an IntelliCorp reply about KEE 4.1 on Harlequin/Lucid Lisp 4.1.2
  under Solaris 2.3.
- `forums/comp.lang.lisp/derived/threads/1998/common-windows-4ee975ab0b388b6d.md`
  quotes the KEE for Symbolics manual set about the 1986 Common Windows
  Manual, its designers, and Interlisp-D/ZetaLisp lineage.

Useful local book/article leads:

- `books/derived/text/building-problem-solvers.pymupdf.txt`
  notes commercial ATMS use by KEE and ART.
- `books/derived/text/object-oriented-programming-the-clos-perspective.pymupdf.txt`
  cites the IntelliCorp Common Windows Manual.
- `code/mcclim/Documentation/Guided-Tour/guided-tour.bib` and the Quicklisp
  mirror cite the IntelliCorp Common Windows Manual.
- `articles/gabriel/dreamsongs.com-derived/pdf-text/Files/HOPL2-Uncut.pymupdf.txt`
  identifies Common Windows as an IntelliCorp-produced window system.
- `articles/lisp-pointers-derived/pdf-extracts/text/pub__scheme__doc__lisp-pointers__v1i3__p43-foderaro.pymupdf.txt`
  discusses IntelliCorp's Common Windows specification in Lisp window-system
  context.

## Search Trails And Missing Artifacts

These are the most important next searches because they point to material that
would materially improve fidelity.

### Original Source Or Binary

Searched:

- Web search for `IntelliCorp KEE source code`, `Knowledge Engineering
  Environment source code`, `IntelliCorp KEE download Lisp`.
- Archive.org and bitsavers searches for `IntelliCorp KEE manual`,
  `Knowledge Engineering Environment IntelliCorp`, and KEE source/binary terms.
- Private local-corpus targeted searches for KEE/IntelliCorp/product names.

Result:

- No original KEE source tree or binary distribution found.
- Only CLOS-on-KEE public code found, which is code built on top of KEE, not
  KEE itself.

### Manuals

Searched:

- Manual numbers from Bielefeld and IBM: `K3.1-UG-1`, `K3.1-IRM-1`,
  `K3.1-CRM-2`, `K3.1-RS3-2`, `K3.1-KW-3`, `K3.1-KP-2`, `CWM-2`,
  `K4.0-RN-UNIX-1`, `K4.0-UK-UNIX-1`, `SC26-4545` through `SC26-4549`.
- Product/tutorial names: `KEEtutor`, `KT-Mods1&2-Sun-3`, `3X3IMPLEM1.U`.
- Archive.org, bitsavers, Google/web, and local corpus.

Result:

- Manual bibliographic evidence is strong.
- Full scans have not surfaced.

### NASA Media And Application Files

Searched:

- NTRS VEG report families, report numbers, `veg4.u`, `veg-methods.lisp`,
  "Sun cartridge tape", and task identifiers.
- KATYDID/KEE-to-Ada, TEXSYS, HITEX, SLED, PROTAIS, SPIKE, POLYMER.

Result:

- Many reports are public and several include appendices.
- No raw delivered tapes or separate application files found.

### Product Sheets And Demos

Searched:

- `KEEconnection`, `IntelliScope`, `KEEscope`, `KEE/C Integration Toolkit`,
  `RunTime KEE`, `Runtime KEE`, `PC-Host`, `J-KEE`, `KEEspy`,
  `ActiveEquations`, `ActiveGantt`, `KEElink`, `Relations Editor`.

Result:

- Trade/product evidence found.
- Original product sheets, demo disks, ads with screenshots, and manuals remain
  missing.

## Repository Handling

Keep this repository source-clean:

- Store citations, identifiers, summaries, and generated screenshots here.
- Do not check in proprietary source, binary media, full manual scans, or large
  copied excerpts without redistribution permission.
- NASA public-domain reports may be downloaded locally for private research,
  but only check them in when the repo explicitly decides large reference PDFs
  are worth the size and provenance cost.
- Prefer generated, reproducible screenshots in `docs/assets/screenshots/` for
  the README.

## Reconstruction Priorities From This Dossier

1. Make the GUI reviewer path stronger before adding exotic inference features:
   desktop, browser, KEEpicture/image-panel workflows, ActiveImages, trace
   panes, and Common Windows vocabulary are what first-hand users are likely to
   recognize.
2. Keep KEEworlds/ATMS aligned with Filman, US4918621A, KATYDID, Hamburg, and
   Bielefeld; avoid overfitting to the toy puzzle.
3. Use CLOS-on-KEE, KATYDID, VEG, and NPS listings as API regression material:
   names and call shapes should stay stable unless better evidence appears.
4. Treat KEEconnection and KEE/C as later reconstruction modules, but record
   the object/database and foreign-integration boundaries now.
5. Keep asking reviewers for concrete memories: browser pane names, menu
   labels, unit/slot editor behavior, ActiveImage construction, KEEpicture
   editing, desktop save/load, and how a real TI/Symbolics KEE session felt.
