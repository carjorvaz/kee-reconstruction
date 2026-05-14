# Provenance Policy

This project should be useful to people who remember KEE, but it must stay
honest about what it is.

## What This Repository Is

- A clean-room, evidence-led reconstruction of selected KEE behavior.
- A running Common Lisp prototype guided by public manuals, papers, patents,
  application reports, recovered API names, and user-visible behavior.
- A place to keep the reconstruction process legible: evidence, uncertainty,
  tests, demos, and design choices should be visible in the repo.

## What This Repository Is Not

- It is not original IntelliCorp KEE source.
- It is not a full clone of the commercial product.
- It is not a substitute for original manuals or binaries if those are later
  recovered.

## Material Handling

- Track public leads in `docs/artifacts.md` with URLs, identifiers, report
  numbers, local corpus paths, and notes.
- Check in generated screenshots and small repo-native artifacts under
  `docs/assets/`.
- Check in redistributable reference material only when rights are clear.
- Do not commit proprietary source trees, binary distributions, manual scans,
  or large copied excerpts unless redistribution permission is established.
- For non-redistributable material, keep a citation, checksum, location note,
  and short summary instead of the material itself.

## Agent Disclosure

This repository is being developed collaboratively by Carlos Vaz and OpenAI
Codex. Codex has generated substantial portions of the implementation,
documentation, scripts, and tests under human direction. The reconstruction
standard is evidence plus verification, not authorship by hand.
