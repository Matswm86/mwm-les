class_name Sandskriving
extends Activity
## Sandskriving, "watch then write" (GDD 0.2, 6.1). Pip writes the letter
## stroke by stroke with its sound, the model fades to empty sand, then the
## child writes it from memory. Lenient shape check, not scored in BKT.
## Hints: 1 dotted start point, 2 Pip writes it again, 3 trace overlay (last).

enum Phase { IDLE, WATCH, WRITE, CHECK, DONE }

var pad: WritePad
var phase: Phase = Phase.IDLE
var skill: String = ""
var model: Array[PackedVector2Array] = []
var _finger_down: bool = false
var _since_up: float = -1.0
var _pass: int = 0
var _passes: int = 1
var _watch_nag_ms: int = 0
var _lifted: GlowLetter


func activity_id() -> String:
	return "skriv"


func scored() -> bool:
	return false


func camera_pose() -> Dictionary:
	return {
		"target": main.world.write_patch + Vector3(0.6, 0, -0.4),
		"distance": GameTune.CAM_WRITE_DISTANCE,
		"pitch": GameTune.CAM_WRITE_PITCH_DEG,
	}


func begin_visit() -> void:
	super.begin_visit()
	if pad == null:
		pad = WritePad.new()
		main.hud.add_overlay(pad)
		main.hud.root.move_child(pad, 0)
	pad.visible = true
	create_tween().tween_property(pad, "patch_alpha", 1.0, 0.5)


func end_visit() -> void:
	super.end_visit()
	phase = Phase.IDLE
	if pad:
		pad.visible = false
		pad.patch_alpha = 0.0
		pad.clear_ink()
		pad.model_alpha = 0.0
	if _lifted:
		_lifted.queue_free()
		_lifted = null


func start_item(p_item: Dictionary, p_format: Dictionary, _hint_start: int) -> void:
	super.start_item(p_item, p_format, 0)
	active = false
	skill = Game.engine.tested_skills(item)[0]
	hints.begin(skill, false)
	hints.level = 0  # pass 1 always starts on empty sand (GDD 6.1)
	hints.highest = 0
	model = WriteCheck.strokes_from_json(Game.engine.pack.skill(skill).get("strokes", []))
	pad.model = model
	_passes = 2 if Game.engine.model.opportunities(skill) == 0 else 1
	_pass = 0
	_run_pass(true)


func _run_pass(with_model: bool) -> void:
	pad.clear_ink()
	pad.show_start_dot = false
	pad.show_trace = false
	if with_model:
		await _watch()
	_start_write()


func _watch() -> void:
	phase = Phase.WATCH
	active = false
	main.pip.point_at(main.world.write_patch + Vector3(1.5, 0.5, 0))
	await get_tree().create_timer(Voice.say(["watch"])).timeout
	var ph: String = Game.phoneme_clip(skill)
	pad.model_alpha = 1.0
	pad.model_progress = 0.0
	for si in model.size():
		Voice.sound(ph)
		var tw: Tween = create_tween()
		tw.tween_property(pad, "model_progress", float(si + 1), LearnBalance.MODEL_STROKE_SEC)
		await tw.finished
	await get_tree().create_timer(LearnBalance.MODEL_HOLD_SEC).timeout
	var ex: String = str(Game.engine.pack.skill(skill).get("example_audio", ""))
	await get_tree().create_timer(Voice.say([ph, "som_i", ex])).timeout
	var fade: Tween = create_tween()
	fade.tween_property(pad, "model_alpha", 0.0, LearnBalance.MODEL_FADE_SEC)
	await fade.finished
	main.pip.go_home()


func _start_write() -> void:
	phase = Phase.WRITE
	pad.show_start_dot = hints.level >= LearnBalance.WRITE_HINT_START_DOT
	pad.show_trace = hints.level >= LearnBalance.WRITE_HINT_TRACE
	var d: float = Voice.say(["your_turn", Game.phoneme_clip(skill)], true)
	mark_prompt_end(d)
	_since_up = -1.0
	active = true
	reset_idle()


func apply_hint(level: int) -> void:
	if phase != Phase.WRITE:
		return
	if level >= LearnBalance.WRITE_HINT_TRACE:
		pad.show_trace = true
		pad.show_start_dot = true
		Voice.repeat_prompt()
	elif level == LearnBalance.WRITE_HINT_REMODEL:
		_run_pass(true)
	elif level >= LearnBalance.WRITE_HINT_START_DOT:
		pad.show_start_dot = true
		Voice.repeat_prompt()


func touch(event: InputEvent) -> void:
	if phase == Phase.WATCH:
		var tw: InputEventScreenTouch = event as InputEventScreenTouch
		if tw and tw.pressed and Time.get_ticks_msec() > _watch_nag_ms:
			_watch_nag_ms = Time.get_ticks_msec() + 4000
			Voice.then(["watch_first"])
		return
	if phase != Phase.WRITE or frozen:
		return
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		if t.pressed and pad.inside(t.position):
			_finger_down = true
			_since_up = -1.0
			pad.begin_stroke(t.position)
			Voice.sound(Game.phoneme_clip(skill))
			reset_idle()
		elif not t.pressed and _finger_down:
			_finger_down = false
			_since_up = 0.0
	elif event is InputEventScreenDrag and _finger_down:
		var dr: InputEventScreenDrag = event as InputEventScreenDrag
		pad.extend_stroke(dr.position)
		if not Voice.sound_playing():
			Voice.sound(Game.phoneme_clip(skill))
		reset_idle()


func _process(delta: float) -> void:
	super._process(delta)
	if phase == Phase.WRITE and _since_up >= 0.0 and not _finger_down:
		_since_up += delta
		if _since_up >= LearnBalance.WRITE_DONE_IDLE_SEC:
			_since_up = -1.0
			_check()


## Also used by the "Ferdig" path and the screenshot bot.
func finish_writing() -> void:
	if phase == Phase.WRITE and not pad.ink.is_empty():
		_since_up = -1.0
		_check()


func _check() -> void:
	phase = Phase.CHECK
	active = false
	var level: int = mini(hints.level, LearnBalance.WRITE_HINT_TRACE)
	var res: Dictionary = WriteCheck.check(pad.ink, model, level)
	var ok: bool = bool(res["accepted"])
	if (
		level >= LearnBalance.WRITE_HINT_TRACE
		and float(res["ink_frac"]) >= LearnBalance.WRITE_MIN_INK_FRAC
	):
		ok = true  # the trace step always ends with the letter lifting out
	Game.engine.log_event(
		{
			"t": "write",
			"skill": skill,
			"ok": ok,
			"hint": level,
			"dist": snappedf(float(res["distance"]), 0.001)
		}
	)
	if ok:
		await _accepted()
	else:
		await _not_accepted()


func _accepted() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(pad, "compare_alpha", 1.0, 0.2)
	tw.parallel().tween_property(pad, "ink_gold", 1.0, 0.2)
	await get_tree().create_timer(LearnBalance.WRITE_COMPARE_SEC).timeout
	var tw2: Tween = create_tween()
	tw2.tween_property(pad, "compare_alpha", 0.0, 0.3)
	tw2.parallel().tween_property(pad, "ink_alpha", 0.0, 0.5)
	tw2.parallel().tween_property(pad, "patch_alpha", 0.0, 0.5)
	pad.show_start_dot = false
	pad.show_trace = false
	_lift_letter()
	var ph: String = Game.phoneme_clip(skill)
	var ex: String = str(Game.engine.pack.skill(skill).get("example_audio", ""))
	Voice.chime()
	main.pip.giggle()
	await get_tree().create_timer(Voice.say([ph, "som_i", ex]) + 0.4).timeout
	_pass += 1
	if _pass < _passes:
		# pass 2: write straight from memory, no model first (GDD 6.1)
		hints.level = 1 if hints.highest >= LearnBalance.WRITE_HINT_REMODEL else 0
		if _lifted:
			_lifted.sink(3.0)
		create_tween().tween_property(pad, "patch_alpha", 1.0, 0.4)
		_run_pass(false)
		return
	phase = Phase.DONE
	await get_tree().create_timer(0.6).timeout
	if _lifted:
		_lifted.sink(3.0)
	create_tween().tween_property(pad, "patch_alpha", 1.0, 0.4)
	item_done.emit()


func _not_accepted() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(pad, "ink_alpha", 0.0, LearnBalance.WRITE_SMOOTH_SEC)
	Voice.sfx("whoosh")
	await tw.finished
	pad.clear_ink()
	var lv: int = mini(hints.on_wrong(), LearnBalance.WRITE_HINT_TRACE)
	hints.level = lv
	phase = Phase.WRITE
	if lv == LearnBalance.WRITE_HINT_REMODEL:
		await get_tree().create_timer(Voice.say(["write_again"])).timeout
		await _run_pass(true)
		pad.show_start_dot = true
		return
	_start_write()


func _lift_letter() -> void:
	if _lifted:
		_lifted.queue_free()
	var p: Vector3 = main.rig.ground_point(pad.ink_bounds().get_center(), main.world.write_patch.y)
	p.y = main.world.write_patch.y
	_lifted = GlowLetter.new()
	_lifted.setup(Game.label(skill), 2.2)
	add_child(_lifted)
	_lifted.global_position = p
	_lifted.set_base_y(p.y)
	_lifted.rotation.y = main.rig.cam.global_rotation.y
	# lean back to face the steep writing camera
	_lifted.rotation.x = -deg_to_rad(GameTune.CAM_WRITE_PITCH_DEG) * 0.8
	_lifted.rise_from(1.6, 0.0)
	main.burst(p + Vector3(0, 0.6, 0))


## For the screenshot bot: the model letter as screen-space strokes.
func model_screen_strokes() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for s: PackedVector2Array in model:
		var pts: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in s:
			pts.append(pad.to_screen(p) + Vector2(-60, 30))
		out.append(pts)
	return out
