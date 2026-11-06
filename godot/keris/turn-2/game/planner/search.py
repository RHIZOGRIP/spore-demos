#!/usr/bin/env python3
"""Compile and run generic oracle beam search; independently verify returned traces."""
import argparse
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import time

BASE = Path(__file__).resolve().parent
FIELDS = 'stone grain hp gift_stone gift_grain gift_gold loss quarry fields repair_cost repair trade wear pressure cascade'.split()

def simulate(config, tides, actions):
    """Independent literal replay of rules.gd.txt (not a policy)."""
    c = config
    s = dict(stone=float(c['stone']), grain=float(c['grain']), gold=0.0,
             workers=9, hp=[float(c['hp'])]*3, flooded=[False]*3)
    debts, states = [], []
    for turn, a in enumerate(actions):
        if turn >= 12 or all(s['flooded']):
            raise ValueError('action after game ended')
        for _ in range(a['hires']):
            if s['gold'] < 5 or s['workers'] >= 12:
                raise ValueError('illegal hire')
            s['gold'] -= 5
            s['workers'] += 1
        q, f, d = a['jobs']
        if min(q, f, d) < 0 or q+f+d > s['workers']:
            raise ValueError('illegal jobs')
        t = tides[turn]
        if a['bargain']:
            if not t['offer']:
                raise ValueError('unavailable bargain')
            s['stone'] += c['gift_stone']
            s['grain'] += c['gift_grain']
            s['gold'] += c['gift_gold']
            debts.append((turn+2, t['debt_section'], t['debt_damage']))
        productivity = 1.0 - s['flooded'].count(True)*c['loss']
        s['stone'] += q*c['quarry']*productivity
        s['grain'] += f*c['fields']*productivity
        for _ in range(d):
            dry = [i for i in range(3) if not s['flooded'][i]]
            k = min(dry, key=lambda i: s['hp'][i]) if dry else -1
            if k >= 0 and s['stone'] >= c['repair_cost']:
                needed = min(c['repair'], 100.0-s['hp'][k])
                if needed > 0:
                    s['stone'] -= c['repair_cost']*(needed/c['repair'])
                    s['hp'][k] += needed
        for due, section, damage in debts:
            if due == turn and not s['flooded'][section]:
                s['hp'][section] -= damage
        def flood(i):
            s['flooded'][i] = True
            s['hp'][i] = 0.0
        if a['gate']:
            s['gold'] += c['trade']
            if t['height'] >= 4:
                dry = [i for i in range(3) if not s['flooded'][i]]
                if dry:
                    flood(dry[0])
        for i in range(3):
            if s['flooded'][i]:
                continue
            hit = c['wear'] + t['height']*c['pressure'] + s['flooded'].count(True)*c['cascade']
            if t['storm'] == i:
                hit += t['strike']
            s['hp'][i] -= hit
            if s['hp'][i] <= 0:
                flood(i)
        missing = max(0, s['workers']-math.floor(s['grain']))
        s['grain'] = max(0.0, s['grain']-s['workers'])
        s['workers'] -= missing
        states.append(json.loads(json.dumps(s)))
    return states

def verify(result, config, schedule):
    expected = simulate(config, schedule['tides'], result['actions'])
    observed = result['states']
    if len(expected) != len(observed):
        raise AssertionError(f"seed {schedule['seed']}: state count expected {len(expected)}, observed {len(observed)}")
    for turn, (e, o) in enumerate(zip(expected, observed)):
        for field in e:
            ev, ov = e[field], o.get(field)
            if field in ('stone', 'grain', 'gold'):
                ok = isinstance(ov, (int, float)) and math.isclose(ev, ov, rel_tol=1e-12, abs_tol=1e-9)
            elif field == 'hp':
                ok = len(ev) == len(ov) and all(math.isclose(x, y, rel_tol=1e-12, abs_tol=1e-9) for x, y in zip(ev, ov))
            else:
                ok = ev == ov
            if not ok:
                raise AssertionError(f"seed {schedule['seed']} tide {turn+1} {field}: expected {ev!r}, observed {ov!r}")
    won = len(expected) == 12 and not all(expected[-1]['flooded'])
    if result['won'] != won:
        raise AssertionError(f"seed {schedule['seed']} won: expected {won}, observed {result['won']}")

def validate(data):
    c = data['config']
    for k in FIELDS:
        if not isinstance(c[k], (int, float)) or not math.isfinite(c[k]):
            raise ValueError(f'non-finite numeric config {k}')
    if c['repair'] <= 0 or c['repair_cost'] <= 0 or not 0 <= c['loss'] <= 1/3:
        raise ValueError('requires positive repair/cost and loss in [0,1/3]')
    if any(c[k] < 0 for k in FIELDS) or c['hp'] > 100:
        raise ValueError('requires nonnegative game parameters and initial hp <=100')
    seen = set()
    for s in data['schedules']:
        if type(s['seed']) is not int or not -(2**63) <= s['seed'] < 2**63 or s['seed'] in seen:
            raise ValueError('seed must be a unique signed 64-bit integer')
        seen.add(s['seed'])
        if len(s['tides']) != 12:
            raise ValueError('each schedule must have exactly 12 tides')
        for t in s['tides']:
            for k in ('height', 'strike', 'debt_damage'):
                if not isinstance(t[k], (int, float)) or not math.isfinite(t[k]) or t[k] < 0:
                    raise ValueError(f'invalid tide {k}')
            if t['storm'] not in (-1, 0, 1, 2) or t['debt_section'] not in (0, 1, 2):
                raise ValueError('invalid section index')
            if type(t['offer']) is not bool:
                raise ValueError('offer must be boolean')

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('input', type=Path)
    p.add_argument('output', type=Path)
    p.add_argument('--width', type=int, default=256)
    p.add_argument('--seeds', help='comma-separated seed IDs')
    p.add_argument('--include-idle', action='store_true', help='enumerate all allocations with sum <= workers (default: sum == workers)')
    a = p.parse_args()
    if a.width < 1:
        p.error('width must be positive')
    data = json.loads(a.input.read_text())
    validate(data)
    schedules = data['schedules']
    if a.seeds is not None:
        seeds = {int(x) for x in a.seeds.split(',')}
        available = {s['seed'] for s in schedules}
        if seeds-available:
            p.error(f'seeds absent from input: {sorted(seeds-available)}')
        schedules = [s for s in schedules if s['seed'] in seeds]
    # Persistent exact protocol and process logs provide evidence even on failure.
    stem = a.output
    stem.parent.mkdir(parents=True, exist_ok=True)
    src, exe = BASE/'search.cpp', BASE/'search_bin'
    buildlog = Path(str(stem)+'.build.log')
    if not exe.exists() or src.stat().st_mtime_ns > exe.stat().st_mtime_ns:
        with buildlog.open('w') as log:
            proc = subprocess.run(['g++', '-std=c++17', '-O3', '-Wall', '-Wextra', str(src), '-o', str(exe)], stdout=log, stderr=subprocess.STDOUT, env=dict(os.environ, TMPDIR=str(BASE)))
        if proc.returncode:
            raise RuntimeError(f'compile failed: see {buildlog}')
    lines = [f'{a.width} {len(schedules)} {int(a.include_idle)}', ' '.join(str(data['config'][k]) for k in FIELDS)]
    for s in schedules:
        lines.append(str(s['seed']))
        for t in s['tides']:
            lines.append(' '.join(str(x) for x in (t['height'], t['storm'], t['strike'], int(t['offer']), t['debt_section'], t['debt_damage'])))
    protocol = Path(str(stem)+'.numeric.txt')
    protocol.write_text('\n'.join(lines)+'\n')
    raw, err = Path(str(stem)+'.raw.json'), Path(str(stem)+'.stderr.log')
    start = time.monotonic()
    with protocol.open('r') as inp, raw.open('w') as out, err.open('w') as errors:
        proc = subprocess.run([str(exe)], stdin=inp, stdout=out, stderr=errors)
    if proc.returncode:
        raise RuntimeError(f'search exit {proc.returncode}; preserved {raw}, {err}, {protocol}')
    result = json.loads(raw.read_text())
    if len(result['results']) != len(schedules):
        raise AssertionError('result count mismatch')
    try:
        for r, s in zip(result['results'], schedules):
            if r['seed'] != s['seed']:
                raise AssertionError('seed order mismatch')
            verify(r, data['config'], s)
            r['diagnostics']['independent_python_replay'] = 'passed'
    except Exception as exc:
        Path(str(stem)+'.verification_failure.txt').write_text(str(exc)+'\n')
        raise
    result.update(algorithm='Deterministic exact-simulation beam; seven scoring portfolios plus flood-mask coverage; exact state deduplication; known future storms and pending debts in ranking', width=a.width,
                  all_workers_assigned=not a.include_idle, elapsed_seconds=time.monotonic()-start,
                  caveats=['Finite beam failure is not proof of impossibility.', 'Full future schedules are required; no RNG or seed-dependent policy.', 'States are after each resolve, not including the initial state.'])
    temp = Path(str(stem)+'.tmp')
    temp.write_text(json.dumps(result, indent=2, allow_nan=False)+'\n')
    os.replace(temp, stem)
    print(f"{sum(r['won'] for r in result['results'])}/{len(schedules)} won; {stem}", file=sys.stderr)

if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        # Keep stdout/raw traces untouched. Include the concrete expected/observed discrepancy.
        print(f'{type(exc).__name__}: {exc}', file=sys.stderr)
        raise
