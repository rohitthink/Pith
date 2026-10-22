# Lessons from the first run

The first Pith run (October 2026) studied a commercial macOS menu-bar file converter the owner
had bought, and ended with [Zest](https://github.com/rohitthink/Zest), a clean-room Swift package
with an engine, a CLI and a menu-bar app. The run's story is in
[case-studies/zest.md](case-studies/zest.md). This file keeps only what's worth knowing before
your own run.

The first run had no formal wall: one agent session did both the analysis and the rebuild, working
from the report's rebuild blueprint. Pith's wall, leak review and provenance log were designed
afterwards from what that run showed.

Each lesson has three parts:

- **Symptom:** what you see.
- **Cause:** why it happens.
- **Fix:** what worked, or, where the run recorded only that a bug was fixed, what we'd do now.

The run used the Xcode Command Line Tools rather than full Xcode, which explains most of the
toolchain lessons. Where the run didn't record a cause, the lesson says so, and general
explanations are marked as such.

## Contents

- [Toolchain](#toolchain) (1–6)
- [Testing and verification](#testing-and-verification) (7–13)
- [UI work](#ui-work) (14–16)
- [Orchestration](#orchestration) (17–22)
- [Process and honesty](#process-and-honesty) (23–28)

## Toolchain

### 1. `@State` doesn't compile without Xcode

- **Symptom:** a SwiftUI view that uses `@State` fails to build when only the Command Line Tools
  are installed.
- **Cause:** in this SDK `@State` is a macro, and the compiler plugin that expands it ships with
  Xcode, not with the Command Line Tools.
- **Fix:** keep view state in a tiny `ObservableObject` and hold it with `@StateObject`, a
  property wrapper that needs no plugin:

  ```swift
  final class Box<Value>: ObservableObject {
      @Published var value: Value
      init(_ value: Value) { self.value = value }
  }

  struct Row: View {
      @StateObject private var hovered = Box(false)
      var body: some View {
          Text("Example").opacity(hovered.value ? 1 : 0.6)
              .onHover { hovered.value = $0 }
      }
  }
  ```

  Before relying on any other macro, build a one-line test of it with the same toolchain.

### 2. App Intents metadata needs Xcode

- **Symptom:** a Shortcuts intent compiles, but you can't confirm Shortcuts will offer it.
- **Cause:** the metadata macOS uses to discover App Intents is extracted by an Xcode build step,
  which a Command Line Tools build doesn't run.
- **Fix:** make the URL scheme and the CLI the main automation surfaces, because you can test
  them without Xcode. Build and test the intent with Xcode when you have it, and until then list it
  under "not verified".

### 3. `Process.waitUntilExit()` hangs off the launching thread

- **Symptom:** a job that runs a child process (ffmpeg, for example) sometimes never finishes,
  though the child has exited. It shows on some runs and not others.
- **Cause:** called from a thread other than the one that launched the process,
  `waitUntilExit()` can wait forever.
- **Fix:** wait on `terminationHandler`, set before `run()`:

  ```swift
  func runToExit(_ process: Process) async throws -> Int32 {
      try await withCheckedThrowingContinuation { done in
          process.terminationHandler = { done.resume(returning: $0.terminationStatus) }
          do { try process.run() } catch { done.resume(throwing: error) }
      }
  }
  ```

  Also give every harness check a timeout, so a hang fails one check instead of the whole run.

### 4. The original's helper tools crash when run on their own

- **Symptom:** a command-line tool inside the original's bundle exits straight away with status 133
  (SIGTRAP).
- **Cause (general mechanism):** a sandboxed helper expects to inherit its sandbox from its
  parent app. Launched on its own, it traps.
- **Fix:** don't run it. Running a vendor's binaries is outside a read-only survey anyway (see
  [GUARDRAILS.md](GUARDRAILS.md)). Read its version and licence from its strings instead:

  ```bash
  strings -a "/Applications/<App>.app/Contents/<path to tool>" | grep -Ei 'version|copyright|licen[cs]e' | head
  ```

### 5. No `#Preview` and no XCTest

- **Symptom:** `#Preview` blocks don't build, and there is no XCTest to run tests with.
- **Cause:** both come with Xcode, not with the Command Line Tools.
- **Fix:** a dependency-free self-test runner inside the product itself (lesson 7), and a snapshot
  mode instead of previews (lesson 14).

### 6. Other Macs block an ad-hoc-signed app

- **Symptom:** the packaged `.app` runs on the machine that built it, but another Mac refuses to
  open it the first time.
- **Cause:** ad-hoc signing isn't notarization. Notarization needs an Apple Developer ID, which
  costs $99 a year.
- **Fix:** whether to pay is the owner's decision. Without it, ship ad-hoc signed and say so in the
  README: on other Macs the first launch has to be approved in System Settings › Privacy &
  Security › Open Anyway (since macOS 15, right-click › Open no longer overrides Gatekeeper).

## Testing and verification

### 7. Write your own self-test runner

- **Symptom:** without XCTest (lesson 5) there's no `swift test`, and a "tested" claim has nothing
  behind it.
- **Cause:** the Command Line Tools toolchain.
- **Fix:** a self-test command built into each product, with no dependencies: a list of named
  checks, each returning pass or fail with a message, and a non-zero exit if any fail. Zest has
  `zest selftest` (81 checks) and `ZestApp --selftest` (45). Because they're part of the product,
  an agent can run them anywhere.

### 8. A hang that shows only under timing

- **Symptom:** the end-to-end harness passes, then hangs on a later run with no code change.
- **Cause:** a timing-dependent bug; this is how lesson 3 was found.
- **Fix:** run the harness several times in a row, not once. Treat a flaky run as a finding, not
  as noise.

### 9. A lossless operation that silently re-encoded

- **Symptom:** "Strip" (remove metadata) changed the image data, not just the metadata.
- **Cause:** a global quality setting pushed Strip off its lossless path, so it re-encoded the
  file without saying so.
- **Fix:** keep lossless paths apart from settings that only make sense for lossy ones, and have
  the harness assert that the image data is unchanged after a strip. Zest's strip preserves byte
  offsets, which makes that check simple.

### 10. Image to PDF kept GPS metadata

- **Symptom:** a PDF made from a photo still carried the photo's location.
- **Cause:** metadata from the source image passed through to the output on that path.
- **Fix:** decide per output path what metadata is kept or dropped, write it in the spec, and
  assert it in the harness, GPS especially, on every path, not only on the "Strip" path. The
  test input never needs to be a personal photo: a short Swift script using ImageIO can write
  invented GPS coordinates into a copy of a test image.

### 11. A queued request cancelled the running job

- **Symptom:** sending a second request through automation (the URL scheme or CLI) while a job ran
  cancelled the running job instead of queuing behind it.
- **Cause:** the automation entry point treated a new request as a replacement for the current one.
- **Fix:** queue requests from every entry point, and add a harness check that sends two requests
  back to back and expects both outputs.

### 12. A cross-volume move lost a finished download

- **Symptom:** a finished download vanished when the destination folder was on another volume.
- **Cause:** a move within one volume is a rename; across volumes it's a copy and then a delete,
  and that path behaved differently. (This is the general mechanism; the case study doesn't record
  the exact code path.)
- **Fix:** test moves onto a second volume (a mounted disk image works), and delete the source only
  after the copy is complete and checked.

### 13. Link tests that depend on the internet

- **Symptom:** tests for the link downloader would depend on third-party sites that change, rate
  limit or go away.
- **Cause:** pointing tests at real URLs.
- **Fix:** serve fixtures from a local HTTP server on 127.0.0.1 inside the harness's scratch
  folder. Zest's harness (33 checks on real files) does this. The downloader itself finds
  `yt-dlp` at runtime; it's a rebuild feature, not something learned from the original.

## UI work

### 14. Agents can't see a menu-bar-only app

- **Symptom:** an agent using computer use can't see or drive the app's menu-bar panel, and its
  host may not have Screen Recording permission either.
- **Cause:** accessory apps (`LSUIElement`: no Dock icon, no main window) are hard to reach with
  computer use, and screen capture is a privacy permission only the owner can grant.
- **Fix:** build verification into the product:
  - a snapshot mode that renders every screen to PNG, light and dark (`ZestApp --snapshot`
    writes 46);
  - flows driven by the URL scheme, so an agent can trigger them without clicking;
  - capture of the app's own windows from inside the app.

### 15. Snapshots flipped the shadows

- **Symptom:** in PNG snapshots, SwiftUI shadows fell upwards instead of downwards.
- **Cause:** `NSView.cacheDisplay` renders SwiftUI shadow offsets flipped.
- **Fix:** `ImageRenderer` for pure-SwiftUI views; window capture for views that contain
  AppKit-backed controls, which `ImageRenderer` doesn't render.

### 16. Headless browsers hang on HTML mockups

- **Symptom:** rendering a design mockup with a headless browser sometimes never returns.
- **Cause:** not recorded.
- **Fix:** `qlmanage -t` (Quick Look) renders an HTML file to a PNG you can use as the design
  reference:

  ```bash
  qlmanage -t -s 1600 -o mockups/ mockups/direction-a.html
  ```

## Orchestration

The patterns themselves are in [AGENT-PLAYBOOK.md](AGENT-PLAYBOOK.md#5-orchestration-patterns).

### 17. Parallel builders' code doesn't fit together

- **Symptom:** agents building UI areas in parallel each invent their own model types, colours and
  sizes, and the pieces don't compile or look right together.
- **Cause:** nothing shared existed when they started.
- **Fix:** contract first. One agent writes the shared model types, the theme tokens (from the
  design direction the owner picked), the shared geometry and compiling stubs. The package builds
  before anyone fans out.

### 18. Build-lock clashes

- **Symptom:** parallel agents in one package directory wait on each other's builds or break them.
- **Cause:** Swift Package Manager locks the package's `.build` folder.
- **Fix:** give each agent its own copy of the package:

  ```bash
  rsync -a --exclude .build pkg/ work/<area>/
  ```

### 19. Builders edit files they don't own

- **Symptom:** after merging, a shared file has been changed by two agents in two ways.
- **Cause:** each builder "fixes" whatever blocks it, including shared files.
- **Fix:** list each area's files in the contract, and copy back only those. A change a builder
  needs in a shared file goes to the lead, who changes the contract.

### 20. Builders miss their own rough edges

- **Symptom:** an area works but has small problems its builder no longer notices.
- **Cause:** the builder's context is full of its own reasoning.
- **Fix:** after each builder, a fresh-eyes polish agent that didn't write the code reviews it
  against the spec and the chosen design, fixes polish only, and re-runs the self-tests and
  snapshots. The first run used four builders, each followed by a polish agent.

### 21. Reviewers report things that aren't bugs

- **Symptom:** a review produces findings, some of which are wrong.
- **Cause:** a reviewer is asked to find problems, so it finds some that aren't real.
- **Fix:** a reviewer per dimension, then an adversarial verifier per dimension, told to refute,
  that must reproduce each finding before it counts. Rank what survives by severity, fix it, and
  re-check every fix with the real-file harness. Repeat until a round confirms nothing above low
  severity, or the owner stops it. On the first run, round 1 kept 15 bugs (refutations not
  recorded); round 2 kept 49 and refuted 1; round 3 kept 39 and refuted 1, for over 100 fixes in
  all. A low refutation rate still pays: every finding on the
  fix list has been reproduced.

### 22. Prior-art searches over-claim

- **Symptom:** search agents report close matches whose features or popularity don't hold up.
- **Cause (likely):** searchers work from search results and quick README reads, and a match is
  what they're looking for.
- **Fix:** a multi-angle sweep (several searchers, each on one angle), then a verifying
  synthesiser that opens every candidate rated 3 or higher and reads its README itself, without
  cloning or running anything. On Pith's own check it caught a tool name that the repo doesn't
  have, lowered several ratings, and flagged a star count that wasn't a reliable signal. Say what
  keyword search might have missed.

## Process and honesty

### 23. Runtime evidence overturned a static conclusion

- **Symptom:** the static survey drew a confident conclusion about how the app was sold, and it was
  wrong.
- **Cause:** strings show what code *could* do, not what it does. The owner's capture of the app's
  launch calls showed otherwise.
- **Fix:** label static conclusions as guesses until behaviour or runtime evidence confirms them.
  When one is overturned, write the correction where the old conclusion was, and say so in the
  summary, rather than quietly rewriting it.

### 24. Gaps disappear into a long report

- **Symptom:** a long report (the first one was about 115 KB) reads as complete even where it
  isn't.
- **Cause:** what wasn't captured is easy to leave out.
- **Fix:** end the report with a table: what was not captured, and the boundary that blocked it.
  Stop at each boundary rather than working around it.

### 25. "Done" without evidence

- **Symptom:** an agent says something works because the code looks right.
- **Cause:** reasoning about code feels like checking it.
- **Fix:** every summary has "verified" (what, how, with counts) and "not verified" (what, and
  why). A number in a summary comes from a tool's output. Nothing counts as verified that was only
  reasoned about.

### 26. Owner-only steps

- **Symptom:** a step needs `sudo`, a password or a System Settings change.
- **Cause:** those are the owner's actions under the hard rules, and an agent's shell can't answer
  a password prompt anyway.
- **Fix:** the agent writes the exact command or setting and why; the owner runs it in their own
  terminal or in System Settings. The agent also asks before every outward-facing action
  (commits, pushes, publishing, posting), each time.

### 27. Turn the original's flaws into rebuild targets

- **Symptom:** most of the original's download was a Java runtime, shipped twice (once per CPU
  architecture), and it had no automation surface at all.
- **Cause:** a bundled cross-platform runtime for document work the system frameworks can do, and
  a UI-only design.
- **Fix:** the report's "flaws and improvement targets" section went into its rebuild blueprint as
  proposed improvements, kept apart from observed behaviour (in Pith's method, the `IMP-` section
  of `spec.md`). Zest converts documents natively with
  `NSAttributedString` and PDFKit (LibreOffice optional at runtime) and adds a CLI, a URL scheme, a
  Shortcuts intent and Open With.

### 28. Check prior art before publishing, and integrate

- **Symptom:** a new method risks re-implementing tools that already exist, or taking a name
  that's already used.
- **Cause:** the field moves fast; several close projects appeared in the month Pith was written.
- **Fix:** run the sweep in lesson 22 before publishing, cite what you build on by name and URL
  (see [README.md](README.md#related-work--what-to-integrate)), and integrate rather than compete.

## Adding a lesson

Keep the three parts, one line of symptom, and say when a cause is a guess. Don't include vendor
names, keys, captured data or anything about how the original's payment or free tier works.
