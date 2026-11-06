#!/usr/bin/env python3
"""Recomputes the turn's results from playtest.json.gz, matches game/ against it and compares with turn 1. Needs only Python."""
import gzip
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).parent
FIRST = HERE.parent / 'turn-1'


def load(folder):
    return json.loads(gzip.decompress((folder / 'playtest.json.gz').read_bytes()))


data = load(HERE)
first = load(FIRST)
bots = data['bots']
fixed = data['fixed_strategies']


def wins(policy):
    return sum(run['won'] for run in policy['runs'])


def rate(name):
    return wins(bots[name]) / len(bots[name]['runs'])


def won_seeds(policy):
    return {run['seed'] for run in policy['runs'] if run['won']}


def bot_wins(name):
    return won_seeds(bots[name])


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
helped = bot_wins('steward') - bot_wins('steward_never_bargain')
ruined = bot_wins('steward_never_bargain') - bot_wins('steward')
always, never = rate('steward_every_bargain'), rate('steward_never_bargain')

targets = [
    ('idle loses before tide 7 on at least 95%', f'{idle_early:.1%}', idle_early >= 0.95, 'idle_loses_before_7'),
    ('greedy wins at most 5%', f"{rate('greedy'):.1%}", rate('greedy') <= 0.05, 'greedy_at_most_5'),
    ('best fixed strategy wins at most 15%', f'{best_fixed:.1%}', best_fixed <= 0.15, 'fixed_at_most_15'),
    ('steward wins 40% to 70%', f"{rate('steward'):.1%}", 0.40 <= rate('steward') <= 0.70, 'steward_40_to_70'),
    ('never opening the gate costs 20 points', f'{gate_drop * 100:.1f}', gate_drop >= 0.20, 'closed_drop_20'),
    ('never repairing costs 20 points', f'{repair_drop * 100:.1f}', repair_drop >= 0.20, 'no_repair_drop_20'),
    ('bargains help some runs, ruin others', f'{len(helped)} / {len(ruined)}', bool(helped and ruined), 'bargains_help_and_ruin'),
    ('seer wins at least 95%', f"{rate('seer'):.1%}", rate('seer') >= 0.95, 'seer_at_least_95'),
    ('steward beats always accepting', f"{rate('steward'):.1%}", rate('steward') > always, 'selective_beats_always'),
    ('steward beats never accepting', f"{rate('steward'):.1%}", rate('steward') > never, 'selective_beats_never'),
]
assert {target[3] for target in targets} == set(data['checks'])

print(f"{'Target':<42} {'Result':>8}  Holds")
for label, result, holds, check in targets:
    assert data['checks'][check] == holds
    print(f"{label:<42} {result:>8}  {'yes' if holds else 'NO'}")

print(f'\n{sum(target[2] for target in targets)} of {len(targets)} targets hold.')

plans = json.loads((HERE / 'game' / 'oracle-plans.json').read_text())['results']
assert [plan['seed'] for plan in plans] == list(range(200))
assert all(plan['won'] and len(plan['actions']) == 12 and len(plan['states']) == 12 for plan in plans)

unwon_first = set(range(200)) - set().union(*(won_seeds(policy) for policy in [*first['bots'].values(), *first['fixed_strategies']]))
assert unwon_first <= {plan['seed'] for plan in plans}
print(f'\nSeer has a 12-tide winning plan for all 200 seeds, including the {len(unwon_first)} no policy won in turn 1.')

others = set().union(*(bot_wins(name) for name in bots if name != 'seer'), *(won_seeds(policy) for policy in fixed))
print(f'{200 - len(others)} of 200 seeds are won by seer alone.')

balance_same = (HERE / 'game' / 'balance.json').read_bytes() == (FIRST / 'game' / 'balance.json').read_bytes()
fixed_same = all(a['split'] == b['split'] and a['gate_open'] == b['gate_open'] and won_seeds(a) == won_seeds(b) for a, b in zip(fixed, first['fixed_strategies']))
print(f"\nSame as turn 1:\n  balance.json: {'yes' if balance_same else 'NO'}\n  every fixed strategy wins the same seeds: {'yes' if fixed_same else 'NO'}")

print('\nBargains, same seeds:')
for label, name in [('always accept', 'steward_every_bargain'), ('never accept', 'steward_never_bargain'), ("steward's rule", 'steward')]:
    print(f"  {label:<15} {rate(name):.1%}")
