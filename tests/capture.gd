extends Node
## Screenshot bot: plays the slice through real InputEventScreenTouch/Drag
## events and saves PNGs to CAPTURE_DIR. Run under Xvfb (studio CLAUDE.md):
##   MWM_LES_FRESH=1 CAPTURE_DIR=/tmp/shots godot --audio-driver Dummy \
##     --display-driver x11 --resolution 1920x1080 res://tests/capture.tscn
## CAPTURE_MODE=story|hub stops at the hub; listen|write|bridge stop after
## that station (stations unlock in order, so earlier ones always run).

var out_dir: String = OS.get_environment("CAPTURE_DIR")
var mode: String = OS.get_environment("CAPTURE_MODE")
var start_at: String = OS.get_environment("CAPTURE_START")  # write|bridge: skip earlier stations
var main: MainScene
var _t0: int = 0
var _shots: int = 0


func _ready() -> void:
	if out_dir == "":
		out_dir = "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	_t0 = Time.get_ticks_msec()
	Game.persist = false
	Game.reset_progress()
	if start_at != "":
		Game.story_seen = true
		Game.stations_done[0] = true
		Game.stations_done[1] = start_at == "bridge"
	main = load("res://scenes/Main.tscn").instantiate() as MainScene
	add_child(main)
	if start_at == "":
		await _opening_story()
	await _until(func() -> bool: return main.mode == MainScene.Mode.HUB, 20.0, "hub")
	await _until(func() -> bool: return not Voice.is_busy(), 10.0, "hub line")
	await _frames(20)
	await _shot("01_hub_next_find")
	_report_hub()
	if mode == "story" or mode == "hub":
		_done()
		return
	await _wait(MainScene.HUB_GHOST_AFTER_SEC + 0.8)
	await _shot("01b_hub_ghost_taps_station")
	if start_at == "":
		await _listen_station()
	if mode == "listen":
		_done()
		return
	if start_at != "bridge":
		await _write_station()
	if mode == "write":
		_done()
		return
	await _bridge_station()
	if mode == "bridge":
		_done()
		return
	await _grownup()
	await _parent()
	_done()


func _done() -> void:
	print("CAPTURE DONE: %d shots in %.1fs" % [_shots, (Time.get_ticks_msec() - _t0) / 1000.0])
	get_tree().quit()


func _report_hub() -> void:
	var lit: Array[int] = []
	for i in 3:
		if main.beacons[i].visible:
			lit.append(i)
	print("hub: lit stations %s, Pip on screen at %s" % [lit, main.pip.screen_pos()])


# ---------------------------------------------------------------- story


func _opening_story() -> void:
	await _until(func() -> bool: return main.mode == MainScene.Mode.STORY, 10.0, "story")
	var t: int = Time.get_ticks_msec()
	var marks: Array = [
		[2.5, "00a_story_night_island_sings"],
		[5.8, "00b_story_happy_unicorn"],
		[12.6, "00c_story_hysj_ship_shush"],
		[17.6, "00d_story_sounds_into_jar"],
		[26.2, "00e_story_grey_sad_unicorn"],
		[31.8, "00f_story_morning_pip"],
	]
	for m: Array in marks:
		var at: int = t + int(float(m[0]) * 1000.0)
		while Time.get_ticks_msec() < at:
			await get_tree().process_frame
		print("  story camera distance %.1f" % main.rig.distance)
		await _shot(str(m[1]))
	var story: OpeningStory = main._story
	await _until(func() -> bool: return story.is_waiting_for_pip(), 30.0, "tap Pip")
	await _wait(1.2)
	await _shot("00g_story_tap_pip_ghost")
	await _tap(main.pip.screen_pos())


# ---------------------------------------------------------------- stations


func _tap_beacon(i: int) -> void:
	var b: Beacon = main.beacons[i]
	await _tap(main.rig.cam.unproject_position(b.global_position))
	await _until(
		func() -> bool: return main.mode == MainScene.Mode.ACTIVITY, 10.0, "station %d" % i
	)


func _listen_station() -> void:
	await _tap_beacon(0)
	var act: HorOgFinn = main.activities[0] as HorOgFinn
	await _wait(1.5)
	await _shot("02a_find_story_sleeping_flower")
	var item_n: int = 0
	var intro_n: int = 0
	while true:
		var ok: bool = await _until(
			func() -> bool:
				return (
					act.active
					or act.in_intro()
					or act.flower.awake
					or main.mode != MainScene.Mode.ACTIVITY
				),
			40.0,
			"listen item"
		)
		if not ok or act.flower.awake or main.mode != MainScene.Mode.ACTIVITY:
			break
		if act.in_intro():
			await _until(func() -> bool: return act.active, 20.0, "intro ready")
			await _wait(0.9)
			if intro_n == 0:
				await _shot("02b_find_intro_letter_pair_ghost")
			intro_n += 1
			await _tap(act.intro_screen_pos())
			await _until(func() -> bool: return not act.in_intro(), 10.0, "intro done")
			continue
		await _until(func() -> bool: return not Voice.is_busy(), 10.0, "prompt")
		await _frames(20)
		if item_n == 0:
			await _shot("02_listen_prompt")
			_report_letters(act)
			var wrong: Vector2 = act.letter_screen_pos(false)
			if wrong.x >= 0.0:
				await _tap(wrong)
				await _wait(0.4)
				await _shot("03_listen_wrong_wobble")
				await _until(func() -> bool: return not act.frozen, 12.0, "wrong done")
				await _wait(0.5)
				await _shot("03b_listen_hint_jump_ring")
				await _tap(act.letter_screen_pos(false))
				await _until(func() -> bool: return not act.frozen, 12.0, "wrong 2 done")
				await _wait(1.0)
				await _shot("03c_listen_hint_ghost_hand")
		await _tap(act.letter_screen_pos(true))
		if item_n == 0:
			await _wait(0.2)
			await _shot("04_listen_right_pop")
			await _wait(0.75)
			await _shot("04b_listen_letter_flies_to_pip")
		item_n += 1
		await _until(func() -> bool: return not act.active, 5.0, "item end")
	print("listen station: %d items, %d letter intros" % [item_n, intro_n])
	await _until(func() -> bool: return act.flower.awake, 20.0, "flower wakes")
	await _wait(1.0)
	await _shot("05_find_payoff_flower_awake")
	await _until(func() -> bool: return main.mode == MainScene.Mode.HUB, 30.0, "hub again")
	await _until(func() -> bool: return not Voice.is_busy(), 10.0, "hub line")
	await _frames(20)
	await _shot("06_hub_next_write")
	_report_hub()


func _report_letters(act: HorOgFinn) -> void:
	for gl: GlowLetter in act.letters:
		print(
			(
				"  find letter '%s': %.0f px tall on screen at %s"
				% [gl.letter, gl.glyph_screen_height(main.rig.cam), gl.screen_pos(main.rig.cam)]
			)
		)


func _write_station() -> void:
	await _tap_beacon(1)
	var act: Sandskriving = main.activities[1] as Sandskriving
	await _until(func() -> bool: return act.pad.wash > 0.35, 15.0, "story wave")
	await _shot("07a_write_story_wave")
	await _until(func() -> bool: return act.phase == Sandskriving.Phase.WATCH, 20.0, "watch")
	await _until(func() -> bool: return act.pad.model_progress > 0.55, 15.0, "model drawing")
	await _shot("07_write_watch_model_pen_tip")
	var first: bool = true
	var letters: int = 0
	while main.mode == MainScene.Mode.ACTIVITY:
		var ok: bool = await _until(
			func() -> bool:
				return (
					(act.phase == Sandskriving.Phase.WRITE and act.active)
					or main.unicorn.stripes > 0
					or main.mode != MainScene.Mode.ACTIVITY
				),
			40.0,
			"write phase"
		)
		if not ok or main.unicorn.stripes > 0 or main.mode != MainScene.Mode.ACTIVITY:
			break
		await _until(func() -> bool: return not Voice.is_busy(), 10.0, "prompt")
		if first:
			await _shot("08_write_empty_sand")
			# a scribble that is not the letter: the sand smooths, hint 1 = start dot
			var c: Vector2 = act.pad.box.get_center()
			await _drag([c + Vector2(-200, 120), c + Vector2(200, 120)])
			await _until(
				func() -> bool: return act.phase == Sandskriving.Phase.CHECK, 6.0, "check 1"
			)
			await _until(
				func() -> bool: return act.pad.show_start_dot and act.active, 8.0, "start dot"
			)
			await _until(func() -> bool: return not Voice.is_busy(), 10.0, "after smooth")
			await _shot("09_write_hint_start_dot")
			first = false
		# a sloppy child letter: bigger, shifted and wobbly, not a copy of the model
		var strokes: Array[PackedVector2Array] = act.model_screen_strokes()
		var k: int = 0
		for st: PackedVector2Array in strokes:
			var wob: PackedVector2Array = PackedVector2Array()
			for q: Vector2 in st:
				wob.append(
					q * 1.0 + Vector2(sin(float(k) * 0.7) * 14.0, cos(float(k) * 0.5) * 12.0)
				)
				k += 1
			await _drag(wob)
		await _shot(
			"10_write_child_letter" if letters == 0 else "10b_write_child_letter_%d" % letters
		)
		await _until(func() -> bool: return act.phase == Sandskriving.Phase.CHECK, 6.0, "check")
		await _until(
			func() -> bool:
				return act.pad.compare_alpha > 0.8 or act.phase == Sandskriving.Phase.WRITE,
			8.0,
			"compare"
		)
		if letters == 0:
			await _shot("11_write_compare")
			await _wait(0.9)
			await _shot("12_write_letter_lifts")
		letters += 1
		await _until(
			func() -> bool: return act.phase != Sandskriving.Phase.CHECK, 10.0, "after check"
		)
		await _until(func() -> bool: return not act.active, 6.0, "")
	print("write station: %d letters accepted" % letters)
	await _until(func() -> bool: return main.unicorn.stripes > 0, 30.0, "unicorn stripe")
	await _wait(1.2)
	print("  payoff camera distance %.1f target %s" % [main.rig.distance, main.rig.target])
	await _shot("12b_write_payoff_unicorn_stripe")
	await _until(func() -> bool: return main.mode == MainScene.Mode.HUB, 30.0, "hub again")
	await _until(func() -> bool: return not Voice.is_busy(), 10.0, "hub line")
	await _frames(20)
	await _shot("13_hub_next_bridge")
	_report_hub()


func _report_bridge(act: OrdBro) -> void:
	var widths: Array[String] = []
	for i in act.slots.size():
		widths.append("%.0f" % act.slot_screen_width(i))
	var stone_px: Array[String] = []
	for st: Stone in act.stones:
		if not st.placed:
			stone_px.append("%.0f" % (st.screen_radius(main.rig.cam) * 2.0 / 1.5))
	print(
		(
			"  bridge '%s': slot widths px %s, first empty slot %d, free stones %d (size px %s)"
			% [act.word, widths, act.first_missing(), stone_px.size(), stone_px]
		)
	)
	for n: int in [2, 3, 4, 6]:
		print(
			"  bridge layout for %d letters: narrowest slot %.0f px" % [n, act.min_slot_px_for(n)]
		)


func _bridge_station() -> void:
	await _tap_beacon(2)
	var act: OrdBro = main.activities[2] as OrdBro
	var words: int = 0
	while main.mode == MainScene.Mode.ACTIVITY:
		var ok: bool = await _until(
			func() -> bool: return act.is_modelling() or main.mode != MainScene.Mode.ACTIVITY,
			40.0,
			"bridge model"
		)
		if not ok or main.mode != MainScene.Mode.ACTIVITY:
			break
		if words == 0:
			await _shot("14a_bridge_story_picture_stuck")
		await _until(func() -> bool: return act.lit_slot() == 1, 15.0, "slot 2 lit")
		await _wait(0.25)
		if words == 0:
			await _shot("14b_bridge_pip_sounds_out_slot_glow")
		await _until(func() -> bool: return act.active, 20.0, "bridge item")
		await _until(func() -> bool: return not Voice.is_busy(), 10.0, "prompt")
		_report_bridge(act)
		if words == 0:
			await _shot("14_bridge_one_slot_empty")
			await _wait(1.5)
			await _shot("14c_bridge_ghost_hand_demo")
		if words == 1:
			await _shot("15_bridge_choice_of_two")
			var wrong: Vector2 = act.stone_screen_pos_for_slot(act.first_missing(), false)
			if wrong.x >= 0.0:
				await _drag_stone(
					wrong, act.slot_screen_pos(act.first_missing()), "15b_bridge_drag_wrong"
				)
				await _wait(0.45)
				await _shot("16_bridge_wrong_wobble")
				await _until(
					func() -> bool: return not act.frozen and not Voice.is_busy(),
					25.0,
					"wrong done"
				)
				await _wait(0.4)
				await _shot("16b_bridge_hint_right_stone_glows")
		for si in range(act.first_missing(), act.graphemes.size()):
			var from: Vector2 = act.stone_screen_pos_for_slot(si, true)
			await _drag_stone(from, act.slot_screen_pos(si), "")
			await _wait(0.5)
		words += 1
		await _wait(1.0)
		if words == 1:
			await _shot("17_bridge_word_done")
			await _wait(5.2)
			await _shot("18_bridge_picture_trots_home")
		await _until(func() -> bool: return not act.active and not act.is_modelling(), 5.0, "")
		await _until(
			func() -> bool: return act.is_modelling() or main.mode != MainScene.Mode.ACTIVITY,
			40.0,
			"next word"
		)
	print("bridge station: %d words built" % words)


func _grownup() -> void:
	await _until(func() -> bool: return main.mode == MainScene.Mode.GROWNUP, 40.0, "grown-up card")
	await _frames(20)
	await _shot("20_hub_all_zones_grownup_card")
	var card: GrownupCard = main._overlay as GrownupCard
	var btn: RoundButton = null
	for c: Node in card.get_children():
		if c is RoundButton and (c as RoundButton).hold_sec > 0.0:
			btn = c as RoundButton
	var at: Vector2 = btn.get_global_rect().get_center()
	_touch(at, true)
	await _wait(0.9)
	await _shot("21_grownup_holding")
	await _wait(0.9)
	_touch(at, false)
	await _until(func() -> bool: return main.mode == MainScene.Mode.SUNSET, 20.0, "sunset")
	await _wait(3.2)
	await _shot("22_sunset")
	await _tap(Vector2(960, 540))
	await _until(func() -> bool: return main.mode == MainScene.Mode.HUB, 10.0, "new session")
	await _frames(30)
	await _shot("23_hub_restored")


func _parent() -> void:
	await _tap(main.hud.parent_btn.get_global_rect().get_center())
	await _until(func() -> bool: return main.mode == MainScene.Mode.PARENT, 5.0, "gate")
	await _frames(10)
	await _shot("24_parent_gate")
	var gate: ParentGate = main._overlay as ParentGate
	var hold: Vector2 = Vector2.ZERO
	for c: Node in gate.get_children():
		if c is RoundButton and (c as RoundButton).hold_sec > 0.0:
			hold = (c as RoundButton).get_global_rect().get_center()
	_touch(hold, true)
	await _wait(GameTune.PARENT_HOLD_SEC + 0.3)
	_touch(hold, false)
	await _frames(5)
	var keys: Dictionary = {}
	for c: Node in gate.find_children("*", "RoundButton", true, false):
		var b: RoundButton = c as RoundButton
		if b.text != "":
			keys[b.text] = b.get_global_rect().get_center()
		elif b.icon == RoundButton.Icon.CHECK and b.hold_sec == 0.0:
			keys["OK"] = b.get_global_rect().get_center()
	for ch: String in str(gate.answer()):
		await _tap(keys[ch])
	await _shot("25_parent_gate_sum")
	await _tap(keys["OK"])
	await _frames(10)
	await _shot("26_parent_page")


# ---------------------------------------------------------------- input + util


func _touch(pos: Vector2, pressed: bool) -> void:
	var e: InputEventScreenTouch = InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _tap(pos: Vector2) -> void:
	_touch(pos, true)
	await _frames(3)
	_touch(pos, false)
	await _frames(3)


func _drag(points: PackedVector2Array) -> void:
	if points.is_empty():
		return
	var dense: PackedVector2Array = PackedVector2Array([points[0]])
	for i in range(1, points.size()):
		var a: Vector2 = points[i - 1]
		var b: Vector2 = points[i]
		var n: int = maxi(1, int(a.distance_to(b) / 14.0))
		for k in range(1, n + 1):
			dense.append(a.lerp(b, float(k) / float(n)))
	_touch(dense[0], true)
	await _frames(1)
	var prev: Vector2 = dense[0]
	for p: Vector2 in dense:
		var d: InputEventScreenDrag = InputEventScreenDrag.new()
		d.index = 0
		d.position = p
		d.relative = p - prev
		prev = p
		Input.parse_input_event(d)
		await _frames(1)
	_touch(dense[dense.size() - 1], false)
	await _frames(2)


func _drag_stone(from: Vector2, to: Vector2, mid_shot: String) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for k in 25:
		pts.append(from.lerp(to, float(k) / 24.0))
	_touch(from, true)
	await _frames(2)
	var prev: Vector2 = from
	for i in pts.size():
		var d: InputEventScreenDrag = InputEventScreenDrag.new()
		d.position = pts[i]
		d.relative = pts[i] - prev
		prev = pts[i]
		Input.parse_input_event(d)
		await _frames(1)
		if i == 18 and mid_shot != "":
			await _shot(mid_shot)
	_touch(to, false)
	await _frames(2)


func _until(cond: Callable, timeout_sec: float, what: String) -> bool:
	var start: int = Time.get_ticks_msec()
	while not bool(cond.call()):
		if Time.get_ticks_msec() - start > int(timeout_sec * 1000.0):
			if what != "":  # "" = optional wait, no report
				print("TIMEOUT waiting for %s (mode %d)" % [what, main.mode])
			return false
		await get_tree().process_frame
	return true


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	img.save_png(out_dir.path_join(name + ".png"))
	_shots += 1
	print("shot %s at %.1fs" % [name, (Time.get_ticks_msec() - _t0) / 1000.0])
