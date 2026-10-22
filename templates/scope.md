# Scope — {run name}

<!--
Phase 0 of Pith: Scope & consent. The agent can draft this file, but the owner decides
every line and signs it off. No other phase starts until section 8 is signed.

This file names the target app, so it stays on the dirty side, at
~/pith-work/{app}/dirty/scope.md: outside the rebuild's repository and out of anything you
publish. The clean side gets the
goals it needs through spec.md, written in its own words.

Placeholders look like {this}. Replace them, or write "none" or "not applicable". Don't
leave a line blank.

Not legal advice. If you're unsure whether you may study this app where you live, ask a
lawyer before you start.
-->

| | |
|---|---|
| Run name | {short name that doesn't include the vendor's name, e.g. "menubar-converter-2026"} |
| Owner | {your name} |
| Agent | {e.g. Claude Code, model, session} |
| Opened | {YYYY-MM-DD} |
| Machine | {Mac model, chip, macOS version} |

## 1. Target

<!--
Copy the target's row from scripts/re-inventory.sh (its output is kept as dirty/inventory.md),
which lists installed apps with their bundle id, version, architectures, how each was built and
where it came from. It only reads
Info.plists and Mach-O headers (the macOS executable format); it runs nothing it finds.
-->

| | |
|---|---|
| App name | {App} |
| Bundle id | `{com.example.app}` |
| Version (build) | {1.2.3 (456)} |
| Path | `/Applications/{App}.app` |
| Architectures | {arm64, x86_64} |
| Built with | {native / Electron / Qt / Flutter / Java / Mac Catalyst / CEF / iOS app (wrapped)} |
| Source | {App Store / Developer ID / development build / ad-hoc signed / unsigned / other} |
| One-line description | {what it does for you, in your own words} |

## 2. Ownership

<!--
Say where the proof of purchase lives. Don't paste receipt numbers, order ids, licence
keys or account details here.
-->

- How I got it: {bought on the Mac App Store, YYYY-MM / bought from the vendor / free download / subscription}
- Licence I hold: {one-time purchase / in-app unlock / subscription active until YYYY-MM-DD / free}
- Proof is in: {e.g. "my App Store purchase history"}
- [ ] It runs on this Mac, which I own and control.
- [ ] I've read the app's licence terms (EULA). Clauses that mention reverse engineering, decompiling or modifying, if any: {clause numbers and a one-line summary in your words}
- Where I live (jurisdiction): {country, state}

## 3. Purpose

Tick all that apply.

- [ ] Understand how it works.
- [ ] Interoperability: read or write its files, or drive it from other tools.
- [ ] A clean-room replacement for my own use.
- [ ] A clean-room replacement published as open source. Phase 7 publishes it, and the vendor isn't named.

Pith doesn't support these purposes: piracy, getting paid features without paying, reselling a clone, or security testing of someone else's service.

## 4. Goals

### Phases in scope

<!-- If you only want to understand the app (a report only), tick 0 to 4: Phase 4 then ends with report.md, and there is no spec.md, leak review, provenance log or Phases 5–7. -->

- [ ] 0 Scope & consent (this file)
- [ ] 1 Static survey: read-only, with `scripts/re-static.sh`
- [ ] 2 Behaviour: use the app normally on throwaway files made for this run
- [ ] 3 Network (optional): observe only the app's own calls, in a capture the owner runs. My consent and its limits: {e.g. "launch and one conversion; stop if traffic is pinned or encrypted end to end"}
- [ ] 4 Report & spec
- [ ] 5 Clean-room rebuild
- [ ] 6 Verification
- [ ] 7 Package & publish: [ ] local build only  [ ] public repository

### What I want to learn

- [ ] Which engines and libraries it bundles, their versions and licences
- [ ] Why it is the size it is
- [ ] Which file formats it reads and writes, and what it does with metadata
- [ ] What it sends over the network, and when
- [ ] Its automation surface: URL scheme, Shortcuts, AppleScript, Services, a command-line tool
- [ ] {other}

### What I want the rebuild to do

<!--
Plain words. These become requirements in spec.md: what the original already does turns
into observed requirements (OBS-), and what you want done better turns into proposed
improvements (IMP-).
-->

- [ ] Do the core job: {e.g. "convert images, audio, video and documents by drag and drop"}
- [ ] Add: {e.g. "a command-line tool, a URL scheme, a Shortcuts action"}
- [ ] Avoid: {e.g. "bundling a large runtime", "any network calls"}
- [ ] {other}

### Success looks like

{One or two sentences, e.g. "I use the rebuild instead of the original for a week without missing anything I rely on."}

## 5. Boundaries

### Hard rules

<!-- Short form of Pith's GUARDRAILS.md. Read that file, then tick each rule. -->

- [ ] Only software I own, on my own machine. I decide; the agent asks.
- [ ] The purpose is understanding, interoperability or a clean-room replacement. Not piracy, not resale of a clone.
- [ ] No decrypting FairPlay (Apple's App Store encryption) or other DRM, no patching binaries, no bypassing licence checks, paywalls, trials or certificate pinning, and no getting around macOS privacy protections. If something is encrypted or protected, we record that as a finding and stop there.
- [ ] Nothing from the original goes into the rebuild: no code, binaries, assets, strings, UI text or keys. Open-source engines are reused only under their own licences.
- [ ] Nothing published contains secrets, payment internals or captured personal data, and the vendor isn't named in public material.
- [ ] Owner-only actions (section 6) are done by me, in my own terminal or System Settings.
- [ ] This is not legal advice.

### In scope for this run

- {e.g. "the app bundle at /Applications/{App}.app, read only"}
- {e.g. "throwaway input files in ~/pith-work/{app}/dirty/behaviour/"}
- {e.g. "the app's own network calls during launch and one conversion (Phase 3)"}

### Out of scope for this run

- {e.g. "the app's stored settings and data"}
- {e.g. "how the purchase or free tier is enforced"}
- {e.g. "the vendor's servers beyond the app's normal traffic"}
- {e.g. "other apps by the same vendor"}

### Inputs

Throwaway files only, made for this run. No personal documents or photos, and no real accounts.
Folder: {e.g. `~/pith-work/{app}/dirty/behaviour/`}

### Stop conditions

The agent stops and asks me when:

- something is encrypted, protected by the operating system, pinned or tamper-checked;
- a step needs `sudo`, a password, a security or privacy setting, or a purchase;
- a step would send anything off this Mac: a push, release, post, issue or email;
- it isn't sure a step is inside this scope.

## 6. Owner-only actions

<!--
The agent never does these. It says what is needed and why; the owner does it in their own
terminal or System Settings and tells the agent when it's done. Record each one here as it
happens.
-->

| # | Action | Why it's needed | Phase | Done by owner (date) |
|---|---|---|---|---|
| 1 | {e.g. "a step that needs an admin password"} | {…} | {n} | {YYYY-MM-DD} |

Decisions that stay with the owner. The agent asks every time:

- choosing the target and goals (this file);
- whether to run Phase 3 at all, and its limits;
- every wall crossing (Phase 4, logged in `provenance.md`);
- choosing a UI design direction (Phase 5);
- every commit, push, release or publication (Phases 5–7).

## 7. The wall

<!--
Dirty side: may look at the original app, the evidence and the report. Clean side: sees
only spec.md and public documentation. Use separate agent sessions for the clean side,
started in clean/ with a Read deny rule for ../dirty/**, and don't paste dirty-side facts
into their prompts yourself; answer their questions through spec.md section 9 instead.
Never put a CLAUDE.md in ~/pith-work/{app}/ or any folder above it.
-->

| | Dirty side (phases 1–4) | Clean side (phases 5–7) |
|---|---|---|
| Who | {owner, analysis agent session(s)} | {implementer and reviewer agent sessions} |
| Folder | {e.g. `~/pith-work/{app}/dirty/` (evidence in `dirty/evidence/static/`)} | {e.g. `~/pith-work/{app}/clean/`, holding the approved `spec.md` and the rebuild's own repository} |
| May read | the original app, evidence, `report.md` | `spec.md` and the files it references, public documentation |
| Never | publish evidence or the report | open the original app, its bundle, the evidence or the report |

## 8. Sign-off

- [ ] I own a licence for {App} and run it on my own Mac.
- [ ] I've read Pith's `GUARDRAILS.md` and this scope.
- [ ] I understand this is not legal advice.

Owner: {name} · Date: {YYYY-MM-DD}

<!-- If the agent drafted this file, the owner may tick these boxes or type "approved" in the session. The agent records which, with the date, in "Changes to scope" below. -->

Agent acknowledgement: "{agent} will work inside this scope, ask before any owner-only or outward-facing action, and stop at the boundaries above." · Date: {YYYY-MM-DD}

### Changes to scope

<!-- Scope changes only with the owner's say-so. Add a row; don't rewrite history. -->

| Date | Change | Why | Approved by |
|---|---|---|---|
| | | | |

## Done when

- [ ] The target row is filled from `re-inventory.sh`.
- [ ] Ownership and purpose are recorded.
- [ ] Goals are ticked and written in plain words.
- [ ] Boundaries, stop conditions and owner-only actions are agreed.
- [ ] The owner has signed section 8.
