extends SceneTree
const Rules=preload("res://rules.gd")
func _initialize():
	var schedules=[]
	var cfg={}
	for seed_i in range(200):
		var r=Rules.new();r.setup(seed_i)
		schedules.append({"seed":seed_i,"tides":r.tides})
		cfg=r.config
	var dest="res://../schedules.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): dest=a.substr(6)
	var f=FileAccess.open(dest,FileAccess.WRITE)
	f.store_string(JSON.stringify({"config":cfg,"schedules":schedules},"",false,true))
	print("Exported 200 seeded schedules to ",dest)
	quit()
