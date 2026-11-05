#!/usr/bin/env python3
"""Recomputes the run's success claims from telemetry.json. Needs only Python."""
import json
import math
from pathlib import Path

HERE = Path(__file__).parent
FPS = 24
FALLEN = 45
TIPPING = 5
BALL = '02 • Released marble'
DOMINOES = [f'Domino_{i:02}' for i in range(1, 19)]
CUP_CENTRE = (7.944087028503418, 2.403568983078003)
CUP_INNER_RADIUS = 0.915
CUP_RIM_Z = 0.04
BALL_RADIUS = 0.22

frames = json.loads((HERE / 'telemetry.json').read_text())


def first_frame(name, degrees):
    return next(f['frame'] for f in frames if f['objects'][name]['tilt'] > degrees)


def ball(frame):
    return frames[frame - 1]['objects'][BALL]['p']


def strictly_rising(values):
    return all(a < b for a, b in zip(values, values[1:]))


falls = [first_frame(n, FALLEN) for n in DOMINOES]
tips = [first_frame(n, TIPPING) for n in DOMINOES]
held = math.dist(ball(60), ball(100))
gate_moves = next(f['frame'] for f in frames[100:] if f['objects'][DOMINOES[-1]]['tilt'] > 1)
ball_moves = next(f['frame'] for f in frames[100:] if math.dist(ball(f['frame']), ball(100)) > 0.01)
end = ball(len(frames))
from_centre = math.dist(end[:2], CUP_CENTRE)
speed = math.dist(ball(len(frames) - 1), end) * FPS

checks = [
    (f'every domino fell, frames {falls}', len(falls) == len(DOMINOES)),
    ('they fell in order', strictly_rising(falls)),
    (f'each started tipping after the one before, frames {tips}', strictly_rising(tips)),
    (f'the ball waited at the gate: {held:.3f} m between frames 60 and 100', held < 0.05),
    (f'the ball left only when the gate moved: gate frame {gate_moves}, ball frame {ball_moves}', ball_moves >= gate_moves),
    (f'the ball is inside the cup: {from_centre:.3f} m from the centre', from_centre + BALL_RADIUS < CUP_INNER_RADIUS),
    ('the ball is below the rim', end[2] + BALL_RADIUS < CUP_RIM_Z),
    (f'the ball is nearly still: {speed * 1000:.1f} mm/s on the last frame', speed < 0.01),
]

for text, passed in checks:
    print('pass' if passed else 'FAIL', text)
raise SystemExit(0 if all(passed for _, passed in checks) else 1)
