# Report — {App} {version}

> [!WARNING]
> **Dirty side.** This report describes someone else's app from evidence. Never give it to a
> clean-side agent, quote it to one, or paste from it into `spec.md`. Only the sanitised spec
> crosses the wall, after a leak review, and every crossing is logged in `provenance.md`.

<!--
Phase 4 of Pith (Report & spec), filled in as phases 1–3 run. Sections 1–9 are the findings;
the appendices hold the runtime notes, the gaps, the corrections and the evidence list.
Length follows the app: the first run's report was about 115 KB.

Rules for every section:
- Write in your own words. Summarise evidence; don't paste symbol lists or long strings.
- Tag every claim with a confidence tag (legend below). If you didn't check it, say so.
- Never write keys or tokens (re-static.sh already redacts key-shaped strings; never undo
  that), receipts, account or device ids, captured personal data, or how purchases, trials
  or free tiers are enforced.
- Don't describe or read the app's protected container or stored data.
- If a section doesn't apply, write "none" or "not studied" and say why.

For a wider checklist of what to look at in an Apple app (entitlements, storage, network),
OWASP MASTG (https://github.com/OWASP/mastg) is useful. It is a security-testing guide;
Pith uses it only as a list of places to look.
-->

| | |
|---|---|
| Target | {App} {version} ({build}) · `{bundle id}` |
| Scope | `scope.md`, signed {YYYY-MM-DD} |
| Evidence | `dirty/evidence/static/` from `scripts/re-static.sh`, run {YYYY-MM-DD}; behaviour notes and inputs in `dirty/behaviour/`; {capture exports in `dirty/captures/`, if Phase 3 ran} |
| Phases covered | 1 Static survey: {done} · 2 Behaviour: {done} · 3 Network: {done / skipped, because …} |
| Authors | {owner}, {agent session(s)} |
| Report version | {v1}, {YYYY-MM-DD} |

**Confidence tags** (one on every claim):

- **[Observed]** seen while running the app (Phase 2 or 3).
- **[Static]** read from the bundle without running it (Phase 1).
- **[Inferred]** reasoned from other facts and not checked.
- **[Corrected, C-n]** an earlier conclusion that later evidence changed. See Appendix B.

**Where each phase writes** (other Pith docs call these groups report §Static, §Behaviour and
§Network; the headings below carry the same labels):

| Phase | Sections |
|---|---|
| 1 Static survey (§Static) | 2 Architecture, 3 Engine and tooling, the declared parts of 4 and 6, the static hints in 5, Appendix C |
| 2 Behaviour (§Behaviour) | Appendix A.1, the observed parts of 4 and 6 |
| 3 Network, optional (§Network) | 5 Network and API, Appendix A.2 |
| 4 Report & spec | 1 Executive summary, 7 Flaws, 8 Blueprint, 9 Legal note, Appendices A.3 and B |

## 1. Executive summary

<!--
Write this last. N takeaways; three to five is typical, and the first run had 4. Each one is
a finding in one sentence, then what it means for the rebuild, then a confidence tag.

Example, based on the first run: "Most of the download is a Java runtime, shipped once for
each CPU architecture. A rebuild that renders documents natively doesn't need it. [Static]"
-->

1. **{Finding.}** {What it means for the rebuild.} [{tag}]
2. **{Finding.}** {What it means for the rebuild.} [{tag}]
3. **{Finding.}** {What it means for the rebuild.} [{tag}]
4. **{Finding.}** {What it means for the rebuild.} [{tag}]

## 2. Architecture (§Static)

<!--
What the app is made of and how the parts fit together.

Sources in the evidence folder: SUMMARY.md; executable.txt (architectures, minimum macOS,
SDK, encryption); linked-libraries.txt; frameworks.txt; nested-bundles.txt;
entitlements.txt (the permissions the app declares to macOS, including the sandbox);
info-plist.txt (e.g. LSUIElement, which makes it a menu-bar agent with no Dock icon).
For the shape of the code: swift-names.txt, swift-field-names.txt (Swift reflection
metadata, which survives stripping) and objc-classes.txt. Read them to understand, then
describe the design in your own words. These names never cross the wall.

If you need more than the script gives: ipsw (https://github.com/blacktop/ipsw) dumps
Objective-C and Swift type metadata. Its output stays on the dirty side. Don't decompile or
disassemble code (see the never-list in Pith's GUARDRAILS.md).

If the executable is FairPlay-encrypted (Apple's App Store encryption), its code and
strings can't be read statically. Record that, don't try to decrypt it, and lean on
Phase 2 instead.
-->

- **Kind of app:** {menu-bar agent / windowed app / both} [{tag}]
- **Language and UI:** {e.g. Swift with SwiftUI and AppKit} [{tag}]
- **Architectures and minimum macOS:** {e.g. arm64 and x86_64; macOS 13 or later; built with SDK …} [{tag}]
- **Distribution and signing:** {Mac App Store / Developer ID; hardened runtime yes/no} [{tag}]
- **Sandbox and entitlements that matter:** {e.g. sandboxed; reads and writes user-selected files; network client} [{tag}]
- **Encryption:** {not FairPlay-encrypted / FairPlay-encrypted, so static reading stopped here} [{tag}]

| Component | What it does | Evidence | Confidence |
|---|---|---|---|
| {main app} | {…} | {evidence file} | {tag} |
| {helper / extension / bundled tool} | {…} | {…} | {tag} |

```text
{optional sketch of how the parts connect, e.g.
 UI ──> job queue ──> engine adapters ──> bundled tools}
```

## 3. Engine and tooling (§Static)

<!--
Bundled engines, helper tools, runtimes and libraries: what they are, which version, under
which licence, and what each is used for.

Sources: embedded-executables.txt, frameworks.txt, licence-files.txt, size.txt. Read
versions from strings, notice and licence files, not by running the tools. Sandboxed helper
tools inside an app bundle die with SIGTRAP (exit 133) when run on their own, and running a
vendor's binaries is outside a read-only survey anyway.
-->

| Engine / library | Version | Licence | How it's bundled | Size | Used for | Evidence | Confidence |
|---|---|---|---|---|---|---|---|
| {e.g. FFmpeg build} | {…} | {e.g. LGPL-class} | {e.g. helper executable} | {…} | {…} | {…} | {tag} |

**What makes up the download:** {e.g. "a runtime shipped twice, once per CPU architecture, is most of it"} [{tag}]

**Notes:** {anything surprising: duplicated runtimes, unused engines, outdated versions with known problems}

## 4. Data formats

<!--
Every file type the app reads or writes, plus any settings or project files it makes.

Declared types: info-plist.txt (CFBundleDocumentTypes, UTImportedTypeDeclarations,
UTExportedTypeDeclarations). Observed behaviour: Appendix A.1.

For standard formats, name the standard and record the options the app uses: quality,
colour profile, which metadata it keeps or strips, and how it names output files.

For a custom format, describe its structure from files the app produced from throwaway
inputs, and draft a Kaitai Struct file (.ksy, a declarative description of a binary layout;
https://github.com/kaitai-io/kaitai_struct). Choose your own field names. The spec can
reference the .ksy once it passes the leak review.

Don't open or describe the app's protected container or stored data.
-->

| Format | Read / write | Standard or custom | Options and variants seen | Metadata handling | Evidence | Confidence |
|---|---|---|---|---|---|---|
| {e.g. PNG} | {read, write} | {standard} | {…} | {e.g. keeps colour profile, strips location} | {B-n} | {tag} |

## 5. Network and API (high level) (§Network)

<!--
Static hints first: strings-hosts.txt, strings-sdks.txt, privacy-manifests.txt. Runtime
observation from Phase 3, if the owner consented and ran it, confirms or corrects them
(Appendix A.2).

Write at this level: which hosts are contacted (by role), when, what kinds of data are sent
(categories, never values), and whether the user's files ever leave the Mac.

Never write: keys, tokens, cookies, receipts, account or device ids, request bodies with
personal data, or how purchases or trials are checked.

For a machine-readable description of the app's own calls (OpenAPI, a standard description
of an HTTP API), see the docs of mitmproxy2swagger (https://github.com/alufers/mitmproxy2swagger)
and Redocly CLI (https://github.com/Redocly/redocly-cli). That OpenAPI draft stays on this
side until it is sanitised for spec.md.
-->

| Role | Host or category | When | Data categories sent | User files leave the Mac? | Confidence |
|---|---|---|---|---|---|
| {e.g. purchases (commerce SDK)} | {…} | {e.g. at launch} | {e.g. app version, purchase state} | {no} | {tag} |
| {e.g. attribution} | {…} | {…} | {…} | {no} | {tag} |

**Summary:** {e.g. "No traffic of the app's own; only third-party commerce and attribution SDKs."} [{tag}]

**OpenAPI draft:** {dirty-side path / "none: the rebuild needs none of these calls"}

## 6. Automation surface

<!--
How other tools can drive the app. Sources: info-plist.txt (CFBundleURLTypes, NSServices,
OSAScriptingDefinition, CFBundleDocumentTypes), strings-automation.txt, nested-bundles.txt
(.appex extensions). In Phase 2, try each declared surface as a normal user would.
-->

| Surface | Present? | Details | Evidence | Confidence |
|---|---|---|---|---|
| URL scheme | | | | |
| Shortcuts / App Intents | | | | |
| AppleScript (scripting dictionary) | | | | |
| Services menu | | | | |
| Open With / document types | | | | |
| Command-line tool | | | | |
| Drag and drop | | | | |
| Share or Finder extensions | | | | |

## 7. Flaws and improvement targets

<!--
Problems a user would notice, or that the evidence shows, each paired with a target for the
rebuild. These become proposed improvements (IMP-) in spec.md, kept separate from observed
behaviour (OBS-). Rate impact from the user's side.

Examples, based on the first run: "No automation surface at all, so a URL scheme, Shortcuts
action and command-line tool are targets." "Most of the download is a bundled runtime, so a
native document backend is a target."
-->

| # | Flaw | Evidence | Impact | Improvement target | Confidence |
|---|---|---|---|---|---|
| F-1 | {…} | {…} | {high / medium / low} | {…} | {tag} |

## 8. Rebuild blueprint

<!--
A proposal for the replacement, based on what you learned about the job, not on how the
original is built inside. It is still dirty-side text: spec.md is rewritten from it, not
pasted.

Example shape (the first run's rebuild, which is public): an engine library with backends
(ffmpeg; ImageIO with a lossless metadata strip; native document rendering instead of a
bundled runtime), a command-line tool, a menu-bar app, a URL scheme, a Shortcuts action
and Open With. See case-studies/zest.md in the Pith repo.
-->

- **Shape:** {e.g. engine library + command-line tool + menu-bar app}
- **Interfaces:** {e.g. CLI, app, URL scheme, Shortcuts, Open With}
- **Deliberately not built:** {…}
- **Biggest risks:** {…}
- **How it will be verified (Phase 6):** {self-tests, end-to-end harness on real files, visual snapshots, adversarial review}

| Engine | Licence | Bundled or found at runtime | Why this one |
|---|---|---|---|
| {…} | {…} | {…} | {…} |

## 9. Legal note

<!--
Facts, not arguments. See Pith's GUARDRAILS.md. This is not legal advice; laws differ by
country, and when in doubt, ask a lawyer.
-->

This is not legal advice.

- **Ownership:** {how the owner acquired the app; see `scope.md`}
- **Purpose:** {understanding / interoperability / clean-room replacement}
- **What was done:** a read-only static survey; normal use on throwaway files; {an owner-run, consented observation of the app's own network calls / no network observation}.
- **What was not done:** no decryption, no patching, no bypassing of licence checks, paywalls, trials or certificate pinning, no getting around macOS privacy protections, no reading of the app's protected data, and no running of the vendor's helper tools on their own.
- **The app's licence terms:** {relevant clauses, in your words, or "none found"}
- **Law the owner may want to read (examples):** US DMCA §1201(f) on interoperability; EU Directive 2009/24/EC Art. 6 on decompilation for interoperability.
- **Must not be published:** the vendor's name, any key noticed (redacted in the evidence), payment or gating internals, captured personal data.

| Open-source component the rebuild may reuse | Licence | What the licence asks of the rebuild (from the licence text) |
|---|---|---|
| {…} | {…} | {e.g. notices, offering source, keeping it replaceable} |

## Appendix A — Runtime observations

### A.1 Behaviour (Phase 2) (§Behaviour)

<!--
Use the app the way a normal user would, on throwaway inputs made for this run, kept in
dirty/behaviour/. macOS's built-in sips, say and textutil can make sample images, spoken
audio and documents; a short Swift script using ImageIO can write invented GPS coordinates
into a copy of a test image. Record inputs, options and outputs.

Don't use personal files, don't connect real accounts, and don't try to unlock paid
features.

Observation ids (B-1, B-2, …) let spec.md trace a requirement back to this report without
quoting it.
-->

**Environment:** macOS {version} · {App} {version} · {YYYY-MM-DD} · licence state: {e.g. "paid, unlocked by the owner"}

| Input | Made with | Properties |
|---|---|---|
| {e.g. sample.png} | {e.g. sips} | {e.g. 64×64, sRGB, no metadata} |

| ID | What I did | Input | Options | Result | Output properties | Confidence |
|---|---|---|---|---|---|---|
| B-1 | {…} | {…} | {…} | {…} | {…} | [Observed] |

### A.2 Network (Phase 3, optional) (§Network)

<!--
Only if scope.md ticks Phase 3 with the owner's consent. The owner runs the capture tool
and follows that tool's own documentation: mitmproxy (https://docs.mitmproxy.org,
https://github.com/mitmproxy/mitmproxy) or Proxyman (see its own documentation; its
official agent skill is https://github.com/ProxymanApp/proxyman-SKILL.md). Pith doesn't
describe how to set them up.

Record only the app's own traffic, at the level below. If traffic is pinned or otherwise
protected, record that as a boundary in A.3 and stop there.

Keep the raw capture export in dirty/captures/, never in a repository. It can contain
tokens and personal data.
-->

| ID | Trigger | Role / host | Method and path shape | Data categories | Notes |
|---|---|---|---|---|---|
| N-1 | {e.g. app launch} | {…} | {e.g. GET /v1/…} | {e.g. app version, locale} | {…} |

### A.3 Not captured, and the boundary that blocked it

<!--
Be explicit about gaps, so a reader knows what this report can't tell them. Kinds of
boundary: OS protection, encryption, certificate pinning, sandbox, a scope decision, a Pith
rule, a tooling limit, time.

Examples (illustrative; the first comes from the first run):
- Wanted: versions of the bundled helper tools by running them. Boundary: sandboxed helpers
  trap (SIGTRAP, exit 133) when run alone, and running the vendor's binaries is outside a
  read-only survey (sandbox, rule). Instead: read the versions with strings. Effect on the
  spec: none.
- Wanted: how the free tier is limited. Boundary: payment and gating internals are out of
  scope (rule). Instead: not investigated. Effect on the spec: the rebuild defines its own
  terms, if any.
- Wanted: the app's stored settings and data. Boundary: protected by macOS and out of scope
  (OS protection, scope). Instead: inferred defaults from behaviour. Effect on the spec:
  defaults are specified fresh.
-->

| What we wanted | Boundary that blocked it | Kind | What we did instead | Effect on the spec |
|---|---|---|---|---|
| {…} | {…} | {…} | {…} | {…} |

## Appendix B — Corrections log

<!--
When runtime evidence disagrees with a static guess, or a later observation with an earlier
one, don't edit silently. Add a row, update the section, and tag the claim
[Corrected, C-n].

Example from the first run: the static reading suggested one way the app was sold;
the owner-consented observation of the app's launch calls showed another.
-->

| ID | Date | Section | Earlier conclusion | New evidence | Corrected conclusion |
|---|---|---|---|---|---|
| C-1 | {YYYY-MM-DD} | {n} | {…} | {…} | {…} |

## Appendix C — Evidence index

<!--
Every source this report relies on, so each claim can be traced. If you used other tools
(ipsw, REA at https://github.com/morluto/rea), list them here. Their output stays on the dirty side, like everything else in this file.
-->

| Source | Produced by | Date | Used in sections |
|---|---|---|---|
| `dirty/evidence/static/SUMMARY.md` and its evidence files | `scripts/re-static.sh` | {YYYY-MM-DD} | {2, 3, 4, 5, 6} |
| Behaviour notes | owner and agent, Phase 2 | {YYYY-MM-DD} | {A.1, 4, 6} |
| {capture export} | {owner, Phase 3} | {YYYY-MM-DD} | {5, A.2} |

## Done when

- [ ] Every section has content, or "none" / "not studied" with a reason.
- [ ] Every claim carries a confidence tag, and corrections are logged in Appendix B.
- [ ] Appendix A.3 lists every gap and the boundary behind it.
- [ ] No keys, tokens, payment internals or personal data appear anywhere in this file.
- [ ] The executive summary was written last, and each takeaway says what it means for the rebuild.
- [ ] The owner has read the report.
- [ ] (If rebuilding) `spec.md` has been written from it, leak-reviewed, approved by the owner, and the crossing logged in `provenance.md`. If the goal is understanding only, the report is the end of the run.
