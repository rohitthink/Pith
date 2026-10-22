# Spec — {rebuild name}

> [!IMPORTANT]
> **This file crosses the wall.** Apart from public documentation, it is the only thing the
> clean side receives. It must pass the leak review below before every crossing, and every
> crossing is logged in `provenance.md`.

<!--
Phase 4 of Pith (Report & spec). The dirty side writes this from what report.md means,
in fresh words, never by pasting. An implementer who has never seen the original app must be
able to build and test the rebuild from this file, the files it references and public
documentation alone.

Name the rebuild, not the original. The implementer doesn't need the original's or the
vendor's name.

Placeholders look like {this}. When the spec changes, bump the version, review it again and
log the new crossing.
-->

| | |
|---|---|
| Spec version | {v1} · {YYYY-MM-DD} |
| Rebuild | {name}: {one line on what it does} |
| Platform | {e.g. macOS 14 or later, Apple silicon and Intel} |
| Author (dirty side) | {owner / agent session} |
| Last leak review | {YYYY-MM-DD} · {reviewer} · {result} · `provenance.md` row {n} |

## Leak review

<!--
Someone other than the author does this before every crossing: a fresh agent session acting
as leak reviewer, then the owner approves. The reviewer may look at the dirty side, since
that's how leaks are spotted; the implementer may not.

Pith borrows this step, in a lighter form, from greenfield's sanitiser and leakage reviewers
(https://github.com/prime-radiant-inc/greenfield). For enforcing the wall with hooks and
handoff schemas, see clean-room-skill (https://github.com/whit3rabbit/clean-room-skill).

The reviewer also runs the mechanical check in Pith's GUARDRAILS.md §Leak-review checklist.
It runs on the dirty side, on this draft (dirty/spec.md), before it crosses. Run it on every
.ksy and OpenAPI file that crosses too.
-->

- [ ] **No code from the original:** no disassembly, decompiled or pseudo-code, and no algorithm written out step by step from the binary.
- [ ] **No names that exist only inside the original:** class, type, method, symbol, field, file or resource names. Names that appear in files or traffic the app produces for the user may stay when interoperability needs them.
- [ ] **No copied text:** UI labels, error messages, help or onboarding text, sample content. Behaviour is described in our own words.
- [ ] **No assets:** icons, images, sounds or fonts, colours or measurements taken from the original's files, or screenshots of the original.
- [ ] **No secrets or identifiers:** keys, tokens, receipts, cookies, account or device ids, or real captured values.
- [ ] **No purchase, licensing, trial or paywall internals.**
- [ ] **No personal data** from captures or test runs.
- [ ] **No pointers into the dirty side:** no evidence file names, paths inside the original bundle, or quotes from the report. Observation ids such as B-7 are fine.
- [ ] **No name of the original app or its vendor.**
- [ ] Every requirement is **user-visible behaviour** with an acceptance test a clean-side agent can run.
- [ ] **Observed behaviour (OBS-) and proposed improvements (IMP-) are in separate sections.**
- [ ] Formats are described by **structure** (a public standard or a reviewed `.ksy`), not by bytes copied from the original's own resources.
- [ ] The network contract lists only calls the rebuild must make, and **every example value is invented**.
- [ ] Open-source engines are named only by their public project name and licence.
- [ ] The mechanical check in GUARDRAILS.md §Leak-review checklist ran, and every hit was fixed or waived with a reason.
- [ ] The reviewer is not the author, the owner approved the crossing, and both are logged in `provenance.md`.

**Result:** {pass / pass after redactions / fail} · logged as `provenance.md` row {n}. If anything fails, fix the spec, review it again and log both reviews.

## 1. Purpose and users

<!-- One short paragraph: what the rebuild is for, who uses it, and what "good enough to switch" means. Restate the owner's goals from scope.md in plain words. -->

{…}

## 2. Observed behaviour (parity)

<!--
What the original does that the rebuild must also do, written as user-visible requirements.
Each has an acceptance test that a clean-side agent can automate (or, failing that, run by
hand) without the original app.

Id prefix OBS-. The trace field holds dirty-side observation ids (B-n from the report's
Appendix A.1): they let the owner check where a requirement came from and mean nothing to
the implementer.

Example:

  ### OBS-001 — Convert a dropped file
  Requirement: when the user drops a supported file on a target format, the product writes
  the converted file next to the original, with the same base name and the new extension,
  and leaves the original unchanged.
  Acceptance test: given a 64×64 PNG made for the test, when it is converted to JPEG, then
  {name}.jpg exists in the same folder, decodes as a 64×64 JPEG, and the PNG's SHA-256 is
  unchanged.
-->

### OBS-001 — {short name}

| | |
|---|---|
| Requirement | When {the user does X}, the product {does Y}. |
| Acceptance test | **Given** {state and input}, **when** {action}, **then** {checkable result}. |
| Test kind | {self-test / end-to-end harness / visual snapshot / manual} |
| Priority | {must / should / could} |
| Trace | {B-n} |

### OBS-002 — {short name}

| | |
|---|---|
| Requirement | |
| Acceptance test | |
| Test kind | |
| Priority | |
| Trace | |

## 3. Data formats

<!--
One row per format the rebuild reads or writes.

For a public standard, link the standard and state the options (quality, colour profile,
which metadata is kept or stripped, output naming). No .ksy needed.

For a custom format, reference a Kaitai Struct file (.ksy, a declarative description of a
binary layout; https://github.com/kaitai-io/kaitai_struct). A .ksy written from observation
is itself a clean-room artifact. It crosses with this spec, passes the same leak review, is
listed in provenance.md, and uses field names you chose, not names from the binary.

Test inputs: the clean side makes its own from this section. Files produced by the original
don't cross by default. If one is essential for interoperability, make it from a throwaway
input, check it for anything the original embeds (encoder tags, app names, ids), and review
and log it like any other artifact.
-->

| Format | Read / write | Definition | Options | Used by |
|---|---|---|---|---|
| {e.g. PNG} | {read, write} | {link to the public standard} | {e.g. keep colour profile, strip location} | {OBS-001} |
| {custom format} | {read} | `formats/{name}.ksy` {v1} | {…} | {OBS-00n} |

The shape of a `.ksy` file (illustrative):

```yaml
meta:
  id: example_project
  title: Example project file, described from observation
  file-extension: exproj
  endian: le
doc: |
  Written from files produced from throwaway inputs. Field names are our own.
seq:
  - id: magic
    contents: "EXPJ"
  - id: version
    type: u2
  - id: num_items
    type: u4
  - id: items
    type: item
    repeat: expr
    repeat-expr: num_items
types:
  item:
    seq:
      - id: len_label
        type: u2
      - id: label
        type: str
        size: len_label
        encoding: UTF-8
```

## 4. Network contract

<!--
What the rebuild sends over the network, and nothing more. Usually that is far less than
the original: third-party SDK traffic (purchases, analytics, attribution) is not reproduced.
State the rebuild's own choice instead.

If the rebuild must call a service for interoperability (one the owner is entitled to use),
describe those calls in an OpenAPI file (a standard, machine-readable description of an
HTTP API) that crosses with this spec. Every example value must be invented: no captured
keys, tokens, cookies or ids. Use example.com hosts in examples.

Dirty-side tools that help: mitmproxy2swagger (https://github.com/alufers/mitmproxy2swagger)
drafts OpenAPI from a capture, and Redocly CLI (https://github.com/Redocly/redocly-cli)
lints the result. Check Redocly's docs for commands that compare recorded traffic with a
description.
-->

- **Default:** the rebuild makes no network requests, except: {list, or "none"}.
- **Contract:** `network/openapi.yaml` {v1} / not applicable.
- **Third-party SDKs:** {none / which, why, and under whose privacy terms}.

The shape of an OpenAPI file (illustrative):

```yaml
openapi: 3.1.0
info:
  title: Example service, calls the rebuild makes
  version: "1"
servers:
  - url: https://api.example.com
paths:
  /v1/items:
    get:
      summary: List the user's items
      responses:
        "200":
          description: A list of items
          content:
            application/json:
              schema:
                type: array
                items:
                  type: object
                  properties:
                    id:
                      type: string
                    name:
                      type: string
```

## 5. Proposed improvements (not observed)

<!--
What the rebuild should do better than the original, or do that the original doesn't.
Id prefix IMP-. Kept apart from section 2 so nobody mistakes a wish for an observed
behaviour, or the other way round. The idea comes from REA-Reconstruction-Companion
(https://github.com/ShadowSwaps/REA-Reconstruction-Companion), which keeps observations and
proposals separate.

Examples (from bugs the first run's review caught):

  ### IMP-001 — Lossless metadata strip
  Requirement: stripping metadata never re-encodes the image, whatever the global quality
  setting.
  Acceptance test: given a JPEG with EXIF and GPS tags, when "strip" runs with quality set
  to 50, then the output has no EXIF or GPS data and decodes to pixels identical to the
  input's.

  ### IMP-002 — No location in image-to-PDF output
  Acceptance test: given a photo with GPS metadata, when it is converted to PDF, then the
  PDF contains no GPS coordinates.
-->

### IMP-001 — {short name}

| | |
|---|---|
| Requirement | |
| Acceptance test | **Given** {…}, **when** {…}, **then** {…}. |
| Test kind | |
| Priority | |
| Trace | {F-n from the report, or "owner goal"} |

## 6. Non-goals

<!-- Things the rebuild deliberately won't do. Writing them down stops agents from helpfully adding them. -->

- Matching the original's look, wording, icons or sounds. The rebuild has its own design.
- Reading or migrating the original's private settings or stored data.
- Reproducing the original's purchase, licensing, trial or analytics behaviour.
- Byte-identical output to the original.
- {…}

## 7. Constraints

| | |
|---|---|
| Platform | {e.g. macOS 14 or later; arm64 and x86_64} |
| Language and packaging | {e.g. a Swift package: engine library, command-line tool, menu-bar app} |
| Toolchain | {e.g. Command Line Tools only, no Xcode: no SwiftUI `@State` macro, `#Preview` or XCTest. See Pith's LESSONS.md} |
| Dependencies | {open-source engines, their licences, bundled or found at runtime} |
| Privacy | {e.g. no telemetry; no network except section 4; metadata handling as in section 3} |
| Distribution | {e.g. ad-hoc signed for the owner's Mac / Developer ID and notarized} |

## 8. Verification

<!--
How Phase 6 will show the rebuild meets this spec. Tools for golden masters, pixel diffs and
parity checks: agentic-cleanroom (https://github.com/climashscape/agentic-cleanroom).
-->

- **Self-tests:** every must-have OBS and IMP requirement has at least one automated check that runs without Xcode.
- **End-to-end harness:** real files, generated by the clean side from section 3.
- **Visual snapshots:** every screen, in light and dark mode.
- **Adversarial review:** a reviewer per dimension; findings follow `finding.schema.json`; a separate verifier must reproduce each finding before it is fixed; fixes are re-checked on the harness.
- **Parity (optional):** the owner, on the dirty side, runs the original and the rebuild on the same throwaway inputs and sends back only pass or fail per requirement, logged in `provenance.md`. The pass/fail-only pattern comes from teardown (https://github.com/lemonadesaltbagel/teardown).

## 9. Questions across the wall

<!--
The implementer will hit gaps. They ask here; the dirty side answers in the same sanitised
style; the answer is leak-reviewed and the exchange logged in provenance.md before it goes
back. "Unknown: choose a sensible behaviour and note it" is a valid answer.
-->

| Q | Asked | Question | Answer | Answered | `provenance.md` row |
|---|---|---|---|---|---|
| Q-1 | {YYYY-MM-DD} | {…} | {…} | {YYYY-MM-DD} | {n} |

## 10. Glossary

| Term | Meaning in this spec |
|---|---|
| {…} | {…} |

## Done when

- [ ] Someone other than the author has passed the leak review, the owner has approved the crossing, and it is logged.
- [ ] Every must-have requirement has an acceptance test a clean-side agent can run.
- [ ] Observed behaviour (OBS-) and proposed improvements (IMP-) are in separate sections, and non-goals are listed.
- [ ] Every format links a public standard or a reviewed `.ksy`.
- [ ] The network contract says "none" or references a reviewed OpenAPI file.
- [ ] Nothing in this file points back to the report, the evidence or the original's internals.
