# Pith — shared outline (writers' contract)

This file is the contract every document in the repo follows. It is kept in
the repo so later contributors write in the same shape.

## What Pith is

**Pith** is a method for reverse engineering an app **you own** in order to
understand it and build a **clean-room** replacement, with an AI coding agent
(Claude Code) doing most of the work and the owner making the decisions.

The name: the pith is the white layer between a fruit's peel and its flesh —
the wall between what you *observed* about someone else's app and what you
*build* yourself.

Audience: a capable Mac user or developer who is **not** a security
professional. Plain language; define terms on first use; no hype.

What Pith is **not** (state this plainly where relevant):
- not an analysis engine, MCP server or capture tool — it uses existing ones;
- not a security, pentest, malware or CTF toolkit;
- not a way to clone and resell someone's product;
- not decompilation or source recovery of any kind;
- never a way to defeat DRM, licence checks, paywalls or certificate pinning, or to
  read data an operating system protects.

## The phases (use these exact numbers and names everywhere)

| # | Phase | Output |
|---|---|---|
| 0 | Scope & consent | `scope.md` (target, ownership, goals, owner-only actions, boundaries) |
| 1 | Static survey | evidence folder from `scripts/re-static.sh`, report §Static |
| 2 | Behaviour | report §Behaviour: what the app does, observed by using it normally on throwaway inputs |
| 3 | Network (optional) | report §Network; an OpenAPI description of *the app's own* documented/observed calls |
| 4 | Report & spec | `report.md` (dirty side) → sanitised `spec.md` (crosses the wall) + `provenance.md` |
| 5 | Clean-room rebuild | a new codebase built only from `spec.md` |
| 6 | Verification | self-tests, end-to-end harness, visual snapshots, multi-agent adversarial review |
| 7 | Package & publish | a signed app bundle, licences honoured, an honest README |

Two sides of the wall:
- **Dirty side** (phases 1–4): may look at the original app. Produces evidence and the report.
- **Clean side** (phases 5–7): sees only `spec.md` and public documentation. Never the
  original binary, its strings, its assets, the report, or the evidence folder.
- Only the **sanitised spec** crosses, after a leak review. Every crossing is logged in `provenance.md`.

Understanding-only exit: if `scope.md`'s goal is understanding or a report only, finish `report.md`
and stop. Skip `spec.md`, the leak review, provenance and phases 5–7.

## Workspace layout (the same in every doc)

```text
~/pith-work/<app>/
  provenance.md            safe for both sides; the only file at the root
  dirty/   scope.md  inventory.md  evidence/static/  behaviour/  captures/  notes/  report.md  spec.md (draft)
  clean/   spec.md (the approved copy)  <rebuild>/ (its own git repo)
```

- Never put a `CLAUDE.md` in `~/pith-work/<app>/` or any parent folder.
- The clean side runs in a **new** Claude Code session started in `clean/`, with a Read deny rule
  for `../dirty/**`.
- Example commands use `W=~/pith-work/<app>` and `PITH=~/src/Pith` ("wherever you cloned Pith").
  The clone URL is https://github.com/rohitthink/Pith. Claude Code is started in the workspace,
  never inside the Pith clone.

## Hard rules (repeat in GUARDRAILS.md; reference elsewhere)

1. Only software you legally own and run on your own machine. You decide; the agent asks.
2. Purpose: understanding, interoperability, a clean-room replacement. Not piracy, not resale of a clone.
3. Never: decrypt FairPlay/DRM, patch binaries, bypass licence checks, paywalls, trials or
   certificate pinning, or get around OS privacy protections. If something is encrypted or
   protected, record that as a finding and stop there.
4. Never copy the original's code, binaries, assets, strings, UI text, or keys into the rebuild.
   Reuse open-source engines only under their own licences.
5. Never publish secrets you notice (API keys, tokens), vendor internals that would help someone
   bypass payment, or captured personal data. Prefer not to name the vendor in public material.
6. Owner-only actions (anything needing `sudo`, a password, a security/privacy setting, or a
   purchase) are done by the owner in their own terminal or System Settings — never by the agent.
7. Not legal advice. Laws differ (US DMCA §1201(f), EU Directive 2009/24/EC Art. 6, …); when in doubt, ask a lawyer.

## Writing rules

- Phases 2 and 3 stay **high-level**: describe goals, what to record and what not to do, and point to
  the tools' own documentation (mitmproxy, Proxyman, mitmproxy2swagger). Do **not** write step-by-step
  interception set-up, and do **not** describe reading another app's protected data. Add no
  interception, proxy, certificate, container or protection-bypass instructions, and never name the
  first target's vendor.
- Commands are shown only for read-only, non-sensitive steps (Phase 1 survey, building, testing).
- Every doc ends with a short "Done when" checklist where it describes a phase.
- Cite prior art by name and URL (see `README.md` §Related work); integrate, don't compete.
  Decompilers and disassemblers (GhidraMCP, ida-pro-mcp, any decompiler) are outside Pith and are
  never recommended as a step; README's related work says so once.
- Tone: concrete, honest about what was and wasn't verified.

Fixed points, so the docs agree:

- **Leak check.** The one mechanical check lives in `GUARDRAILS.md` §Leak-review checklist. Other
  docs point to it and keep no copy of their own. It runs on the dirty side, on `dirty/spec.md`,
  before the spec crosses.
- **Gatekeeper.** "On other Macs the first launch has to be approved in System Settings › Privacy &
  Security › Open Anyway (since macOS 15, right-click › Open no longer overrides Gatekeeper)."
- **Review stopping rule.** "Repeat until a round confirms nothing above low severity, or the owner
  stops it." First-run counts: round 1 kept 15 bugs (refutations not recorded); round 2 kept 49 and
  refuted 1; round 3 kept 39 and refuted 1.
- **Finding schema.** `templates/finding.schema.json` is for Phase 6 review findings only. Dirty-side
  claims use the report's confidence tags and its Appendix A.3.
- **The first run's wall.** "The first run had no formal wall: one agent session did both the analysis
  and the rebuild, working from the report's rebuild blueprint. Pith's wall, leak review and
  provenance log were designed afterwards from what that run showed."

## Files

| File | Purpose |
|---|---|
| `README.md` | what/why/who, phases at a glance, quickstart, related work, licence |
| `GUARDRAILS.md` | the rules above, expanded; contamination runbook; what's safe to publish |
| `METHOD.md` | each phase in detail: goal, inputs, steps, outputs, pitfalls, done-when |
| `AGENT-PLAYBOOK.md` | running Pith with Claude Code: prompts, orchestration patterns, schemas, owner moments |
| `LESSONS.md` | concrete lessons from the first run (toolchain, testing, UI verification, review) |
| `templates/` | `scope.md`, `report.md`, `spec.md`, `provenance.md`, `finding.schema.json` (Phase 6 review findings only) |
| `scripts/` | `re-inventory.sh`, `re-static.sh` (read-only; tested on macOS 27), `install-skill.sh` (copies the skill; writes only to the chosen skills folder) |
| `skill/pith/SKILL.md` | a Claude Code skill that runs the method with these rules |
| `case-studies/zest.md` | the first run, sanitised (no vendor name, keys or payment internals) |
