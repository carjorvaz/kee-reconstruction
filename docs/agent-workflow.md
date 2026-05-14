# Agent Workflow

This repo follows a lightweight version of the "harness engineering" style
described by OpenAI: keep repository knowledge local, structured, and
executable so agents and humans can both navigate the project.

Source: https://openai.com/index/harness-engineering/

## Local Principles

- `AGENTS.md` is a map, not a manual.
- `docs/` is the system of record for evidence, uncertainty, design direction,
  and demo instructions.
- Scripts provide repeatable feedback loops: test, render, screenshot, inspect.
- Generated screenshots are allowed when the command that produced them is
  checked in.
- Small commits are preferred. Each should move evidence, behavior, or
  presentation forward without hiding uncertainty.

## Current Feedback Loops

```sh
scripts/smoke.sh
scripts/render-demo.sh
scripts/screenshot-demo.sh
```

Future useful loops:

- browser-driven assertions over the generated viewer
- screenshot comparison for the demo surface
- a doc ledger check for artifacts and missing manual identifiers
- an expert-review checklist that can be updated after conversations
