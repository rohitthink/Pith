# Pith method

This is the long form of Pith: every phase from 0 to 7, each written in the
same shape: **Goal · Inputs · Steps · Outputs · Pitfalls · Done when**.

- Read [`GUARDRAILS.md`](GUARDRAILS.md) first. This document assumes its hard rules.
- [`AGENT-PLAYBOOK.md`](AGENT-PLAYBOOK.md) covers running the phases with Claude Code: prompts,
  orchestration and owner moments.
- [`LESSONS.md`](LESSONS.md) has the detail behind many of the pitfalls below.
- The templates named here (`scope.md`, `report.md`, `spec.md`, `provenance.md`,
  `finding.schema.json`) live in [`templates/`](templates/).
- Each phase ends with a **Done when** checklist. That checklist is the one that counts: where the
  skill or the playbook sum up a phase, this list wins.

**Where this comes from.** Pith was first run in October 2026 on one target: a commercial
macOS menu-bar file converter the owner had bought. The rebuild is
[Zest](https://github.com/rohitthink/Zest). The examples below come from that run. That target was a
native, sandboxed Swift app. The other app types listed in [Other targets](#other-targets) have been
tested less, or not at all, and this document says so where it matters.

The first run had no formal wall: one agent session did both the analysis and the rebuild, working
from the report's rebuild blueprint. Pith's wall, leak review and provenance log were designed
afterwards from what that run showed.

**Not legal advice.** Where this document mentions licences, terms or law, it describes what the
first run did. It does not tell you what is lawful where you live. Laws differ, for example US DMCA
§1201(f) and EU Directive 2009/24/EC Art. 6. When in doubt, ask a lawyer. See
[`GUARDRAILS.md`](GUARDRAILS.md).

---

## Words used here

| Term | Meaning |
|---|---|
| **Owner** | The person who legally owns the app's licence and the Mac it runs on. The owner decides; the agent proposes and asks. |
| **Agent** | An AI coding agent (Claude Code in the first run) that reads, writes, builds and tests. |
| **Owner moment** | A step only the owner performs, in their own terminal or System Settings: anything needing `sudo`, a password, a security or privacy setting, a purchase, or approval of an outward-facing action (hard rule 6). |
| **Evidence** | Plain-text output of read-only tools, kept in a private folder. |
| **Finding** | One claim about the original app, plus the evidence for it and how sure you are. |
| **Clean room** | Building a replacement from a written description of *what* something does, by people (or agents) who never saw *how* the original does it. |
| **Dirty side / clean side** | The two sides of the wall. They are described next. |
| **Entitlements** | Permissions an app declares in its code signature, such as the sandbox, network access or access to files the user picks. macOS enforces them. |
| **FairPlay** | Apple's App Store copy protection. When it is on, the app's code and strings are encrypted on disk. Pith records that and never tries to decrypt. |
| **Certificate pinning** | An app that trusts only the server certificates it was built to expect, usually the vendor's own, so it refuses a capture tool's certificate. Pith never bypasses it. |
| **OpenAPI** | A standard, machine-readable description of an HTTP API: its endpoints, requests and responses. |
| **HAR / SAZ** | Saved records of web traffic. HAR (HTTP Archive) is a JSON format most capture tools export; SAZ is Fiddler's session archive. Both hold cookies and tokens until you redact them. |
| **MCP server** | A plug-in that gives an agent a tool, using the Model Context Protocol. |

## The wall

The name comes from the pith of a fruit: the white layer between the peel and the flesh. In Pith it
is the wall between what you *observed* about someone else's app and what you *build* yourself.

```text
                      Phase 0  Scope & consent  ->  scope.md
                                         |
 DIRTY SIDE (may look at the original)   |  CLEAN SIDE (never does)
 --------------------------------------  |  ----------------------------------
 1 Static survey   -> dirty/evidence/    |  5 Clean-room rebuild
 2 Behaviour       -> report, Behaviour  |  6 Verification
 3 Network (opt.)  -> report, Network    |  7 Package & publish
 4 Report & spec   -> report.md          |
                      spec.md -----------+---> spec.md + public documentation
                      provenance.md      |
                                         |
    spec.md crosses only after a leak review and the owner's approval;
    every crossing is logged in provenance.md
```

- **Dirty side (Phases 1–4)** may look at the original app. It produces evidence and the report.
- **Clean side (Phases 5–7)** sees only `spec.md` and public documentation. It never sees the original
  binary, its strings, its assets, the report or the evidence folder.
- **Only the sanitised spec crosses**, after a leak review. Every crossing is logged in `provenance.md`.

The wall is easiest to keep with separate folders and separate agent sessions. An agent that has read
the evidence still has it in its context, so it must not write rebuild code. Start the clean side in
a new Claude Code session in `clean/`; any subagents it uses are handed only `spec.md`.

The workspace (the same layout the skill creates):

```text
~/pith-work/<app>/            private; never published
  provenance.md               Phase 4, log of every crossing (safe for both sides)
  dirty/
    scope.md                  Phase 0
    inventory.md              Phase 0
    evidence/static/          Phase 1 evidence from re-static.sh
    behaviour/                Phase 2 inputs, outputs and notes
    captures/                 Phase 3 (optional): redacted captures only
    notes/                    working and reader notes
    report.md                 Phase 4
    spec.md                   Phase 4 draft, leak-reviewed before it crosses
  clean/
    spec.md                   the approved copy: the only file that crossed
    <rebuild>/                the new codebase, its own git repository
```

`scope.md` and `inventory.md` name the target, so they live in `dirty/`. `provenance.md` records
dates, hashes, verdicts and the kinds of thing removed, never the original's names or text, so it is
safe for both sides and is the only file at the root.

Never put a `CLAUDE.md` in `~/pith-work/<app>/` or any parent folder. Claude Code loads those
automatically, so a clean session started in `clean/` would read it too. The clean side runs in a
new Claude Code session started in `clean/`, with a permission rule that denies `Read` of
`../dirty/**` ([`AGENT-PLAYBOOK.md`](AGENT-PLAYBOOK.md) shows the settings file). That rule covers
Claude's own file tools, not shell commands, so it is a guard rail rather than a sandbox.

## Phases at a glance

| # | Phase | Side | Output |
|---|---|---|---|
| 0 | Scope & consent | before both | `scope.md` (target, ownership, goals, owner-only actions, boundaries) |
| 1 | Static survey | dirty | evidence folder from `scripts/re-static.sh`, report §Static |
| 2 | Behaviour | dirty | report §Behaviour: what the app does, observed by using it normally on throwaway inputs |
| 3 | Network (optional) | dirty | report §Network; an OpenAPI description of *the app's own* documented or observed calls |
| 4 | Report & spec | dirty → crossing | `report.md` → sanitised `spec.md` + `provenance.md` |
| 5 | Clean-room rebuild | clean | a new codebase built only from `spec.md` |
| 6 | Verification | clean | self-tests, end-to-end harness, visual snapshots, multi-agent adversarial review |
| 7 | Package & publish | clean | a signed app bundle, licences honoured, an honest README |

Commands appear only for read-only or building steps: Phase 0, Phase 1, and Phases 5–7. Phases 2 and
3 are written as goals, records and limits, with pointers to the tools' own documentation.

---

## Phase 0 — Scope & consent

### Goal

Pick one app you own. Before any analysis, write down why you are studying it, what you hope to
build, and where you will stop.

### Inputs

- An app you legally own, installed on your own Mac. A trial, a borrowed copy, or an app on someone
  else's machine does not qualify.
- [`scripts/re-inventory.sh`](scripts/re-inventory.sh).
- The app's licence terms (EULA). The owner reads these. Some forbid reverse engineering, and some
  laws allow it for interoperability anyway. That question is for a lawyer, not this document.
- [`templates/scope.md`](templates/scope.md).

### Steps

1. **List the candidates.** `re-inventory.sh` reads each app's `Info.plist` and executable header,
   and runs nothing it finds. Create the private workspace (see [The wall](#the-wall)) and run it
   from there:

   ```bash
   PITH=~/src/Pith                                        # wherever you cloned Pith
   W=~/pith-work/some-app                                 # ~/pith-work/<app>, one per target
   mkdir -p "$W/dirty" "$W/clean" && cd "$W"
   "$PITH/scripts/re-inventory.sh" > dirty/inventory.md    # /Applications and ~/Applications
   "$PITH/scripts/re-inventory.sh" /Applications/Utilities # or any folders you name
   ```

   If you haven't picked the target yet, use a working name and rename the folder before Phase 1.

   It prints a Markdown table with the columns **App · Bundle id · Version · Archs · Built with ·
   Source**. It looks two levels deep in each folder.

   - **Built with** is one of `native`, `Electron`, `Qt`, `Flutter`, `Java`, `Mac Catalyst`, `CEF`
     or `iOS app (wrapped)`. It is a guess from bundled frameworks and the build platform. `native`
     only means none of the others matched, so it covers Swift, Objective-C, C++ and more. This
     column decides which profile applies (see [Other targets](#other-targets)).
   - **Source** comes from the code signature: `App Store`, `Developer ID`, `development build`,
     `ad-hoc signed`, `unsigned` or `other`. For an `iOS app (wrapped)` row, Archs and Source are
     not read from the wrapped bundle, so treat those two columns as assumptions.
   - **Archs** lists the CPU architectures in the main executable, such as `arm64` and `x86_64`.

2. **Choose the target with the owner.** A good first target is small, does one job, is `native`,
   and has something you want changed: missing automation, too much size, a feature you need.
   Poor first targets are wrapped iOS apps (usually encrypted), apps whose value lives on a server,
   and anything you cannot confirm you own.

3. **Write `dirty/scope.md`** from the template. Include:
   - **Target**: name, bundle id, version, and how it was acquired. The owner confirms ownership; do
     not paste receipts or order numbers.
   - **Goals**, for example: "learn which engines it uses and why it is so large; build a scriptable
     replacement for my own use".
   - **Non-goals**, for example: "not a copy to sell; not its account or sync features".
   - **Boundaries**: what the agent may read (the app bundle, and files the owner hands it) and what
     it may not (the app's own data, other apps, the network unless Phase 3 is approved).
   - **Phase 3 decision**: skip it, or allow it, with the question it answers and the hosts and
     actions in scope.
   - **Owner-only actions**: every step that needs `sudo`, a password, a System Settings change or a
     purchase.
   - **Publication intent**: private, or public under a new name with no vendor name.

4. **Owner sign-off.** The owner adds a dated line approving the scope. Start a dated decision log at
   the bottom of `scope.md`, and add to it whenever the scope changes.

### Outputs

- `dirty/scope.md`, signed off by the owner.
- `dirty/inventory.md`, which stays private.

### Pitfalls

- **Assuming an App Store app is unreadable, or that any app is readable.** Encryption is checked in
  Phase 1. The first target was a Mac App Store build without FairPlay encryption (Apple's App Store
  copy protection), so its strings could be read.
- **Scope creep.** "While we're here" drifts into the app's data, account or servers. Change the
  scope in writing, or don't do it.
- **Letting the agent do owner moments.** The agent asks; the owner types the password.
- **Trusting the inventory's guesses.** It is a heuristic, and Phase 1 confirms or corrects it.

### Done when

- [ ] The owner has confirmed they own the app and it runs on their own Mac.
- [ ] `scope.md` names the target, goals, non-goals, boundaries, owner-only actions, the Phase 3
      decision and the publication intent.
- [ ] The owner has signed and dated the scope, and the decision log has started.

---

## Phase 1 — Static survey

### Goal

Learn what the app is made of without running it: identity, signature, permissions, architecture,
embedded engines and their licences, third-party SDKs, declared automation and referenced hosts. All
of it comes from files already on disk.

### Inputs

- `scope.md`.
- The `.app` bundle.
- Apple's Command Line Tools (`otool`, `nm`, `strings`, `codesign`, `lipo`, `vtool`, `plutil`, and
  `swift-demangle` through `xcrun`). Full Xcode is not needed.
- [`scripts/re-static.sh`](scripts/re-static.sh).

### Steps

1. **Run the survey.**

   ```bash
   PITH=~/src/Pith                    # again, if this is a new shell
   W=~/pith-work/some-app             # the workspace from Phase 0
   cd "$W"
   "$PITH/scripts/re-static.sh" "/Applications/Some.app" dirty/evidence/static
   # without an out-dir it writes to ./re-out/<App>-static/ (git-ignored in the Pith repo)
   ```

   The script never executes anything inside the bundle. Strings and symbols come from the **main
   executable only**. API-key-shaped strings are masked before they are written. The raw string and
   symbol dumps it uses along the way (`.strings-all.txt`, `.symbols.txt`) are deleted at the end.

2. **Read `SUMMARY.md` first.** It has a table with bundle id, version, the executable and its
   architectures, distribution (Mac App Store or not, from `_MASReceipt`), size, **Encrypted
   (FairPlay)**, **Sandboxed**, **Swift reflection metadata**, **URL schemes declared** and
   **LSUIElement (menu-bar agent)**. Below that are file counts, the top 25 hosts, and the first 40
   embedded executables.

   > **If "Encrypted (FairPlay)" says YES**, the app's code and strings are encrypted by Apple's App
   > Store protection. Record that as a finding and stop reading code. `Info.plist`, entitlements,
   > bundle layout and licence files are usually still readable. Then move to Phase 2. Never try to
   > decrypt (hard rule 3).

3. **Read the evidence files.** Each file is plain text.

   | File | What it holds | What to look for |
   |---|---|---|
   | `info-plist.txt` | `Info.plist`, pretty-printed | Document types and UTIs (the formats it opens), `CFBundleURLTypes` (URL schemes), `LSUIElement` (menu-bar-only app), `LSMinimumSystemVersion`, `NS…UsageDescription` keys (the protected resources it asks for), `NSServices`, `OSAScriptingDefinition` (AppleScript). |
   | `signature.txt` | `codesign -dvvv` | Authority chain (App Store, Developer ID or ad-hoc), hardened-runtime flags, timestamp. The team identifier names the vendor, so keep it out of anything public. |
   | `entitlements.txt` | The signed entitlements (permissions the app declares) | `com.apple.security.app-sandbox`, network client/server, user-selected file access, app groups, Apple Events exceptions, hardened-runtime exceptions. These tell you what the app *may* do on your Mac. |
   | `executable.txt` | `file`, architectures, build version, encryption info | Platform (`MACOS`, `MACCATALYST`…), minimum OS, SDK, and `cryptid` (non-zero means FairPlay-encrypted). |
   | `linked-libraries.txt` | `otool -L` | System frameworks (SwiftUI, AppKit, PDFKit, AVFoundation, StoreKit…) and `@rpath` libraries shipped inside the bundle. |
   | `load-commands.txt` | Full `otool -l` | `LC_RPATH`, `LC_BUILD_VERSION`, segments and sections. `__swift5_*` sections mean Swift. |
   | `size.txt` | `du` of the bundle and of each `Contents/` folder | Where the weight is. |
   | `frameworks.txt` | Embedded `.framework`s | Updaters, commerce SDKs, crash reporters, UI kits. |
   | `nested-bundles.txt` | `.xpc`, `.appex`, `.plugin`, `.bundle`, nested `.app` | Helpers, extensions (Share, Quick Look, Finder Sync), login items. |
   | `embedded-executables.txt` | Every Mach-O executable file (Mach-O is the macOS executable format) in the bundle, with its type | Bundled command-line engines, helpers, runtimes, and the architectures of each. |
   | `licence-files.txt` | Paths to licence, notice, copying and acknowledgement files | Which third-party code ships, and on what terms. Open and read each one. |
   | `privacy-manifests.txt` | Each `PrivacyInfo.xcprivacy` | Declared data collection, tracking domains, required-reason APIs. |
   | `strings-urls.txt` | Every `http(s)://` URL in the main executable | Endpoints, documentation links, SDK hosts. |
   | `strings-hosts.txt` | Hosts from those URLs, with counts | What the app might talk to. This is a hypothesis for Phase 3, not proof. |
   | `strings-possible-secrets-REDACTED.txt` | Key-shaped tokens (`appl_`, `goog_`, `amzn_`, `sk_live_`, `pk_live_`, `AIza`, `AKIA`, `ghp_`, `xox…-`), masked | Only that a key of that kind exists. Never unmask, copy or use it. |
   | `strings-sdks.txt` | Lines naming analytics, commerce or crash SDKs (first 200) | Which services are linked in. |
   | `strings-automation.txt` | URL-scheme patterns, `CFBundleURLSchemes`, `NSUserActivity`, `NSServices`, `INIntent`, `AppIntent`, `OSAScripting`, `scriptSuite` (first 100) | Signs of an automation surface. A few `NSUserActivity` or `INIntent` lines come from AppKit's own delegate methods and appear in almost every app. Look for the app's own scheme or intent types. |
   | `objc-classes.txt` | Objective-C class and protocol names (Swift classes appear mangled, e.g. `_TtC…`) | Module and feature names. Dirty side only. |
   | `symbols-demangled.txt` | Exported symbols, demangled when `swift-demangle` is available | Usually short in a shipped (stripped) app. |
   | `swift-names.txt` | Swift protocols the binary refers to by mangled name, demangled (framework ones such as `View`, plus some of the app's own) | Not a list of the app's structs, classes or enums: in a stripped binary those need `ipsw swift-dump` (dirty side). Only written when `swift-demangle` is found. |
   | `swift-field-names.txt` | Swift stored-property names from the `__swift5_reflstr` section | The shape of the app's model, such as settings and job fields. This is the file most likely to leak into a spec, so it never crosses the wall. |
   | `xattrs.txt` | `com.apple.quarantine`, `com.apple.provenance`, `com.apple.macl` attributes (first 20) | How the bundle arrived and whether macOS tracks it. |

4. **Read bundled tools without running them.** Take paths from `embedded-executables.txt`.

   ```bash
   T="/Applications/Some.app/Contents/Resources/bin/ffmpeg"   # a path from embedded-executables.txt
   lipo -archs "$T"                                      # architectures
   otool -L "$T"                                         # what it links (static or dynamic build)
   strings -a "$T" | grep -m 5 -E 'version [0-9]|--enable-'   # version and build flags
   codesign -d --entitlements - "$T"                     # its own sandbox entitlements, if any
   ```

   An FFmpeg build stores its configure flags as a string, in the binary or in its `libavutil`
   library. Whether `--enable-gpl` or `--enable-nonfree` appears tells you its licence class. The
   first run read the bundled engines' versions this way, and their licences from the licence and
   notice files.

5. **Find where the weight is.**

   ```bash
   du -sh "/Applications/Some.app/Contents/"*/* 2>/dev/null | sort -hr | head -15
   ```

   In the first run, a Java runtime shipped twice (once per CPU architecture) made up most of the
   download.

6. **Go deeper only if you need to, and only on the dirty side.**
   - [blacktop/ipsw](https://github.com/blacktop/ipsw) has `class-dump` and `swift-dump` commands that
     recover Objective-C and Swift type metadata more fully than the script does.
   - [morluto/rea](https://github.com/morluto/rea) can serve as an optional discovery backend. Per its
     own docs, its Apple bundle view does not decode Swift or Objective-C metadata, so the script's
     Swift steps still apply.
   - [OWASP/mastg](https://github.com/OWASP/mastg) is a useful checklist for Mach-O, entitlements,
     sandbox and plist checks. It is written for security testing, not interoperability, so take the
     checklist and leave the attack material.
   - Going deeper never means decompiling or disassembling code: that is on the never-list in
     [`GUARDRAILS.md`](GUARDRAILS.md#the-never-list). The first run didn't need to.

7. **Write report §Static.** Write each claim as a finding with a pointer to its evidence file, how
   it was observed (static), and a confidence tag from `templates/report.md`. Tag guesses
   **[Inferred]** so that Phases 2 and 3 can check them. One of the first run's static guesses
   turned out wrong (see Phase 3).

### Outputs

- `dirty/evidence/static/`: 22 evidence files (21 when `swift-demangle` is missing, since
  `swift-names.txt` is then skipped) plus `SUMMARY.md`.
- Report §Static: identity and distribution, signing, architecture and platform, encryption, sandbox
  and entitlements, embedded engines (name, version, licence, architectures), SDKs, declared
  automation, referenced hosts, size breakdown. All of it is written as findings.

### Pitfalls

- **Running the vendor's bundled tools.** Sandboxed helpers die with `SIGTRAP` (exit code 133) when
  run on their own. Running a vendor's binaries is outside a read-only survey anyway. Read their
  versions with `strings`.
- **Treating strings as facts.** A URL or SDK name in the binary shows that code exists, not that it
  runs. Static conclusions are hypotheses until behaviour or runtime evidence confirms them.
- **Reading only the main executable.** The script's string and symbol files cover the main
  executable. Helpers, frameworks and nested bundles need the step 4 commands.
- **Letting names leak.** Type, field, class and symbol names are the original's own expression. They
  belong in evidence and the report, never in `spec.md`.
- **Wandering outside the bundle.** The survey reads the `.app` and nothing else: not the app's data,
  preferences or caches, and not other apps.

### Done when

- [ ] `re-static.sh` has run and `SUMMARY.md` has been read.
- [ ] Encryption status is recorded. If the app is encrypted, code-level reading stopped there.
- [ ] Every embedded engine has a name, version, licence and architectures, or a note saying why not.
- [ ] Every licence and notice file is listed in the report.
- [ ] Report §Static is written as findings, with unconfirmed guesses marked.
- [ ] Nothing was executed from inside the bundle.

---

## Phase 2 — Behaviour

This phase is descriptive on purpose. It says what to find out and what to record. It does not give
an instrumentation recipe, because none is needed.

### Goal

Describe what the app does from the outside: every feature, input → output, option, default and
edge case. You find this out by using the app normally on throwaway inputs. The spec can then
describe behaviour rather than code.

### Inputs

- `scope.md` and report §Static. The static survey suggests which features exist: document types,
  automation hints and engines.
- A scratch folder, `dirty/behaviour/`.
- Throwaway inputs made with tools built into macOS: `sips` for images, `say` for audio, `textutil`
  for documents. `sips` can't write GPS metadata, but a short Swift script using ImageIO can write
  invented GPS coordinates into a copy of a test image. Never use personal files.
- Read-only tools to inspect outputs, such as `file`, `mdls`, `afinfo`, and `ffprobe` or `exiftool`
  if installed.

### Steps

1. **Plan a feature matrix** from the static survey: each input type × each output × each option
   the UI offers.
2. **Make throwaway inputs** covering the normal and the awkward. Vary sizes; include files with and
   without metadata; add a zero-byte file, a wrong extension, a very large file, names with spaces
   and non-ASCII characters, a read-only destination and an external volume.
3. **Use the app as a normal user would.** In the first run the owner used the app normally on
   throwaway files, and the inputs, outputs and options were recorded. Agents can't see or drive
   menu-bar-only apps with computer use, and may lack screen-capture permission. Plan for the owner
   to click while the agent prepares inputs and measures outputs.
4. **Record each run** in `behaviour/`:
   - the input: type, size, relevant properties;
   - the action and options, as set in the UI, and which values were defaults;
   - the output: type, size, properties, where it landed, how it was named, what happened when a
     file of that name already existed;
   - metadata: kept, changed or stripped (EXIF, GPS, colour profile, timestamps);
   - whether a "lossless" operation re-encoded;
   - time taken, and any message shown, paraphrased in your own words.
5. **Probe the behaviours a rebuild must get right**: several jobs queued, cancelling, quitting
   mid-job, errors on bad input, settings that persist across launches (as seen in the UI), drag and
   drop, multi-file batches.
6. **Check the automation surface the way a user would**: the Shortcuts app's action list, Script
   Editor's dictionary browser, the Services menu, Finder's Open With menu, and any URL scheme declared
   in `info-plist.txt`. The first target had none of these: no URL scheme, no Shortcuts actions and
   no AppleScript.
7. **Stay inside these limits:**
   - Do not read the app's own data, preferences, caches or container, or any data the OS protects.
   - Do not attach debuggers, inject code, or modify the bundle.
   - Do not run the app's bundled tools on their own.
   - Do not feed it real personal files.
   - Do not probe paid features or limits to learn how they are enforced. Use what you paid for and
     record behaviour, not the gate.
   - Treat any screenshots as dirty-side notes, never as material for the rebuild.
8. **Write report §Behaviour**: a feature catalogue; an edge-case table; the automation surface; and
   a "not tested, and why" list. Keep improvement ideas in their own column, apart from what was
   observed.

### Outputs

- `behaviour/`: inputs, outputs and run notes.
- Report §Behaviour, with every row traceable to a run in `behaviour/`.

### Pitfalls

- **Happy path only.** Many of the rebuild's real bugs in the first run were in edge cases: queues,
  cancellation, cross-volume moves and metadata. The original's behaviour in those cases is what the
  spec needs.
- **Missing silent behaviour.** Metadata quietly kept or stripped, and quiet re-encoding, only show up
  if you measure the output.
- **Treating defaults as requirements.** Note which values were defaults. The spec decides which ones
  matter.
- **UI wording in notes.** Paraphrase now, so verbatim text never drifts into the spec later.
- **Expecting the agent to drive the UI.** For menu-bar apps, plan for the owner to do the clicking.

### Done when

- [ ] Every feature from the static survey has been used at least once, or listed as not tested with
      a reason.
- [ ] Edge cases are recorded: bad input, existing output, cancel, queue, quit mid-job.
- [ ] Metadata and lossless behaviour are measured, not assumed.
- [ ] The automation surface is confirmed from the user side.
- [ ] Report §Behaviour is written, with observations separate from improvement ideas.
- [ ] No app data was read, nothing was attached or injected, and no personal files were used.

---

## Phase 3 — Network (optional)

This phase is descriptive on purpose and optional. Pith contains no interception set-up,
certificate or proxy instructions. Point to the capture tool's own documentation instead, and keep
every set-up step with the owner.

### Goal

Know which network calls the app makes on its own behalf, why it makes them, and what that means for
the rebuild. Often the answer is "nothing the rebuild needs". Skip this phase when `scope.md` says to
skip it, or when Phases 1 and 2 already answer the question.

### Inputs

- Explicit owner consent in `scope.md`: the question the capture answers, the hosts and actions in
  scope, and when it will happen.
- Static hints: `strings-hosts.txt`, `strings-sdks.txt`, `privacy-manifests.txt`, and the network
  entitlements in `entitlements.txt`.
- A capture tool the owner chooses and sets up from its own documentation:
  [mitmproxy](https://github.com/mitmproxy/mitmproxy), or Proxyman, which also has an official agent
  skill at [ProxymanApp/proxyman-SKILL.md](https://github.com/ProxymanApp/proxyman-SKILL.md).

### Steps

1. **Write down the question** first, for example: "What does the app send at launch, and is any of
   it my file data?" A capture without a question collects too much.
2. **The owner sets up the capture** from the tool's own documentation. Reading HTTPS traffic needs
   changes to the Mac's trust and proxy settings. Those are owner-only security settings (hard rule
   6). The owner makes them and reverses them when finished.
3. **Capture narrowly**: only the target app, only normal use, a short session (for example launch,
   one typical action, quit).
4. **Record, per call:**
   - the host and its category: commerce, attribution, analytics, crash reporting, update check, or
     a content API;
   - when it fires: launch, purchase screen, a particular feature, quit;
   - whether any user content or file data leaves the Mac;
   - for an API the rebuild might genuinely need, the *shape* of requests and responses, with every
     value redacted.
5. **If you export a HAR file** (HTTP Archive, a JSON record of web requests) for Phase 4, redact it
   before it goes into `captures/`. Remove auth headers, cookies, tokens, receipts, device and user
   identifiers, and personal data.
6. **Compare with Phase 1 and record corrections** (see [Phase 4, step 2](#steps-4)). In the first
   run, an owner-run capture of the app's own launch calls overturned a static conclusion about
   how the app was sold.
7. **Stay inside these limits:**
   - Never bypass certificate pinning, or modify the app or system to force a capture. If the
     traffic can't be read with the owner's ordinary set-up, that is a finding. Record it and stop.
   - Do not read purchase or entitlement payloads beyond noting that they exist. Do not replay,
     modify or forge any request, and touch nothing related to payment or feature gating.
   - Do not capture other apps' traffic, or anyone else's.
   - Do not keep or publish keys, tokens, receipts or personal data.
   - Send nothing to the vendor's servers beyond what normal use sends.
8. **Write report §Network**, plus rows in the report's "what was not captured and the boundary that
   blocked it" table.

### Outputs

- Report §Network: hosts, categories, timing, whether user data leaves the Mac, and corrections.
- Optionally, a redacted HAR in `captures/`, used in Phase 4 to draft an OpenAPI description.
- "Not captured" rows naming the boundary for each, such as pinning, encryption or out of scope.

### Pitfalls

- **Capturing too much.** A whole-machine capture collects other apps' and other people's data.
- **Reading a quiet capture as "no network".** You saw one session, not every code path.
- **Leaving the set-up in place.** Trust and proxy changes are reversed when the capture ends.
- **Forgetting what a HAR holds.** HARs carry cookies and tokens by default.
- **Over-building.** In the first run, the only traffic was a commerce SDK and attribution. The
  rebuild needed none of it.

### Done when

- [ ] Consent and the question are in `scope.md`, or the phase is marked skipped with a reason.
- [ ] Every observed host has a category, timing and a note on whether user data leaves the Mac.
- [ ] Captures are redacted, and nothing secret or personal is kept.
- [ ] Corrections to earlier conclusions are recorded.
- [ ] The "not captured" table names each boundary that stopped you.
- [ ] The owner confirms they have undone any capture set-up, following the tool's own
      documentation.

---

## Phase 4 — Report & spec

### Goal

Turn everything learned on the dirty side into a full **report**, then into a sanitised **spec** that
a clean-side builder can work from without ever seeing the original, and log the crossing.

**Understanding-only exit.** If `scope.md`'s goal is understanding or a report only, finish
`report.md` (steps 1–3) and stop. Skip `spec.md`, the leak review, provenance and Phases 5–7.

### Inputs

- Evidence from Phase 1, `behaviour/` from Phase 2, and `captures/` from Phase 3 if it ran.
- [`templates/report.md`](templates/report.md), [`templates/spec.md`](templates/spec.md),
  [`templates/provenance.md`](templates/provenance.md).

### Steps

1. **Write `dirty/report.md`.** The first run's report was about 115 KB, in these sections:
   - executive summary (four takeaways);
   - architecture;
   - engine;
   - data formats;
   - network / API;
   - automation surface;
   - flaws and improvement targets;
   - rebuild blueprint;
   - legal note;
   - a runtime appendix, including a **"what was not captured and the boundary that blocked it"**
     table.

   Write each claim as a finding: the statement, a pointer to its evidence, how it was observed
   (static, behaviour or network), a confidence tag from `templates/report.md`, and a status. Each
   gap goes in the report's Appendix A.3, with the boundary that caused it. `finding.schema.json` is
   only for Phase 6 review findings.

2. **Record corrections; never overwrite silently.** When later evidence contradicts an earlier
   conclusion, keep the old finding, mark it superseded, and add a correction entry:

   | Field | Example from the first run |
   |---|---|
   | Earlier conclusion | How the app was sold (Phase 1, a guess from static strings) |
   | Evidence that overturned it | Owner-run capture of the app's own launch calls (Phase 3) |
   | Corrected conclusion | A different model, recorded in the private report and left out of public write-ups |
   | What changed downstream | Executive summary, report §Network, the rebuild blueprint's non-goals |
   | Date | when it was recorded |

   Then check whether anything that already crossed the wall depended on the old conclusion. If so,
   amend the spec and log a new crossing (step 8). Corrections are the honest record of how the
   understanding changed, and they show reviewers which conclusions rest on static guesses alone.

3. **Separate observation from improvement.** Keep "what the original does" apart from "what the
   rebuild should do better". [ShadowSwaps/REA-Reconstruction-Companion](https://github.com/ShadowSwaps/REA-Reconstruction-Companion)
   uses the same rule, and its eval topics (preferences, undo, unsaved changes, locale) make a good
   completeness checklist.

4. **Sanitise into `dirty/spec.md`.** This is the draft. The spec says *what* the rebuild must do,
   in your own words.
   - **Keep**: observed behaviours phrased as requirements; public standards (MP3, HEIC, PDF…);
     open-source engines by name, with their public licences; the edge cases and defaults that
     matter; improvement targets, labelled as such; non-goals.
   - **Remove**: the vendor's and app's names; type, field, class and symbol names; strings and UI
     text; asset references; keys and tokens; commerce and gating details; hosts the rebuild doesn't
     need; anything that mirrors the original's code layout.

5. **Use machine-readable parts where they fit.**
   - **Network contracts → OpenAPI** (a standard, machine-readable description of an HTTP API).
     Draft an OpenAPI description from an owner-made, redacted HAR
     with [alufers/mitmproxy2swagger](https://github.com/alufers/mitmproxy2swagger), or with
     [Redocly/redocly-cli](https://github.com/Redocly/redocly-cli). Per the prior-art check, Redocly
     can infer a description from HAR traffic and check a capture for drift; confirm the current
     command names in its docs. Then cut the description down to the calls the rebuild really needs,
     and delete example values. If the only traffic is commerce and attribution, as in the first run,
     write "the rebuild makes no such calls" instead of an OpenAPI file.
   - **File formats → Kaitai Struct** (a language for describing binary file formats). For a
     proprietary format, such as a project or preset file, write a `.ksy` description with [kaitai-io/kaitai_struct](https://github.com/kaitai-io/kaitai_struct),
     working from your own sample files and public documentation. A `.ksy` written from observation is
     a clean-room artifact. [WerWolv/ImHex](https://github.com/WerWolv/ImHex) patterns are an
     interactive alternative. For public standards, as with the first run's images, audio, video and
     documents, cite the standard instead.
   - **Everything else → behavioural specs with acceptance tests.** Give each requirement an ID, a
     *Given / When / Then* statement and a concrete check, for example: "Given a HEIC with GPS
     metadata, when stripped, then the output has no GPS and the image data is byte-identical." These
     checks become Phase 6 harness cases.

6. **Leak review.** Use a fresh reviewer agent on the dirty side, one that can read both the dirty
   material and the draft `dirty/spec.md` but did not write the spec. It checks three things:
   - **structural leakage**: names, module layout or data shapes that mirror the original;
   - **content contamination**: strings, UI text, assets, keys, hosts, the vendor's name;
   - **completeness**: every behaviour the rebuild needs is present, so the clean side won't go
     looking for more.

   Also run the mechanical check in
   [`GUARDRAILS.md` §Leak-review checklist](GUARDRAILS.md#leak-review-checklist-for-specmd) on
   `dirty/spec.md`, before the spec crosses. Fix every hit, or waive it with a reason logged in
   `provenance.md`. Fix the spec and review again until it is clean.
   [prime-radiant-inc/greenfield](https://github.com/prime-radiant-inc/greenfield) is a fuller model
   of this sanitiser-plus-reviewers design.

7. **Owner approval.** The owner reads the spec and approves the crossing.

8. **Log the crossing in `provenance.md`.** Each entry records the date, the spec version (a hash or
   a version number), who or what reviewed it, what was removed, the review result and the owner's
   approval. The log is append-only: entries are added, never edited.
   [lemonadesaltbagel/teardown](https://github.com/lemonadesaltbagel/teardown) does this with a
   signed, hash-chained log; a plain append-only file is enough for Pith. Then copy the approved
   `dirty/spec.md` to `clean/spec.md`.

9. **Answer clean-side questions through the spec.** When the clean side asks something, amend the
   spec, review it again, and log a new crossing. Never paste report excerpts or answer informally
   across the wall. If the clean side needs to know whether its build matches the original, give it
   pass/fail verdicts, not observations. teardown uses the same pattern.

### Outputs

- `dirty/report.md`: dirty side, private.
- `dirty/spec.md`, sanitised, and its approved copy `clean/spec.md`; it may hold an OpenAPI file,
  `.ksy` files and acceptance tests.
- `provenance.md`: at least one logged crossing.

### Pitfalls

- **A spec that mirrors the code.** If the spec's types match the original's field names, that is
  structural leakage, even when no strings were copied.
- **A spec that is too thin.** The clean side guesses, then asks for "just one screenshot". Write
  enough behaviour and acceptance tests that it never needs to.
- **Guesses becoming requirements.** Unconfirmed findings stay labelled in the spec, or stay out.
- **Real values in examples.** OpenAPI drafts copy example values from the capture, so delete them.
- **Reviewing your own spec.** The agent that wrote the spec is the worst one to find its leaks.
- **Publishing the report.** `report.md` and the evidence never leave the private folder.

### Done when

If the goal is understanding only: `report.md` is complete and the owner has read it. The rest of
this list doesn't apply.

- [ ] `report.md` covers every section above and includes the "not captured" table.
- [ ] Every correction is recorded, with the superseded finding kept.
- [ ] `spec.md` states behaviours, formats and contracts in your own words, with acceptance tests.
- [ ] A fresh reviewer and the mechanical check in `GUARDRAILS.md` found no leaks in
      `dirty/spec.md` before it crossed.
- [ ] The owner approved the crossing, it is logged in `provenance.md`, and `clean/spec.md` is the
      logged version.

---

## Phase 5 — Clean-room rebuild

### Goal

Build a new codebase from `spec.md` and public documentation only, and make it better where the
report found flaws.

### Inputs

- `clean/spec.md`, at the version logged in `provenance.md`.
- Public documentation: Apple's frameworks and each open-source engine's own docs.
- Open-source engines, used under their own licences.
- The owner's design choice.
- **Not** the report, the evidence, the original app, screenshots of it, or the dirty-side agent
  session.

### Steps

1. **Set up the clean workspace.** `clean/spec.md` holds the approved spec, at the logged version.
   Create the rebuild's own git repository in `clean/<rebuild>/`. Start a new Claude Code session in
   `clean/`, with the deny rule for `../dirty/**` described under [The wall](#the-wall); any
   subagents it uses receive only `spec.md`. If you want the wall enforced more firmly than a
   permission rule, Claude Code hooks can block reads of the dirty folder.
   [whit3rabbit/clean-room-skill](https://github.com/whit3rabbit/clean-room-skill) shows one way to
   do it.

2. **Build the engine first and keep the front ends thin.** Zest is one Swift package. The `ZestKit`
   library holds the engine, and the `zest` CLI and the `ZestApp` menu-bar app both call it:

   ```swift
   // Package.swift (excerpt)
   products: [
       .library(name: "ZestKit", targets: ["ZestKit"]),
       .executable(name: "zest", targets: ["zest"]),
       .executable(name: "ZestApp", targets: ["ZestApp"]),
   ],
   ```

   ```bash
   swift build
   swift run zest formats        # the CLI against the engine
   swift run ZestApp             # the menu-bar app (no Dock icon)
   ```

3. **Choose engines on purpose.** Use open-source engines under their own licences. Prefer the
   operating system's frameworks to bundling a heavy runtime. Decide whether to bundle an engine or
   find it at runtime. Zest's backends:
   - **ffmpeg** for audio and video;
   - **ImageIO**, with a lossless metadata strip that keeps every byte offset in the file unchanged;
   - **native documents** through NSAttributedString and PDFKit, instead of bundling a Java runtime,
     with LibreOffice used at runtime if present.

4. **Make automation first-class.** The original had none. Zest has a `zest` CLI, a `zest://` URL
   scheme, a Shortcuts intent, and Open With through declared document types. These also make the
   app testable by agents in Phase 6, because agents can't drive a menu-bar UI.

5. **Design the UI from the spec, not from the original's look.** Mock two or three design
   directions as HTML artboards, render them to PNG for reference, and let the owner pick. The first
   run mocked three directions, and the owner picked "Citrus".

   ```bash
   mkdir -p mockups/png && qlmanage -t -s 1600 -o mockups/png mockups/citrus.html
   # writes mockups/png/citrus.html.png; with no output folder it reports success and writes nothing
   ```

   `qlmanage` worked where headless browsers sometimes hung.

6. **Fan out to parallel agents, contract first.**
   - Write the shared contract before any agent starts: theme tokens, model types, shared geometry,
     and stubs that compile.
   - Give each agent its own copy of the package, so builds don't fight over the build lock:

     ```bash
     rsync -a --exclude .build ./ ../rebuild-agent-ui/
     ```

   - Give each agent a list of the files it owns, and copy back only those files. Then build the
     merged tree.
   - Follow each agent with a fresh-eyes polish agent for the same area.

   Zest's UI was built this way, by four parallel agents.

7. **Know your toolchain.** With only the Command Line Tools (no full Xcode):
   - SwiftUI's `@State` is a macro whose plugin ships only with Xcode. Use `@StateObject` with a
     small `ObservableObject` holder instead.
   - `#Preview` and XCTest are unavailable, so write a dependency-free self-test runner (Phase 6).
   - AppIntents metadata extraction needs Xcode. The URL scheme works without it.

8. **The owner approves commits.** The agent proposes each commit and waits for a yes.

9. **New features are ordinary product work.** Zest later gained a link downloader that finds
   `yt-dlp` at runtime. That is part of the rebuild, not reverse engineering, so it needs no wall.
   Licences and site terms still apply.

### Outputs

- A new repository that builds from clean.
- An engine library, front ends (CLI, app, automation surfaces) and a draft README.

### Pitfalls

- **Contamination.** It shows up as an agent with dirty context writing code, a report excerpt
  pasted "just this once", remembered UI text, or a reused icon, name or colour. If it happens,
  follow the contamination runbook in [`GUARDRAILS.md`](GUARDRAILS.md).
- **`Process.waitUntilExit()` hanging.** It can hang when called off the thread that launched the
  process. Set a `terminationHandler` before `run()` and wait on that instead.
- **Global settings leaking into special paths.** In Zest, "Strip" silently re-encoded because a
  global quality setting pushed it off the lossless path. Make lossless paths explicit, and test them.
- **Shared build folders.** Parallel agents in one folder clash on the build lock.
- **"The original bundled it."** That is not a reason to bundle a runtime, and it is not a licence.

### Done when

- [ ] The clean side worked only from `spec.md` and public docs, in a separate session and repository.
- [ ] `swift build` (or your stack's equivalent) succeeds from a clean checkout.
- [ ] Every spec requirement maps to code or to an explicit "not done".
- [ ] Engines are chosen, with each one's licence noted.
- [ ] The owner chose the design and approved each commit.

---

## Phase 6 — Verification

### Goal

Show that the rebuild does what the spec says on real files, looks right in every state, and
survives adversarial review. Say plainly what was not verified.

### Inputs

- The rebuild.
- The spec's acceptance tests.
- Throwaway real files, made with built-in tools (see Phase 2, Inputs, for metadata such as GPS).
- Reviewer and verifier agents.
- [`templates/finding.schema.json`](templates/finding.schema.json), the shape of a review finding.

### Steps

1. **Self-tests that need no dependencies.** XCTest isn't available with only the Command Line
   Tools, so the checks run from the product itself:

   ```bash
   swift run zest selftest        # engine checks: 81 in Zest
   swift run ZestApp --selftest   # app-layer checks: 45 in Zest
   ```

   A runner can be this small (illustrative):

   ```swift
   final class SelfTest {
       private(set) var failures = 0
       func check(_ name: String, _ condition: () throws -> Bool) {
           let ok = (try? condition()) ?? false
           print(ok ? "PASS" : "FAIL", name)
           if !ok { failures += 1 }
       }
   }
   // let t = SelfTest(); t.check("parses quality 0.8") { ... }; exit(t.failures == 0 ? 0 : 1)
   ```

2. **A snapshot renderer.** Agents can't see menu-bar-only apps, so build visual verification into
   the product:

   ```bash
   swift run ZestApp --snapshot snapshots   # Zest: 46 PNGs, every surface and state, light and dark
   ```

   Use `ImageRenderer` for pure-SwiftUI views and window capture for AppKit-backed controls.
   `NSView.cacheDisplay` flips SwiftUI shadow offsets, so don't mistake that for a layout bug.

3. **An end-to-end harness on real files.** It makes inputs with built-in tools, runs the real CLI
   (and the URL scheme, once the app is packaged), and checks outputs with *independent* read-only
   tools. Write one check per acceptance test. Zest's harness has 33 checks, plus a local HTTP server
   for link tests. A skeleton:

   ```bash
   #!/bin/zsh
   # e2e.sh: real files in, real files out; exits non-zero on any failure.
   # Run from the package root after `swift build`.
   set -u
   W="$(mktemp -d)"; fails=0
   CLI="$(swift build --show-bin-path)/zest"
   check() {                         # check "<name>" '<shell test>'
     if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"
     else echo "FAIL  $1"; fails=$((fails + 1)); fi
   }

   printf 'Hello\n' > "$W/note.txt"
   textutil -convert docx "$W/note.txt" -output "$W/note.docx"     # throwaway document
   "$CLI" convert "$W/note.docx" "$W/note.pdf"
   check "DOCX to PDF writes a PDF" 'file "$W/note.pdf" | grep -q "PDF document"'

   # link tests: serve fixtures locally, never from the internet
   python3 -m http.server 8765 --bind 127.0.0.1 --directory "$W" >/dev/null 2>&1 &
   SERVER=$!; trap 'kill $SERVER 2>/dev/null' EXIT
   # ... link checks against http://127.0.0.1:8765/ go here

   echo "$fails failure(s)"; exit $(( fails > 0 ))
   ```

   Check results with something other than the rebuild's own reader. For example, confirm GPS is gone
   with a separate metadata tool, not with the rebuild's `inspect` command.

4. **Multi-agent adversarial review, in rounds.**
   - Choose the review dimensions, for example: conversion correctness, process and concurrency
     handling, file safety (overwrites, moves, other volumes), privacy and metadata, automation
     inputs (URL-scheme parameters), UI states, packaging and licences, and spec conformance.
   - Assign **one reviewer per dimension**. Each finding states the severity, the file and line, and a
     concrete failure scenario, in the shape of `finding.schema.json`.
   - Assign **one adversarial verifier per dimension**. It must reproduce each finding with a failing
     command, test or harness case, or refute it.
   - Rank the kept findings by severity and fix them. Re-run the harness after the fixes, and add a
     regression check for each one.
   - Repeat until a round confirms nothing above low severity, or the owner stops it.

   Zest's rounds: round 1 kept 15 bugs (refutations not recorded); round 2 kept 49 and refuted 1;
   round 3 kept 39 and refuted 1. That is over 100 fixes in all. The verifiers refuted one finding in
   each of rounds 2 and 3, and that is why the verifier exists. The first run stopped after round 3.

   Notable real bugs it caught:
   - `Process.waitUntilExit()` hung when called off the launching thread.
   - "Strip" silently re-encoded, because a global quality setting pushed it off the lossless path.
   - Queued automation cancelled a running job.
   - A cross-volume move lost a finished download.
   - Image → PDF kept GPS metadata.

   Related prior art: [amd2g2zz/kunglao-agent](https://github.com/amd2g2zz/kunglao-agent) uses a
   blind verifier, and it is AGPL-3.0, so borrow ideas, not code.
   [Dryxio/reagent](https://github.com/Dryxio/reagent) runs maker and checker loops.
   [climashscape/agentic-cleanroom](https://github.com/climashscape/agentic-cleanroom) offers
   ratchets (checks that only let a score improve), golden masters (saved known-good outputs to
   compare against) and pixel diffs.

5. **Re-run everything several times.** One green run proves little. In the first run, a hang that
   showed up only under certain timing led to the `waitUntilExit` discovery.

6. **Check conformance to the spec.** Map every acceptance test to a passing check. If the spec has a
   network contract, check the rebuild's traffic against it, for example with Redocly CLI's drift
   check (confirm the command in its docs, as in Phase 4).

7. **Write the verification record.** State what was verified (counts, machine, toolchain) and what
   was not. One example from Zest: the Shortcuts action needs a full Xcode build to show up in the
   Shortcuts app.

### Outputs

- Passing self-tests, a snapshot set, a harness log, review reports with kept and refuted counts, and
  a fix list.
- A verification record that is honest about the gaps.

### Pitfalls

- **Grading with your own ruler.** A metadata stripper checked by its own inspector proves little.
- **Findings without reproduction.** Unverified findings waste fixes, and some are wrong.
- **Fixing without re-running the harness.** Fixes break neighbouring behaviour.
- **One green run.** Flaky hangs only show up on repeat runs.
- **Relying on computer use for menu-bar UI.** It can't see those apps. Snapshot mode and URL-scheme
  flows can.

### Done when

- [ ] Both self-test suites pass.
- [ ] The snapshot set renders every surface and state in light and dark mode, and someone has
      looked at it.
- [ ] The end-to-end harness passes on real files, over several runs.
- [ ] Review rounds were repeated until a round confirmed nothing above low severity, or the owner
      stopped them. Every kept finding is fixed or deferred with a reason, and fixes are re-checked.
- [ ] The verification record states what was and wasn't verified.

---

## Phase 7 — Package & publish

### Goal

Ship an app bundle that registers its URL scheme and document types. Honour every licence, publish
an honest README, and get the owner's approval for each outward-facing step.

### Inputs

- The verified rebuild and its verification record.
- An `Info.plist` for the app.
- The licence texts of every engine.
- The owner's publication decision from `scope.md`.

### Steps

1. **Use a package script.** Zest's `Scripts/package-app.sh` makes a release build, assembles the
   `.app`, signs it ad hoc (a signature with no developer certificate behind it), and registers it
   with Launch Services (the macOS database of apps, URL schemes and document types). Generic shape:

   ```bash
   #!/bin/zsh
   set -e
   APP=dist/MyApp.app
   ARCHS=(--arch arm64 --arch x86_64)                       # universal: Apple silicon + Intel
   swift build -c release "${ARCHS[@]}" --product MyApp
   swift build -c release "${ARCHS[@]}" --product mycli
   BIN="$(swift build -c release "${ARCHS[@]}" --product MyApp --show-bin-path)"

   rm -rf "$APP"
   mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Helpers"
   cp "$BIN/MyApp" "$APP/Contents/MacOS/MyApp"
   cp "$BIN/mycli" "$APP/Contents/Helpers/mycli"            # the CLI ships inside the app
   cp Packaging/Info.plist "$APP/Contents/Info.plist"
   printf 'APPL????' > "$APP/Contents/PkgInfo"

   codesign --force --deep --sign - "$APP"                  # ad-hoc signature
   LSREG=/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister
   "$LSREG" -f "$APP"                                       # register URL scheme and document types
   ```

2. **Fill in the `Info.plist` keys that matter.**

   | Key | Why |
   |---|---|
   | `CFBundleExecutable`, `CFBundleIdentifier` | Identity. Use your own identifier, never the original's. |
   | `LSUIElement` = true | A menu-bar app with no Dock icon. |
   | `CFBundleURLTypes` | Your URL scheme, such as `zest://`, available system-wide once registered. |
   | `CFBundleDocumentTypes` with `LSItemContentTypes` | Open With for the formats you handle. `LSHandlerRank` = `Alternate` adds you to the menu without taking over the user's defaults. |
   | `LSMinimumSystemVersion` | Match your package's platform. Zest uses macOS 13. |

   If full Xcode is installed, also extract AppIntents metadata so the Shortcuts action appears.
   Zest's script tries this and skips it under the Command Line Tools.

3. **Leave install-time steps to the owner.** Putting the bundled CLI on `PATH` needs `sudo`, so the
   owner runs it in their own terminal. The agent only prints the command.

4. **Be honest about signing.** The app is ad-hoc signed, not notarized. Notarization is Apple's
   check-and-approve step for apps shared outside the App Store, and it needs an Apple Developer ID,
   which costs $99 a year. On other Macs the first launch has to be approved in System Settings ›
   Privacy & Security › Open Anyway (since macOS 15, right-click › Open no longer overrides
   Gatekeeper). If you share a disk image, include a short guide; Zest's `Scripts/make-dmg.sh`
   builds one.

5. **Honour every licence.** List every engine, whether bundled or found at runtime, with its licence
   and what it requires of you. "The original app ships it" is not a licence. If you bundle an
   LGPL-class FFmpeg, for example, keep its notices, provide its source as the licence requires, and
   don't ship a GPL-enabled build inside a non-GPL app. Zest finds `ffmpeg` and `yt-dlp` on the
   user's machine at runtime instead of bundling them.

6. **Write an honest README.** Say what the rebuild is: an independent, clean-room tool with no
   affiliation to any vendor. Prefer not to name the original. Then cover how to build, test and
   package it, what was verified (with numbers), what wasn't, the signing status, and the licences.

7. **Run the pre-publish checks.**

   ```bash
   # Dirty-side files must not be tracked, now or in history. Both should print nothing.
   git ls-files | grep -Ei 're-out/|report\.md|provenance\.md|captures/|\.har$'
   git log --all --name-only --format= | grep -Ei 're-out/|report\.md|captures/|\.har$'

   # No key-shaped strings in the repository
   git grep -nE '(appl_|goog_|amzn_|sk_live_|pk_live_|AIza|AKIA|ghp_|xox[bap]-)[A-Za-z0-9_-]{8,}'

   # The vendor's and original app's names appear nowhere. Keep this word list outside the repo.
   git grep -niE -f ~/private/vendor-words.txt
   ```

   Also check commit messages, screenshots, test-fixture names and the app icon.

8. **Check prior art before publishing.** Run a multi-angle GitHub search for similar projects and
   name collisions, then have a separate agent verify what the searchers reported. Pith's own
   related-work list (`README.md` §Related work) came from such a check, run on 2026-10-22.

9. **The owner approves each outward-facing action.** The agent asks before every commit, push,
   release or post, and the owner says yes or no each time. In the first run the agent asked before
   every one.

### Outputs

- `dist/<App>.app`, and optionally a disk image.
- `README.md`, `LICENSE`, and third-party notices.
- A public repository, if the owner chose one. Zest is at
  [github.com/rohitthink/Zest](https://github.com/rohitthink/Zest).

### Pitfalls

- **Gatekeeper surprises.** Gatekeeper, the macOS first-launch check, blocks un-notarized apps on
  other Macs. Say so in the README.
- **A missing Shortcuts action.** It needs AppIntents metadata, which needs Xcode. The URL scheme
  doesn't.
- **Dirty files in git history.** Deleting them in a later commit doesn't remove them from history.
- **The vendor's name in places you forget**: commit messages, fixture file names, screenshots.
- **Overclaiming.** The README says only what the verification record supports.

### Done when

- [ ] The package script builds, signs and registers the app from a clean checkout.
- [ ] The URL scheme and Open With work from outside the terminal.
- [ ] Every engine's licence is honoured and documented.
- [ ] The pre-publish checks print nothing, and the vendor's name appears nowhere.
- [ ] The README is honest about verification, signing and gaps.
- [ ] The owner approved each commit, push and release.

---

## Other targets

Pith was first run on a **native macOS Swift app**: sandboxed, menu-bar only, from the Mac App Store
without FairPlay encryption. That is the only profile tested end to end. The notes below are
starting points, not tested recipes. Corrections from real runs are welcome.

| Profile | How to spot it | What changes | Tested? |
|---|---|---|---|
| **Electron** | `Built with` = `Electron` | The app's logic is JavaScript in `Contents/Resources` (often an `app.asar` archive), not in the main executable. `re-static.sh` still reports signature, entitlements and bundle layout, but its string files cover only the Electron shell. Readable JavaScript is effectively source code, so the contamination risk is higher: keep it strictly dirty-side and lean on Phase 2. | No |
| **Mac Catalyst** | `Built with` = `Mac Catalyst`; the platform in `executable.txt` is `MACCATALYST` | An iPad app built for the Mac. The static survey works as for native apps. Expect UIKit-style behaviour and iPad-like settings. | No |
| **iOS app on a Mac** | `Built with` = `iOS app (wrapped)` | Usually FairPlay-encrypted. The bundle wraps an iOS app, and `re-static.sh` was written for Mac-style bundles with a `Contents/` folder; it has not been tested on wrapped apps. Record the encryption as a finding and work from behaviour (Phase 2) only. Never decrypt. | No |
| **Command-line tools** | A bare executable, not an `.app` | `re-static.sh` needs an `.app`. Use the same read-only tools (`otool`, `strings`, `codesign`, `lipo`) by hand. Behaviour is easy to script, but `--help` text is UI text, so paraphrase it. | No |
| **File formats** | The target is a format rather than an app | Phases 2 and 4 carry the weight. Describe the format in Kaitai `.ksy` from your own sample files and public documentation, and build readers and writers against those samples. | No |
| **Web APIs** | The app is a thin client for a service | Phase 3 becomes central, but only for your own account and only within the service's terms. Prefer official API documentation to captures. Produce OpenAPI. Never work around authentication, rate limits or paywalls. | No |
| Qt, Flutter, Java, CEF | `Built with` column | The inventory detects these, but no run has used them. | No |

---

## Tools by phase

Pith runs existing tools; it doesn't replace them. The tools for each phase, with notes on what to
integrate, are listed once, in
[`README.md` §Related work](README.md#related-work--what-to-integrate). Everything there is optional
unless a phase above says otherwise. Anything a tool shows you about the original stays on the dirty
side.
