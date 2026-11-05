# Chain reaction

The spore builds a physics contraption and debugs it from the simulation's own numbers: a marble,
a curved line of dominoes, and a second ball that must land in a cup.

[![Six frames from the finished video](run-1/contact_sheet.jpg)](run-1/chain.mp4)

## One run

One prompt, one turn, no human help. [Watch the video](run-1/chain.mp4).

| | |
|---|---|
| Time | 28 min 28 s, of which 7 min 44 s rendering |
| Rounds | 101 |
| Simulation attempts | 18 |
| Rigid bodies | 69, with 18 dominoes on a curve turning 32° |
| Versions | spore 1.57.0, Blender 4.3.2 |
| Model | `gpt-6.1-sol`, on a ChatGPT plan, so no metered cost |
| Machine | laptop, Intel i9-13900H, 15 GiB, integrated graphics |

What broke in each attempt, in the spore's words:

| Attempt | Result and correction |
|---|---|
| 1 | The release chute intersected the final gate, causing an explosive reverse cascade. Split the chute around it. |
| 2 | Chain stopped at domino 10; the release lane disturbed domino 16 early. Increased traction and separated the lane. |
| 3 | The final gate jammed against the ramp. Replaced it with a T-shaped gate. |
| 4 | The ball lodged in the ramp gap; the first two dominoes also tied. Restored a continuous floor and raised the launch endpoint. |
| 5 | Correct fall order, but the fallen gate arm blocked the ball. Thinned the arm. |
| 6 | The arm still obstructed the ball. Reduced its thickness further. |
| 7 | The thin arm remained an obstacle. Redesigned the release lane perpendicular to the chain. |
| 8 | The elevated transverse lane blocked the final dominoes. Lowered it and shortened its rails. |
| 9 | The ball was deflected sideways and escaped the stage. Added a recessed cup along its measured trajectory. |
| 10 | The ball stopped short of the small cup. Enlarged and moved the cup closer. |
| 11 | Ball captured, but still rolling. Increased damping. |
| 12 | Modified final spacing caused premature backward collapse. Tried a stabilizing hinge. |
| 13 | The one-object hinge did not effectively constrain the gate. Investigated the constraint and cache. |
| 14 | Explicit cache reset confirmed the reverse-collapse failure. Added a passive hinge anchor. |
| 15 | The hinge blocked forward travel and jammed the chain. Reversed its limit. |
| 16 | The hinge assembly caused another early disturbance. Removed it and restored the free-gate design. |
| 17 | Correct sequence and capture, but insufficient settling. Increased ball damping moderately. |
| **18** | **Passed sequence, containment, and numerical rest checks.** |

### Check it yourself

`run-1/` holds the [per-frame telemetry](run-1/telemetry.json) of the passing attempt, the
[attempt log](run-1/attempts.md), the [run's numbers](run-1/run.json) and the
[scene](run-1/chain.blend). The log mentions `data/sim/`, the spore's working folder, which isn't
included. This recomputes the claims, with no Blender and no model:

```sh
python3 run-1/verify.py
```

### What the spore's report leaves out

We checked its claims against the telemetry and the frames, and they hold. Four things are worth
knowing:

- **One change isn't reported.** Attempt 17 failed partly because dominoes 16 and 17 tied on a
  frame. Attempt 18 raised the ball's damping, as reported, and also changed the solver's iterations
  from 40 to 41, which isn't. That is probably what broke the tie, so the order may be fragile.
- **"At rest" is generous.** The ball is still creeping at 8.6 mm/s on the last frame. The spore set
  its 10 mm/s limit after seeing this result, though attempt 17 would have failed it too.
- **Attempt 13 was probably not a new simulation.** Its numbers are identical to attempt 12's, which
  points to a stale cache. The spore reset the cache in attempt 14, but the report still blames the
  hinge. That makes it 17 distinct runs.
- **The target moved.** After attempt 10 the spore enlarged the cup and put it where the ball was
  going. It is about four times the ball's width.

This is one run. A physics simulation is sensitive to small changes, and a new run builds a
different machine, so expect a different number of attempts, and possibly a failure.

## Run it

Expect about 30 minutes, a quarter of it rendering. You need `ffmpeg`, and spore 1.57.0 or newer.

```sh
spore define chain
spore edit chain
```

In the editor, set these lines:

```
rounds: [120, 150]
cost: [5.00, 8.00]
wall: [60m, 75m]
images: [12, 30MB]
```

[Start the bridge](../README.md) in an empty Blender, then run `spore tui chain`. Paste the bridge's
paragraph, followed by this:

```
Clear the default scene and build a chain reaction that runs by itself under Blender's rigid body physics, with at most 150 rigid bodies. A marble rolls down a ramp and hits the first of a curved line of dominoes. The dominoes fall in sequence, and the last one releases a second ball, which must end up inside a cup. Build it in several small requests, so that someone watching the viewport sees it grow.

Decide success by numbers, not by eye. After each simulation, step through the frames and read the objects' world positions and rotations: when each domino fell, and where the second ball ended up. It has succeeded only when every domino has fallen, in order, and the second ball is at rest inside the cup. When it fails, find where the chain broke and why from those numbers, change the scene and run it again. Keep every attempt in data/attempts.md: what failed, where, what you changed.

To see a run, render 6 frames across it at low resolution and join them into one contact sheet, so one look covers a whole run. Look at a sheet whenever the numbers leave you unsure, and before the final render, to check that the camera keeps the action in frame.

When a run succeeds, render 10 seconds at 24 fps and 1280x720 with EEVEE as PNG frames in data/frames/, in chunks that respect the 3-minute limit, with a camera that follows the action. Join them into data/out/chain.mp4 with ffmpeg, which is installed. Make a contact sheet from the finished frames and look at it, and fix what is wrong before you hand it over. Save the scene to data/chain.blend.

Then tell me how many attempts it took, what broke in each one, and the absolute path of the video.
```
