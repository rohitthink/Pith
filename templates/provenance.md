# Provenance — wall crossings

<!--
Phase 4 of Pith (Report & spec), kept up to date through Phase 7. An append-only log of
everything that crosses the wall between the dirty side (which may look at the original app)
and the clean side (which sees only spec.md and public documentation). It lives at the
workspace root (~/pith-work/<app>/provenance.md), the only file there, because nothing in it
is dirty.

Rules:
- Append only. Never edit or delete a row. To correct one, add a new row that names the row
  it corrects.
- One row per artifact per crossing. A new spec version is a new crossing.
- Dirty to clean needs a leak review by someone other than the author, a result, and the
  owner's approval (Approved by: owner). Clean to dirty (a question, a build of the rebuild
  for a parity run) needs no leak review or approval; write "n/a".
- Identify each artifact by its version and the first 12 characters of its SHA-256. Hash the
  reviewed dirty-side file, from the workspace folder:
    shasum -a 256 dirty/spec.md | cut -c1-12
  The copy in clean/spec.md must give the same value.
- Notes say what kind of thing was removed, and how the mechanical-check hits were handled,
  never the removed content. That keeps this file safe for both sides to read.
- Public documentation (Apple's docs, open-source project docs) doesn't need a row.
- If dirty material reaches the clean side by mistake, add an INCIDENT row at once and follow
  the contamination runbook in Pith's GUARDRAILS.md. Then add rows for what was done.

Leak check results: pass · pass after redactions · fail (not sent) · n/a · INCIDENT

A careful log helps show clean-room practice. It is not a legal guarantee, and this is not
legal advice.

The append-only audit log is borrowed, in a much lighter form, from teardown's signed,
hash-chained log (https://github.com/lemonadesaltbagel/teardown).

Example rows (illustrative; don't copy them into the table):

| 1 | 2026-10-20 | dirty | clean | spec.md | v1 · 3f9c0a1b2d4e | leak-review agents (fresh) | fail (not sent) | n/a (not sent) | type names from the binary and a copied UI label found; fixed in v1.1 |
| 2 | 2026-10-20 | dirty | clean | spec.md | v1.1 · 8e17b2c4a9d0 | leak-review agents (fresh) | pass | owner | re-review of row 1; mechanical check: 2 hits, both public Apple names, waived |
| 3 | 2026-10-21 | clean | dirty | Q-1 (spec §9) | n/a | n/a | n/a | n/a | question about default output naming |
| 4 | 2026-10-21 | dirty | clean | answer to Q-1 | spec v1.2 · 52ad90e7c3f1 | leak-review agents (fresh) | pass after redactions | owner | an internal file name removed from the answer |
-->

| | |
|---|---|
| Run | {run name, without the vendor's name} |
| Owner | {name} |
| Dirty side | {who and which agent sessions} |
| Clean side | {which agent sessions; the rebuild's repository} |

| # | Date | From | To | Artifact | Version · SHA-256 (12) | Reviewer | Leak check | Approved by | Notes |
|---|---|---|---|---|---|---|---|---|---|
| 1 | {YYYY-MM-DD} | {dirty / clean} | {clean / dirty} | {spec.md / formats/{name}.ksy / network/openapi.yaml / answer to Q-n / parity results} | {v1 · …} | {not the author} | {result} | {owner / n/a} | {…} |

## Done when

For every crossing:

- [ ] The artifact has a row with its version and hash.
- [ ] A dirty-to-clean row names a reviewer other than the author and a result.
- [ ] A dirty-to-clean row names the owner under Approved by.
- [ ] Nothing reached the clean side with a "fail" result.
- [ ] No earlier row was edited, and every INCIDENT row has follow-up rows.
