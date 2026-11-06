extends SceneTree
const Rules = preload("res://rules.gd")
const FIRST = 1000
const COUNT = 2000
func play(kind, forced, seed_i):
	var r = Rules.new(); r.setup(seed_i); r.forced_bargain = forced
	while not r.ended:
		if kind == "fixed333":
			r.gate_open = false; r.accepted = false; r.jobs = [3, 3, 3]
			while r.jobs[0] + r.jobs[1] + r.jobs[2] > r.workers:
				var k = r.jobs.find(r.jobs.max()); r.jobs[k] -= 1
		else:
			r.policy(kind)
		r.resolve()
	return r.won
func _init():
	var names = {"steward": ["steward", -1], "never": ["steward", 0], "always": ["steward", 1], "closed": ["steward_closed", -1], "no_repair": ["steward_no_repair", -1], "greedy": ["greedy", -1], "idle": ["idle", -1], "fixed333": ["fixed333", -1]}
	var won = {}
	for name in names:
		won[name] = []
		for i in range(COUNT):
			won[name].append(play(names[name][0], names[name][1], FIRST + i))
		print(name, " ", won[name].count(true), "/", COUNT, " ", 100.0 * won[name].count(true) / COUNT)
	for other in ["always", "never"]:
		var a = 0; var b = 0
		for i in range(COUNT):
			if won.steward[i] and not won[other][i]: a += 1
			if won[other][i] and not won.steward[i]: b += 1
		print("steward vs ", other, ": steward only ", a, ", ", other, " only ", b)
	var stats = {}
	for i in range(COUNT):
		var r = Rules.new(); r.setup(FIRST + i)
		for t in range(12):
			if r.tides[t].offer:
				r.turn = t; r.offer = true
				var sign = r.bargain_sign(); var dmg = r.tides[t].debt_damage
				if not stats.has(sign): stats[sign] = [0, 0.0, 0]
				stats[sign][0] += 1; stats[sign][1] += dmg
				if dmg >= 65.0: stats[sign][2] += 1
	for sign in stats:
		print("voice ", sign, " offers ", stats[sign][0], " mean damage ", snappedf(stats[sign][1] / stats[sign][0], 0.1), " heavy(>=65) ", snappedf(100.0 * stats[sign][2] / stats[sign][0], 0.1), "%")
	quit()
