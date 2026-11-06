extends Node2D

const Rules = preload("res://rules.gd")
const NAVY = Color("091c2b")
const DEEP = Color("102a3b")
const TEAL = Color("4baea7")
const COPPER = Color("c98d62")
const IVORY = Color("f2e5ca")
const MUTED = Color("9bb7ba")
const RED = Color("e38172")
var rules
var font = ThemeDB.fallback_font
var screen = "title"
var help_open = false
var buttons = []
var pointer = Vector2(-1, -1)
var clock = 0.0
var tide_time = 0.0
var planning_time = 0.0
var incoming = {}
var resolved = false
var notice = "Assign your people. The sea can wait."
var seed_value = 1741
var phone_preview = false
var landscape_phone = false
var landscape_preview = false
var ui_test = false
var autoplay = ""
var capture = false
var shot = ""
var start_turn = 0
var best = 0
var muted = false
var audio_started = false
var ocean_player: AudioStreamPlayer
var bell_player: AudioStreamPlayer
var bell_sound: AudioStreamWAV
var deep_bell: AudioStreamWAV
var bell_timer = 0.0
var sink = 0.0
var submerged_seconds = 0.0
var settled_bell_started = false
var ending_test = false
var scale_factor = 1.0
var offset = Vector2.ZERO
var portrait = false

func _ready():
	randomize()
	seed_value = randi_range(0,99999)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--auto="): autoplay = arg.get_slice("=", 1)
		if arg.begins_with("--seed="): seed_value = int(arg.get_slice("=", 1))
		if arg.begins_with("--start-turn="): start_turn = clampi(int(arg.get_slice("=", 1)), 0, 12)
		if arg.begins_with("--shot="): shot = arg.get_slice("=", 1)
		if arg == "--capture": capture = true
		if arg == "--phone": phone_preview = true
		if arg == "--landscape-phone": landscape_preview = true
		if arg == "--ui-test": ui_test = true
		if arg == "--ending-test": ending_test = true
	rules = Rules.new()
	rules.setup(seed_value)
	if capture or autoplay != "" or shot != "" or start_turn > 0:
		if autoplay == "": autoplay = "steward"
		new_game()
		start_audio()
		if shot == "low" or shot == "bargain":
			if shot == "bargain":
				while not rules.offer and not rules.ended:
					rules.policy("steward");rules.resolve()
			rules.policy("steward")
		elif shot == "tide" or shot == "storm":
			if shot == "storm":
				while int(rules.peek().storm) < 0 and rules.turn < 10 and not rules.ended:
					rules.policy("steward"); rules.resolve()
			rules.policy("steward")
			begin_tide()
			tide_time = 4.4 if shot == "tide" else 5.2

		elif shot == "sink" or shot == "result":
			var guard = 0
			while not rules.ended and guard < 12:
				rules.policy("greedy")
				rules.resolve()
				guard += 1
			screen = "sinking"
			sink = 1.0
			submerged_seconds = 3.0
			if shot == "result":screen="end";submerged_seconds=8.5
			notice = "The bells are still ringing beneath the sea."
	set_process(true)
	if ui_test: call_deferred("run_ui_test")
	if ending_test: call_deferred("run_ending_test")

func new_game():
	help_open=false
	if rules != null: best = maxi(best, survived())
	rules = Rules.new()
	rules.setup(seed_value)
	sink = 0.0
	submerged_seconds = 0.0
	settled_bell_started = false
	planning_time = 0.0
	tide_time = 0.0
	notice = "Assign your people. The sea can wait."
	for i in range(start_turn):
		if rules.ended: break
		rules.policy(autoplay if autoplay != "" else "steward")
		rules.resolve()
	screen = ("end" if rules.won else "sinking") if rules.ended else "plan"
	if autoplay != "" and not rules.ended: rules.policy(autoplay)

func _process(delta):
	clock += delta
	var size = get_viewport_rect().size
	portrait = size.y > size.x or phone_preview
	var physical = DisplayServer.window_get_size()
	landscape_phone = landscape_preview or (not portrait and physical.x < 1000 and physical.y < 650)
	var design = Vector2(430,900) if portrait else Vector2(800,390) if landscape_phone else Vector2(1280,720)
	scale_factor = minf(size.x / design.x, size.y / design.y)
	offset = (size - design * scale_factor) * 0.5
	if shot == "":
		if screen == "plan" and not help_open:
			planning_time += delta
			if autoplay != "" and planning_time >= 2.0: begin_tide()
		elif screen == "tide":
			tide_time += delta
			if tide_time >= 7.2 and not resolved:
				resolved = true
				rules.resolve()
				best = maxi(best, survived())
				var events = rules.last.get("events", [])
				notice = str(events[0]) if events.size() > 0 else "The tide recedes. The city counts its blessings."
				if rules.ended: ring_bell(not rules.won)
			if tide_time >= 8.0:
				screen = ("end" if rules.won else "sinking") if rules.ended else "plan"
				planning_time = 0.0
				if autoplay != "" and not rules.ended: rules.policy(autoplay)
		if screen == "sinking": advance_sinking(delta)
	bell_timer += delta
	var weak = false
	for h in rules.hp:
		if h > 0 and h < 30: weak = true
	if audio_started and bell_timer > (3.5 if screen == "sinking" or (screen == "end" and not rules.won) else 4.5 if weak else 12.0):
		bell_timer = 0.0
		ring_bell(sink > 0.2)
	queue_redraw()

func begin_tide():
	if screen != "plan": return
	screen = "tide"
	tide_time = 0.0
	resolved = false
	incoming = rules.peek()
	notice = "The bronze gate trembles. All hands hold their breath."
	ring_bell(false)

func _unhandled_input(event):
	var pos = Vector2.ZERO
	var activate = false
	if event is InputEventMouseMotion:
		pointer = (event.position - offset) / scale_factor
	if event is InputEventMouseButton:
		if event.device == -1: return
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pos = event.position
			activate = true
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
		activate = true
	if not activate: return
	pointer = (pos - offset) / scale_factor
	for i in range(buttons.size() - 1, -1, -1):
		var b = buttons[i]
		if b["rect"].has_point(pointer):
			if b["enabled"]: action(b["id"])
			break

func action(id):
	match id:
		"start":
			start_audio()
			new_game()
		"restart":
			seed_value += 1
			start_audio()
			new_game()
		"title": screen = "title"
		"help": help_open = true
		"close": help_open = false
		"mute":
			if not audio_started: start_audio()
			muted = not muted
			if audio_started:
				ocean_player.volume_db = -80.0 if muted else -24.0
				bell_player.volume_db = -80.0 if muted else -12.0
		"commit": begin_tide()
		"gate": rules.gate_open = not rules.gate_open
		"bargain": rules.accepted = not rules.accepted
		"hire":
			if rules.hire(): notice = "A new pair of hands joins the city."
		_:
			if str(id).begins_with("job"):
				var parts = str(id).split(":")
				rules.assign(int(parts[1]), int(parts[2]))

func text(at: Vector2, value: String, size: int = 22, color: Color = IVORY):
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(at: Vector2, value: String, size: int, color: Color):
	text(Vector2(at.x - font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5, at.y), value, size, color)

func box(rect: Rect2, color: Color, border: Color = Color.TRANSPARENT):
	draw_rect(rect, color)
	if border.a > 0.0: draw_rect(rect, border, false, 1.0)

func button(rect: Rect2, label: String, id: String, enabled: bool = true, primary: bool = false):
	var hover = rect.has_point(pointer) and enabled
	var fill = Color("1c3d4b")
	if primary: fill = COPPER
	elif hover: fill = Color("2b5760")
	if not enabled: fill = Color("142c3a")
	box(rect, fill, COPPER if primary or hover else Color("42616a"))
	var color = NAVY if primary else IVORY
	if not enabled: color = Color("607a83")
	var label_size=22
	while label_size>18 and font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size).x>rect.size.x-16:
		label_size-=1
	if ui_test:assert(font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size).x<=rect.size.x-12,"Button label clipped: "+label)
	centered(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.5 + 8), label, label_size, color)
	buttons.append({"rect": rect, "id": id, "enabled": enabled})

func _draw():
	buttons.clear()
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), NAVY)
	if screen == "sinking" or (screen == "end" and not rules.won):
		draw_loss_layout()
		return
	if landscape_phone:
		draw_set_transform(offset,0,Vector2(scale_factor,scale_factor))
		draw_landscape_phone()
		return
	if portrait:
		draw_set_transform(offset,0,Vector2(scale_factor,scale_factor))
		draw_phone()
		return
	draw_set_transform(offset, 0, Vector2(scale_factor, scale_factor))
	draw_scene()
	if screen == "title": draw_title()
	else:
		draw_hud()
		draw_controls()
		if screen == "end": draw_end()
	if help_open: draw_help()

func draw_scene():
	# A painted sky, in thin tonal bands, is deliberately quieter than the sea.
	for i in range(48):
		var f = float(i) / 48.0
		box(Rect2(0, 80 + i * 8.5, 1280, 9), Color("101e32").lerp(Color("38616b"), f))
	for i in range(65):
		var x = fmod(i * 139.73 + 25, 1280)
		var y = 96 + fmod(i * 71.13, 168)
		var a = 0.2 + 0.35 * (0.5 + 0.5 * sin(clock * 0.5 + i))
		draw_circle(Vector2(x, y), 1.0 if i % 4 else 1.6, Color(0.85, 0.89, 0.8, a))
	draw_circle(Vector2(198, 167), 35, Color(0.73, 0.85, 0.79, 0.04))
	draw_circle(Vector2(198, 167), 26, Color("d0d9c7"))
	draw_circle(Vector2(210, 159), 23, Color("1b3041"))
	# Remote Breton headlands.
	poly([Vector2(0, 322), Vector2(0, 286), Vector2(82, 270), Vector2(143, 292), Vector2(218, 275), Vector2(344, 322)], Color("233e4d"))
	poly([Vector2(480, 340), Vector2(640, 223), Vector2(745, 245), Vector2(866, 204), Vector2(1012, 223), Vector2(1177, 170), Vector2(1280, 224), Vector2(1280, 466)], Color("284854"))
	var drop = sink * 180.0
	# Terraces and their individual skylines.
	for d in range(3):
		var x = 452.0 + d * 259
		var ground = 430.0 - d * 57 + drop
		box(Rect2(x, ground, 260, 480 - ground + drop), Color("263f47"))
		box(Rect2(x, ground, 260, 7), COPPER.darkened(0.38))
		for row in range(3):
			for k in range(8):
				var bx = x + k * 35 + (17 if row % 2 else 0)
				draw_line(Vector2(bx, ground + 13 + row * 16), Vector2(bx + 27, ground + 13 + row * 16), Color("37515a"), 1)
		for j in range(6):
			var bx = x + 12 + j * 40
			var h = 47.0 + fmod(j * 29.0 + d * 23, 42)
			building(bx, ground, 33, h, j + d * 7, d == 2 and j == 2)
		if d == 0:
			# Quayside cranes, sails and mooring posts.
			draw_line(Vector2(473, ground - 8), Vector2(473, ground - 102), COPPER, 3)
			draw_line(Vector2(473, ground - 99), Vector2(526, ground - 70), COPPER, 2)
			draw_line(Vector2(514, ground - 76), Vector2(514, ground - 40), MUTED, 1)
		var flooded = rules.flooded[d]
		if flooded:
			box(Rect2(x, ground - 28, 259, 110), Color(0.13, 0.43, 0.48, 0.66))
			for j in range(6): draw_line(Vector2(x + j * 41, ground - 23), Vector2(x + j * 41 + 25, ground - 23), TEAL, 1)
		if screen != "title":
			var ly = 275.0 - d * 55
			if screen == "tide" and int(incoming.get("storm",-1))==d:
				draw_arc(Vector2(x+87,ly+8),92,PI,TAU,32,Color(0.9,0.56,0.42,0.6+0.3*sin(clock*5)),2)
			var name_text = ["HARBOUR", "MARKET", "SANCTUARY"][d]
			text(Vector2(x + 8, ly), name_text, 20, IVORY if not flooded else RED)
			box(Rect2(x + 8, ly + 9, 154, 5), Color("112b37"))
			box(Rect2(x + 8, ly + 9, 154 * clampf(float(rules.hp[d]) / 100.0, 0, 1), 5), TEAL if rules.hp[d] >= 30 else RED)
			text(Vector2(x + 172, ly + 17), "%d%%" % rules.hp[d] if not flooded else "LOST", 20, MUTED if not flooded else RED)
	# Ocean height is revealed only once the tide has begun.
	var progress = clampf(tide_time / 8.0, 0, 1) if screen == "tide" else 0.0
	var height = float(incoming.get("height", 3.0))
	var surge = sin(progress * PI * 0.86)
	var level = 374.0 - surge * height * 22.0
	if sink > 0: level = lerpf(level, 80.0, sink)
	box(Rect2(0, level, 425, maxf(0, 480 - level)), Color("0c2b3e"))
	for i in range(35):
		var y = level + i * 7
		if y > 483: break
		box(Rect2(0, y, 425, 8), Color("22636c").lerp(Color("0c2b3e"), minf(float(i) / 27.0, 1.0)))
	for i in range(41):
		var y = level + fmod(i * 17.4, maxf(10, 478 - level))
		var x = fmod(i * 83.7 + clock * (5 + i % 4), 408)
		var length = 15 + fmod(i * 19.7, 67)
		draw_line(Vector2(x, y), Vector2(minf(x + length, 422), y + sin(clock + i) * 1.6), Color(0.42, 0.76, 0.73, 0.14 + 0.13 * sin(i * 2.0)), 1.3)
	for i in range(9):
		var x = 159 + sin(i * 1.8 + clock) * 12
		draw_line(Vector2(x, level + 8 + i * 10), Vector2(x + 54 - i * 4, level + 8 + i * 10), Color(0.8, 0.81, 0.6, 0.16), 2)
	draw_gate(drop, level)
	if screen == "tide":
		for i in range(16):
			var y = level + fmod(i * 23 + clock * 42, maxf(12, 475 - level))
			draw_line(Vector2(376 + sin(i * 2.1) * 12, y), Vector2(393, y - 7), Color(0.64, 0.88, 0.81, surge * 0.55), 1.5)
	if sink > 0:
		box(Rect2(425, level + 34, 855, 450 - level), Color(0.06, 0.27, 0.35, sink * 0.82))
		for i in range(30):
			var x = 435 + fmod(i * 79.3, 845)
			var y = level + 36 + fmod(i * 31.1 + clock * 7, 120)
			draw_line(Vector2(x, y), Vector2(x + 30, y), Color(0.4, 0.75, 0.72, sink * 0.23), 1)
	var storm = screen == "tide" and int(incoming.get("storm", -1)) >= 0
	if storm:
		for i in range(110):
			var x = fmod(i * 59.7 - clock * 155, 1320)
			if x < 0: x += 1320
			var y = 85 + fmod(i * 47.3 + clock * 310, 390)
			draw_line(Vector2(x, y), Vector2(x - 9, y + 19), Color(0.67, 0.81, 0.82, 0.26), 1)
		if sin(clock * 3.5) > 0.96:
			var strike_x=535+int(incoming.get("storm",0))*259
			poly([Vector2(strike_x+20,100),Vector2(strike_x-16,162),Vector2(strike_x+5,160),Vector2(strike_x-35,225),Vector2(strike_x+31,146),Vector2(strike_x+10,147)],Color("d3f4e3"))
			box(Rect2(0, 80, 1280, 400), Color(0.7, 0.9, 0.9, 0.07))
	if sink > 0:
		var submerge = clampf((sink-0.15)/0.85,0,1)
		box(Rect2(0,80,1280,400),Color(0.015,0.16,0.23,submerge*0.70))
		for j in range(22):
			var bx=fmod(j*117.3+sin(clock+j)*9,1280)
			var by=80+fposmod(j*61.1-clock*18,400)
			draw_arc(Vector2(bx,by),2+j%4,0,TAU,12,Color(0.4,0.75,0.75,submerge*0.22),1)
	box(Rect2(0, 477, 1280, 3), COPPER.darkened(0.4))

func poly(points: Array, color: Color):
	draw_colored_polygon(PackedVector2Array(points), color)

func building(x: float, ground: float, w: float, h: float, index: int, church: bool):
	var top = ground - h
	var wall = Color("35515a") if index % 2 else Color("2b454f")
	box(Rect2(x, top, w, h), wall)
	poly([Vector2(x - 4, top), Vector2(x + w * 0.5, top - 21), Vector2(x + w + 4, top)], Color("122c3a"))
	draw_line(Vector2(x - 4, top), Vector2(x + w * 0.5, top - 21), COPPER.darkened(0.35), 1)
	for r in range(2):
		for c in range(2):
			var wx = x + 7 + c * 14
			var wy = top + 10 + r * 22
			box(Rect2(wx, wy, 5, 9), Color("d6b478") if (index + r + c) % 3 else Color("192f3a"))
	box(Rect2(x + w * 0.43, ground - 18, 8, 18), Color("112835"))
	if church:
		box(Rect2(x + 5, top - 51, 23, 56), Color("35535c"))
		poly([Vector2(x, top - 50), Vector2(x + 16, top - 111), Vector2(x + 34, top - 50)], Color("132e3b"))
		draw_line(Vector2(x + 16, top - 123), Vector2(x + 16, top - 99), COPPER, 2)
		draw_line(Vector2(x + 10, top - 116), Vector2(x + 22, top - 116), COPPER, 2)
		draw_circle(Vector2(x + 16, top - 30), 6, COPPER)
		draw_circle(Vector2(x + 16, top - 30), 4, Color("142f3a"))

func draw_gate(drop: float, level: float, show_caption: bool = true):
	var y = 270 + drop * 0.4
	box(Rect2(393, y - 25, 23, 230), Color("263d46"), Color("9b795c"))
	box(Rect2(429, y - 25, 20, 230), Color("263d46"), Color("9b795c"))
	var gy = y + 15 + (58 if rules.gate_open else 0)
	box(Rect2(415, gy, 14, 190), Color("714f3e"), COPPER)
	for j in range(8):
		draw_line(Vector2(416, gy + j * 24), Vector2(428, gy + j * 24), COPPER, 2)
		draw_circle(Vector2(422, gy + 10 + j * 24), 2, Color("e4b47e"))
	for x in [390, 426]:
		poly([Vector2(x, y - 25), Vector2(x + 15, y - 48), Vector2(x + 29, y - 25)], Color("947452"))
	box(Rect2(388, y + 12, 65, 9), Color("d09a66"))
	if rules.gate_open:
		for i in range(5): draw_line(Vector2(423, level + i * 10), Vector2(470, level + 15 + i * 10), Color(0.35, 0.8, 0.76, 0.5), 2)
	if screen != "title" and show_caption:
		text(Vector2(32, 447), "THE BRONZE GATE", 20, COPPER)
		text(Vector2(32, 471), "OPEN / GOLD & DANGER" if rules.gate_open else "SEALED / HOLDING THE SEA", 20, MUTED)

func draw_hud():
	box(Rect2(0, 0, 1280, 80), NAVY)
	text(Vector2(26, 36), "KÊR-IS", 32, IVORY)
	text(Vector2(28, 63), "CITY BELOW THE SEA", 20, COPPER)
	var items = [["STONE", "%d" % rules.stone], ["GRAIN", "%d" % rules.grain], ["GOLD", "%d" % rules.gold]]
	for i in range(3):
		var x = 284 + i * 153
		draw_line(Vector2(x - 20, 20), Vector2(x - 20, 61), Color("36505a"), 1)
		text(Vector2(x, 30), items[i][0], 20, MUTED)
		text(Vector2(x, 62), items[i][1], 30, IVORY)
	text(Vector2(758, 29), "TIDE %02d / 12" % (rules.turn if screen=="end" else mini(rules.turn+1,12)), 21, COPPER)
	var label = ("Ys endures the equinox" if rules.won else "Ys rests below the sea") if screen=="end" else "Forecast  %.1f m" % rules.forecast
	if screen == "tide": label = "Incoming  %.1f m" % float(incoming.get("height", 0))
	text(Vector2(758, 60), label, 21 if screen=="end" else 25, IVORY)
	button(Rect2(1052, 17, 92, 48), "Help", "help")
	button(Rect2(1156, 17, 100, 48), "Muted" if muted else "Sound", "mute")
	if screen == "tide":
		box(Rect2(24, 96, 372, 66), Color(0.03, 0.1, 0.16, 0.9), TEAL)
		text(Vector2(40, 123), "HIGH TIDE  •  HOLD FAST", 22, IVORY)
		text(Vector2(40, 150), "Storm strikes section %d" % (int(incoming.get("storm", -1))+1) if int(incoming.get("storm", -1)) >= 0 else "The Atlantic is rising", 20, MUTED)
		box(Rect2(24, 162, 372 * minf(tide_time / 8, 1), 4), COPPER)
	else:
		text(Vector2(27, 116), "LOW TIDE  /  YOUR TIME TO PLAN" if screen == "plan" else "THE EQUINOX HAS PASSED" if rules.won else "BENEATH THE ATLANTIC", 20, MUTED)

func draw_controls():
	box(Rect2(0, 480, 1280, 240), NAVY)
	var idle = rules.workers - rules.jobs[0] - rules.jobs[1] - rules.jobs[2]
	text(Vector2(24, 510), "YOUR PEOPLE  %d / 12" % rules.workers, 22, IVORY)
	text(Vector2(322, 510), "%d idle" % idle, 22, TEAL)
	var editable = screen == "plan" and not help_open
	var names = ["QUARRY", "FIELDS", "DIKE"]
	var desc = ["Gather stone", "Grow grain", "Mend weakest wall"]
	for i in range(3):
		var x = 24 + i * 204
		box(Rect2(x, 525, 190, 119), Color("122d3c"), Color("2c4b57"))
		text(Vector2(x + 12, 550), names[i], 21, COPPER)
		button(Rect2(x + 10, 564, 50, 50), "−", "job:%d:-1" % i, editable and rules.jobs[i] > 0)
		centered(Vector2(x + 94, 600), str(rules.jobs[i]), 30, IVORY)
		button(Rect2(x + 130, 564, 50, 50), "+", "job:%d:1" % i, editable and idle > 0)
		text(Vector2(x + 10, 637), desc[i], 20, MUTED)
	button(Rect2(648, 528, 220, 50), "Gate: OPEN" if rules.gate_open else "Gate: SEALED", "gate", editable)
	button(Rect2(880, 528, 180, 50), "Hire · 5 gold", "hire", editable and rules.gold >= 5 and rules.workers < 12)
	button(Rect2(648, 590, 412, 54), ("Gift accepted · " + rules.bargain_sign() if rules.accepted else rules.bargain_sign().capitalize()+" voice · +18 stone, +12 grain") if rules.offer else "No stranger at the gate", "bargain", editable and rules.offer)
	button(Rect2(1072, 528, 184, 116), "RAISE THE TIDE" if screen == "plan" else ("HOLD FAST" if screen == "tide" else "TIDE ENDED"), "commit", editable, true)
	text(Vector2(26, 678), notice.left(106), 21, IVORY)
	text(Vector2(26, 706), "Workers eat each tide. Open gates bring gold, but a sea of 4 m or higher enters the city. Forecasts can err.", 20, MUTED)

func draw_title():
	box(Rect2(0, 0, 1280, 720), Color(0.025, 0.07, 0.12, 0.43))
	box(Rect2(45, 71, 584, 586), Color(0.035, 0.1, 0.15, 0.96), Color("63817e"))
	text(Vector2(84, 120), "A BRETON LEGEND • TWELVE TIDES", 20, COPPER)
	text(Vector2(78, 211), "KÊR-IS", 86, IVORY)
	text(Vector2(84, 250), "THE CITY BELOW THE SEA", 26, MUTED)
	draw_line(Vector2(84, 275), Vector2(584, 275), COPPER, 1)
	var lines = ["Ys lies below the sea, behind its dikes.", "Gradlon wears the ship-gate key at his neck.", "Dahut takes it for a mysterious stranger.", "The gate that made Ys rich will drown it.", "", "Keep the walls. Feed your people.", "Decide what richness is worth."]
	for i in range(lines.size()): text(Vector2(84, 313 + i * 29), lines[i], 22, IVORY if i < 4 else MUTED)
	button(Rect2(84, 539, 250, 60), "KEEP THE CITY", "start", true, true)
	button(Rect2(350, 539, 234, 60), "Legend & help", "help")
	text(Vector2(84, 634), "No clock in planning. The sea waits for your hand.", 20, MUTED)
	text(Vector2(900, 683), "FINISTÈRE  /  A CITY OF TIDES", 20, COPPER)

func draw_help():
	buttons.clear()
	box(Rect2(0, 0, 1280, 720), Color(0.02, 0.06, 0.1, 0.88))
	box(Rect2(145, 55, 990, 612), DEEP, COPPER)
	text(Vector2(185, 107), "THE KEY & THE SEA", 34, IVORY)
	text(Vector2(185, 148), "Gradlon holds the key. Dahut hears the stranger. You keep the city.", 24, COPPER)
	var lines = ["Ys is below the sea. Dahut steals Gradlon’s key for a stranger.", "Each worker: QUARRY +4.5 stone; FIELDS +3.5 grain.", "DIKE spends up to 4 stone per worker to repair 18 integrity.", "Each worker eats 1 grain per tide. Unfed workers leave.", "Gold hires workers: 5 per person, up to twelve people.", "Open the bronze gate: +15 gold. At 4 m or higher,", "the lowest district floods: −28% production, more wall pressure.", "Stranger: +18 stone, +12 grain; hidden fractures two tides later.", "Read his voice: warm often means less risk; hollow means more.", "Forecasts can err. Survive twelve tides with a district still standing.", "Plan as long as you need, then raise the tide for eight seconds."]
	for i in range(lines.size()): text(Vector2(185, 198 + i * 35), lines[i], 23, IVORY if i % 2 == 0 else MUTED)
	button(Rect2(825, 591, 270, 52), "Return to the city", "close", true, true)

func draw_end():
	box(Rect2(308, 142, 664, 292), Color(0.025, 0.08, 0.13, 0.95), COPPER)
	centered(Vector2(640, 180), "THE TWELFTH TIDE" if rules.won else "THE SEA REMEMBERS", 22, COPPER)
	centered(Vector2(640, 230), "The city endures." if rules.won else "Kêr-Is is beneath the waves.", 34, IVORY)
	centered(Vector2(640, 271), "A light remains above the water." if rules.won else "Only the bells know the way home.", 23, MUTED)
	centered(Vector2(640, 310), "%d tides held  •  Session best: %d / 12" % [survived(), maxi(best, survived())], 22, IVORY)
	button(Rect2(350, 349, 277, 58), "Keep the city again", "restart", true, true)
	button(Rect2(643, 349, 277, 58), "Return to title", "title")

func make_bell(underwater: bool) -> AudioStreamWAV:
	var rate = 22050
	var count = rate * 4
	var data = PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / rate
		var v = sin(TAU * 196.0 * t) * exp(-t * 1.1) * 0.46
		v += sin(TAU * 392.7 * t) * exp(-t * 1.7) * (0.05 if underwater else 0.23)
		v += sin(TAU * 534.2 * t) * exp(-t * 2.6) * (0.015 if underwater else 0.14)
		v += sin(TAU * 813.4 * t) * exp(-t * 3.6) * (0.0 if underwater else 0.08)
		v *= minf(t * 85, 1.0)
		data.encode_s16(i * 2, int(clampf(v, -1, 1) * 25000))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream

func start_audio():
	if audio_started: return
	audio_started = true
	bell_sound = make_bell(false)
	deep_bell = make_bell(true)
	bell_player = AudioStreamPlayer.new()
	add_child(bell_player)
	bell_player.volume_db = -80.0 if muted else -12.0
	var rate = 22050
	var count = rate * 6
	var data = PackedByteArray()
	data.resize(count * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 97
	var filtered = 0.0
	for i in range(count):
		var t = float(i) / rate
		filtered = filtered * 0.94 + rng.randf_range(-1, 1) * 0.06
		var v = filtered * (0.65 + 0.25 * sin(TAU * t / 6))
		v *= minf(1.0, minf(t * 8, (6.0 - t) * 8))
		data.encode_s16(i * 2, int(v * 29000))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	ocean_player = AudioStreamPlayer.new()
	add_child(ocean_player)
	ocean_player.stream = stream
	ocean_player.volume_db = -80.0 if muted else -24.0
	ocean_player.play()
	ring_bell(false)

func ring_bell(underwater: bool):
	if not audio_started or muted: return
	if capture and underwater:print("BELL_UNDERWATER game_seconds=",clock)
	bell_player.stream = deep_bell if underwater else bell_sound
	bell_player.play()

func survived():
	return rules.turn if not rules.ended or rules.won else maxi(0,rules.turn-1)

# Portrait is a genuine touch layout, not a shrunken desktop or rotate blocker.
# 430×900 logical points: all actionable targets >=48 points tall.
func draw_phone():
	box(Rect2(0,0,430,900),NAVY)
	if screen == "title":
		text(Vector2(24,58),"A BRETON LEGEND",18,COPPER)
		text(Vector2(20,134),"KÊR-IS",70,IVORY)
		text(Vector2(24,174),"THE CITY BELOW THE SEA",22,MUTED)
		draw_set_transform(offset+Vector2(0,200)*scale_factor,0,Vector2(scale_factor*430.0/1280.0,scale_factor*430.0/1280.0))
		draw_scene()
		draw_set_transform(offset,0,Vector2(scale_factor,scale_factor))
		var legend=["Ys lies below the Atlantic.","Gradlon wears the gate key at his neck.","Dahut takes it for a mysterious stranger.","The gate made Ys rich. It will drown it.","", "Keep three districts through twelve tides.","Feed workers. Mend walls. Risk trade."]
		for i in range(legend.size()): text(Vector2(24,426+i*32),legend[i],20,IVORY)
		button(Rect2(24,692,382,62),"KEEP THE CITY","start",true,true)
		button(Rect2(24,770,382,54),"Legend & help","help")
		centered(Vector2(215,870),"No clock during low tide.",20,MUTED)
	else:
		text(Vector2(18,38),"KÊR-IS",30,IVORY)
		text(Vector2(245,35),"TIDE %02d / 12"%(rules.turn if screen=="end" else mini(rules.turn+1,12)),21,COPPER)
		text(Vector2(18,76),"STONE %d    GRAIN %d    GOLD %d"%[rules.stone,rules.grain,rules.gold],23,IVORY)
		text(Vector2(18,109),("Incoming %.1f m"%float(incoming.get("height",0))) if screen=="tide" else "Forecast %.1f m • may err"%rules.forecast,21,MUTED)
		draw_set_transform(offset+Vector2(0,98)*scale_factor,0,Vector2(scale_factor*430.0/1280.0,scale_factor*430.0/1280.0))
		draw_scene()
		draw_set_transform(offset,0,Vector2(scale_factor,scale_factor))
		var idle=rules.workers-rules.jobs[0]-rules.jobs[1]-rules.jobs[2]
		text(Vector2(18,292),"%d people · %d idle"%[rules.workers,idle],20,IVORY)
		text(Vector2(209,292),"H%d  M%d  S%d"%[rules.hp[0],rules.hp[1],rules.hp[2]],19,TEAL)
		var editable=screen=="plan" and not help_open
		for j in range(3):
			var y=310+j*66
			text(Vector2(18,y+34),["QUARRY","FIELDS","DIKE"][j],21,COPPER)
			button(Rect2(187,y,58,54),"−","job:%d:-1"%j,editable and rules.jobs[j]>0)
			centered(Vector2(285,y+37),str(rules.jobs[j]),29,IVORY)
			button(Rect2(344,y,68,54),"+","job:%d:1"%j,editable and idle>0)
		button(Rect2(18,516,192,54),"Gate: OPEN" if rules.gate_open else "Gate: SEALED","gate",editable)
		button(Rect2(222,516,190,54),"Hire · 5 gold","hire",editable and rules.gold>=5 and rules.workers<12)
		button(Rect2(18,584,394,54),("Gift accepted · "+rules.bargain_sign() if rules.accepted else rules.bargain_sign().capitalize()+" voice · +18 S, +12 G") if rules.offer else "No stranger this tide","bargain",editable and rules.offer)
		text(Vector2(18,664),"Warm voice: often safer. Hollow: beware.",18,MUTED)
		button(Rect2(18,686,394,64),"RAISE THE TIDE" if screen=="plan" else "THE ATLANTIC RISES" if screen=="tide" else "THE TIDE HAS ENDED","commit",editable,true)
		text(Vector2(18,785),notice.left(41),19,IVORY)
		text(Vector2(18,812),notice.substr(41,41),19,IVORY)
		button(Rect2(18,838,185,50),"Help","help")
		button(Rect2(217,838,195,50),"Muted" if muted else "Sound","mute")
		if screen=="end":
			buttons.clear()
			box(Rect2(12,240,406,530),DEEP,COPPER)
			centered(Vector2(215,292),"THE CITY ENDURES" if rules.won else "THE SEA REMEMBERS",23,COPPER)
			centered(Vector2(215,350),"A light above the water." if rules.won else "The bells still ring below.",23,IVORY)
			centered(Vector2(215,408),"%d tides held • Best %d / 12"%[survived(),maxi(best,survived())],22,MUTED)
			button(Rect2(36,494,358,62),"Keep the city again","restart",true,true)
			button(Rect2(36,578,358,58),"Return to title","title")
			button(Rect2(36,660,358,54),"Muted" if muted else "Sound","mute")
	if help_open:
		buttons.clear()
		box(Rect2(0,0,430,900),DEEP,COPPER)
		text(Vector2(22,52),"THE KEY & THE SEA",29,IVORY)
		var lines=["Dahut steals Gradlon’s key for a stranger.","The gate that enriched Ys will drown it.","", "Tap + and − to assign your people.","Quarry: +4.5 stone per worker.","Fields: +3.5 grain per worker.","Dike: 4 stone repairs 18 integrity.","Repairs go to the weakest dry wall.","Each worker eats 1 grain per tide.","Unfed people leave. Hire for 5 gold.","", "Open gate: +15 gold from trade.","At 4 m+, the lowest district floods.","Forecasts may be wrong.","Each loss removes 28% production", "and exposes the remaining walls.","", "Gift: +18 stone and +12 grain.","Hidden fractures arrive two tides later.","Warm voice is often safer; hollow is not.","Hold a district through the 12th tide.","Plan freely. Each tide takes 8 seconds."]
		for i in range(lines.size()):text(Vector2(22,98+i*30),lines[i],20,IVORY if i%2==0 else MUTED)
		button(Rect2(22,812,386,62),"Return to the city","close",true,true)

func draw_landscape_phone():
	box(Rect2(0,0,800,390),NAVY)
	draw_set_transform(offset+Vector2(0,28)*scale_factor,0,Vector2(scale_factor*0.625,scale_factor*0.267))
	draw_scene()
	draw_set_transform(offset,0,Vector2(scale_factor,scale_factor))
	if screen=="title":
		box(Rect2(0,0,468,390),Color(0.02,0.07,0.12,0.95),COPPER)
		text(Vector2(22,58),"KÊR-IS",52,IVORY)
		text(Vector2(24,92),"THE CITY BELOW THE SEA",21,COPPER)
		var legend=["Ys lies below the Atlantic, behind its dikes.","Gradlon wears the bronze ship-gate key.","Dahut steals it for a mysterious stranger.","The gate made Ys rich. It will drown it.","Hold three districts through twelve tides."]
		for i in range(legend.size()): text(Vector2(24,137+i*27),legend[i],19,IVORY)
		button(Rect2(24,302,235,60),"KEEP THE CITY","start",true,true)
		button(Rect2(275,302,170,60),"Legend & help","help")
	else:
		box(Rect2(0,0,800,49),NAVY)
		text(Vector2(12,31),"KÊR-IS",24,IVORY)
		text(Vector2(134,30),"S %d   GRAIN %d   GOLD %d"%[rules.stone,rules.grain,rules.gold],21,IVORY)
		text(Vector2(451,30),"T%02d/12  •  %.1f m%s"%[(rules.turn if screen=="end" else mini(rules.turn+1,12)),float(incoming.get("height",0)) if screen=="tide" else rules.forecast,"" if screen=="tide" else " ?"],21,COPPER)
		text(Vector2(668,30),"%d/%d/%d"%[rules.hp[0],rules.hp[1],rules.hp[2]],19,TEAL)
		var editable=screen=="plan" and not help_open
		var idle=rules.workers-rules.jobs[0]-rules.jobs[1]-rules.jobs[2]
		box(Rect2(0,157,800,233),NAVY)
		for j in range(3):
			var x=10+j*262
			text(Vector2(x,183),["QUARRY","FIELDS","DIKE"][j]+"   "+str(rules.jobs[j]),21,COPPER)
			button(Rect2(x+1,194,114,50),"−","job:%d:-1"%j,editable and rules.jobs[j]>0)
			button(Rect2(x+130,194,114,50),"+","job:%d:1"%j,editable and idle>0)
		button(Rect2(10,256,157,53),"Gate: OPEN" if rules.gate_open else "Gate: SEALED","gate",editable)
		button(Rect2(177,256,143,53),"Hire · 5 gold","hire",editable and rules.gold>=5 and rules.workers<12)
		button(Rect2(330,256,224,53),("Accepted · "+rules.bargain_sign() if rules.accepted else rules.bargain_sign().capitalize()+" voice: gift?") if rules.offer else "No stranger","bargain",editable and rules.offer)
		button(Rect2(564,256,226,53),"RAISE THE TIDE" if screen=="plan" else "HOLD FAST","commit",editable,true)
		button(Rect2(10,328,93,50),"Help","help")
		button(Rect2(113,328,111,50),"Muted" if muted else "Sound","mute")
		text(Vector2(238,346),"%d people • %d idle • open gate floods at 4 m+"%[rules.workers,idle],20,MUTED)
		text(Vector2(238,374),notice.left(55),19,IVORY)
		if screen=="end":
			buttons.clear()
			box(Rect2(148,61,504,266),DEEP,COPPER)
			centered(Vector2(400,107),"THE CITY ENDURES" if rules.won else "THE SEA REMEMBERS",25,IVORY)
			centered(Vector2(400,151),"%d tides held • Session best %d / 12"%[survived(),maxi(best,survived())],22,MUTED)
			button(Rect2(170,186,460,55),"Keep the city again","restart",true,true)
			button(Rect2(170,254,460,51),"Return to title","title")
	if help_open:
		buttons.clear()
		box(Rect2(0,0,800,390),DEEP,COPPER)
		text(Vector2(18,40),"THE KEY & THE SEA",27,IVORY)
		var left=["Ys lies below the Atlantic.","Dahut takes Gradlon’s key for a stranger.","Tap + / − to assign workers.","Quarry: +4.5 stone; fields: +3.5 grain.","Dike: 4 stone repairs 18 integrity.","Each worker eats 1 grain per tide.","Unfed people leave. Hire for 5 gold.","Masonry targets the weakest dry wall."]
		var right=["Open gate: +15 gold.","At 4 m+ the lowest district floods.","Forecasts can err. Watch the walls.","Each loss: −28% production, more pressure.","Gift: +18 stone, +12 grain.","Warm voice often safer; hollow costly.","Hidden damage follows two tides later.","Hold a district through tide 12.","No planning clock. Tides take 8 seconds."]
		for i in range(left.size()):
			text(Vector2(18,82+i*28),left[i],18,IVORY)
			text(Vector2(408,82+i*25),right[i],18,MUTED)
		button(Rect2(480,326,300,52),"Return to the city","close",true,true)

func test_wait():
	for _i in range(3): await get_tree().process_frame

func test_tap(id:String):
	await test_wait()
	var target={}
	for b in buttons:
		if b.id==id: target=b
	assert(not target.is_empty(), "UI missing touch target: "+id)
	assert(target.enabled,"UI unexpectedly disabled: "+id)
	var e=InputEventScreenTouch.new()
	e.pressed=true; e.index=0
	e.position=offset+target.rect.get_center()*scale_factor
	_unhandled_input(e)

func run_ui_test():
	autoplay=""; shot=""; start_turn=0
	new_game()
	await test_wait()
	for b in buttons:
		assert(b.rect.size.x>=48 and b.rect.size.y>=48,"touch target smaller than 48 logical points: "+b.id)
		var design=Vector2(430,900) if portrait else Vector2(800,390) if landscape_phone else Vector2(1280,720)
		assert(Rect2(Vector2.ZERO,design).encloses(b.rect),"touch target outside layout: "+b.id)
	await test_tap("job:0:1")
	assert(rules.jobs[0]==1,"touch + must assign one worker")
	await test_tap("job:0:-1")
	assert(rules.jobs[0]==0,"touch − must unassign one worker")
	rules.gold=10
	await test_tap("hire")
	assert(rules.workers==10 and rules.gold==5,"hire expected 10 people / 5 gold")
	await test_tap("gate")
	assert(rules.gate_open,"touch gate must open")
	rules.offer=true
	await test_tap("bargain")
	assert(rules.accepted,"touch bargain must accept")
	assert(rules.visible().bargain_sign==rules.bargain_sign(),"player and steward must receive identical public omen")
	assert(not rules.visible().has("debt_damage") and not rules.visible().has("debt_section"),"exact weakening must remain hidden")
	await test_tap("help")
	assert(help_open,"touch help must open")
	await test_tap("close")
	assert(not help_open,"touch help close must return")
	await test_tap("mute")
	assert(muted,"touch mute must mute")
	await test_tap("mute")
	assert(not muted,"touch sound must unmute")
	await test_tap("commit")
	assert(screen=="tide","touch commit must start tide")
	tide_time=8.0; _process(0.01)
	assert(rules.turn==1,"tide must resolve once")
	rules.ended=true; rules.won=false; rules.turn=5; screen="end"
	var instance=get_instance_id()
	await test_tap("restart")
	assert(screen=="plan" and rules.turn==0,"restart must reset run")
	assert(best==4,"best must exclude losing tide")
	assert(get_instance_id()==instance,"restart must not reload scene")
	rules.ended=true; screen="end"
	await test_tap("title")
	assert(screen=="title","touch title must return")
	await test_tap("start")
	assert(screen=="plan","touch start must begin run")
	print("UI_TEST PASS: all actions via synthetic screen touch; bounds, target size, tide resolve, best and in-scene restart. portrait=",portrait," landscape_phone=",landscape_phone)
	get_tree().quit()

func _exit_tree():
	if audio_started:
		ocean_player.stop()
		bell_player.stop()
		ocean_player.stream=null
		bell_player.stream=null
	bell_sound=null
	deep_bell=null

# The result is gated by two independent conditions: settled camera AND eight
# full seconds of the underwater bell sequence. No planning panel is drawn.
func advance_sinking(delta):
	if sink < 1.0:
		sink = move_toward(sink,1.0,delta*0.16)
		return
	if not settled_bell_started:
		settled_bell_started=true
		if capture: print("ENDING_CAMERA_SETTLED game_seconds=",clock)
		submerged_seconds=0.0
		bell_timer=0.0
		ring_bell(true)
	submerged_seconds+=delta
	if submerged_seconds>=8.0:
		screen="end"
		print("ENDING_SETTLED_BELLS seconds=",submerged_seconds," sink=",sink," game_seconds=",clock)

func draw_sinking_world():
	for row in range(72):
		var f=float(row)/72.0
		box(Rect2(0,row*10,1280,11),Color("245b6b").lerp(Color("143f53"),f))
	# Downward shafts of light keep the drowned architecture readable.
	for j in range(7):
		var rx=80+j*205+sin(clock*0.15+j)*20
		poly([Vector2(rx-15,0),Vector2(rx+16,0),Vector2(rx+180,720),Vector2(rx+42,720)],Color(0.51,0.85,0.78,0.035))
	var descent=(1.0-sink)*-110.0
	for district in range(3):
		var x=452.0+district*259
		var ground=584.0-district*57+descent
		box(Rect2(x,ground,260,720-ground),Color("315d66"))
		box(Rect2(x,ground,260,7),Color("90aaa1"))
		for j in range(6):
			var bx=x+12+j*40
			var h=47.0+fmod(j*29.0+district*23,42)
			draw_circle(Vector2(bx+16,ground-h*0.45),36,Color(0.9,0.74,0.40,0.055))
			building(bx,ground,33,h,j+district*7,district==2 and j==2)
			# Windows stay warm and visibly lit beneath the sea.
			for wr in range(2):
				for wc in range(2):
					var wpos=Vector2(bx+7+wc*14,ground-h+10+wr*22)
					box(Rect2(wpos-Vector2(2,2),Vector2(9,13)),Color(1.0,0.83,0.48,0.14))
					box(Rect2(wpos,Vector2(5,9)),Color("f2d99a"))
		for j in range(5):
			draw_line(Vector2(x,ground+18+j*21),Vector2(x+259,ground+18+j*21),Color(0.48,0.72,0.72,0.18),1)
	draw_gate(85,190,false)
	# A travelling bell halo marks the church, without blackening the city.
	var pulse=fposmod(clock,3.5)/3.5
	draw_arc(Vector2(1090,293+descent),26+pulse*80,0,TAU,64,Color(0.78,0.90,0.76,(1.0-pulse)*0.25),1.5)
	for j in range(58):
		var bx=fposmod(j*117.3+sin(clock*0.4+j)*13,1280)
		var by=fposmod(j*63.8-clock*(12+j%7),720)
		draw_arc(Vector2(bx,by),2+j%4,0,TAU,12,Color(0.66,0.91,0.87,0.25),1)
	for j in range(18):
		var cy=100+j*33+sin(clock*0.6+j)*9
		draw_line(Vector2(fposmod(j*151+clock*7,1280),cy),Vector2(fposmod(j*151+clock*7,1280)+130,cy+4),Color(0.57,0.83,0.77,0.08),1)

func draw_loss_layout():
	var design=Vector2(430,900) if portrait else Vector2(800,390) if landscape_phone else Vector2(1280,720)
	draw_set_transform(offset,0,Vector2(scale_factor,scale_factor))
	box(Rect2(Vector2.ZERO,design),Color("184657"))
	var world_scale=design.x/1280.0
	var world_y=200.0 if portrait else -30.0 if landscape_phone else 0.0
	draw_set_transform(offset+Vector2(0,world_y)*scale_factor,0,Vector2(scale_factor*world_scale,scale_factor*world_scale))
	draw_sinking_world()
	draw_set_transform(offset,0,Vector2(scale_factor,scale_factor))
	text(Vector2(22,40),"KÊR-IS",30,IVORY)
	text(Vector2(22,76),"THE BELLS BENEATH THE SEA",19,COPPER)
	if screen=="sinking":
		var y=600.0 if portrait else 360.0 if landscape_phone else 675.0
		centered(Vector2(design.x*0.5,y),"The city falls silent. The bells do not.",21,IVORY)
	else:
		if portrait:
			box(Rect2(18,563,394,258),Color(0.04,0.16,0.21,0.93),COPPER)
			centered(Vector2(215,603),"THE SEA REMEMBERS",23,COPPER)
			centered(Vector2(215,641),"%d tides held • Best %d / 12"%[survived(),best],21,IVORY)
			button(Rect2(36,666,358,58),"Keep the city again","restart",true,true)
			button(Rect2(36,744,358,54),"Return to title","title")
		elif landscape_phone:
			box(Rect2(16,90,400,227),Color(0.04,0.16,0.21,0.93),COPPER)
			centered(Vector2(216,128),"THE SEA REMEMBERS",23,COPPER)
			centered(Vector2(216,164),"%d tides held • Best %d / 12"%[survived(),best],21,IVORY)
			button(Rect2(34,182,364,54),"Keep the city again","restart",true,true)
			button(Rect2(34,249,364,51),"Return to title","title")
		else: draw_end()
	button(Rect2(design.x-122,18,104,50),"Muted" if muted else "Sound","mute")

func run_ending_test():
	autoplay="";shot="";new_game();start_audio()
	rules.ended=true;rules.won=false;rules.turn=5
	screen="sinking";sink=0.0;submerged_seconds=0.0;settled_bell_started=false
	var elapsed=0.0
	while screen=="sinking" and elapsed<20:
		advance_sinking(0.1);elapsed+=0.1
		if sink<1.0 or submerged_seconds<8.0:
			assert(screen=="sinking","Result appeared before camera and 8-second bell hold")
	assert(screen=="end" and sink==1.0 and submerged_seconds>=8.0,"Ending never settled correctly")
	shot="ending_test"
	screen="sinking";sink=0.5
	await test_wait()
	for b in buttons:
		assert(b.id=="mute","Sinking exposed a planning or result control: "+b.id)
	screen="sinking";sink=1.0;submerged_seconds=7.9
	await test_wait()
	assert(screen=="sinking","Dialog shown early during test rendering")
	print("ENDING_TEST PASS: transition_seconds=",elapsed," underwater_bell_seconds=8.1 panels_hidden=true result_controls_hidden=true")
	get_tree().quit()
