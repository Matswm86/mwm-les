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
var _attempts: int = 0  # tries on this pass; the third only has to be near
var _others: Array = []  # stroke models of every other letter (the lenient judge)
var _orient: bool = false


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


## Story: the letter lies in the sand, a wave washes it away. Pip: "Havet
## har vasket bort bokstaven. Skriv den i sanden, så øya husker den!"
func story_intro(first_task: Dictionary) -> void:
	var sk: String = str(first_task.get("skill", ""))
	var strokes: Array[PackedVector2Array] = WriteCheck.strokes_from_json(
		Game.engine.pack.skill(sk).get("strokes", [])
	)
	pad.model = strokes
	pad.model_progress = float(strokes.size())
	await get_tree().create_timer(0.5).timeout
	create_tween().tween_property(pad, "model_alpha", 1.0, 0.4)
	await get_tree().create_timer(1.0).timeout
	var d: float = Voice.say(["story_write"])
	Voice.sfx("whoosh")
	pad.wash = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(pad, "wash", 1.0, 2.2).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(pad, "model_alpha", 0.0, 0.8).set_delay(0.7)
	await tw.finished
	pad.wash = -1.0
	pad.model_progress = 0.0
	await get_tree().create_timer(maxf(d - 2.2, 0.0) + 0.2).timeout


## Payoff: the meadow's unicorn gets one more colour ribbon in its mane.
func story_payoff() -> void:
	create_tween().tween_property(pad, "patch_alpha", 0.0, 0.4)
	var u: Unicorn = main.unicorn
	var at: Vector3 = u.global_position + Vector3(0, 1.1, 0)
	await main.rig.fly_to(at, GameTune.CAM_UNICORN_DISTANCE, 18.0, 0.0, 1.4).finished
	u.gain_stripe()
	Game.unicorn_stripes = u.stripes
	Game.save()
	main.burst(u.global_position + Vector3(0, 2.0, 0))
	Voice.sfx("fanfare")
	await get_tree().create_timer(Voice.say(["payoff_write"]) + 1.0).timeout


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
	_others = other_models(skill)
	_orient = LearnBalance.ORIENT_CHECK_LETTERS.has(Game.label(skill))
	_passes = 2 if Game.engine.model.opportunities(skill) == 0 else 1
	_pass = 0
	_run_pass(true)


## Stroke models of every other letter in the pack: the child's letter must
## look more like the target than like any of them.
static func other_models(target: String) -> Array:
	var out: Array = []
	for sk: Dictionary in Game.engine.pack.skills:
		var sid: String = str(sk.get("id", ""))
		var raw: Array = sk.get("strokes", [])
		if sid != target and not raw.is_empty():
			out.append(WriteCheck.strokes_from_json(raw))
	return out


func _run_pass(with_model: bool) -> void:
	_attempts = 0
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
	await draw_model()
	await get_tree().create_timer(LearnBalance.MODEL_HOLD_SEC).timeout
	var ph: String = Game.phoneme_clip(skill)
	var ex: String = str(Game.engine.pack.skill(skill).get("example_audio", ""))
	await get_tree().create_timer(Voice.say([ph, "som_i", ex])).timeout
	var fade: Tween = create_tween()
	fade.tween_property(pad, "model_alpha", 0.0, LearnBalance.MODEL_FADE_SEC)
	await fade.finished
	main.pip.go_home()


## Pip's pen draws the model stroke by stroke at a calm, even speed (time per
## stroke follows its length); the letter's sound plays while the pen moves.
func draw_model() -> void:
	var ph: String = Game.phoneme_clip(skill)
	pad.model_alpha = 1.0
	pad.model_progress = 0.0
	for si in model.size():
		var one: Array[PackedVector2Array] = [model[si]]
		var sec: float = maxf(
			LearnBalance.MODEL_STROKE_MIN_SEC, WriteCheck.ink_length(one) / LearnBalance.MODEL_SPEED
		)
		var tw: Tween = create_tween()
		tw.tween_method(
			func(v: float) -> void:
				pad.model_progress = v
				if not Voice.sound_playing():
					Voice.sound(ph),
			float(si),
			float(si + 1),
			sec
		)
		await tw.finished
		await get_tree().create_timer(0.25).timeout


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
	_attempts += 1
	var level: int = mini(hints.level, LearnBalance.WRITE_HINT_TRACE)
	var res: Dictionary = WriteCheck.judge(pad.ink, model, _others, level, _orient)
	var ok: bool = bool(res["accepted"])
	var sized: bool = bool(res["letter_sized"])
	if level >= LearnBalance.WRITE_HINT_TRACE and sized:
		ok = ok or float(res["ink_frac"]) >= LearnBalance.WRITE_MIN_INK_FRAC
	# never an endless loop: the third try only has to be near, later any letter lifts
	if _attempts >= LearnBalance.WRITE_NEAR_ATTEMPT and bool(res["near"]):
		ok = true
	if _attempts >= LearnBalance.WRITE_ANY_INK_ATTEMPT and sized:
		ok = true
	Game.engine.log_event(
		{
			"t": "write",
			"skill": skill,
			"ok": ok,
			"hint": level,
			"try": _attempts,
			"mirrored": bool(res["mirrored"]),
			"dist": snappedf(float(res["distance"]), 0.001)
		}
	)
	if ok:
		await _accepted()
	elif bool(res["mirrored"]):
		await _mirrored()
	else:
		await _not_accepted()


## A mirrored letter is not a failure (GDD 6.1): the child's letter stays faint,
## Pip says it turns the other way and writes it again on top, then the child
## tries again with the start point.
func _mirrored() -> void:
	create_tween().tween_property(pad, "ink_alpha", 0.4, 0.3)
	main.pip.point_at(main.world.write_patch + Vector3(1.5, 0.5, 0))
	await get_tree().create_timer(Voice.say(["mirror"]) + 0.2).timeout
	await draw_model()
	await get_tree().create_timer(1.5).timeout
	var tw: Tween = create_tween()
	tw.tween_property(pad, "ink_alpha", 0.0, LearnBalance.WRITE_SMOOTH_SEC)
	tw.parallel().tween_property(pad, "model_alpha", 0.0, LearnBalance.WRITE_SMOOTH_SEC)
	await tw.finished
	main.pip.go_home()
	pad.clear_ink()
	hints.level = maxi(hints.level, LearnBalance.WRITE_HINT_START_DOT)
	hints.highest = maxi(hints.highest, hints.level)
	phase = Phase.WRITE
	_start_write()


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
		var tries: int = _attempts
		await _run_pass(true)
		_attempts = tries
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
