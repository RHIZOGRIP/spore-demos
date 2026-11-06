# Kêr-Is — complete balance attempt ledger

> CORRECTION: Attempts 1–6 used an incomplete readiness check set. Their historical “all targets pass” conclusions are superseded, not current claims. Attempts 7–10 audit the missing seer adequacy and bargain-choice requirements, preserve the earlier numbers, and record the corrections.

Each full run used Godot 4.7.2 headless, identical seeds 0–199, 200 runs per bot and per fixed strategy. Fixed sweep: all nonnegative integer splits summing to the initial nine workers, both always-open and always-closed gate (110 policies). Fixed policies never hire or bargain; after starvation, remove assignments from largest remaining job (lowest index breaks ties). Resources-by-tide average only runs reaching that tide; `n` is provided. The failure tide is not counted as survived.

## Attempt 1
Initial model: wear 8 + 2.2×height; repair14; gifts24 stone/16 grain/10 gold.

| Bot | Wins / 200 | Win rate | Mean resolved tides |
|---|---:|---:|---:|
| idle | 0 | 0.0% | 4.725 |
| greedy | 0 | 0.0% | 6.120 |
| best_fixed | 198 | 99.0% | 11.985 |
| steward | 197 | 98.5% | 11.945 |
| seer | 200 | 100.0% | 12.000 |
| steward_closed | 199 | 99.5% | 11.990 |
| steward_no_repair | 0 | 0.0% | 4.660 |

Idle loss before tide 7: 100.0%. Best fixed: [3, 3, 3], gate closed.
Bargain paired counterfactual: helped 1 seeds; ruined 2 seeds.
Failed targets: closed_drop_20, fixed_at_most_15, steward_40_to_70.

Fixed 3/3/3 can exhaust one district then concentrate all repairs on the remainder. Nine workers suffice, so trading is not necessary. Increase pressure and repair efficiency to sharpen workforce economics.

## Attempt 2
Wear13, pressure2.8, repair16, quarry4.5, repair goal62, trade forecast cutoff3.6.

| Bot | Wins / 200 | Win rate | Mean resolved tides |
|---|---:|---:|---:|
| idle | 0 | 0.0% | 3.450 |
| greedy | 0 | 0.0% | 5.985 |
| best_fixed | 188 | 94.0% | 11.685 |
| steward | 194 | 97.0% | 11.930 |
| seer | 191 | 95.5% | 11.895 |
| steward_closed | 197 | 98.5% | 11.960 |
| steward_no_repair | 0 | 0.0% | 3.445 |

Idle loss before tide 7: 100.0%. Best fixed: [3, 3, 3], gate closed.
Bargain paired counterfactual: helped 9 seeds; ruined 2 seeds.
Failed targets: closed_drop_20, fixed_at_most_15, steward_40_to_70.

Still no cascade penalty: sacrificing districts makes defence easier. Add +14 damage per lost district and reduce production 28% per loss, reflecting water attacking exposed inner walls.

## Attempt 3
Added cascade14 and loss0.28.

| Bot | Wins / 200 | Win rate | Mean resolved tides |
|---|---:|---:|---:|
| idle | 0 | 0.0% | 3.105 |
| greedy | 0 | 0.0% | 5.215 |
| best_fixed | 0 | 0.0% | 4.170 |
| steward | 54 | 27.0% | 10.245 |
| seer | 88 | 44.0% | 10.830 |
| steward_closed | 39 | 19.5% | 10.210 |
| steward_no_repair | 0 | 0.0% | 3.065 |

Idle loss before tide 7: 100.0%. Best fixed: [0, 0, 9], gate closed.
Bargain paired counterfactual: helped 15 seeds; ruined 12 seeds.
Failed targets: closed_drop_20, steward_40_to_70.

Steward too weak and closed-gate almost as strong: strangers finance hiring. Remove gold from bargains, increase trade to15, repairs to18, repair goal68. Bargains still pay stone and grain.

## Attempt 4
Bargain gold0; trade15; repair18; repair goal68.

| Bot | Wins / 200 | Win rate | Mean resolved tides |
|---|---:|---:|---:|
| idle | 0 | 0.0% | 3.105 |
| greedy | 0 | 0.0% | 5.395 |
| best_fixed | 14 | 7.0% | 10.970 |
| steward | 122 | 61.0% | 11.205 |
| seer | 166 | 83.0% | 11.735 |
| steward_closed | 120 | 60.0% | 11.235 |
| steward_no_repair | 0 | 0.0% | 3.065 |

Idle loss before tide 7: 100.0%. Best fixed: [3, 2, 4], gate closed.
Bargain paired counterfactual: helped 5 seeds; ruined 16 seeds.
Failed targets: closed_drop_20.

Steward61% meets target but closed60% proves trade optional. Tighten wear13→15 and reduce gifts24/16→18/12; safer forecast cutoff3.3 and repair goal70. Extra hires must now support the sustained load.

## Attempt 5
Wear15, gifts18 stone/12 grain, safe gate forecast<3.3, repair goal70.

| Bot | Wins / 200 | Win rate | Mean resolved tides |
|---|---:|---:|---:|
| idle | 0 | 0.0% | 2.930 |
| greedy | 0 | 0.0% | 5.125 |
| best_fixed | 2 | 1.0% | 7.200 |
| steward | 89 | 44.5% | 10.735 |
| seer | 92 | 46.0% | 10.810 |
| steward_closed | 40 | 20.0% | 9.915 |
| steward_no_repair | 0 | 0.0% | 2.920 |

Idle loss before tide 7: 100.0%. Best fixed: [3, 3, 3], gate closed.
Bargain paired counterfactual: helped 13 seeds; ruined 19 seeds.
Failed targets: none.

All specified targets pass. Audit seer: only current actual tide used before; strengthen to use the entire actual future via receding-horizon rollouts. No mechanics changed.

## Attempt 6
Same final mechanics. Seer evaluates neighboring worker splits, both gate actions and available bargain decisions against all future actual tides/bargains; baseline continuation uses actual tide heights. Added resource/assignment invariant assertions and complete fixed per-seed traces.

| Bot | Wins / 200 | Win rate | Mean resolved tides |
|---|---:|---:|---:|
| idle | 0 | 0.0% | 2.930 |
| greedy | 0 | 0.0% | 5.125 |
| best_fixed | 2 | 1.0% | 7.200 |
| steward | 89 | 44.5% | 10.735 |
| seer | 174 | 87.0% | 11.820 |
| steward_closed | 40 | 20.0% | 9.915 |
| steward_no_repair | 0 | 0.0% | 2.920 |

Idle loss before tide 7: 100.0%. Best fixed: [3, 3, 3], gate closed.
Bargain paired counterfactual: helped 13 seeds; ruined 19 seeds.
Failed targets: none.

All targets pass. Freeze mechanics. Presentation and export validation follow; these do not change bot rules.

## Attempt 7 — corrected-check audit of frozen attempt 6

No mechanics or policy changes. Added target registry and missing current-message seer >=95% and bargain-superiority checks. Recomputed from the preserved 200-seed traces: original T1–T7 pass; T8 fails (seer87%); T9 fails (44.5% vs always55%); T10 fails (44.5% vs never47.5%). Exactly24 seeds were won by none of the tested policies. Prior all_pass flag covered only seven checks; it is not a valid readiness claim under these requirements. Next: stronger search and Godot witness replay on the original mechanics, before tuning.

## Attempt 8 — stronger seer on original mechanics

The exact24 previously-unwon seeds are recorded in prior/unwon-seeds.json. A generic C++ full-future beam planner (width256, all integer worker splits, all affordable hire counts, both gate states, available bargain choices, seven ranking portfolios plus flood-mask diversity) found winning action witnesses for all24 on original mechanics. Godot replay verified all288 states. Extended to all200: first run exposed a serialization error on seed95 tide6 (expected hp2=22.28, Godot=4.28); default JSON export had rounded a near-tie affecting sequential repairs. Fixed schedule export to full-precision JSON, without changing mechanics or relaxing checks. Reran search and Godot replay:200/200 wins, all2400 state snapshots match to1e-6. No seeds needed a gameplay difficulty change. The former seer was a weak one-step neighborhood search, not evidence of impossibility. Full 200-seed bot sweep with strong seer: idle0%, greedy0%, bestfixed1%, steward44.5%, seer100%, closed20%, no-repair0%, always55%, never47.5%. T1–T8 pass; T9/T10 fail. Next: expose a noisy public bargain cue and use it sensibly.

## Attempt 9 — imperfect public bargain signs and selective stewardship

No changes to tide schedules, damage, gifts, repair costs or production. Added a public voice omen derived from concealed severity plus forecast-noise masking (warm / wavering / hollow); exact weakening amount and target remain hidden. Steward accepts a warm-voiced gift when stone<36 or grain<two tides of food, otherwise declines. The same available omen is exposed through visible() and must appear in UI/help. Full sweep: best_fixed=2/200 (1.0%), greedy=0/200 (0.0%), idle=0/200 (0.0%), seer=200/200 (100.0%), steward=120/200 (60.0%), steward_closed=8/200 (4.0%), steward_every_bargain=110/200 (55.0%), steward_never_bargain=95/200 (47.5%), steward_no_repair=0/200 (0.0%). All ten numerical targets pass. Paired bargain counterfactual helped 31 seeds and ruined 6. Next: integrate visible signs into all UI layouts and help; regenerate generic search from full-precision schedules and replay every oracle state in the final harness.

## Attempt 10 — final integrated sweep and presentation regression

Regenerated 200 full-precision schedules, rebuilt generic beam planner at width256, found200 winning witnesses, and replayed all2400 oracle states through Godot. No mechanic changes. Final harness now registers all ten required numerical checks and asserts registry/check completeness. It also independently compares every oracle state during the bot sweep and records the public voice sign used for each choice. Full sweep: idle=0/200 (0.0%), greedy=0/200 (0.0%), steward=120/200 (60.0%), seer=200/200 (100.0%), steward_closed=8/200 (4.0%), steward_no_repair=0/200 (0.0%), best_fixed=2/200 (1.0%), steward_never_bargain=95/200 (47.5%), steward_every_bargain=110/200 (55.0%). All ten targets pass. Fixed sweep still includes all110 policies at200 seeds each. Bargain paired outcomes: helped31, ruined6. Final replay/sweep after UI integration reproduces outcomes.

Presentation: removed the planning-duration suggestion; added voice signs and explanations to desktop/portrait/compact-landscape controls; replaced dark submerged ending with a lit drowned skyline and warm windows. Sinking draws no planning or result controls, only sound. Result waits for camera settlement, followed by at least eight full seconds of underwater bells. Synthetic touch and ending tests pass in all three layouts; ending unit timing is14.4sec including8.1sec settled underwater hold. Reviewed a single contact sheet containing planning/storm/settled/results and mobile voice cues. New recording/export verification follows below.

### Attempt10 — completed artifact checks

New video encoded and inspected:75s,2250frames,1280x720/30fps/AAC. Recorded settled camera at26.358s of greedy clip and result at34.358s:8.000s of settled bells; no planning controls in between. Native AVI teardown hung once after all900 steward frames were written; all frames and PCM decoded without errors, then MP4 verified. Measured compact-landscape wavering label218px against208px available and added bounded font fitting; six UI/ending regressions rerun successfully. Final non-threaded web export has no ERROR and mounted PCK loads compiled rules/main/balance with no test harness. No browser/physical phone/audio audition available. Numbered target report distinguishes passing numerical/implementation checks from unverified browser/human-pacing checks.

Fresh extracted source archive smoke test: cached-witness headless harness reproduced every stored adaptive/control trace and all ten target checks; no SCRIPT ERROR.
