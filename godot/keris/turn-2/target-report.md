# Kêr-Is — numbered target-by-target report

## Correction of the first report

- Claimed overall readiness from an incomplete numerical/adequacy check set; seer only87%.
- Did not establish whether the24 seeds no policy won were winnable.
- Called a44.5% bargain heuristic sensible despite always55% and never47.5%.
- Accepted a result overlay during sinking and an inadequately lit drowned view.

The visible original numerical list has T1-T7. The current message explicitly supplies T8>=95% and adds T9/T10. None of those thresholds was weakened. PASS is limited to the stated evidence.

## Numerical, process and presentation targets

| # | Target | Pass/fail | Final evidence |
|---|---|---|---|
| T1 | Idle loses before tide 7 on at least 95% of seeds | **PASS** | 100.0% lose before tide 7 |
| T2 | Greedy win rate at most 5% | **PASS** | 0.0% |
| T3 | Best of every integer fixed split / both gate policies wins at most 15% | **PASS** | 1.0%; all 110 fixed policies tested |
| T4 | Steward win rate from 40% to 70% inclusive | **PASS** | 60.0% |
| T5 | Never-open ablation reduces steward win rate by at least 20 percentage points | **PASS** | 56.0 percentage-point drop |
| T6 | No-repair ablation reduces steward win rate by at least 20 points | **PASS** | 60.0 point drop |
| T7 | Accepting bargains helps some steward runs and ruins others | **PASS** | 31 helped / 6 ruined, paired against never-accept |
| T8 | Seer wins at least 95% of seeds | **PASS** | 100.0% (200/200), every witness replayed |
| T9 | Selective steward beats otherwise identical always-accept steward | **PASS** | 60% selective > 55% always (same base policy) |
| T10 | Selective steward beats otherwise identical never-accept steward | **PASS** | 60% selective > 47.5% never (same base policy) |
| T11 | Check every original numerical condition; add seer and new bargain checks | **PASS** | One-to-one ten-entry registry; test.gd asserts check count and every named key |
| T12 | Investigate the 24 previously-unwon seeds with stronger search | **PASS** | All 24 won on ORIGINAL mechanics; 200/200 overall, 2400 Godot-replayed states; no seed exceptions |
| T13 | Result only after the view settles underwater and bells ring at least 8 seconds | **PASS** | Recorded camera settles at 26.358s, result at 34.358s: 8.000s hold |
| T14 | Keep the drowned city visible and lit | **PASS** | Bright underwater palette, warm lit windows and light shafts; final video/contact sheet visually inspected |
| T15 | Hide planning panels throughout sinking | **PASS** | Separate sinking renderer; tests in all three layouts find only sound control, no planning/result controls before the hold |
| T16 | Remove the suggested-planning-duration line | **PASS** | No such string in main.gd or game layouts; inspected planning frames |
| T17 | Rerun every bot on 200 seeds, including every fixed split; record per-tide resources | **PASS** | All 110 fixed policies plus 8 adaptive/control policies rerun; complete per-seed traces and per-tide means with n |
| T18 | New 1280x720 sound video: 30s steward then greedy final tides and sinking | **PASS** | 75 seconds, 2250 frames, 30 fps, H.264/AAC; first 900 frames steward, next 1350 greedy; final contact sheet inspected |
| T19 | Clean non-threaded web export; no old builds packed | **PASS** | Godot4.7.2 GL Compatibility; no ERROR in final export; HTML threads=false; explicit output/planner/test exclusions; PCK mounted |
| T20 | Log every attempt in data/attempts.md | **PASS** | Attempt headings 1-10 retained; audit, search/precision failure, cue change and final verification recorded |
| T21 | Explain what the first report got wrong | **PASS** | Readiness claim lacked oracle adequacy; 87% seer and 24 uncovered seeds were not resolved; selective bargaining was worse than both fixed choices; ending review was inadequate |

## Every original functional requirement (implementation evidence)

| # | Requirement | Pass/fail and scope | Evidence |
|---|---|---|---|
| F1 | Godot4.7.2; English; gl_compatibility; 1280x720 scalable viewport | PASS (implementation/native evidence) | Source configuration and supplied runtime; native software OpenGL renders verified |
| F2 | Desktop and phone web delivery, every action touch-accessible | PASS (implementation/native evidence) | Non-threaded web build plus desktop/portrait/compact-landscape layouts; every action passes synthetic screen-touch tests. |
| F3 | About six-minute, 12-tide run with untimed low-tide planning and about8s animated tides | PASS (implementation/native evidence) | 12-tide rules and8s animation preserved; no human planning clock. |
| F4 | One screen: sea left, bronze gate/dike, climbing city districts | PASS (implementation/native evidence) | Planning, tide and storm native frames inspected; no map navigation or separate district screens |
| F5 | Stone repairs, grain feeds, gold hires; unfed workers leave; tapping assigns quarry/fields/dike | PASS (implementation/native evidence) | Rules/state invariants and touch +/- /hire tests; resource traces at every tide |
| F6 | Open/closed gate per tide: trade gold vs high-water loss of lowest district; next forecast can err | PASS (implementation/native evidence) | Deterministic rules, gate touch tests and actual/forecast traces |
| F7 | Storm strikes one dike section | PASS (implementation/native evidence) | Single seeded storm index; indexed warning/impact graphic in captured frames |
| F8 | Stranger gives supplies now against concealed weakening revealed later | PASS (implementation/native evidence) | Current tide gifts; debt due two tides later; exact amount/target hidden. New noisy public voice sign is displayed and explained |
| F9 | Flooded district loses production; all districts lost sinks Ys; survive equinox wins | PASS (implementation/native evidence) | Production loss/cascade rules; end-state assertions across all trajectories; 12th tide is6.2m |
| F10 | Warning bells near failure; underwater bells continue muffled on loss | PASS (implementation/native evidence) | Warning threshold and repeated bell synthesis; nonzero recorded sound and reduced upper-partial energy underwater |
| F11 | Title and short Breton legend with Gradlon/key/Dahut/stranger/bronze ship gate | PASS (implementation/native evidence) | English title, legend and help text preserved; title/start/help screen-touch tests |
| F12 | Restart without page reload; best session result | PASS (implementation/native evidence) | Same-instance restart test and session-best assertion; sinking tide excluded |
| F13 | All art and sound generated in code/shaders, no downloaded assets | PASS (implementation/native evidence) | GDScript drawing/PCM synthesis, built-in fallback font; custom HTML/CSS loader, no default exported logo reference |
| F14 | Rules separate from drawing; reproducible seeded headless faster-than-real-time playtests | PASS (implementation/native evidence) | rules.gd independent of main scene; native C++ future planner and Godot replay; fixed/adaptive sweep without display |
| F15 | Idle, greedy, every fixed split/gate policy, visible-state steward and all-future seer | PASS (implementation/native evidence) | Complete bot sweep; steward reads only public snapshot and voice cue; seer receives full schedules, never seed-specific policy branches |
| F16 | Capture/inspect planning, tide, storm, sinking and final video contact sheets | PASS (implementation/native evidence) | Revision contact sheet and final encoded video contact sheet read and inspected; mobile cue previews included |
| F17 | Deliver web/index.html, keris.mp4, playtest.json and an account of attempts/final numbers/limits/absolute paths | PASS (implementation/native evidence) | Files, target report, README, complete attempt ledger, source/web archives and hashes delivered |
