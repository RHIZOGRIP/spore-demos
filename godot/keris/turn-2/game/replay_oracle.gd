extends SceneTree
const Rules=preload("res://rules.gd")
func _initialize():
	var args=OS.get_cmdline_user_args()
	var plans=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var wins=0
	var states_checked=0
	for entry in plans.results:
		var r=Rules.new();r.setup(int(entry.seed))
		for a in entry.actions:
			assert(not r.ended,"plan action after end seed %s tide %s"%[entry.seed,r.turn])
			for _h in range(int(a.hires)):
				assert(r.hire(),"illegal planned hire seed %s tide %s"%[entry.seed,r.turn])
			r.jobs=[int(a.jobs[0]),int(a.jobs[1]),int(a.jobs[2])]
			assert(r.jobs[0]+r.jobs[1]+r.jobs[2]<=r.workers,"illegal plan jobs")
			r.gate_open=a.gate;r.accepted=a.bargain
			r.resolve()
			var expected=entry.states[r.turn-1]
			for key in ["stone","grain","gold","workers"]:
				assert(absf(r.get(key)-expected[key])<0.000001,"REPLAY seed %s tide %s %s expected %s observed %s"%[entry.seed,r.turn,key,expected[key],r.get(key)])
			for i in range(3):
				assert(absf(r.hp[i]-expected.hp[i])<0.000001,"REPLAY seed %s tide %s hp%s expected %s observed %s"%[entry.seed,r.turn,i,expected.hp[i],r.hp[i]])
				assert(r.flooded[i]==expected.flooded[i],"REPLAY flood mismatch")
			states_checked+=1
		assert(r.won==entry.won,"REPLAY seed %s won expected %s observed %s"%[entry.seed,entry.won,r.won])
		if r.won:wins+=1
	print("GODOT_WITNESS_REPLAY PASS wins=",wins,"/",plans.results.size()," states=",states_checked," all resources, hp, floods, workers agree to 1e-6")
	quit()
