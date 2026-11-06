Built **Kêr-Is** in Godot **4.7.2**, with procedural artwork and synthesized sound, desktop and phone touch layouts, the legend, session-best tracking, and restart without reloading.

**All numerical targets pass.** It took **six full test attempts**: the balance first passed on attempt five; attempt six strengthened the seer’s whole-future planning and completed the detailed audit.

### Final playtest results

Each policy ran over **200 seeds**. All **110 fixed strategies** were tested.

| Bot / policy | Wins | Win rate | Mean tides survived¹ |
|---|---:|---:|---:|
| Idle | 0/200 | 0% | 1.930 |
| Greedy | 0/200 | 0% | 4.125 |
| Best fixed: 3 quarry / 3 fields / 3 dike, gate closed | 2/200 | 1% | 6.210 |
| Steward | 89/200 | **44.5%** | 10.180 |
| Seer | 174/200 | 87% | 11.690 |
| Steward, never opens gate | 40/200 | 20% | 9.115 |
| Steward, never repairs | 0/200 | 0% | 1.920 |
| Steward, declines every bargain | 95/200 | 47.5% | 10.060 |
| Steward, accepts every bargain | 110/200 | 55% | 10.505 |

¹ The sinking tide is excluded.

- Idle lost before tide 7 on **100%** of seeds.
- Never opening the gate reduced steward wins by **24.5 percentage points**.
- Never repairing reduced wins by **44.5 points**.
- In paired steward counterfactuals, accepting bargains **helped 13 runs win and ruined 19** that otherwise won.

Full per-seed actions, resources and wall states at every tide are in `playtest.json`.

### What changed, and why

Early versions let fixed policies sacrifice districts and concentrate repairs indefinitely. I added increased pressure on surviving walls and permanent production losses. Bargains originally supplied enough gold to make trade unnecessary; removing that gold and tightening sustained pressure made safe gate openings important. Repair efficiency, gifts and forecast uncertainty were then tuned to reach the steward target without making fixed play successful.

Presentation fixes included dedicated portrait and compact-landscape layouts, clearer storm targets and wall readings, correct session-best counting, and a fully submerged ending. The final encoded video’s contact sheet was inspected; numerical audio checks confirm that the underwater bells retain sound while losing their bright upper partials.

### Deliverables

**Video — 1280×720, 30 fps, sound, 65 seconds:**  
`data/out/keris.mp4`

**Web build:**  
`data/out/web/index.html`

**Complete web archive:**  
`data/out/keris-web.zip`

**Playtest data:**  
`data/out/playtest.json`

**Source project:**  
`data/out/keris-source.zip`

The video contains **30 seconds of steward play**, followed by greedy’s final tides, sinking, and submerged bells. The final non-threaded web export contains **no `ERROR` lines**. Serve the complete web directory over HTTP(S), rather than opening the HTML through `file://`.

The attempt ledger, verification details and remaining native audio-teardown warnings are documented in `attempts.md` and `quality-report.md` alongside the deliverables.