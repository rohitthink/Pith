---
name: pith
description: Use when the user wants to reverse engineer an app they own, either to understand how it works or to build a clean-room replacement for it. Runs the Pith phases (0 Scope & consent through 7 Package & publish) with owner checkpoints, a dirty/clean wall and hard guardrails.
---

# Pith

Pith is a method for studying a Mac app the owner has bought and, if they want, building a
**clean-room** replacement: new code written only from a written description, never from the
original's code or assets. You (the agent) do most of the work. The owner makes the decisions
and does anything that needs a password or a security setting.

The name comes from the white layer between a fruit's peel and its flesh. In Pith it is the
wall between what was *observed* about someone else's app (the **dirty side**, phases 1–4) and
what is *built* (the **clean side**, phases 5–7). Only a sanitised `spec.md` crosses it.

Pith is not legal advice. Laws differ by country; when the owner is unsure, tell them to ask a lawyer.

## Files this skill uses

Paths are relative to this skill's base directory. `scripts/install-skill.sh` copies everything
below into it. If you are running the skill straight from a clone of the Pith repo
(https://github.com/rohitthink/Pith) instead, the same files are at the repo root (`../../scripts`,
`../../templates`, `../../*.md`). Never rewrite them from memory. When you run a script, give its
full path under this skill's base directory, not `./scripts/…`: your working directory is the
owner's, not the skill's.

| File | Use |
|---|---|
| `./scripts/re-inventory.sh` | Lists installed apps as a Markdown table (bundle id, version, architectures, how it was built, where it came from). Read-only. |
| `./scripts/re-static.sh` | Read-only static survey of one `.app`. Writes evidence files and `SUMMARY.md`. Redacts key-shaped strings. Never runs anything inside the bundle. |
| `./templates/` | `scope.md`, `report.md`, `spec.md`, `provenance.md`, and `finding.schema.json` (Phase 6 review findings only; dirty-side claims use the report's confidence tags and its Appendix A.3) |
| `./AGENT-PLAYBOOK.md`, `./METHOD.md`, `./GUARDRAILS.md`, `./LESSONS.md` | Installed next to this file. Detail behind every step below. |

## Hard rules (always on)

1. Only software the owner legally owns, running on their own machine. The owner decides; you ask.
2. Purpose: understanding, interoperability, or a clean-room replacement. Not piracy, not resale of a clone.
3. Never decrypt FairPlay or other DRM, patch binaries, bypass licence checks, paywalls, trials or
   certificate pinning, or get around OS privacy protections. If something is encrypted or
   protected, record that as a finding and stop there.
4. Never copy the original's code, binaries, assets, strings, UI text or keys into the rebuild.
   Open-source engines may be reused only under their own licences.
5. Never publish secrets you notice (API keys, tokens), vendor internals that would help someone
   avoid paying, or captured personal data. Prefer not to name the vendor in public material.
6. Owner-only actions (anything needing `sudo`, a password, a security or privacy setting, or a
   purchase) are done by the owner in their own terminal or System Settings. Never by you.
7. Not legal advice (for example US DMCA §1201(f), EU Directive 2009/24/EC Art. 6).

**When a request crosses a rule:** refuse that part, name the rule, and offer the in-bounds
alternative. Then carry on with the rest of the work.

| Request | Your answer |
|---|---|
| "Decrypt it" / "the binary is encrypted, get around it" | Rule 3. Record "encrypted" as a finding and move to Phase 2 (behaviour). |
| "Decompile it" / "disassemble that function" | GUARDRAILS.md never-list: Pith reads metadata, symbols and strings, not code. Learn what the code does from Phase 2 instead. |
| "Patch out the trial" / "unlock the paid feature" | Rule 3. The owner can buy the feature; the rebuild can implement it from the spec. |
| "Get past the pinning so we can see the API" | Rule 3. Record "not captured: pinned" in the report's boundary table. |
| "Read what it saved in its container" | Rule 3. Use only output files the owner hands you. |
| "Copy its icons / strings / layout" | Rule 4. Describe the behaviour in the spec in your own words; design new assets. |
| "Put the key you found in the report" | Rule 5. Note that a key exists and where (redacted); never the value. |
| "Run this sudo command for me" | Rule 6. Give the owner the command to run themselves, and why. |

## Where to start

Check these in order before anything else:

1. **Clean side.** If your working directory is a workspace's `clean/` folder (the one holding the
   approved `spec.md`) or anything below it, you are the clean session. Run Phases 5–7 only. Skip the scope questions: the owner's goals reach you
   through `spec.md`. Read nothing outside `clean/` except this skill's own files and public
   documentation, and never open `../dirty/` or the original app.
2. **Resuming.** If `~/pith-work/<app>/dirty/scope.md` (or the workspace the owner names) exists
   and section 8 is signed, or its change log records the owner's approval, read it and skip the
   Phase 0 questions. Continue at the first phase whose Done-when isn't met, judging by what is
   on disk (evidence, report sections, `dirty/spec.md`, `provenance.md` rows).
3. **Otherwise** start at Phase 0.

Each phase below ends with a short Done-when. The full checklist for each phase is the one in
`METHOD.md`: a phase is done when the METHOD.md checklist for that phase is met.

## Phase 0 — Scope & consent (gate: do nothing else first)

Before running any command or reading any file, ask the scope questions with **AskUserQuestion**.
It takes a few questions per call, so ask in two rounds. Skip any question the owner's request
already answers, and confirm those answers in one line instead. If AskUserQuestion isn't
available (for example in a non-interactive or SDK run), ask the same questions in plain text and
wait for the answers.

Round 1:
- **Target:** which app? Offer to run `re-inventory.sh` from this skill's base directory (read-only)
  if they want a list to pick from.
- **Ownership:** do you hold a licence for it, and is it installed on this Mac, which you control?
  If the answer is no or unsure, stop and explain rule 1.
- **Goal:** understand it / interoperate with its files / build a clean-room replacement.
- **Network phase:** skip Phase 3, or include it with the owner running any capture themselves.

Round 2:
- **Publishing:** keep everything private, or publish the rebuild? (Publishing means no vendor
  name, a leak review before every push, and licences honoured.)
- **Licence terms and location:** have you read the app's licence terms (EULA)? Does it say
  anything about reverse engineering? Which country do you live in?
- **Owner-only actions:** confirm they will run any `sudo`, password or System Settings step themselves.
- **Boundaries:** anything off-limits (features, folders, accounts)?

Then create the workspace (default `~/pith-work/<app>/`; the owner can change it at the
checkpoint) and fill `dirty/scope.md` from `./templates/scope.md`. Fill every field you can: the
machine from `sw_vers`, the target row from `re-inventory.sh` (save its output as
`dirty/inventory.md`). Mark the rest "owner to fill"; never invent an answer.

```
~/pith-work/<app>/
  provenance.md      log of every wall crossing; safe for both sides (the only file at the root)
  dirty/             Phases 1–4
    scope.md         target, ownership, goals, owner-only actions, boundaries
    inventory.md     re-inventory.sh output
    evidence/static/ from re-static.sh
    behaviour/       throwaway inputs, and outputs the owner hands you
    captures/        capture exports the owner hands you (Phase 3)
    notes/           reader notes
    report.md
    spec.md          the draft
  clean/             Phases 5–7
    spec.md          the approved copy
    <rebuild>/       the new codebase, its own git repository
```

Never put a `CLAUDE.md` in `~/pith-work/<app>/` or any folder above it: Claude Code loads those
into every session started below them, the clean session included.

**Checkpoint:** the owner ticks section 8 of `scope.md` or types "approved". Record which, with the
date, in the scope's change log. Done when: `scope.md` is filled (no blank lines) and approved.

## Phase 1 — Static survey (dirty side)

```bash
W=~/pith-work/<app>      # the workspace
bash "<this skill's base directory>/scripts/re-static.sh" "/Applications/<App>.app" "$W/dirty/evidence/static"
```

Use the base directory Claude Code gave you when it loaded this skill (for example
`~/.claude/skills/pith`).

Read `SUMMARY.md` first, then the evidence files: identity and signing (`info-plist.txt`,
`signature.txt`, `entitlements.txt`), the executable (`executable.txt`, `linked-libraries.txt`,
`load-commands.txt`), bundle anatomy (`size.txt`, `frameworks.txt`, `nested-bundles.txt`,
`embedded-executables.txt`, `licence-files.txt`, `privacy-manifests.txt`), strings (`strings-urls.txt`,
`strings-hosts.txt`, `strings-sdks.txt`, `strings-automation.txt`, `strings-possible-secrets-REDACTED.txt`)
and code structure (`objc-classes.txt`, `symbols-demangled.txt`, `swift-names.txt`, `swift-field-names.txt`).

Fill report §Static: architecture, bundled engines and their licences, data formats hinted at,
hosts referenced, automation surface (URL schemes, Shortcuts, AppleScript), sandboxing.

- If `SUMMARY.md` says **Encrypted (FairPlay): YES**, stop the static work there (rule 3). Record it and go to Phase 2.
- Do not run embedded tools. Sandboxed helpers die with SIGTRAP (exit 133) when run on their own,
  and running a vendor's binaries is outside a read-only survey anyway. Read versions with `strings`.
- Never un-redact a key-shaped string. Its existence is the finding.
- For deeper type metadata, `ipsw` (https://github.com/blacktop/ipsw) has class-dump and swift-dump;
  its output stays on the dirty side. Do not decompile or disassemble code (GUARDRAILS.md never-list).
- Tag each claim with the report's confidence tags: **[Static]** until behaviour or runtime
  evidence confirms it.

**Checkpoint:** show the owner the summary and the open questions. Done when: report §Static is filled.

## Phase 2 — Behaviour (dirty side, owner-run)

Goal: learn what the app does by using it normally. Keep this descriptive.

- Propose a test plan: features to exercise, options to try, and throwaway inputs. Make the
  inputs in `dirty/behaviour/` with built-in tools (`sips` for images, `say` for audio,
  `textutil` for documents), never with the owner's real files. `sips` can't write location
  metadata; for that, a short Swift script using ImageIO can write invented GPS coordinates into
  a copy of a test image.
- The owner uses the app. Record inputs, options chosen, outputs, errors and timings.
- You may inspect output files the owner hands you (format, size, metadata).
- Do not read the app's container, preferences or other data the OS protects; do not script
  around its UI limits. If a question can only be answered that way, record it as *not captured*.

Done when: report §Behaviour lists each feature tried, with input, options and observed output.

## Phase 3 — Network (optional, dirty side, owner-run)

Only if the owner chose it in Phase 0. Goal: a description of **the app's own** calls (hosts,
purpose, request and response shapes), ideally as OpenAPI.

- The owner sets up and runs any capture tool themselves, following that tool's own documentation:
  mitmproxy (https://github.com/mitmproxy/mitmproxy) or Proxyman
  (https://github.com/ProxymanApp/proxyman-SKILL.md). Do not give or run proxy, certificate-trust
  or interception commands.
- Work only on exports the owner hands you (kept in `dirty/captures/`). Redact tokens, cookies,
  account ids and personal data before anything is written down.
- To produce OpenAPI, point the owner to mitmproxy2swagger (https://github.com/alufers/mitmproxy2swagger)
  or Redocly CLI (https://github.com/Redocly/redocly-cli).
- If the app refuses capture (pinning or any other protection), write *not captured* and the
  boundary that blocked it. Never work around it (rule 3).
- Do not document how payment or unlocking works beyond "uses an in-app purchase SDK" (rule 5).
- Runtime evidence can overturn static guesses. When it does, correct the earlier section and say so.

Done when: report §Network lists hosts and purposes, the boundary table is complete, and the owner
confirms they have undone any capture set-up, following the tool's own documentation.

## Phase 4 — Report & spec (the wall)

1. Finish `dirty/report.md` from the template, including the runtime appendix table:
   *what was not captured, and the boundary that blocked it*.

   **Understanding only?** If `scope.md`'s goal is understanding or a report only, finish
   `report.md` and stop. Skip `spec.md`, the leak review, provenance and Phases 5–7. Done when:
   `report.md` is complete and the owner has read it.
2. Write `dirty/spec.md` from the template, in your own words: behaviour, file formats (a Kaitai
   `.ksy` from observation is fine: https://github.com/kaitai-io/kaitai_struct), the app's own
   API as OpenAPI, the rebuild's surfaces and acceptance criteria. No original strings, UI text,
   symbol names, assets, keys, vendor name or payment internals.
3. **Leak review**, by two fresh subagents, neither of them the spec's author:
   (a) one that never saw the evidence reads only `dirty/spec.md` and flags anything that looks
   copied, identifying or too vague to build from;
   (b) a second gets `dirty/spec.md` and `dirty/evidence/`, runs the mechanical check in
   GUARDRAILS.md §Leak-review checklist, and justifies or removes every hit.
   Fix the spec and repeat until both pass. Every `.ksy` and OpenAPI file that crosses gets the
   same review.
4. **Checkpoint:** the owner approves the spec.
5. Log the crossing in `provenance.md`: date, version, `shasum -a 256 dirty/spec.md | cut -c1-12`,
   the reviewers' verdicts, the kinds of thing removed (never the content), and the owner as
   approver. Then copy it to `clean/spec.md`.
6. **Stop.** This session has read the dirty side, so it must not plan, write or review the
   rebuild. Tell the owner to open a new Claude Code session in `~/pith-work/<app>/clean/`, with a
   Read deny rule for `../dirty/**` (AGENT-PLAYBOOK.md §Set-up shows one), and type `/pith` there.

Done when: `clean/spec.md` exists, its crossing is logged with the owner's approval, and the owner
has been told to start the clean session.

## Phase 5 — Clean-room rebuild (clean side)

- This phase runs only in the clean session: a new session started in `clean/` that has never
  read `dirty/` (see "Where to start"). A session that did dirty work never does clean work, not
  even by briefing subagents. If you have read anything in `dirty/`, stop and go back to Phase 4
  step 6.
- Implementer subagents get **only** `clean/spec.md`, public documentation and the `clean/`
  folder. Never pass them paths into `dirty/`, the original app, the report or the evidence.
  To enforce this with hooks, see https://github.com/whit3rabbit/clean-room-skill.
- Write gaps in the spec as questions in the shape of `spec.md` §9 and give them to the owner.
  The owner takes them to a dirty-side session; the answer comes back as a new spec version,
  leak-reviewed and logged in `provenance.md`.
- Engine first, then a CLI, then the GUI. Add the automation surface the spec asks for.
- UI: mock two or three design directions; **the owner picks one**.
- Parallel work: the clean session (never a session that read `dirty/`) writes the contract first
  (shared types, theme tokens, stubs) so every agent compiles. Give each agent its own copy of
  the package (rsync, excluding `.build`) and copy back only the files it owns. Follow each with
  a fresh-eyes polish agent.
- Toolchain notes (Command Line Tools only): SwiftUI `@State` needs a macro plugin that ships
  with Xcode, so use `@StateObject` with a small `ObservableObject`; `#Preview` and XCTest are
  unavailable, so write a dependency-free self-test runner. More in `LESSONS.md`.
- Wait on `Process.terminationHandler`, not `waitUntilExit()`, off the launching thread.

**Checkpoint:** the owner approves every commit and push. Done when: the spec's acceptance criteria are implemented.

## Phase 6 — Verification (clean side)

- Self-tests that need no dependencies, run from the CLI and the app (for example `--selftest`).
- An end-to-end harness on real files. Run it several times: some hangs only show under timing.
- Build verification into the product. Agents often cannot see or drive menu-bar-only apps, and
  may lack screen-capture permission, so add a snapshot mode (light and dark), URL-scheme-driven
  flows and own-window capture. Use `ImageRenderer` for pure SwiftUI views (`NSView.cacheDisplay`
  flips SwiftUI shadow offsets) and window capture for AppKit-backed controls.
- Adversarial review: one reviewer per dimension (for example correctness, concurrency, data
  safety, metadata and privacy, UI, packaging), then a verifier per dimension that must reproduce
  each finding before it counts. Findings follow `./templates/finding.schema.json`. Rank by
  severity, fix, re-run the harness. Repeat until a round confirms nothing above low severity, or
  the owner stops it.

Done when: all self-tests and harness checks pass on repeated runs, the review rounds stopped as
above, and every kept finding is fixed or listed.

## Phase 7 — Package & publish

- A package script: release build, `.app` assembly, `Info.plist` (for example `LSUIElement`, URL
  types, document types), signing, Launch Services registration, any CLI inside the bundle.
- Ad-hoc signing works locally. Notarization needs the owner's Apple Developer ID. Without it,
  say this in the README: "On other Macs the first launch has to be approved in System Settings ›
  Privacy & Security › Open Anyway (since macOS 15, right-click › Open no longer overrides
  Gatekeeper)."
- Honour the licences of any open-source engine you ship or call.
- Before anything goes public: a leak review of the repo (no vendor name, strings, keys,
  evidence or report), an honest README, and the owner's explicit yes for each push or release.
  The mechanical check in GUARDRAILS.md §Leak-review checklist also works on a whole folder; it
  reads the evidence, so the owner runs it from a dirty-side session, never this one.

Done when: the app installs from the package script and the README states what was and wasn't verified.

## Owner checkpoints (stop and wait)

| When | Owner does |
|---|---|
| Phase 0 | Answers scope questions; approves `scope.md` |
| Phase 1 end | Reviews the static summary |
| Phases 2–3 | Uses the app; runs any capture, `sudo` or System Settings step themselves, and undoes any capture set-up afterwards |
| Phase 4 end | Reads the report; approves the spec before it crosses the wall; opens the clean session in `clean/` |
| Phase 5 | Picks the design direction; approves commits and pushes |
| Phase 7 | Approves publishing; signs or notarizes with their own account if they want |

Ask before every outward-facing action (push, release, post, message), even mid-phase.

## Orchestration

When the session allows multi-agent workflows (a Workflow tool, or subagents via Agent/Task),
use the patterns in `AGENT-PLAYBOOK.md`: parallel readers over the evidence in Phase 1, a
sanitiser plus leak reviewers in Phase 4, contract-first fan-out in Phase 5, and
reviewer-plus-verifier pairs per dimension in Phase 6. Ask the owner before starting a large
workflow. If neither is available, run the same steps one after another and say so in the summary.

## Finish with an honest summary

End every session (or phase, if the owner stops early) with:

- **Produced:** files and where they are.
- **Verified:** what was checked, how (command, test counts, rounds), and the result.
- **Not verified:** what wasn't checked, and why.
- **Corrections:** earlier conclusions that later evidence overturned.
- **Boundaries hit:** what was not captured and which rule or protection stopped it.
- **Owner next steps:** anything only they can do.

Never claim a check you did not run. If a number comes from a tool, quote the tool's output.
