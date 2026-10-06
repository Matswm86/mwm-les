extends Node
## Screenshot bot: plays a first launch through real InputEventScreenTouch /
## InputEventScreenDrag events and saves PNGs to CAPTURE_DIR. Run under Xvfb
## (studio CLAUDE.md):
##   MWM_LES_FRESH=1 CAPTURE_DIR=/tmp/shots godot --audio-driver Dummy \
##     --display-driver x11 --resolution 1920x1080 res://tests/capture.tscn
## Prints every clip Voice starts, tagged with its scene.
## CAPTURE_LEVEL=n starts at word level n (0 = sol, the opening plays; later
## levels skip it, the earlier words' letters count as learned);
## CAPTURE_LEVELS=k plays k levels and stops (default: to the end of the play).
## Shot names start with the level (L1_ = sol ... L6_ = lam).

const SPEED: float = 2.0

var out_dir: String = OS.get_environment("CAPTURE_DIR")
var main: MainScene
var _t0: int = 0
var _shots: int = 0
var _prefix: String = ""


func _ready() -> void:
	if out_dir == "":
		out_dir = "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	_t0 = Time.get_ticks_msec()
	Engine.time_scale = SPEED
	Game.persist = false
	Game.reset_progress()
	Voice.clip_started.connect(
		func(id: String, _f: String, sc: String) -> void:
			print(
				(
					"  clip [%s] %s at %.1fs (game clock %.1fs)"
					% [sc, id, (Time.get_ticks_msec() - _t0) / 1000.0, Voice._clock]
				)
			)
	)
	var start: int = int(OS.get_environment("CAPTURE_LEVEL"))
	var n_env: String = OS.get_environment("CAPTURE_LEVELS")
	var n_levels: int = int(n_env) if n_env != "" else BridgeWords.LEVELS.size() - start
	if start > 0:
		Game.story_seen = true
		Game.level = start
		Game.learned = BridgeWords.learned_before(start)
	main = (load("res://scenes/Main.tscn") as PackedScene).instantiate() as MainScene
	add_child(main)
	(main.stations[2] as OrdBro).step.connect(_on_bridge_step)
	(main.stations[1] as Sandskriving).step.connect(_on_write_step)
	if start == 0:
		await _opening()
	if OS.get_environment("CAPTURE_STOP") == "opening":
		get_tree().quit()
		return
	for k in n_levels:
		_prefix = "L%d_" % (start + k + 1)
		await _hub(0, "05_hub_hook_picture")
		await _find()
		await _hub(1, "")
		await _write()
		await _hub(2, "")
		await _bridge()
	if start + n_levels < BridgeWords.LEVELS.size():
		print("CAPTURE DONE: %d shots in %.1fs" % [_shots, (Time.get_ticks_msec() - _t0) / 1000.0])
		get_tree().quit()
		return
	_prefix = ""
	await _until(func() -> bool: return main.mode == MainScene.Mode.END, 60.0, "end")
	await _wait(0.5)
	await _shot("15_end_goodnight")
	print("VOICE refused %s, sequence errors %d" % [Voice.refused, Voice.sequence_errors])
	print("CAPTURE DONE: %d shots in %.1fs" % [_shots, (Time.get_ticks_msec() - _t0) / 1000.0])
	get_tree().quit()


func _opening() -> void:
	_prefix = "L0_"
	await _until(func() -> bool: return _stage() == "op_1", 20.0, "op_1")
	await _wait(1.2)
	await _shot("01_opening_op1_pip")
	await _until(func() -> bool: return _stage() == "op_2", 20.0, "op_2")
	await _wait(2.0)
	await _shot("02_opening_op2_lamb_on_islet")
	await _until(func() -> bool: return _stage() == "op_3", 20.0, "op_3")
	await _wait(2.0)
	await _shot("03_opening_op3_gap")
	await _until(func() -> bool: return _stage() == "op_4", 20.0, "op_4")
	await _wait(1.6)
	await _shot("03b_opening_op4_letters_over_gap")
	await _until(
		func() -> bool: return main.story != null and main.story.waiting_for_pip, 20.0, "op_5"
	)
	await _wait(0.9)
	await _shot("04_opening_op5_ghost_on_pip")
	await _tap(main.pip.screen_pos())


func _stage() -> String:
	return main.story.stage if main.story else ""


func _hub(i: int, shot: String) -> void:
	await _until(
		func() -> bool: return main.mode == MainScene.Mode.HUB and main._next == i, 60.0, "hub"
	)
	await _until(func() -> bool: return not Voice.is_busy(), 20.0, "hub line")
	await _wait(0.6)
	if shot != "":
		await _shot(shot)
	var b: Beacon = main.beacons[i]
	await _tap(main.rig.cam.unproject_position(b.global_position))
	await _until(func() -> bool: return main.mode == MainScene.Mode.STATION, 20.0, "station")


func _find() -> void:
	var f: HorOgFinn = main.stations[0] as HorOgFinn
	var n: int = 0
	while f.active:
		var ok: bool = await _until(
			func() -> bool: return (not f.busy and not Voice.is_busy()) or not f.active,
			60.0,
			"find item"
		)
		if not ok or not f.active:
			break
		if n == 0:
			await _shot("06_find_tiles_prompt")
			for gl: GlowLetter in f.letters:
				print(
					(
						"  find letter '%s': %.0f px tall at %s"
						% [
							gl.letter,
							gl.glyph_screen_height(main.rig.cam),
							gl.screen_pos(main.rig.cam)
						]
					)
				)
			var wrong: String = ""
			for l: String in f.tile_letters():
				if l != f.target:
					wrong = l
			await _tap(f.letter_screen_pos(wrong))
			await _wait(0.25)
			await _shot("07_find_wrong_answer")
			await _until(func() -> bool: return not f.busy and not Voice.is_busy(), 30.0, "wrong")
		var items: int = f.items_done
		await _tap(f.letter_screen_pos(f.target))
		if n == 0:
			await _wait(0.2)
			await _shot("08_find_right_answer")
		await _until(func() -> bool: return f.items_done > items, 10.0, "right")
		await _until(func() -> bool: return f.busy and Voice.is_busy() or not f.active, 5.0, "")
		await _until(func() -> bool: return not Voice.is_busy() or not f.active, 10.0, "")
		n += 1


func _write() -> void:
	var w: Sandskriving = main.stations[1] as Sandskriving
	var first: bool = true
	var modelled: Array[String] = []
	var traced: Array[String] = []
	while w.active:
		var ok: bool = await _until(
			func() -> bool:
				return (
					(
						w.phase == Sandskriving.Phase.WATCH
						and w.pad.model_progress >= float(w.model.size()) - 0.02
					)
					or (w.phase == Sandskriving.Phase.WRITE and not Voice.is_busy())
					or (w.phase == Sandskriving.Phase.TRACE and not traced.has(w.letter))
					or not w.active
				),
			60.0,
			"write"
		)
		if not ok or not w.active:
			break
		if w.phase == Sandskriving.Phase.WATCH:
			var key: String = "%s_%d" % [w.letter, w.shows]
			if not modelled.has(key):
				modelled.append(key)
				await _shot("09_write_model_%s_show%d" % [LetterRules.glyph(w.letter), w.shows])
			await _until(
				func() -> bool:
					return w.pad.model_progress < 0.5 or w.phase != Sandskriving.Phase.WATCH,
				30.0,
				""
			)
			continue
		if w.phase == Sandskriving.Phase.TRACE:
			traced.append(w.letter)
			await _until(func() -> bool: return not Voice.is_busy(), 20.0, "trace line")
			await _shot("09t_write_trace_stripes_%s" % LetterRules.glyph(w.letter))
			for st: PackedVector2Array in w.model_screen_strokes():
				await _drag(st)
			await _shot("09u_write_trace_followed_%s" % LetterRules.glyph(w.letter))
			await _until(func() -> bool: return w.traced, 20.0, "traced")
			continue
		var count: int = w.written.size()
		for st: PackedVector2Array in w.model_screen_strokes():
			var wob: PackedVector2Array = PackedVector2Array()
			var k: int = 0
			for q: Vector2 in st:
				wob.append(q + Vector2(sin(float(k) * 0.7) * 12.0, cos(float(k) * 0.5) * 10.0))
				k += 1
			await _drag(wob)
		if first:
			await _shot("10_write_child_letter")
			await _until(func() -> bool: return w.pad.compare_alpha > 0.8, 20.0, "compare")
			await _until(func() -> bool: return w.lifted != null, 20.0, "lift")
			await _wait(0.8)
			await _shot("11_write_accepted_stone")
			await _until(func() -> bool: return w.rolling, 20.0, "roll")
			await _wait(0.35)
			await _shot("11b_write_stone_rolls_to_bridge")
		await _until(func() -> bool: return w.written.size() > count, 30.0, "stone")
		first = false


func _on_write_step(name: String) -> void:
	var w: Sandskriving = main.stations[1] as Sandskriving
	if name == "alone":
		await _wait(0.6)
		await _shot("09w_write_alone_%s" % LetterRules.glyph(w.letter))


## Shots at the bridge's named moments (runs beside _bridge, which lays the stones).
func _on_bridge_step(name: String) -> void:
	var br: OrdBro = main.stations[2] as OrdBro
	var word: String = str(br.words[br.word_i]["id"]) if br.word_i >= 0 else ""
	if name == "hook":
		await _wait(1.0)
		await _shot("12a_hook_%d_%s" % [br.word_i, word])
	elif br.word_i >= 0 and name == "lit_%d" % (br.word_start[br.word_i] + 1):
		await _wait(0.15)
		await _shot("12b_planks_light_%s" % word)
	elif name == "word_done":
		await _wait(0.5)
		await _shot("12e_word_done_%s" % word)
	elif name == "next":
		await _wait(1.0)
		await _shot("12f_bridge_next_after_%s" % word)


func _bridge() -> void:
	var br: OrdBro = main.stations[2] as OrdBro
	var n: int = 0
	while true:
		var ok: bool = await _until(
			func() -> bool:
				return (
					(not br.busy and br.cur >= 0 and not Voice.is_busy())
					or br.lit == -2
					or br.cur == -1 and br.missing.size() == n and n > 0
					or not br.active
				),
			90.0,
			"ask"
		)
		if not ok or br.lit == -2 or not br.active or (br.cur == -1 and n > 0):
			break
		var want: String = br.graphemes[br.cur]
		await _shot("12c_bridge_ask_%d_%s" % [n, LetterRules.glyph(want)])
		var st: Stone = br.stone_for(want)
		await _drag_stone(
			st.screen_pos(main.rig.cam),
			br.slot_screen_pos(br.cur),
			"12d_bridge_drag_%d_%s" % [n, LetterRules.glyph(want)]
		)
		await _until(func() -> bool: return br.busy, 5.0, "drop")
		n += 1
	if str(br.words[0]["id"]) != BridgeWords.LAST:
		await _until(func() -> bool: return not br.active, 60.0, "level done")
		return
	await _until(func() -> bool: return br.lit == -2, 40.0, "bridge done")
	await _wait(0.6)
	await _shot("12g_bridge_done_all_lit")
	await _until(func() -> bool: return br.walking, 40.0, "walk")
	await _wait(0.9)
	await _shot("13_bridge_lamb_crossing")
	await _wait(0.9)
	await _shot("13b_bridge_lamb_crossing_later")
	await _until(func() -> bool: return not br.walking, 20.0, "")
	await _wait(0.3)
	await _shot("14_bridge_lamb_home")


# ---------------------------------------------------------------- input and shots


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
	_touch(from, true)
	await _frames(2)
	var prev: Vector2 = from
	for i in 25:
		var p: Vector2 = from.lerp(to, float(i) / 24.0)
		var d: InputEventScreenDrag = InputEventScreenDrag.new()
		d.position = p
		d.relative = p - prev
		prev = p
		Input.parse_input_event(d)
		await _frames(1)
		if i == 16 and mid_shot != "":
			await _shot(mid_shot)
	_touch(to, false)
	await _frames(2)


func _until(cond: Callable, timeout_sec: float, what: String) -> bool:
	var start: int = Time.get_ticks_msec()
	while not bool(cond.call()):
		if Time.get_ticks_msec() - start > int(timeout_sec * 1000.0):
			if what != "":
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
	img.save_png(out_dir.path_join(_prefix + name + ".png"))
	_shots += 1
	print("shot %s at %.1fs" % [name, (Time.get_ticks_msec() - _t0) / 1000.0])
