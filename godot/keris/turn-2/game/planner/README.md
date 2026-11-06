# Full-future generic oracle planner

## Entry points

- `search.py`: executable Python 3 stdlib-only wrapper, compiler launcher, independent trace verifier.
- `search.cpp`: C++17 transition simulator and deterministic beam search.
- `search_bin`: compiled executable; rebuilt by wrapper if missing or older than C++ source.

From the enclosing workspace:

```sh
python3 data/search.py INPUT.json data/OUTPUT.json --width 256
python3 data/search.py INPUT.json data/OUTPUT1024.json --width 1024 --seeds 1,2,3
python3 data/search.py INPUT.json data/OUTPUT_IDLE.json --width 256 --include-idle
```

Paths to compiler source/executable are relative to `search.py`'s resolved location, not cwd. Use output paths inside `data/`. Compiler temporary files are placed beside the source. No network, external libraries, RNG implementation, or assets are required. Neither rules nor balance are modified. Config is supplied in INPUT, not hardcoded into the planner. Fixed mechanics from rules (12 tides, 3 sections, 9 initial workers, 12 worker cap, 5 gold hires, 100 max HP, 2-turn debt, gate threshold 4) remain fixed.

## JSON contract

Input:

```json
{"config": {"...": "all balance fields"}, "schedules": [
  {"seed": 123, "tides": ["12 complete exported tide dictionaries"]}
]}
```

Tide fields used: `height`, `storm`, `strike`, `offer`, `debt_section`, `debt_damage`. `forecast` is accepted but irrelevant to an oracle. Seed is an identifier only; no seed-specific policy or exception code exists. Seeds must be unique signed 64-bit integers. All schedules are processed unless selected with `--seeds`. Mechanic config fields consumed are listed in `search.py:FIELDS`; forecast/RNG/policy-only balance fields are accepted but unused. Wrapper validates ordinary nonnegative parameters, initial HP <=100, positive repair amount/cost, and loss in [0,1/3], covering the supplied balance.

Output contains `algorithm`, `width`, `results`, timing, caveats. Each result contains:

- `seed`, `won`;
- `actions`: ordered `{jobs:[quarry,fields,repair],gate:bool,bargain:bool,hires:int}`;
- `states`: ordered `{stone,grain,gold,workers,hp:[...],flooded:[...]}`, **after each corresponding resolve**, no initial-state element;
- diagnostics including expanded action count, expansions per tide, exact duplicates, unique live candidates, reached tide, and independent Python replay result.

A win always includes all 12 actions and 12 states. On search failure the deepest encountered loss path is retained (then a heuristic tie-break); this is **not** an impossibility certificate. To replay in Godot, use the supplied config and exported tides, clear/reassign jobs each turn, apply `hires` before resolve, set gate/bargain, assign jobs, and resolve. Hiring cannot spend gifts or gate trade from the same resolve. Godot replay is the final external fidelity check; this environment did not supply Godot or original exported schedules.

## Exact simulation order

1. Pre-resolve hires, limited by existing gold and worker cap.
2. Accepted available offer: all gifts, and debt due at current turn + 2.
3. Quarry and fields using pre-tide flooded count.
4. Each repair worker independently picks the weakest dry section; exact ties choose low index. Full repair-cost eligibility is required even for a partial repair. Actual cost is proportional to HP restored.
5. Due debt subtracts HP without flooding yet.
6. Open gate adds trade even when dangerous; actual height >=4 sacrifices the lowest-index dry section.
7. Damage runs section 0,1,2; each recomputes flooded count, allowing within-tide cascades. Flooding sets HP to zero.
8. Missing workers use `max(0,workers-floor(grain))`; grain is reduced by the pre-starvation workforce and clamped at zero; missing workers leave.
9. Any dry section after tide 12 wins.

C++ uses doubles, strict comparisons, no fast-math, and 17-digit JSON serialization. Pending debts are carried as bits referencing exported tide metadata. Exact binary state deduplication includes pending debts, resources, workers, HP, and flood mask. There is no approximate state merging.

## Search coverage and pruning

For **every retained parent**, enumerate all affordable hire counts (including zero), all nonnegative worker splits, both gate states, and both bargain choices when offered. By default the splits sum to all available workers. Every partially assigned action is weakly dominated by assigning its idle workers to quarry in this nonnegative-production game: quarry does not alter repair ordering, food, exposure, or upkeep and extra stone can only enable more non-harmful repairs. `--include-idle` enumerates every split whose sum is <= workers if that reduction is not desired. At tide 12 enumeration may stop immediately on the first actual winning transition.

All-flooded states end immediately. Starvation and zero workers are **not** arbitrarily pruned. Resource quantities are capped only for heuristic scoring, never for simulation or deduplication. Seven score portfolios share about two-thirds of width; flood-mask-specific quotas share about one-third; duplicates among those selections free slots for the balanced ranking. Objectives differ in HP, weakest/strongest wall, workforce, economic stock, districts saved, and next known pressure/storm/debt vulnerability. Selection fills unused slots to width. Narrow widths truncate portfolio coverage.

The full known schedule is simulated over the 12-layer horizon. Ranking is heuristic (current position plus next-tide risk), not an exhaustive dynamic program or a proof of optimality. Wider beams can still discard a needed state and are not guaranteed monotonic in wins. This is a generic search, not a policy trained or specialized on seeds. Beam nodes retain parent/action pointers across 12 layers; candidate nodes do not copy full action paths. Peak candidate/deduplication storage grows with the complete expansion of a layer, so extremely large widths can consume substantial memory.

## Numeric C++ protocol

Whitespace-separated stdin:

1. `width schedule_count include_idle` (last flag 0/1).
2. Config values in this order:
   `stone grain hp gift_stone gift_grain gift_gold loss quarry fields repair_cost repair trade wear pressure cascade`
3. For each schedule: signed integer seed, then 12 tide rows:
   `height storm strike offer debt_section debt_damage` (offer 0/1).

Stdout is `{ "results": [...] }` JSON. Wrapper adds description/timing and verifies traces.

## Evidence and failure preservation

Every invocation keeps beside OUTPUT:

- `.numeric.txt`: exact numeric input;
- `.raw.json`: unmodified executable output, including partial output on process failure;
- `.stderr.log`: executable stderr;
- `.build.log` when compiling;
- `.verification_failure.txt` on Python trace mismatch, reporting seed, tide, field, expected and observed values.

The final OUTPUT is replaced only after all returned states pass independent Python verification. Process/compile failures raise exceptions without deleting evidence. If reusing an output filename and a new run fails, the prior final JSON may remain; inspect process exit status and the current raw/log files rather than treating old output as a new result.

## Tests executed on supplied, unmodified balance

```sh
python3 data/test_search.py
python3 data/test_corners.py
```

- 2,000 deterministic randomized differential traces, 7,158 transitions: all matched Python. Mixed full/partial allocations, hires, bargains, losses, storms and starvation.
- Seven hand-calculated corner cases: proportional repair with full-cost eligibility; low-index repair ties; immediate gift-funded repairs/feeding; triple within-tide flood cascade; fractional-grain starvation; debt-negative section staying dry until its loop index; gate/debt/cascade ordering. All passed.
- Four synthetic schedules: 4/4 winning paths at widths 256 and 1024, independently replayed.
- An additional 24 synthetic schedules resembling the schedule distribution: 24/24 at width 256, 15,676,310 expansions, approximately 4.6 seconds total in this environment. These **are not the parent's 24 seeds** and do not establish those wins.
- A deliberately extreme synthetic height-100 schedule: returned a replay-checked loss path, not an impossibility assertion.
- Width 1, `--seeds`, and `--include-idle` smoke tests passed.

Evidence: `test_summary.json`, `test_corners_summary.json`, `test_modes.log`, `test_search_output.json`, `test_search_1024.json`, `test_stress_synthetic.json`, `test_stress_256.json`, `test_loss_output.json`, and accompanying protocol/log/raw files. `transition_test.cpp` is a transition-only C++ driver for differential tests. Original-seed witnesses must be established by running the parent-provided exported schedules, then Godot replaying every returned state before any balance tuning.
