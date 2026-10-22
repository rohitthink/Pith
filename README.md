# Pith

**Reverse engineer a Mac app you own, then rebuild it clean-room with an AI coding agent, with a wall in between.**

The pith is the white layer between a fruit's peel and its flesh. In this method it is the wall between what you *observed* about someone else's app and what you *build* yourself.

> **Status:** early. One full run so far ([case study](case-studies/zest.md)). The scripts are read-only and were tested on macOS 27. Nothing here is legal advice.

## What Pith is

Pith is a **method** for studying a macOS app you legally own, writing down what it does, and building your own replacement from that description. An AI coding agent (Claude Code) does most of the work. You, the owner, make the decisions.

It ships as:

- **docs**: the method phase by phase, the guardrails, an agent playbook and lessons from the first run;
- **templates**: scope, report, spec, provenance log and a schema for Phase 6 review findings;
- **two read-only scripts**: an app inventory and a static survey of one app bundle;
- **a Claude Code skill** that runs the method with these rules.

A **clean-room** rebuild is written only from a description of *what* the original does, by someone (here, a separate agent session) who never saw *how* it does it: no binary, no strings, no assets. Pith keeps that separation with a wall: one side looks at the original, the other side only ever sees a sanitised spec.

## What Pith is not

- **Not** an analysis engine, MCP server or capture tool. It uses existing ones (see [Related work](#related-work--what-to-integrate)).
- **Not** a security, pentest, malware or CTF toolkit.
- **Not** a way to clone and resell someone's product.
- **Not** decompilation or source recovery of any kind.
- **Never** a way to defeat DRM, licence checks, paywalls, trials or certificate pinning, or to read data the operating system protects. If something is encrypted or protected, Pith records that as a finding and stops there.

## Who it is for

A capable Mac user or developer who is **not** a security professional, and who wants to:

- understand an app they bought: what engines it bundles, under which licences, what it sends over the network;
- get **interoperability** the app doesn't offer, such as a CLI, a URL scheme or Shortcuts support;
- replace an app that is limited, heavy or abandoned with one they control, for their own use;
- learn how to run a long, multi-phase project with an agent without losing track of what was verified.

You don't need to read assembly. Terms are defined in [Words used here](METHOD.md#words-used-here) and where they first appear in [METHOD.md](METHOD.md).

## The phases at a glance

| # | Phase | Side | Output |
|---|---|---|---|
| 0 | Scope & consent | before both | `scope.md` (target, ownership, goals, owner-only actions, boundaries) |
| 1 | Static survey | dirty | evidence folder from `scripts/re-static.sh`, report §Static |
| 2 | Behaviour | dirty | report §Behaviour: what the app does, observed by using it normally on throwaway inputs |
| 3 | Network (optional) | dirty | report §Network; an OpenAPI description of *the app's own* documented/observed calls |
| 4 | Report & spec | dirty → wall | `report.md` (dirty side) → sanitised `spec.md` (crosses the wall) + `provenance.md` |
| 5 | Clean-room rebuild | clean | a new codebase built only from `spec.md` |
| 6 | Verification | clean | self-tests, end-to-end harness, visual snapshots, multi-agent adversarial review |
| 7 | Package & publish | clean | a signed app bundle, licences honoured, an honest README |

```text
  0  Scope & consent: scope.md records ownership, goals, boundaries
     and owner-only steps. It comes first and governs both sides.
  ------------------------------------------------------------------------
     DIRTY SIDE  (phases 1-4)           || WALL ||  CLEAN SIDE  (phases 5-7)
     may look at the original app       ||      ||  sees only spec.md
                                        ||      ||  and public docs
                                        ||      ||
  1 Static survey ------+               ||      ||
  2 Behaviour ----------+-> 4 report.md ||      ||
  3 Network (optional) -+   + evidence  ||      ||
                              |         ||      ||
               sanitise + leak review   ||      ||
                              |         ||      ||
                              v         ||      ||
                          spec.md ====================> 5 Clean-room rebuild
                                        ||      ||      6 Verification
                                        ||      ||      7 Package & publish

  provenance.md logs every crossing. Never crosses: the original binary,
  its strings or assets, report.md, or the evidence folder.
```

Phases 2 and 3 are deliberately descriptive in these docs: goals, what to record and what not to do, with pointers to the tools' own documentation. Full detail for every phase, with a "Done when" checklist each, is in [METHOD.md](METHOD.md).

## Quickstart

**Requirements:** macOS with the Xcode Command Line Tools (install them with `xcode-select --install`). Xcode itself is optional; [LESSONS.md](LESSONS.md) lists what changes without it. `swift-demangle` is found through `xcrun` if present; without it, Swift symbols stay mangled.

Start by cloning this repository:

```bash
git clone https://github.com/rohitthink/Pith ~/src/Pith   # or wherever you like
cd ~/src/Pith
```

### The workspace

Both paths below use one private workspace per app, outside the Pith clone:

```text
~/pith-work/<app>/            private; never published
  provenance.md               log of every crossing; safe for both sides, the only file at this level
  dirty/                      may look at the original
    scope.md  inventory.md
    evidence/static/  behaviour/  captures/  notes/
    report.md
    spec.md                   draft, leak-reviewed before it crosses
  clean/                      sees only spec.md and public docs
    spec.md                   the approved copy
    <rebuild>/                the new codebase, its own git repository
```

Never put a `CLAUDE.md` in `~/pith-work/<app>/` or any folder above it: Claude Code loads those into every session started below them, the clean side's included.

### A. With Claude Code

```bash
scripts/install-skill.sh                        # installs to ~/.claude/skills/pith
scripts/install-skill.sh ~/code/myproj/.claude/skills   # or into one project only
```

The installer copies `skill/pith/SKILL.md`, the templates, the two survey scripts and the main docs into the skill folder, so the skill is self-contained. Re-run it to update.

Then start Claude Code in the app's workspace, never inside the Pith clone, and give it read access to the app bundle:

```bash
mkdir -p ~/pith-work/example/dirty
cd ~/pith-work/example/dirty && claude --add-dir /Applications/Example.app
```

The agent needs to read the bundle and write to the workspace. `--add-dir` covers the bundle, so you aren't asked about each path inside it; if you leave it out, approve read-only access when it asks. Then type `/pith`, or ask in plain words:

> Use Pith to study /Applications/Example.app. I bought it and it's installed on this Mac.

The method starts at Phase 0: ownership, goals and boundaries go into `scope.md` before anything is read. The agent asks before every outward-facing action (commits, pushes, publishing), and steps that need `sudo`, a password or System Settings are handed back to you to run yourself.

### B. By hand

```bash
# Phase 0: pick a target you own, then set up its workspace
PITH=~/src/Pith                  # wherever you cloned Pith
W=~/pith-work/example
mkdir -p "$W/dirty" "$W/clean"
"$PITH/scripts/re-inventory.sh" > "$W/dirty/inventory.md"   # Markdown table of installed apps
cp "$PITH/templates/provenance.md" "$W/"
cp "$PITH/templates/scope.md" "$PITH/templates/report.md" "$PITH/templates/spec.md" "$W/dirty/"
```

**Stop here.** Fill in `~/pith-work/example/dirty/scope.md` and sign its section 8 before going on. Nothing else starts until the scope is signed.

```bash
# Phase 1: read-only static survey of one app
PITH=~/src/Pith; W=~/pith-work/example   # again, if this is a new shell
"$PITH/scripts/re-static.sh" /Applications/Example.app "$W/dirty/evidence/static"
open "$W/dirty/evidence/static/SUMMARY.md"
```

- **`re-inventory.sh [folder ...]`** scans `/Applications` and `~/Applications` by default. For each app it prints the bundle id, version, architectures, how it was built (native, Electron, Qt, Flutter, Java, Mac Catalyst, CEF) and where it came from (App Store, Developer ID, development build, ad-hoc, unsigned or other). It reads `Info.plist` files, Mach-O headers and signatures, and runs nothing it finds.
- **`re-static.sh App.app [out-dir]`** writes plain-text evidence files to `out-dir` (default `./re-out/<AppName>-static/`), plus a `SUMMARY.md`. Evidence covers the Info.plist, signature and entitlements (the permissions the app declares), architectures, platform and SDK, encryption info, linked libraries and load commands, bundle size and anatomy, embedded executables, licence and notice files, privacy manifests, URLs and hosts, SDK and automation hints, Objective-C classes, Swift names and Swift field names. It reads the bundle with `file`, `otool`, `nm`, `strings`, `codesign -d`, `lipo`, `vtool`, `plutil` and `swift-demangle`, and **never executes anything inside the bundle**. Key-shaped strings are masked as `…REDACTED…`: knowing a key exists is enough. If the binary is FairPlay-encrypted (Apple's App Store copy protection), the summary says so; record it and stop static work there.

Then work through the templates in order: `report.md` §Static from the evidence, then §Behaviour and §Network per [METHOD.md](METHOD.md). If `scope.md`'s goal is understanding or a report only, finish `report.md` and stop: skip `spec.md`, the leak review, provenance and phases 5–7.

Otherwise, write `dirty/spec.md` and run the mechanical check in [GUARDRAILS.md](GUARDRAILS.md) §Leak-review checklist on it while it is still on the dirty side. Once the owner approves it, copy it to `clean/spec.md` and log the crossing in `provenance.md`. Build the rebuild in `clean/<rebuild>/`, its own git repository, from a **new** Claude Code session started in `clean/`, with a Read deny rule for `../dirty/**`.

Evidence describes someone else's app. Keep the workspace out of version control (only `clean/<rebuild>/` is a repository) and away from the Pith clone. If you ever run `re-static.sh` from inside this repo without an output folder, its default `re-out/` is already excluded by `.gitignore`. The skill uses the same `~/pith-work/<app>/` layout by default.

## Repo map

| Path | What it is |
|---|---|
| [`README.md`](README.md) | this page |
| [`GUARDRAILS.md`](GUARDRAILS.md) | the hard rules expanded; contamination runbook; what's safe to publish |
| [`METHOD.md`](METHOD.md) | each phase in detail: goal, inputs, steps, outputs, pitfalls, done-when |
| [`AGENT-PLAYBOOK.md`](AGENT-PLAYBOOK.md) | running Pith with Claude Code: prompts, orchestration patterns, schemas, owner moments |
| [`LESSONS.md`](LESSONS.md) | concrete lessons from the first run (toolchain, testing, UI verification, review) |
| [`templates/`](templates/) | `scope.md`, `report.md`, `spec.md`, `provenance.md`, `finding.schema.json` |
| [`scripts/`](scripts/) | `re-inventory.sh`, `re-static.sh` (read-only), `install-skill.sh` |
| [`skill/pith/SKILL.md`](skill/pith/SKILL.md) | the Claude Code skill |
| [`case-studies/zest.md`](case-studies/zest.md) | the first run, sanitised |
| [`docs/OUTLINE.md`](docs/OUTLINE.md) | the writers' contract every doc follows |
| [`LICENSE`](LICENSE) | MIT |

## Related work & what to integrate

A prior-art check on 2026-10-22 (a multi-angle GitHub search, then a verifier that re-read every close match's README) found **no single project covering the whole path** from "I own this Mac app" to "I have a clean, verified rebuild". Every stretch of it exists somewhere, often done better than Pith does it. Use those projects for their jobs. The table says which.

**Closest projects**

| Project | Use it for | Where Pith differs |
|---|---|---|
| [morluto/rea](https://github.com/morluto/rea) | An optional evidence backend: MCP server, CLI and agent skill; Electron, .NET, APK, SQLite; saved HAR/SAZ traffic captures; Apple bundle anatomy; Evidence records with stated limits. Its `DISCLAIMER.md` is a good model. | A tool layer, not an end-to-end method. No clean-room wall: its showcases reproduce compiled code byte for byte. Its Apple inventory says it doesn't decode Swift/ObjC metadata or read plist semantics, which Pith's Phase 1 does. Its README warns about copies posing as the official repo, so use the link here. |
| [ShadowSwaps/REA-Reconstruction-Companion](https://github.com/ShadowSwaps/REA-Reconstruction-Companion) | Turning evidence into requirements and validation; keeping observed behaviour apart from proposed improvements; its eval topics (preferences, undo, unsaved changes, locale) as a spec checklist. | No analyst/implementer separation, no adversarial review, not macOS-specific. |
| [prime-radiant-inc/greenfield](https://github.com/prime-radiant-inc/greenfield) | The model for Phase 4's handoff: a sanitiser, then structural-leakage, content-contamination and completeness reviewers, with a raw / output / provenance split. | Stops at specs. No macOS tooling, no rebuild. |
| [whit3rabbit/clean-room-skill](https://github.com/whit3rabbit/clean-room-skill) | Enforcing the wall in Claude Code with hooks and JSON schemas for handoff artifacts. | Starts from source code or screenshots, not a compiled Mac app. |
| [lemonadesaltbagel/teardown](https://github.com/lemonadesaltbagel/teardown) | Two patterns, in lighter form: the implementer gets only pass/fail verdicts, and every crossing goes into an append-only log. | Behaviour-only by design (no static phase); its README lists macOS as not started. Pre-release. |
| [climashscape/agentic-cleanroom](https://github.com/climashscape/agentic-cleanroom) | Phase 6 tools (ratchets, golden masters, pixel diff, inventory parity) and its clean-room policy, spec and scorecard templates. | The forward half only; it doesn't read the target. |
| [AngryRatLabs/ai-skills](https://github.com/AngryRatLabs/ai-skills) | The phase graph closest to Pith's, with a leak check and completeness audit before the spec reaches the implementer. | Windows DLLs to Wine specs; one agent; stops at the spec. |
| [OwenPawl/cerberus-re-skill](https://github.com/OwenPawl/cerberus-re-skill) | Prior art for Apple-focused analysis: a Ghidra/LLDB/Frida workbench with evidence reports. | Analysis only, no spec handoff or rebuild. It decompiles, debugs and instruments; Pith does none of these (see below). |

Pith doesn't decompile or disassemble: that is on the never-list in [GUARDRAILS.md](GUARDRAILS.md). Some projects here can, through Hopper, Ghidra, IDA or decompiler connectors such as GhidraMCP and ida-pro-mcp, and that work is outside Pith. Anyone who goes further takes on the limits of EU Directive 2009/24/EC Art. 6 themselves, and keeps everything those tools produce on the dirty side.

**Tools to plug into a phase**

| Tool | Phase | Job |
|---|---|---|
| [blacktop/ipsw](https://github.com/blacktop/ipsw) | 1 | Objective-C class-dump and Swift type metadata, beyond what `re-static.sh` extracts. |
| [OWASP/mastg](https://github.com/OWASP/mastg) | 1–3 | A static, dynamic, network and storage checklist. It is a security-testing guide, not an interoperability guide. |
| [mitmproxy/mitmproxy](https://github.com/mitmproxy/mitmproxy), [ProxymanApp/proxyman-SKILL.md](https://github.com/ProxymanApp/proxyman-SKILL.md) | 3 | An owner-run, consented capture of the app's own calls. Follow their own docs; Pith doesn't repeat set-up steps. |
| [alufers/mitmproxy2swagger](https://github.com/alufers/mitmproxy2swagger) | 3 | Turns captured traffic into an OpenAPI 3.0 description. |
| [Redocly/redocly-cli](https://github.com/Redocly/redocly-cli) | 3, 6 | Infers OpenAPI from a HAR file and checks traffic against a spec, so the rebuild can be held to the observed contract. |
| [kaitai-io/kaitai_struct](https://github.com/kaitai-io/kaitai_struct) | 4 | Describe observed file formats as `.ksy` files, a machine-readable part of `spec.md`. |
| [amd2g2zz/kunglao-agent](https://github.com/amd2g2zz/kunglao-agent), [Dryxio/reagent](https://github.com/Dryxio/reagent) | 6 | Prior art for adversarial verification: a blind verifier, and a maker/checker loop. kunglao is AGPL-3.0, so take ideas, not code. |
| [Kyvero-Vexus/clean-room-reverse-engineering](https://github.com/Kyvero-Vexus/clean-room-reverse-engineering) | all | Legal citations and a contamination-response runbook. Not legal advice. |

**What Pith adds**

1. **A macOS-first, end-to-end method**, from app inventory and Swift/ObjC metadata to a signed app bundle, written for people who aren't security professionals, with the owner making every decision.
2. **A middle-ground clean-room wall.** The dirty side may do a read-only static survey of metadata, symbols and strings. Only a leak-reviewed `spec.md` crosses, and every crossing is logged in `provenance.md`. That sits between byte-exact reconstruction and refusing to look at the binary at all.
3. **Adversarial review applied to a clean-room rebuild.** It borrows reviewer-plus-reproducing-verifier rounds from kunglao-agent and reagent: a reviewer per dimension, then a verifier per dimension who must reproduce each finding before it counts. Fixes are re-checked with an end-to-end harness on real files.

The space is moving fast: several of these projects appeared in October 2026, and GitHub search only matches keywords. If Pith misses or misdescribes your project, please open an issue.

## First case study: Zest

The first run studied **a commercial macOS menu-bar file converter the owner had bought**. It was a sandboxed Swift app built around drag-and-drop conversion. The static survey showed it bundled open-source engines (an LGPL-class FFmpeg build, WebP tools) and a Java runtime, which made up most of the download. It had no automation surface: no URL scheme, Shortcuts or AppleScript. Runtime evidence later corrected one static conclusion, and the report records the correction.

The first run had no formal wall: one agent session did both the analysis and the rebuild, working from the report's rebuild blueprint. Pith's wall, leak review and provenance log were designed afterwards from what that run showed.

The rebuild is **[Zest](https://github.com/rohitthink/Zest)**, a Swift package:

- **ZestKit**, an engine with ffmpeg, ImageIO (including a lossless metadata strip) and native document backends (NSAttributedString and PDFKit instead of a bundled Java runtime);
- a `zest` CLI, a menu-bar app, a `zest://` URL scheme, a Shortcuts intent and Open With;
- verification: 81 + 45 dependency-free self-tests, 46 light and dark snapshot PNGs, a 33-check end-to-end harness on real files, and 3 adversarial review rounds with over 100 fixes;
- packaged as an ad-hoc-signed `.app`. It is not notarized (that needs a paid Apple Developer ID). On other Macs the first launch has to be approved in System Settings › Privacy & Security › Open Anyway (since macOS 15, right-click › Open no longer overrides Gatekeeper).

Read the full write-up in [case-studies/zest.md](case-studies/zest.md), and what we'd do differently in [LESSONS.md](LESSONS.md).

## Guardrails (summary)

The full rules, a contamination runbook and what's safe to publish are in **[GUARDRAILS.md](GUARDRAILS.md)**. In short:

1. **Only software you legally own**, on your own machine. You decide; the agent asks.
2. **Purpose:** understanding, interoperability, a clean-room replacement. Not piracy, not resale of a clone.
3. **Never** decrypt FairPlay or other DRM, patch binaries, bypass licence checks, paywalls, trials or certificate pinning, or get around OS privacy protections. If something is protected, record it and stop.
4. **Never copy** the original's code, binaries, assets, strings, UI text or keys into the rebuild. Reuse open-source engines only under their own licences.
5. **Never publish** secrets you notice, vendor internals that would help someone bypass payment, or captured personal data. Prefer not to name the vendor.
6. **Owner-only actions** (`sudo`, passwords, security or privacy settings, purchases) are done by the owner, never the agent.
7. **Not legal advice.** Laws differ (for example US DMCA §1201(f) and EU Directive 2009/24/EC Art. 6). When in doubt, ask a lawyer.

## Contributing

Contributions are welcome, especially new case studies, better templates and fixes to the scripts.

- Read [docs/OUTLINE.md](docs/OUTLINE.md) first. It fixes the phase numbers and names, the writing rules and the file list.
- **Scripts stay read-only.** They must never execute or modify anything inside the target bundle, and must mask secrets. Say which macOS version you tested on.
- **Case studies must be sanitised:** no vendor name, keys, payment or gating internals, personal data, or evidence folders. Use [case-studies/zest.md](case-studies/zest.md) as the model.
- **Out of scope:** anything that decrypts, patches or bypasses protections (see hard rule 3), security or pentest features, and any vendor binaries or extracted assets.
- Pith is macOS-first on purpose. Other platforms are welcome later, as separate phase notes that keep the same wall.

## Licence

[MIT](LICENSE), © 2026 Rohit. The licence covers Pith's own docs, templates and scripts. It grants nothing about the apps you study, and the tools Pith points to keep their own licences.
