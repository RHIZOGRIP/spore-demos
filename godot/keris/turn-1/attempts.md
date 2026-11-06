# Kêr-Is — complete balance attempt ledger

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
