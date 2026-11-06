extends SceneTree
const Rules = preload("res://rules.gd")
var summary={}
var all_runs={}
var num=200
var oracle_results={}

func run_bot(kind:String,split=[],gate=false,forced=-1):
	var records=[]
	var wins=0
	var early=0
	var total=0
	var resources=[]
	for t in range(12): resources.append({"n":0,"stone":0.0,"grain":0.0,"gold":0.0,"workers":0.0})
	for seed_i in range(num):
		var r=Rules.new(); r.setup(seed_i); r.forced_bargain=forced
		if kind=="seer":
			assert(oracle_results.has(str(seed_i)),"Missing generic search result seed %s"%seed_i)
			r.oracle_actions=oracle_results[str(seed_i)].actions
		var trace=[]
		while not r.ended:
			if kind=="fixed":
				r.gate_open=gate
				r.accepted=false
				# A fixed split is a ratio kept after attrition; initial nine workers, no reactive hiring.
				r.jobs=split.duplicate()
				while r.jobs[0]+r.jobs[1]+r.jobs[2]>r.workers:
					var k=r.jobs.find(r.jobs.max()); r.jobs[k]-=1
			else: r.policy(kind)
			var action={"jobs":r.jobs.duplicate(),"gate":r.gate_open,"bargain":r.accepted,"forecast":r.forecast,"bargain_sign":r.bargain_sign(),"offer_available":r.offer}
			r.resolve()
			assert(r.stone>=0 and r.grain>=0 and r.gold>=0, "negative resource seed %s tide %s" % [seed_i,r.turn])
			assert(r.jobs[0]+r.jobs[1]+r.jobs[2]<=r.workers, "overassigned seed %s tide %s" % [seed_i,r.turn])
			assert(r.workers>=0 and r.workers<=12, "worker bound seed %s tide %s" % [seed_i,r.turn])
			if kind=="seer":
				var predicted=oracle_results[str(seed_i)].states[r.turn-1]
				for key in ["stone","grain","gold","workers"]:
					assert(absf(r.get(key)-predicted[key])<0.000001,"oracle replay seed %s tide %s %s expected %s observed %s"%[seed_i,r.turn,key,predicted[key],r.get(key)])
				for k in range(3):
					assert(absf(r.hp[k]-predicted.hp[k])<0.000001 and r.flooded[k]==predicted.flooded[k],"oracle replay wall mismatch seed %s tide %s section %s"%[seed_i,r.turn,k])
			var state={"tide":r.turn,"stone":r.stone,"grain":r.grain,"gold":r.gold,"workers":r.workers,"hp":r.hp.duplicate(),"flooded":r.flooded.duplicate(),"action":action,"actual":r.last}
			trace.append(state)
			var row=resources[r.turn-1]; row.n+=1
			for key in ["stone","grain","gold","workers"]: row[key]+=state[key]
		if r.won: wins+=1
		if r.turn<7 and not r.won: early+=1
		total+=r.turn
		records.append({"seed":seed_i,"won":r.won,"tides":r.turn,"survived":r.turn if r.won else r.turn-1,"bargains":r.bargain_count,"trace":trace})
	for row in resources:
		if row.n>0:
			for key in ["stone","grain","gold","workers"]: row[key]/=row.n
	return {"wins":wins,"win_rate":float(wins)/num,"mean_tides_resolved":float(total)/num,"loss_before_7_rate":float(early)/num,"resources_by_tide":resources,"runs":records}

func _initialize():
	var args=OS.get_cmdline_user_args()
	var output="res://../test.json"
	for a in args:
		if a.begins_with("--out="): output=a.substr(6)
	var oracle_path="res://oracle-plans.json"
	for a in args:
		if a.begins_with("--oracle="):oracle_path=a.substr(9)
	var plans=JSON.parse_string(FileAccess.get_file_as_string(oracle_path))
	assert(plans!=null and plans.results.size()==num,"Need 200 freshly generated oracle plans")
	for entry in plans.results:oracle_results[str(int(entry.seed))]=entry
	var detailed={}
	for kind in ["idle","greedy","steward","seer","steward_closed","steward_no_repair"]:
		var result=run_bot(kind)
		detailed[kind]=result
		print(kind," wins=",result.wins,"/",num," mean=",result.mean_tides_resolved," early=",result.loss_before_7_rate)
	var fixed=[]
	var best={"wins":-1}
	for q in range(10):
		for f in range(10-q):
			var split=[q,f,9-q-f]
			for gate in [false,true]:
				var result=run_bot("fixed",split,gate)
				var row={"split":split,"gate_open":gate,"wins":result.wins,"win_rate":result.win_rate,"mean_tides_resolved":result.mean_tides_resolved,"resources_by_tide":result.resources_by_tide,"runs":result.runs}
				fixed.append(row)
				if result.wins>best.wins:
					best=row.duplicate(true); best.erase("runs"); detailed["best_fixed"]=result
	print("best fixed ",best)
	var declined=run_bot("steward",[],false,0)
	var always=run_bot("steward",[],false,1)
	detailed["steward_never_bargain"]=declined
	detailed["steward_every_bargain"]=always
	var helped=[]; var ruined=[]
	for i in range(num):
		if detailed.steward.runs[i].won and not declined.runs[i].won: helped.append(i)
		if not detailed.steward.runs[i].won and declined.runs[i].won: ruined.append(i)
	var checks={"idle_loses_before_7":detailed.idle.loss_before_7_rate>=0.95,"greedy_at_most_5":detailed.greedy.win_rate<=0.05,"fixed_at_most_15":best.win_rate<=0.15,"steward_40_to_70":detailed.steward.win_rate>=0.4 and detailed.steward.win_rate<=0.7,"closed_drop_20":detailed.steward.win_rate-detailed.steward_closed.win_rate>=0.20-0.00001,"no_repair_drop_20":detailed.steward.win_rate-detailed.steward_no_repair.win_rate>=0.20-0.00001,"bargains_help_and_ruin":not helped.is_empty() and not ruined.is_empty()}
	checks["seer_at_least_95"]=detailed.seer.win_rate>=0.95
	checks["selective_beats_always"]=detailed.steward.win_rate>always.win_rate
	checks["selective_beats_never"]=detailed.steward.win_rate>declined.win_rate
	var registry=JSON.parse_string(FileAccess.get_file_as_string("res://targets.json"))
	assert(checks.size()==registry.size(),"Check registry mismatch expected %s observed %s"%[registry.size(),checks.size()])
	for target in registry:
		assert(checks.has(target.check),"Missing required check "+target.id+": "+target.target)
	var passed=true
	for k in checks:
		if not checks[k]:
			passed=false; print("FAIL ",k)
	print("BARGAINS helped=",helped.size()," ruined=",ruined.size()," PASS=",passed)
	var payload={"target_registry":registry,"oracle_search":{"algorithm":plans.algorithm,"width":plans.width,"witnesses_replayed_in_godot":num},"seeds":num,"seed_range":[0,num-1],"config":JSON.parse_string(FileAccess.get_file_as_string("res://balance.json")),"bots":detailed,"fixed_strategies":fixed,"best_fixed":best,"bargain_counterfactual":{"helped_seeds":helped,"ruined_seeds":ruined,"comparison":"same seeds, steward policy with bargains disabled; changed subsequent visible-state decisions are part of causal outcome"},"checks":checks,"all_pass":passed}
	var file=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify(payload,"",false,true))
	quit()
