# Case study: Zest, the first Pith run

In October 2026 the owner of a commercial macOS menu-bar file converter, which they had bought,
ran Pith on it with Claude Code. The run ended with **Zest**, a replacement published at
https://github.com/rohitthink/Zest.

The first run had no formal wall: one agent session did both the analysis and the rebuild, working
from the report's rebuild blueprint. Pith's wall, leak review and provenance log were designed
afterwards from what that run showed.

This write-up is sanitised. It does not name the vendor or the original app. It contains no keys
or tokens, and it does not describe how the original's purchase or free tier works. It is not
legal advice.

## At a glance

| Phase | What it produced | Numbers |
|---|---|---|
| 0 Scope & consent | Target, goals and owner-only actions agreed | — |
| 1 Static survey | Engines, versions, licences and architecture from read-only tools | — |
| 2 Behaviour | Inputs, options and outputs from normal use on throwaway files | — |
| 3 Network | The app's own launch calls, captured by the owner | 1 static conclusion corrected |
| 4 Report & spec | The report, ending in a rebuild blueprint | ~115 KB |
| 5 Clean-room rebuild | Zest: engine, CLI, menu-bar app, URL scheme, Shortcuts intent | 3 design directions, 4 parallel UI agents |
| 6 Verification | Self-tests, snapshots, real-file harness, adversarial review | 81 + 45 self-test checks, 46 snapshots, 33 harness checks, 3 review rounds, 100+ fixes |
| 7 Package & publish | A package script producing an ad-hoc-signed `.app` | Not notarized |

## The target

A commercial, sandboxed Swift menu-bar app: drop a file on it and pick a target format.
It was a Mac App Store build. ("Sandboxed" means macOS limits what the app can touch to what it
declares; "menu-bar app" means it has no Dock icon or main window.)

## Phase 0: Scope & consent

The owner picked the target and set the goals. They also agreed which steps were theirs alone:
anything needing `sudo`, a password or System Settings ran in their own terminal, never the
agent's. The agent asked before every outward-facing action for the rest of the run.

## Phase 1: Static survey

Only read-only tools touched the bundle:

- `otool` for load commands, linked libraries and encryption info;
- `nm` and `strings`;
- `codesign` for the signature and entitlements;
- `lipo` and `vtool` for architectures, platform and SDK;
- `swift-demangle`, plus Swift reflection field names, which survive in a stripped binary;
- `PlistBuddy` and `plutil`;
- the licence and notice files inside the bundle.

Pith's [`scripts/re-static.sh`](../scripts/re-static.sh) now runs this survey in one command.

What it found:

- **Not FairPlay-encrypted.** The App Store build carried no FairPlay encryption, so its strings
  were readable statically. Had it been encrypted, the survey would have recorded that and stopped
  (see [`GUARDRAILS.md`](../GUARDRAILS.md)).
- **Bundled open-source engines.** An LGPL-class FFmpeg build, WebP tools, and a Java runtime.
  The Java runtime made up most of the download.
- **Versions and licences.** Each bundled tool's version was read from its strings, not by
  running it. Sandboxed helper tools die with SIGTRAP (exit 133) when run on their own, and
  running a vendor's binaries is outside a read-only survey anyway.
- **No automation surface.** No URL scheme, no Shortcuts actions, no AppleScript.

## Phase 2: Behaviour

The owner used the app normally. Every input was a throwaway file made with built-in tools
(`sips`, `say`, `textutil`), never a real document. For each conversion they recorded the input,
the options chosen and the output.

## Phase 3: Network

With their consent, and on their own machine, the owner captured the app's own calls at launch.
The only traffic was a commerce SDK and attribution.

The capture **corrected a static conclusion**. The static survey had drawn a conclusion about how
the app was sold, and the runtime capture showed it was wrong. The report was updated to say so. The
lesson: runtime evidence can overturn static guesses, so record the correction rather than
quietly rewriting the earlier section.

How the capture was set up is deliberately not described here. See the tools' own documentation
and [`METHOD.md`](../METHOD.md).

## Phase 4: Report & spec

The report came to about 115 KB, in these sections:

1. Executive summary (four takeaways)
2. Architecture
3. Engine
4. Data formats
5. Network and API
6. Automation surface
7. Flaws and improvement targets
8. Rebuild blueprint
9. Legal note
10. Runtime appendix, including a table of *what was not captured and the boundary that blocked it*

The rebuild blueprint was the starting point. In Pith's method, `spec.md` is rewritten from it in
fresh words and leak-reviewed; it is the only document that crosses the wall. In this run the same
session went on to build Zest from the blueprint itself (see the note at the top).

## Phase 5: Clean-room rebuild

Zest is a Swift package. Two owner goals shaped it: add an automation surface, and don't bundle a
Java runtime.

**Engine (ZestKit)**, with three backends:

- **ffmpeg**.
- **ImageIO** for images, including a lossless metadata strip that preserves byte offsets.
- **Native documents** through `NSAttributedString` and PDFKit, instead of bundling a Java
  runtime. LibreOffice is optional at runtime.

**Surfaces:** the `zest` CLI, the ZestApp menu-bar app, a `zest://` URL scheme, a Shortcuts
intent, and Open With.

**UI.** Three design directions were mocked as artboards, and the owner picked one.
A contract came first: theme tokens, the model and shared geometry. Then four agents built the UI
in parallel, each in its own isolated copy of the package. A fresh-eyes polish agent followed each one.

**Later addition.** A link downloader that finds `yt-dlp` at runtime. This is part of the rebuild,
not reverse engineering: nothing about it came from the original app.

## Phase 6: Verification

| Check | Size |
|---|---|
| `zest selftest` (dependency-free) | 81 checks |
| `ZestApp --selftest` | 45 checks |
| `ZestApp --snapshot` (light and dark) | 46 PNGs |
| End-to-end harness on real files, with a local HTTP server for link tests | 33 checks |

The snapshot mode exists because agents could not see or drive the menu-bar-only app with
computer use, and may lack screen-capture permission. So verification was built into the
product: snapshots, flows driven by the URL scheme, and capture of the app's own windows.

**Adversarial review.** Three rounds. Each had a reviewer per dimension, then a verifier per
dimension that had to reproduce a finding before it counted.

| Round | Kept | Refuted |
|---|---|---|
| 1 | 15 bugs | not recorded |
| 2 | 49 | 1 |
| 3 | 39 | 1 |

Over 100 fixes in total, each re-checked with the real-file harness.

Pith's rule is to repeat until a round confirms nothing above low severity, or the owner stops it.
The run stopped after round 3. The run's summary doesn't record the severities of round 3's
findings, so this write-up can't say which of the two ended it.

**Bugs worth knowing about:**

| Bug | What happened |
|---|---|
| Process hang | `Process.waitUntilExit()` hung when called off the launching thread. It showed only under timing, and was found by re-running the harness several times. Fixed by waiting on `terminationHandler` instead. |
| "Strip" re-encoded | A global quality setting pushed Strip off its lossless path, so it silently re-encoded the file. Fixed. |
| Queue cancelled work | A queued automation request cancelled a job that was already running. Fixed. |
| Lost download | Moving a finished download across volumes lost it. Fixed. |
| GPS left in PDFs | Converting an image to PDF kept its GPS metadata. Fixed. |

## Phase 7: Package & publish

A package script does the release build and assembles the `.app`. It writes an `Info.plist` with
`LSUIElement`, URL types and document types. It signs ad hoc, registers the app with Launch
Services, and bundles the CLI at `Contents/Helpers`.

Zest is **not notarized**. Notarization needs an Apple Developer ID ($99 a year). On other Macs the
first launch has to be approved in System Settings › Privacy & Security › Open Anyway (since macOS
15, right-click › Open no longer overrides Gatekeeper).

## Owner moments

These were the owner's decisions and actions, not the agent's:

- picking the target and the goals;
- any `sudo`, password or System Settings step, in their own terminal;
- choosing the design direction;
- approving commits and pushes.

## What was not verified

- **The gaps in the report's boundary table.** Whatever the runtime appendix lists as not captured
  stayed uncaptured. The run stopped at each boundary rather than working around it.
- **Bundled tool versions** are as their strings state. The tools were never run to confirm them.
- **Live menu-bar interaction** was not driven by an agent. Agent-side visual checks came from the
  app's own snapshot mode and its URL-scheme flows.
- **Gatekeeper on other Macs.** The app is ad-hoc signed and not notarized.
- **This write-up** comes from the run's own summary. It does not reproduce the report, and it
  claims nothing that summary doesn't record.

## Lessons

The full list is in [`LESSONS.md`](../LESSONS.md). The ones that cost the most time:

- **Command Line Tools only.** SwiftUI `@State` is a macro whose plugin ships only with Xcode, so
  use `@StateObject` with a small `ObservableObject`. `#Preview` and XCTest are unavailable, so
  write your own self-test runner. AppIntents metadata extraction also needs Xcode.
- **Render the right way.** `NSView.cacheDisplay` flips SwiftUI shadow offsets. Use `ImageRenderer`
  for pure SwiftUI views and window capture for AppKit-backed controls. `qlmanage -t` turns an HTML
  mockup into a PNG design reference when headless browsers hang.
- **Re-run the harness.** One hang showed only under timing.
- **Report honestly.** Say what was and wasn't verified, and correct earlier conclusions when
  runtime evidence disagrees.

## Links

- Zest: https://github.com/rohitthink/Zest
- The method: [`METHOD.md`](../METHOD.md) · Running it with an agent: [`AGENT-PLAYBOOK.md`](../AGENT-PLAYBOOK.md) · Rules: [`GUARDRAILS.md`](../GUARDRAILS.md)
- Related work and how Pith fits with it: [`README.md`](../README.md#related-work--what-to-integrate)
