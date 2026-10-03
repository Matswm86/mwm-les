extends Node
## Screenshot bot: plays the slice through real InputEventScreenTouch/Drag
## events and saves PNGs to CAPTURE_DIR. Run under Xvfb (studio CLAUDE.md):
##   MWM_LES_FRESH=1 CAPTURE_DIR=/tmp/shots godot --audio-driver Dummy \
##     --display-driver x11 --resolution 1920x1080 res://tests/capture.tscn
## CAPTURE_MODE=hub takes only the opening shots.

var out_dir: String = OS.get_environment("CAPTURE_DIR")
var mode: String = OS.get_environment("CAPTURE_MODE")
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
	main = load("res://scenes/Main.tscn").instantiate() as MainScene
	add_child(main)
	await _until(func() -> bool: return main.mode == MainScene.Mode.HUB, 20.0, "hub")
	await _frames(20)
	await _shot("01_hub_grey")
	if mode == "hub":
		for i in 3:
			main.world.set_zone_now(i, 1.0)
		await _frames(10)
		await _shot("01b_hub_colour")
		_done()
		return
	if mode == "listen":
		await _tap_beacon(0)
		await _until(
			func() -> bool: return (main.activities[0] as HorOgFinn).active, 10.0, "letters"
		)
		await _frames(30)
		await _shot("02_listen_prompt")
		_done()
		return
	if mode != "write" and mode != "bridge":
		await _listen_station()
	if mode != "bridge":
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
	var item_n: int = 0
	while true:
		var ok: bool = await _until(
			func() -> bool: return act.active or main.mode != MainScene.Mode.ACTIVITY,
			25.0,
			"listen item"
		)
		if not ok or main.mode != MainScene.Mode.ACTIVITY:
			break
		await _frames(30)
		if item_n == 0:
			await _shot("02_listen_prompt")
			var wrong: Vector2 = act.letter_screen_pos(false)
			if wrong.x >= 0.0:
				await _tap(wrong)
				await _wait(0.5)
				await _shot("03_listen_wrong_wobble")
				await _until(func() -> bool: return not Voice.is_busy(), 10.0, "voice")
		await _tap(act.letter_screen_pos(true))
		if item_n == 0:
			await _wait(0.25)
			await _shot("04_listen_right_pop")
		item_n += 1
		await _until(func() -> bool: return not act.active, 5.0, "item end")
		await _until(
			func() -> bool: return act.active or main.mode != MainScene.Mode.ACTIVITY, 25.0, "next"
		)
	print("listen station: %d items" % item_n)
	await _wait(1.6)
	await _shot("05_zone_a_restoring")
	await _until(func() -> bool: return main.mode == MainScene.Mode.HUB, 20.0, "hub again")
	await _frames(20)
	await _shot("06_hub_one_zone")


func _write_station() -> void:
	await _tap_beacon(1)
	var act: Sandskriving = main.activities[1] as Sandskriving
	await _until(func() -> bool: return act.phase == Sandskriving.Phase.WATCH, 15.0, "watch")
	await _until(func() -> bool: return act.pad.model_progress > 0.6, 15.0, "model drawing")
	await _shot("07_write_watch_model")
	var first: bool = true
	var letters: int = 0
	while main.mode == MainScene.Mode.ACTIVITY:
		var ok: bool = await _until(
			func() -> bool:
				return (
					(act.phase == Sandskriving.Phase.WRITE and act.active)
					or main.mode != MainScene.Mode.ACTIVITY
				),
			30.0,
			"write phase"
		)
		if not ok or main.mode != MainScene.Mode.ACTIVITY:
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
		var strokes: Array[PackedVector2Array] = act.model_screen_strokes()
		for s: PackedVector2Array in strokes:
			await _drag(s)
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
	await _until(func() -> bool: return main.mode == MainScene.Mode.HUB, 30.0, "hub again")
	await _frames(20)
	await _shot("13_hub_two_zones")


func _bridge_station() -> void:
	await _tap_beacon(2)
	var act: OrdBro = main.activities[2] as OrdBro
	var words: int = 0
	while main.mode == MainScene.Mode.ACTIVITY:
		var ok: bool = await _until(
			func() -> bool: return act.active or main.mode != MainScene.Mode.ACTIVITY,
			30.0,
			"bridge item"
		)
		if not ok or main.mode != MainScene.Mode.ACTIVITY:
			break
		await _until(func() -> bool: return not Voice.is_busy(), 10.0, "prompt")
		if words == 0:
			await _shot("14_bridge_start")
			var wrong: Vector2 = act.stone_screen_pos_for_slot(0, false)
			if wrong.x >= 0.0:
				await _drag_stone(wrong, act.slot_screen_pos(0), "15_bridge_drag_wrong")
				await _wait(0.45)
				await _shot("16_bridge_wrong_wobble")
				await _until(
					func() -> bool: return not act.frozen and not Voice.is_busy(),
					10.0,
					"wrong done"
				)
		for si in act.graphemes.size():
			var from: Vector2 = act.stone_screen_pos_for_slot(si, true)
			await _drag_stone(from, act.slot_screen_pos(si), "")
			await _wait(0.5)
			if words == 0 and si == 1:
				await _shot("17_bridge_two_planks")
		words += 1
		await _wait(1.6)
		if words == 1:
			await _shot("18_bridge_word_done")
		await _until(func() -> bool: return not act.active, 5.0, "bridge end")
		await _wait(5.5)
		if words == 1:
			await _shot("19_bridge_hero_across")
		await _until(
			func() -> bool: return act.active or main.mode != MainScene.Mode.ACTIVITY,
			30.0,
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
