You were right to reject my readiness claim. I had checked an incomplete set of conditions, left the weak seer and uncovered seeds unresolved, and called a bargain heuristic sensible when both fixed bargain rules beat it.

I preserved the earlier results and logged **four corrective attempts, 7–10**. There are now **ten logged attempts in total**.

## What changed

### Stronger seer: the 24 seeds are winnable

A generic full-future beam search found winning plans for **all 24 previously-uncovered seeds on the original mechanics**, then for **all 200 seeds**.

Every resulting plan was replayed through the actual Godot rules: **2,400 resource, worker, wall-integrity and flooding snapshots matched**. The search contains no seed-specific exceptions. Renaming seed identity labels while retaining their schedules produced identical decisions.

I did **not** reduce damage or change resource costs to rescue those seeds. The former seer’s search was inadequate. During verification, I also caught a schedule-serialization precision error and fixed the export to retain full precision rather than weakening the replay checks.

### Bargains: readable, imperfect signs

The stranger now has a public **warm / wavering / hollow voice** cue, displayed and explained in every layout. It imperfectly signals risk; the exact weakening and affected section remain concealed.

Steward accepts a warm-voiced offer when supplies are needed, otherwise declines. Its result is now **60%**, beating **55% always accepting** and **47.5% never accepting**.

## Numbered numerical targets

Every policy ran over **200 seeds**. The fixed sweep includes **all 110 integer-split/gate combinations**.

| # | Target | Final result | Status |
|---|---|---|---|
| T1 | Idle loses before tide 7 on ≥95% of seeds | **200/200 — 100%** | **PASS** |
| T2 | Greedy wins ≤5% | **0/200 — 0%** | **PASS** |
| T3 | Best fixed policy wins ≤15% | **2/200 — 1%**; 3 quarry / 3 fields / 3 dike, gate closed | **PASS** |
| T4 | Steward wins 40–70% | **120/200 — 60%** | **PASS** |
| T5 | Never opening the gate costs ≥20 percentage points | **60% → 4%**: **56-point drop** | **PASS** |
| T6 | Never repairing costs ≥20 points | **60% → 0%**: **60-point drop** | **PASS** |
| T7 | Bargains help some steward runs and ruin others | **31 helped, 6 ruined**, paired against declining offers | **PASS** |
| T8 | Seer wins ≥95% | **200/200 — 100%** | **PASS** |
| T9 | Selective steward beats always accepting | **60% > 55%** | **PASS** |
| T10 | Selective steward beats never accepting | **60% > 47.5%** | **PASS** |

Full per-seed actions, resources at every tide, public signs and outcomes are in `playtest.json`.

## Remaining requested changes and checks

| # | Requirement | Result | Status |
|---|---|---|---|
| T11 | Audit the checks target by target | Ten-entry registry; harness asserts completeness | **PASS** |
| T12 | Investigate the 24 uncovered seeds | Winning witnesses for all 24, before changing bargain information | **PASS** |
| T13 | Delay results until settled underwater plus ≥8 seconds of bells | Recorded settlement at **26.358 s**, result at **34.358 s** of the greedy clip: **8.000 s** | **PASS** |
| T14 | Keep the drowned city visible and lit | Dedicated underwater scene, warm windows and light shafts; inspected in the final video | **PASS** |
| T15 | Hide planning panels during sinking | Only the sound control remains; tested in all three layouts | **PASS** |
| T16 | Remove the planning-duration suggestion | Removed from the game; checked in source and captured frames | **PASS** |
| T17 | Rerun every bot and preserve detailed results | Complete 200-seed sweep, including every fixed policy | **PASS** |
| T18 | Make and inspect a new sound video | **75 seconds, 1280×720, 30 fps, AAC sound**; first 30 seconds steward, then greedy’s last tides and ending | **PASS** |
| T19 | Make a clean, non-threaded web export | No `ERROR` lines; compiled PCK loads; test/planner/output artifacts excluded | **PASS** |
| T20 | Keep every attempt in `data/attempts.md` | Attempts 1–10 retained, with correction notice and diagnoses | **PASS** |
| T21 | State what the first report got wrong | Corrected above and in the delivered audit | **PASS** |

The complete report also individually numbers the original functional requirements **F1–F17**, with evidence and verification scope:

[Complete numbered target report]( data/out/target-report.md)

### What remains unverified

These are **not included in the pass claim**:

- **V1 — FAIL / verification unavailable:** actual browser startup, phone hardware, orientation behavior and browser audio-resume behavior. There is no working browser or physical phone/audio output here. Native rendering and synthetic touch tests passed.
- **V2 — FAIL / unmeasured:** actual human completion time near six minutes. Planning remains deliberately untimed; no human pacing study was performed.

## New deliverables

**Video**
```text
data/out/keris.mp4
```

**Web build**
```text
data/out/web/index.html
```

**Complete playtest results**
```text
data/out/playtest.json
```

**Source archive**
```text
data/out/keris-source.zip
```

**Complete web archive**
```text
data/out/keris-web.zip
```

The same directory contains the attempt ledger, final contact sheets, oracle witnesses, verification reports and file hashes. Serve the complete web directory over HTTP(S), not through `file://`.