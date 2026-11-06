#!/usr/bin/env python3
"""Recomputes the turn's results from playtest.json.gz and matches game/ against it. Needs only Python."""
import gzip
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).parent

data = json.loads(gzip.decompress((HERE / 'playtest.json.gz').read_bytes()))
bots = data['bots']
fixed = data['fixed_strategies']


def wins(policy):
    return sum(run['won'] for run in policy['runs'])


def rate(name):
    return wins(bots[name]) / len(bots[name]['runs'])


def won_seeds(name):
    return {run['seed'] for run in bots[name]['runs'] if run['won']}


for policy in [*bots.values(), *fixed]:
    assert [run['seed'] for run in policy['runs']] == list(range(200))
    assert wins(policy) == policy['wins']

for name, digest in data['source_sha256'].items():
    assert hashlib.sha256((HERE / 'game' / name).read_bytes()).hexdigest() == digest, name

print(f"Consistent: {len(bots) - 1 + len(fixed)} policies over 200 seeds, source matches the data.\n")

idle_early = sum(not run['won'] and run['tides'] < 7 for run in bots['idle']['runs']) / 200
best_fixed = max(wins(policy) for policy in fixed) / 200
gate_drop = rate('steward') - rate('steward_closed')
repair_drop = rate('steward') - rate('steward_no_repair')
helped = won_seeds('steward') - won_seeds('steward_never_bargain')
ruined = won_seeds('steward_never_bargain') - won_seeds('steward')

targets = [
    ('idle loses before tide 7 on at least 95%', f'{idle_early:.1%}', idle_early >= 0.95, 'idle_loses_before_7'),
    ('greedy wins at most 5%', f"{rate('greedy'):.1%}", rate('greedy') <= 0.05, 'greedy_at_most_5'),
    ('best fixed strategy wins at most 15%', f'{best_fixed:.1%}', best_fixed <= 0.15, 'fixed_at_most_15'),
    ('steward wins 40% to 70%', f"{rate('steward'):.1%}", 0.40 <= rate('steward') <= 0.70, 'steward_40_to_70'),
    ('never opening the gate costs 20 points', f'{gate_drop * 100:.1f}', gate_drop >= 0.20, 'closed_drop_20'),
    ('never repairing costs 20 points', f'{repair_drop * 100:.1f}', repair_drop >= 0.20, 'no_repair_drop_20'),
    ('bargains help some runs, ruin others', f'{len(helped)} / {len(ruined)}', bool(helped and ruined), 'bargains_help_and_ruin'),
]

print(f"{'Target':<42} {'Result':>8}  Holds")
for label, result, holds, check in targets:
    assert data['checks'][check] == holds
    print(f"{label:<42} {result:>8}  {'yes' if holds else 'NO'}")

print(f'\n{sum(target[2] for target in targets)} of {len(targets)} targets hold.')

won_by_any = set().union(*(won_seeds(name) for name in bots))
won_by_any |= {run['seed'] for policy in fixed for run in policy['runs'] if run['won']}
print(f"\nBeyond the targets:\n  seer wins {rate('seer'):.1%}\n  {200 - len(won_by_any)} of 200 seeds were won by no policy")

print('\nBargains, same seeds:')
for label, name in [('always accept', 'steward_every_bargain'), ('never accept', 'steward_never_bargain'), ("steward's rule", 'steward')]:
    print(f"  {label:<15} {rate(name):.1%}")
