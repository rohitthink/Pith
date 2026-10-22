# Agent playbook

How to run Pith with Claude Code: who does what, prompts you can paste, the orchestration
patterns that worked on the first run, the finding format, the points where the agent must stop
and ask, and what an agent can and can't do on a Mac.

Read [GUARDRAILS.md](GUARDRAILS.md) before you start. [METHOD.md](METHOD.md) explains each phase
in detail, and [LESSONS.md](LESSONS.md) lists what went wrong on the first run and how it was
fixed. This file is only about driving the agent. Nothing here is legal advice.

Terms used throughout:

- **Owner**: you, the person who bought the app and runs the project.
- **Subagent**: a separate agent that Claude Code starts with an empty context (through its
  Agent/Task tool or a Workflow script). It knows only what its prompt says and what it reads
  itself.
- **Fresh eyes**: a subagent that did not write the thing it is checking.
- **The wall**: the line between the **dirty side** (Phases 1–4, which may look at the original
  app) and the **clean side** (Phases 5–7, which may only see `spec.md` and public
  documentation). Only a leak-reviewed `spec.md` crosses, and `provenance.md` logs each crossing.

## Contents

1. [Roles](#1-roles)
2. [Set-up](#2-set-up)
3. [Kickoff prompt](#3-kickoff-prompt)
4. [One prompt per phase](#4-one-prompt-per-phase)
5. [Orchestration patterns](#5-orchestration-patterns)
6. [The finding schema](#6-the-finding-schema)
7. [Owner checkpoints](#7-owner-checkpoints)
8. [macOS tool notes](#8-macos-tool-notes)
9. [Tools that plug in](#9-tools-that-plug-in)
10. [Done when](#done-when)

## 1. Roles

The short version: **you decide; the agent asks.**

| Phase | Owner | Agent |
|---|---|---|
| 0 Scope & consent | Picks the target and goals. Confirms they own it. Approves `scope.md`. | Lists installed apps if asked, drafts `scope.md`, lists what it still needs. |
| 1 Static survey | Reads the summary and answers questions. | Runs `re-static.sh`, reads the evidence with parallel readers, writes report §Static. |
| 2 Behaviour | Uses the app normally on throwaway inputs and says what they did. | Makes the inputs, writes the test plan, inspects the output files it is given, writes §Behaviour. |
| 3 Network (optional) | Decides whether to do it. Runs any capture personally, following the tool's own docs. Hands over an export, then undoes any capture set-up the same way. | Plans what to look for, redacts the export, summarises it, drafts OpenAPI, writes §Network. |
| 4 Report & spec | Reviews the report. Approves the spec before it crosses. | Finishes the report, drafts the spec, runs the leak review, logs provenance. |
| 5 Clean-room rebuild | Picks a design direction. Approves new dependencies. | Builds only from `spec.md`, contract first. |
| 6 Verification | Spot-checks the app by hand. | Runs self-tests, snapshots, the harness and review rounds; says what was and wasn't verified. |
| 7 Package & publish | Approves every commit, push and release. Decides about notarization. | Writes the package script, licence notices and an honest README. |

**Always the owner's:** anything that needs `sudo`, a password, a System Settings or privacy
change, or a purchase; anything outward-facing (commit, push, publish, post, send); installing or
downloading tools; legal judgement calls.

**Always the agent's:** stopping at checkpoints, saying how each claim was checked, writing
corrections down when later evidence overturns an earlier conclusion, and never claiming a check
it didn't run.

One more rule from the skill: **an agent that has read the dirty side is not the implementer.**
If one session did the analysis, the coding goes to a new session or subagent that never saw it.

## 2. Set-up

Get Pith and install the skill (it copies `SKILL.md`, the templates, the two survey scripts and
the main docs). The commands here and in the prompts below use two names: `PITH` is wherever you
cloned Pith, and `W` is the workspace for one app.

```bash
PITH=~/src/Pith                          # wherever you cloned Pith
W=~/pith-work/<app>                      # one workspace per app; replace <app>
git clone https://github.com/rohitthink/Pith "$PITH"
"$PITH/scripts/install-skill.sh"         # personal: ~/.claude/skills/pith
```

Then type `/pith` in Claude Code, or paste the kickoff prompt below.

**Workspace.** The skill's default is `$W`, that is `~/pith-work/<app>/`. Keep the wall physical:

```text
~/pith-work/<app>/
  provenance.md       every crossing of the wall; safe for both sides, and the only file at the root
  dirty/              everything that names or describes the original (Phases 0–4)
    scope.md          target, ownership, goals, owner-only actions, boundaries
    inventory.md      re-inventory.sh output, if you ran it
    evidence/static/  from re-static.sh (never commit it)
    behaviour/        Phase 2 inputs, outputs and notes
    captures/         Phase 3 (optional): redacted exports only
    notes/            reader notes
    report.md
    spec.md           draft, leak-reviewed before it crosses
  clean/              Phases 5–7
    spec.md           the approved copy, nothing else from dirty/
    <rebuild>/        the new codebase, its own git repository
```

**Sessions.** Run the dirty side and the clean side in different Claude Code sessions, started in
different folders. The clean side is a **new** session started in `clean/`, with `clean/` as its
working directory and nothing above it. Never reuse a session that did dirty work for clean work.

**Memory.** `CLAUDE.md` files, auto-memory and shared notes can be loaded into a session
automatically, so they can carry dirty facts across the wall unnoticed. Keep anything learned about the original
out of any memory or instructions file a clean session will load, including global ones. Claude
Code also loads `CLAUDE.md` files from every folder above the one a session starts in, so never put
a `CLAUDE.md` in `~/pith-work/<app>/` or any folder above it.

**Optional guard rail.** In `clean/.claude/settings.json`, add a Read deny rule for the dirty folder
next to it (`../dirty/**`), written as an absolute path:

```json
{
  "permissions": {
    "deny": ["Read(//Users/<you>/pith-work/<app>/dirty/**)"]
  }
}
```

`//` starts an absolute path in Claude Code permission rules. This rule covers Claude's own file
tools, not shell commands, so it is a guard rail, not a sandbox. For hook-based enforcement and
handoff schemas, see [whit3rabbit/clean-room-skill](https://github.com/whit3rabbit/clean-room-skill).

**Between phases.** Artifacts on disk are the memory. Finish each phase by writing its section,
then start the next phase in a fresh session (or after `/clear`) with the next prompt.

## 3. Kickoff prompt

Paste this, fill in the angle brackets, and delete the lines that don't apply.

```text
I want to run Pith on an app I own.

Target: <App name>, installed at </Applications/App.app>. I bought it <where/when> and it runs on this Mac, which I control.
Why: <understand how it works | open its files from my own tools | a replacement I can automate | it's slow, heavy or abandoned>
Wanted at the end: <a report only | a report and a clean-room rebuild>
Rebuild shape (only if rebuilding): <e.g. a Swift package: engine library, CLI, menu-bar app, URL scheme>
Network phase: <skip | include, with me running any capture myself>
Publishing: <private | publish the rebuild without naming the vendor>

Rules for this whole project:
- Follow Pith's GUARDRAILS.md and work phase by phase. Stop at every owner checkpoint.
- The original app is read-only. Never run its binaries or bundled tools, patch or decrypt anything, or read its container or any other data macOS protects. If something is encrypted or protected, record it as a finding and stop that line of work.
- Anything that needs sudo, a password, a System Settings change or a purchase: tell me what and why, and I will do it myself.
- Ask before anything outward-facing or lasting: installing or downloading tools, commits, pushes, creating repos, publishing, posting.
- If you notice a key, token or personal data, record only that it exists (redacted). Never copy the value.
- Label guesses as guesses. Say what you verified and how. If later evidence contradicts an earlier conclusion, correct it in writing.

Start with Phase 0: draft scope.md from the Pith template using what I wrote above, list what you still need from me, and stop for my sign-off.
```

## 4. One prompt per phase

Each prompt assumes the earlier phases' files exist. Each ends at an owner checkpoint. `$PITH` and
`$W` are the names from [Set-up](#2-set-up); replace them, or tell the agent once what they stand
for.

### Phase 0 — Scope & consent

```text
Phase 0 — Scope & consent.

1. If I haven't picked a target, run $PITH/scripts/re-inventory.sh (read-only) and show me the table. Once I pick, save it as $W/dirty/inventory.md.
2. Create the workspace with the layout in AGENT-PLAYBOOK.md §2 ($W, with dirty/ and clean/) and fill $W/dirty/scope.md from $PITH/templates/scope.md: target (name, bundle id, version, where it came from), how I own it, my goals, what "done" means, which phases we'll run, the boundaries from GUARDRAILS.md that apply, anything I've put off-limits, and the owner-only actions you expect.
3. Phase 3 (Network) needs my separate consent later; note whether I want it.
4. List open questions, then stop. Do not read the app until I approve scope.md.
```

### Phase 1 — Static survey

```text
Phase 1 — Static survey. scope.md is approved.

1. Run: "$PITH/scripts/re-static.sh" "/Applications/<App>.app" "$W/dirty/evidence/static"
   It only reads the bundle. Then read SUMMARY.md.
2. If SUMMARY.md says the executable is FairPlay-encrypted, stop the static work, record that as a finding, tell me, and plan Phase 2 instead.
3. Split the evidence files across parallel reader subagents (Pattern A in AGENT-PLAYBOOK.md). Each writes its claims into dirty/notes/<slice>.md: the statement, the evidence file it rests on, how it was observed (static), a confidence level, and "unconfirmed" until Phase 2 or 3 checks it.
4. Merge into report.md §Static: identity and distribution; signing and entitlements (sandboxed or not); architectures, platform and SDK; encryption; bundle anatomy and what takes the space; bundled engines with versions and licences; linked frameworks; automation surface (URL schemes, Services, intents, scripting); hosts and SDKs referenced; the type and field names that explain the data model.

Rules: never run anything inside the bundle (read bundled tools' versions with strings); never decompile or disassemble code (the never-list in GUARDRAILS.md); never unmask a redacted value; mark every claim as a static guess until behaviour confirms it. If you want a deeper tool (ipsw, REA), ask me before installing it, and keep its output in dirty/.

Stop and show me: a one-screen summary, the open questions Phase 2 should answer, and any key-shaped strings (redacted).
```

### Phase 2 — Behaviour

Descriptive by design. The owner drives the app; the agent plans and records.

```text
Phase 2 — Behaviour. Goal: describe what the app does from the outside, as a careful user sees it.

1. Make a throwaway fixtures folder in $W/dirty/behaviour/ and fill it only with generated inputs (sips for images, say for audio, textutil for documents). For metadata, a short Swift script using ImageIO can write invented GPS coordinates into a copy of a test image. Nothing personal. Cover each input type the app claims to handle, plus edge cases: tiny, large, odd file names, unusual formats.
2. Write a test plan as a table: feature × input × options. I'll use the app normally and tell you what I did, in small batches.
3. For each run record: input, options, output (format, size, dimensions or duration, metadata kept or dropped), time taken, any message or error, and what the UI showed. Inspect only output files I made, in folders I chose, with read-only tools (file, sips, mdls and similar).
4. Note the automation surface as a user sees it: Open With, Services, Shortcuts actions, URL scheme, AppleScript dictionary — present or absent.
5. Write report.md §Behaviour, and list every place where behaviour disagrees with §Static.

Do not: open or read the app's container, preferences, caches, keychain items or anything else macOS protects; run its bundled tools; attach a debugger or inject code; script around its UI limits; try paid features without paying or probe how limits are enforced (write "needs purchase" and move on). If a question can only be answered one of those ways, record it as not captured.

Stop and show me the behaviour summary and any corrections to §Static.
```

### Phase 3 — Network (optional)

Descriptive by design. The agent never sets up interception; the owner runs any capture with
the tool's own documentation ([mitmproxy docs](https://docs.mitmproxy.org/stable/),
[Proxyman](https://proxyman.com)) and hands over an export.

```text
Phase 3 — Network. I consent to studying <App>'s own network calls, on this Mac, for this session.

Goal: know what the app talks to and why, and whether the rebuild needs any of it.

1. From §Static (hosts, SDKs) and §Behaviour, list the actions that probably cause network calls and what we want to learn from each: purpose, host, rough request and response shape, when it fires.
2. I will run any capture myself with a tool I choose, following that tool's own documentation. Do not set up proxies, interception or certificates, and do not write steps for them.
3. When I hand you an export (for example a HAR file), redact tokens, keys, cookies, receipts, account and device identifiers and personal data before anything else, and keep only the redacted copy, in $W/dirty/captures/. Then group the calls by purpose. For calls to the app's own API, draft an OpenAPI description (mitmproxy2swagger or Redocly CLI can help; follow their READMEs).
4. Write report.md §Network, ending with a table: what was not captured, and the boundary that blocked it.

Never: work around certificate pinning or any other protection; describe how purchases are validated or features are gated (at most "uses an in-app purchase SDK"); replay calls against the vendor's servers; keep captured personal data. If the app refuses the capture, record that and stop. If the only traffic is third-party commerce or analytics, say so: the rebuild may need no network code at all.

Stop and show me §Network, plus any static conclusion this changes, and remind me to undo any capture set-up, following the tool's own documentation.
```

On the first run this phase did one useful thing: the static survey had drawn a conclusion about
how the app was sold, and the owner's capture of its launch calls overturned it. The report kept
the correction visible instead of quietly rewriting §Static.

### Phase 4 — Report & spec

```text
Phase 4 — Report & spec.

1. Finish report.md from templates/report.md: executive summary (3–5 takeaways), architecture, engines, data formats, network/API, automation surface, flaws and improvement targets, rebuild blueprint, a legal note (not legal advice), and an appendix table of what was not captured and the boundary that blocked it. Keep every correction visible. If scope.md's goal is understanding or a report only, finish report.md and stop here: skip spec.md, the leak review, provenance and Phases 5–7.
2. Draft dirty/spec.md from templates/spec.md, in your own words: features with acceptance criteria, inputs and outputs, data formats (name public standards; for a custom format, a Kaitai .ksy written from observation), the OpenAPI description if Phase 3 ran, automation surfaces, and proposed improvements (IMP-) kept in their own section, apart from observed behaviour (OBS-). Leave out: strings, symbol, type and field names from the binary, UI text, assets, keys, the vendor's name, and anything about purchase or gating.
3. Leak review with two fresh subagents:
   - a blind reader that sees only dirty/spec.md and flags anything that looks copied or identifying, and anything a builder couldn't build from it;
   - a comparer that sees dirty/spec.md and dirty/evidence/, and flags any word or structure that came from the binary rather than from behaviour. Start with the mechanical check in GUARDRAILS.md §Leak-review checklist, run on the dirty side on dirty/spec.md; every hit must be justified (a public standard, a common word) or removed.
4. Fix every hit. Draft the provenance.md entry: what crosses, date, reviewers' verdicts, what was removed.

Stop for my sign-off. Only after I approve, copy dirty/spec.md to clean/spec.md and log the crossing in provenance.md.
```

### Phase 5 — Clean-room rebuild

Paste into a **new** session started in `clean/`.

```text
You are the clean-side builder for a Pith clean-room rebuild. Your only source about the original app is spec.md in this folder; you may also use public documentation. Do not open, search for or ask about the original app, its bundle, any report or evidence, or anything outside this folder, except Pith's own method docs (AGENT-PLAYBOOK.md, LESSONS.md in the Pith skill folder), which say nothing about this app. If the spec doesn't answer something, add it to the "Questions across the wall" table in spec.md and tell me; answers come back as a new, leak-reviewed spec version logged in provenance.md, never as pasted material.

1. Propose the architecture (<engine library, CLI, app, automation surfaces>) and the open-source engines you'd use, each under its own licence. Wait for my OK.
2. If there is a UI: mock 3 distinct design directions as HTML artboards (Pattern C), render them to PNG with qlmanage -t, and show me. I'll pick one.
3. Write the contract first: shared model types, theme tokens from the chosen direction, shared geometry, and stubs that compile. Build it.
4. Fan out (Pattern D): one subagent per area, each in its own copy of the package, then a fresh-eyes polish subagent per area.
5. From day one keep a dependency-free self-test command, a snapshot mode that renders the app's own screens to PNG (light and dark), and a URL scheme that can drive the main flows, so you can verify without seeing the screen.

Ask before adding a dependency, downloading anything, or committing. See LESSONS.md for toolchain traps if only the Command Line Tools are installed.
```

### Phase 6 — Verification

```text
Phase 6 — Verification.

1. Run the self-tests and the snapshot renderer; look at every PNG.
2. Build an end-to-end harness in a scratch copy (Pattern F): generated real files in, outputs checked for format, size, metadata and lossless-ness, a timeout on every check, and a local HTTP server on 127.0.0.1 for anything that fetches. Run it several times; timing bugs only show on some runs.
3. Run review rounds (Pattern E): one reviewer per dimension, then one adversarial verifier per dimension that tries to reproduce each finding and gives a verdict (confirmed, plausible or refuted) with evidence. Record everything as JSON that validates against templates/finding.schema.json. Rank by severity, fix in batches, and re-run self-tests and the harness after each batch; record the recheck.
4. Repeat until a round confirms nothing above low severity, or I stop it.
5. Write a verification section: what was checked, how, and the counts; what was not verified and why; which findings were refuted.

Nothing counts as verified that you only reasoned about.
```

### Phase 7 — Package & publish

```text
Phase 7 — Package & publish.

1. Write a package script: release build, .app assembly, Info.plist (LSUIElement for a menu-bar app, URL types, document types), the CLI bundled under Contents/Helpers, ad-hoc signing, Launch Services registration. Run it, then check the app launches and its URL scheme and Open With work.
2. Licences: list every open-source engine the app bundles or calls, with its licence, and ship the required notices. Flag any licence condition you're unsure of for me (not legal advice).
3. README: what it does, how it was built (clean-room from a spec, without naming the original or its vendor), what kind of wall we had (with one owner it is procedural: separate sessions, folders and briefs), what was verified and what wasn't, and install notes. An ad-hoc-signed app isn't notarized. On other Macs the first launch has to be approved in System Settings › Privacy & Security › Open Anyway (since macOS 15, right-click › Open no longer overrides Gatekeeper). Notarization needs an Apple Developer ID, which is my call.
4. Final leak check on everything that will be public: no vendor name, keys, captured data, strings, UI text or assets from the original, and no evidence, notes or report files.

Show me exactly what will be published, then ask before each commit, push, repo creation, release or post.
```

## 5. Orchestration patterns

Each pattern says when to use it and gives a compact pseudo-workflow. The steps work with
Claude Code subagents or a Workflow script; without either, run them one after another and say so
in the summary. Ask the owner before starting a large fan-out: it costs time and tokens.

### A. Parallel readers for analysis

**Use when** the evidence is too big for one context, or its slices need different expertise:
Phase 1, and gathering material for the report in Phase 4.

```text
evidence = dirty/evidence/static/
slices = {
  identity: info-plist.txt signature.txt entitlements.txt privacy-manifests.txt xattrs.txt
  anatomy:  size.txt frameworks.txt nested-bundles.txt embedded-executables.txt licence-files.txt
  binary:   executable.txt load-commands.txt linked-libraries.txt
  code:     objc-classes.txt symbols-demangled.txt swift-names.txt swift-field-names.txt
  surface:  strings-urls.txt strings-hosts.txt strings-sdks.txt strings-automation.txt
            strings-possible-secrets-REDACTED.txt
}
parallel for name, files in slices:
    reader(name): read only `files` -> dirty/notes/<name>.md
                  each claim: statement, evidence file, how observed, confidence,
                  "unconfirmed" until behaviour or network evidence checks it
                  quote at most a line of evidence; never unmask a redacted value
lead: merge notes -> report.md §Static
      list contradictions between readers and the questions for Phase 2
      add no claim that lacks a cite
```

The slice names match the files `re-static.sh` writes. Readers never run anything in the bundle.

### B. Multi-angle prior-art sweep, then a verifying synthesiser

**Use when** you're about to publish a method or tool, pick a name, or build something that may
already exist. This is how Pith's own related-work section was checked.

```text
angles = [whole-scope matches, analysis engines and MCP servers, clean-room kits,
          capture-to-spec tools, adversarial verification, name collisions]
parallel for a in angles:
    searcher(a): GitHub search (repos, code, topics) plus the web
                 per candidate: name, URL, licence, last push, what it covers,
                 gap versus ours, rating 1-5 with a supporting quote from its README
synthesiser (fresh eyes): for every candidate rated >= 3, open the repo and read its README
                          and the docs it depends on; correct or downgrade claims;
                          nothing is cloned or run
    -> {verdict, closest[], integrate[], gap, notToBe, nameCollisions}
owner: decide build / integrate / drop; cite what you integrate by name and URL
```

On the first run the synthesiser caught a tool name a searcher had reported that the repo
doesn't have, lowered several ratings, and noted that one repo's star count was not a reliable
signal. Keyword search can miss small repos; say so in the result.

### C. Design directions as artboards

**Use when** the rebuild has a UI and the owner hasn't fixed a look.

```text
designer: from spec.md (UI section) and the owner's taste notes, write 3 distinct directions,
          one HTML file each, with the same artboards (e.g. main panel light/dark,
          busy state, error state, settings); each lists its tokens
          (colour, type, radius, spacing, motion)
render:   qlmanage -t -s 1600 -o mockups/ mockups/*.html   # headless browsers sometimes hang
owner:    picks one, or names an explicit mix
lead:     copies the chosen tokens into the contract (Pattern D) and records the choice
```

On the first run: three directions, and the owner picked "Citrus".

### D. Contract-first parallel build in isolated copies, then fresh-eyes polish

**Use when** a build splits into areas that share types, and you want several agents working at
once.

```text
1 contract (lead, alone):
    shared model types, theme tokens, shared geometry, stub views and APIs that compile
    a list of which files each area owns
    swift build passes before anyone fans out
2 fan-out (parallel):
    for area in areas:
        rsync -a --exclude .build pkg/ work/<area>/    # own copy, own build lock
        builder(area): edit only its owned files; treat the contract as read-only;
                       build and self-test inside work/<area>/
3 merge (lead):
    copy back only each area's owned files; swift build; run the self-tests
4 polish (parallel):
    for area in areas: a fresh subagent that didn't build it reviews against spec.md and the
                       chosen design; fixes polish only; re-runs self-tests and snapshots
```

Why the copies: Swift Package Manager locks the `.build` folder, so parallel builds in one
package directory block each other or clash. Why copy back only owned files: builders sometimes
"fix" shared files, and those changes have to go through the lead into the contract. A git
worktree per area works too, since each gets its own `.build`. The first run used four UI builders
this way, each followed by a polish agent.

### E. Review by dimension, adversarial verifier, fix, re-verify

**Use when** the rebuild works end to end and you want the bugs a single reviewer misses. Also
for the Phase 4 leak review, with leak and completeness as the dimensions.

```text
dimensions = e.g. [correctness, concurrency, file-safety (never lose or overwrite files),
                   privacy (metadata), automation (CLI, URL scheme, Shortcuts), ui,
                   licences, packaging]
round n:
    parallel for d: reviewer(d) reads code + spec.md
                    -> findings[] (finding.schema.json: id, severity, file, line,
                       title, scenario, fix)
    parallel for d: verifier(d), fresh eyes, told to refute; tries to reproduce each
                    finding (test, harness run or minimal script)
                    -> verdict: confirmed | plausible | refuted, with evidence
    rank confirmed and plausible findings by severity (high, medium, low); fix in batches
    after each batch: re-run self-tests and the end-to-end harness -> recheck: pass | fail
    close refuted findings as not-a-bug, keeping the verifier's evidence
stop: a round confirms nothing above low severity, or the owner stops it
```

First run: three rounds. Round 1 kept 15 bugs (refutations not recorded); round 2 kept 49 and
refuted 1; round 3 kept 39 and refuted 1. Over 100 fixes in total, each re-checked with the real-file harness. Related prior art:
[amd2g2zz/kunglao-agent](https://github.com/amd2g2zz/kunglao-agent) (a blind verifier; AGPL-3.0,
so ideas only) and [Dryxio/reagent](https://github.com/Dryxio/reagent) (a maker/checker loop).

### F. End-to-end harness in a scratch copy

**Use when** you need proof on real files that the product works, and to re-check every batch of
fixes. Never point it at the owner's own files.

```text
scratch = a new temporary folder; build or copy the release product into it
fixtures: generate inputs with built-in tools (sips, say, textutil) into scratch/in/;
          a short Swift script using ImageIO can write invented GPS coordinates into a
          copy of a test image
server:   python3 -m http.server 8765 --bind 127.0.0.1 --directory scratch/www   # link tests
for check in checks:                       # the first run had 33
    run the CLI or URL scheme on a real input -> scratch/out/
    assert: exit status; output format, size, dimensions or duration;
            metadata kept or stripped as promised (GPS especially);
            unchanged image data on lossless paths; nothing written outside scratch
    under a timeout, so a hang fails that check instead of the whole run
repeat the whole harness several times; a timing bug may show once in five runs
throw scratch away at the end
```

Golden masters and pixel diffs from
[climashscape/agentic-cleanroom](https://github.com/climashscape/agentic-cleanroom) fit here too.
If the owner wants parity with the original, the owner runs the same fixture through it on the
dirty side and passes back only pass/fail verdicts, logged in `provenance.md` (the pattern from
[lemonadesaltbagel/teardown](https://github.com/lemonadesaltbagel/teardown)).

## 6. The finding schema

Phase 6 review findings use one shape, defined in
[`templates/finding.schema.json`](templates/finding.schema.json) (JSON Schema 2020-12). That file
is the source of truth. A file may hold one finding or an array of them (one reviewer's output).
The reviewer writes the finding, a different agent fills in `verifier`, and the lead records the
fix's `recheck`.

| Field | Filled by | Meaning |
|---|---|---|
| `id` | reviewer | Unique within the review, for example `R2-concurrency-03`. |
| `round`, `dimension` | reviewer | Which round, and the dimension the reviewer was given. |
| `severity` | reviewer | `high`: data loss, wrong output that looks right, a hang or crash, a privacy leak, or a broken must-have requirement. `medium`: wrong or degraded behaviour with a workaround, or in an uncommon path. `low`: polish. |
| `file`, `line` | reviewer | Repository-relative path in the rebuild; a line number, or `null`. |
| `title` | reviewer | The defect in one short line. |
| `scenario` | reviewer | Concrete inputs and state that lead to the failure, precise enough to reproduce. |
| `fix` | reviewer | The proposed fix. |
| `reviewer` | reviewer | Which agent or session reported it. |
| `verifier` | verifier | `verdict` (`confirmed`: reproduced; `plausible`: not reproduced, but the reasoning holds against the code; `refuted`), `evidence`, and optionally `reproducedWith` and `verifiedBy` (never the reviewer). |
| `status` | lead | `open`, `fixed`, `wont-fix`, `duplicate` or `not-a-bug`. |
| `recheck` | lead | `result` (`pass` or `fail`) and `evidence`: how the fix was re-checked. |

`id`, `severity`, `file`, `line`, `title`, `scenario` and `fix` are required. A finding marked
`fixed` must also carry a `confirmed` or `plausible` verdict and a `recheck`. Extra fields need an
`x-` prefix.

An example, based on a real bug from the first run (the id, round, path and wording are
illustrative):

```json
{
  "id": "R2-privacy-01",
  "round": 2,
  "dimension": "privacy",
  "severity": "high",
  "file": "Sources/ExampleKit/PDFExport.swift",
  "line": null,
  "title": "Image to PDF keeps the photo's GPS location",
  "scenario": "Convert a test JPEG that carries GPS tags to PDF. The PDF still contains the location.",
  "fix": "Drop location metadata on the image-to-PDF path, and assert its absence in the harness.",
  "reviewer": "privacy reviewer, round 2",
  "verifier": {
    "verdict": "confirmed",
    "evidence": "Converted a JPEG with GPS tags; the tags were present in the output PDF.",
    "reproducedWith": "end-to-end harness, image-to-PDF check",
    "verifiedBy": "privacy verifier, round 2"
  },
  "status": "fixed",
  "recheck": {
    "result": "pass",
    "evidence": "Self-tests and the end-to-end harness pass on repeated runs; no GPS tags in the output."
  }
}
```

The schema is for Phase 6 review findings only. Dirty-side claims in Phases 1–4 (report entries
and reader notes) use the report's confidence tags ([templates/report.md](templates/report.md)),
and a protection boundary you hit goes in the report's Appendix A.3. They never leave the dirty
side.

## 7. Owner checkpoints

**Stop and ask.** The agent stops, shows what it has, and waits for a clear yes.

| When | The agent shows | The owner decides |
|---|---|---|
| End of Phase 0 | `scope.md` and open questions | Approve the scope, or change it |
| Before installing or downloading anything (deeper analysis tools, engines, `yt-dlp`, packages) | What, from where, why, and its licence | Yes or no |
| Something is encrypted or protected | The finding, and the boundary it hit | Accept the boundary (the work never goes around it) |
| A step needs `sudo`, a password, a System Settings or privacy change, or a purchase | The exact command or setting, and why | Do it themselves, or skip it |
| Before Phase 3, and before each capture | What to capture and what will be redacted | Consent, and run it themselves |
| End of Phase 4 | `spec.md` and the leak review results | Approve the crossing |
| Design directions are ready | The rendered artboards | Pick one |
| Before adding a dependency to the rebuild | Name, licence, why | Yes or no |
| Before any commit, push, repo creation, release, post or message | The exact diff or content | Yes or no, each time |
| A legal question comes up | The question and any sources (not legal advice) | Decide, or ask a lawyer |
| Clean-side contamination (dirty material reached the clean side) | What, where, when | Follow the [contamination runbook](GUARDRAILS.md#contamination-runbook) |

**Tell, then continue.** The agent says it plainly in its next summary and carries on:

- a later finding overturns an earlier conclusion (write the correction where the old one was);
- a key, token or personal data was noticed (record that it exists, redacted; never the value);
- a check was skipped or couldn't run (it goes under "not verified");
- a verifier refuted a finding;
- the harness was flaky on one run (that is a finding, not noise).

## 8. macOS tool notes

What an agent running in Claude Code on a Mac can and can't do, and what to do instead.

| Situation | What happens | What to do |
|---|---|---|
| Menu-bar-only apps (`LSUIElement`, also called accessory apps: no Dock icon, no main window) | Agents could not see or drive them with computer use on the first run. | Build verification into the product: a snapshot mode that renders the app's screens to PNG, URL-scheme-driven flows, and capture of its own windows. The owner does the manual checks. |
| Screen capture | The agent's host app may not have Screen Recording permission. Granting it is a privacy setting, so it's the owner's call. | Prefer rendering inside the app (`ImageRenderer` for pure SwiftUI views), which needs no permission. |
| `sudo`, passwords, System Settings | The agent's shell can't answer a password prompt, and under the hard rules it must not try. | The agent writes the exact command or setting and why; the owner runs it in their own terminal. |
| Running the original's bundled tools | Sandboxed helpers die with SIGTRAP (exit 133) when run on their own. Running them is outside a read-only survey anyway. | Read versions with `strings`. |
| Command Line Tools without Xcode | SwiftUI `@State` (a macro whose plugin ships with Xcode), `#Preview`, XCTest and App Intents metadata extraction are unavailable. | See [LESSONS.md](LESSONS.md): `@StateObject` with a small holder, your own self-test runner, and URL scheme and CLI as the testable automation surfaces. |
| Rendering HTML mockups | Headless browsers sometimes hang. | `qlmanage -t` renders an HTML file to a PNG thumbnail. |
| Long-running child processes | `Process.waitUntilExit()` can hang off the launching thread. | Wait on `terminationHandler`; put a timeout on every harness check. |
| Network in tests | Real sites are slow, change, and are not yours to hammer. | Serve fixtures from a local HTTP server on 127.0.0.1. |
| Signing and notarization | Ad-hoc signing works locally. Notarization needs an Apple Developer ID ($99 a year), a purchase decision for the owner. | Ship ad-hoc signed and say so in the README. On other Macs the first launch has to be approved in System Settings › Privacy & Security › Open Anyway (since macOS 15, right-click › Open no longer overrides Gatekeeper). |

## 9. Tools that plug in

Pith uses existing tools rather than replacing them. The list, with what each one covers, the phase
it fits and where Pith differs, is in [README.md](README.md#related-work--what-to-integrate).

## Done when

The checklists that count are the "Done when" lists at the end of each phase in
[METHOD.md](METHOD.md): a phase is done when its METHOD.md checklist is met. In short:

- [ ] **Phase 0:** `dirty/scope.md` is filled and the owner approved it.
- [ ] **Phase 1:** the evidence folder exists, report §Static cites it, and the owner has seen the summary.
- [ ] **Phase 2:** report §Behaviour lists every feature tried with input, options and output, plus corrections to §Static.
- [ ] **Phase 3 (if run):** report §Network lists hosts and purposes, redacted, with the "not captured" table complete, and the owner confirms they have undone any capture set-up, following the tool's own documentation.
- [ ] **Phase 4:** `report.md` is complete. If the goal is understanding or a report only, stop here. Otherwise `spec.md` passed both leak reviewers and the mechanical check, the owner approved it, and `provenance.md` logs the crossing.
- [ ] **Phase 5:** the rebuild meets the spec's acceptance criteria, built by a new session started in `clean/` that never saw the dirty side.
- [ ] **Phase 6:** self-tests and the harness pass on repeated runs; review rounds were repeated until a round confirmed nothing above low severity, or the owner stopped them; what wasn't verified is written down.
- [ ] **Phase 7:** the package script builds a working `.app`, licences are honoured, the README is honest, and the owner approved every push.
