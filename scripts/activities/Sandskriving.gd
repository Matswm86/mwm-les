class_name Sandskriving
extends Activity
## Sandskriving, "watch then write" (GDD 0.2, 6.1, docs/SCRIPT.md scene 3).
## Pip writes the letter stroke by stroke with its held sound, the model fades
## to empty sand, then the child writes it from memory. Lenient shape check,
## not scored in BKT. An accepted letter lifts out of the sand as a letter
## stone and rolls off to the bridge; at the end of the visit the stones lie
## ready by the bridge. Hints: 1 dotted start point, 2 Pip writes it again,
## 3 trace overlay (last).

enum Phase { IDLE, WATCH, WRITE, CHECK, DONE }

var pad: WritePad
var phase: Phase = Phase.IDLE
var skill: String = ""
var model: Array[PackedVector2Array] = []
var rolling: bool = false  # a stone is rolling to the bridge (screenshot bot)
var payoff_shown: bool = false  # the stones by the bridge are on screen (screenshot bot)
var _finger_down: bool = false
var _since_up: float = -1.0
var _pass: int = 0
var _passes: int = 1
var _watch_nag_ms: int = 0
var _lifted: Stone
var _pile: Array[Stone] = []  # letter stones by the bridge (this session)
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


## Every visit (write_in_1-4): writing makes letter stones for the bridge.
func story_intro(_first_task: Dictionary) -> void:
	var ids: Array = ["write_in_1", "write_in_2", "write_in_3", "write_in_4"]
	var d: float = Voice.say(ids)
	await get_tree().create_timer(Voice.offset_of(ids, 3)).timeout
	main.pip.point_toward(main.world.bridge_start + Vector3(0, 1.0, 0))
	await get_tree().create_timer(d - Voice.offset_of(ids, 3) + 0.2).timeout
	main.pip.go_home()


## Payoff: the stones written this visit lie ready by the bridge frame.
func story_payoff() -> void:
	create_tween().tween_property(pad, "patch_alpha", 0.0, 0.4)
	var at: Vector3 = _pile_center()
	await (
		main
		. rig
		. fly_to(at + Vector3(0, 0.6, 0), GameTune.CAM_PILE_DISTANCE, 30.0, 0.0, 1.4)
		. finished
	)
	payoff_shown = true
	for st: Stone in _pile:
		st.glyph.pop()
	main.burst(at + Vector3(0, 1.0, 0))
	Voice.sfx("fanfare")
	await get_tree().create_timer(Voice.say(["write_payoff"]) + 0.8).timeout


func end_visit() -> void:
	super.end_visit()
	phase = Phase.IDLE
	if pad:
		pad.visible = false
		pad.patch_alpha = 0.0
		pad.clear_ink()
		pad.model_alpha = 0.0
	if _lifted and not _pile.has(_lifted):
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


## Pass 1 watches the model first (with the link line); pass 2 writes from
## memory (write_again_2).
func _run_pass(with_model: bool) -> void:
	_attempts = 0
	pad.clear_ink()
	pad.show_start_dot = false
	pad.show_trace = false
	if with_model:
		await _watch(true)
		_start_write(["write_turn_1"] + _turn_prompt())
	else:
		_start_write(["write_again_2"])


## "Skriv bokstaven som sier [x]": the prompt replayed on Pip tap and idle.
func _turn_prompt() -> Array:
	return ["write_turn_2", Game.phoneme_clip(skill)]


## write_watch, then the model with its held sound. With `link`: one more
## [x] on its own, then "Sol begynner med den lyden." as a separate line.
func _watch(link: bool) -> void:
	phase = Phase.WATCH
	active = false
	main.pip.point_at(main.world.write_patch + Vector3(1.5, 0.5, 0))
	await get_tree().create_timer(Voice.say(["write_watch"])).timeout
	await draw_model()
	await get_tree().create_timer(LearnBalance.MODEL_HOLD_SEC).timeout
	if link:
		await get_tree().create_timer(Voice.sound(Game.phoneme_clip(skill)) + 0.35).timeout
		await get_tree().create_timer(Voice.say([Game.sound_clip(skill, "link")])).timeout
	var fade: Tween = create_tween()
	fade.tween_property(pad, "model_alpha", 0.0, LearnBalance.MODEL_FADE_SEC)
	await fade.finished
	main.pip.go_home()


## Pip's pen draws the model stroke by stroke at a calm, even speed (time per
## stroke follows its length); the held sound plays while the pen moves.
func draw_model() -> void:
	var ph: String = Game.sound_clip(skill, "hold")
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


## Empty sand, the child's turn. `ids` is what Pip says now; the replayable
## prompt is always write_turn_2 + [x] (write_again_2 on pass 2).
func _start_write(ids: Array) -> void:
	phase = Phase.WRITE
	pad.show_start_dot = hints.level >= LearnBalance.WRITE_HINT_START_DOT
	pad.show_trace = hints.level >= LearnBalance.WRITE_HINT_TRACE
	var d: float = Voice.say(ids)
	Voice.set_prompt(["write_again_2"] if ids == ["write_again_2"] else _turn_prompt())
	mark_prompt_end(d)
	_since_up = -1.0
	active = true
	reset_idle()


## One line per hint level (SCRIPT.md 3): 1 "Begynn ved prikken.", 2 "Se en
## gang til." + Pip writes it again + write_turn_2, 3 "Følg prikkene med
## fingeren."
func apply_hint(level: int) -> void:
	if phase != Phase.WRITE:
		return
	if level >= LearnBalance.WRITE_HINT_TRACE:
		pad.show_trace = true
		pad.show_start_dot = true
		mark_prompt_end(Voice.say(["write_hint_3"]))
	elif level == LearnBalance.WRITE_HINT_REMODEL:
		_remodel()
	elif level >= LearnBalance.WRITE_HINT_START_DOT:
		pad.show_start_dot = true
		mark_prompt_end(Voice.say(["write_hint_1"]))


## Hint 2: "Se en gang til.", the model again (no link line), then the turn.
func _remodel() -> void:
	var tries: int = _attempts
	pad.clear_ink()
	await get_tree().create_timer(Voice.say(["write_hint_2"])).timeout
	await _watch(false)
	_attempts = tries
	pad.show_start_dot = true
	_start_write(_turn_prompt())


func touch(event: InputEvent) -> void:
	if phase == Phase.WATCH:
		var tw: InputEventScreenTouch = event as InputEventScreenTouch
		if tw and tw.pressed and Time.get_ticks_msec() > _watch_nag_ms:
			_watch_nag_ms = Time.get_ticks_msec() + 4000
			Voice.then(["write_wait"])
		return
	if phase != Phase.WRITE or frozen:
		return
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		if t.pressed and pad.inside(t.position):
			_finger_down = true
			_since_up = -1.0
			pad.begin_stroke(t.position)
			Voice.sound(Game.sound_clip(skill, "hold"))
			reset_idle()
		elif not t.pressed and _finger_down:
			_finger_down = false
			_since_up = 0.0
	elif event is InputEventScreenDrag and _finger_down:
		var dr: InputEventScreenDrag = event as InputEventScreenDrag
		pad.extend_stroke(dr.position)
		if not Voice.sound_playing():
			Voice.sound(Game.sound_clip(skill, "hold"))
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
## Pip says it turns the other way, writes it again on top (write_watch +
## model), then the child tries again with the start point (write_hint_1).
func _mirrored() -> void:
	create_tween().tween_property(pad, "ink_alpha", 0.4, 0.3)
	main.pip.point_at(main.world.write_patch + Vector3(1.5, 0.5, 0))
	await get_tree().create_timer(Voice.say(["write_mirror"]) + 0.2).timeout
	await get_tree().create_timer(Voice.say(["write_watch"])).timeout
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
	_start_write(["write_hint_1"])


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
	_lift_stone()
	var ph: String = Game.phoneme_clip(skill)
	Voice.chime()
	# the stone says its sound, then Pip says what the child did
	await get_tree().create_timer(Voice.sound(ph) + 0.35).timeout
	main.pip.giggle()
	await get_tree().create_timer(Voice.say(["write_right", ph]) + 0.3).timeout
	await _roll_to_bridge(_lifted)
	_pass += 1
	if _pass < _passes:
		# pass 2: write straight from memory, no model first (GDD 6.1)
		hints.level = 1 if hints.highest >= LearnBalance.WRITE_HINT_REMODEL else 0
		create_tween().tween_property(pad, "patch_alpha", 1.0, 0.4)
		_run_pass(false)
		return
	phase = Phase.DONE
	await get_tree().create_timer(0.3).timeout
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
	# one calm line: "Prøv en gang til." (R10), then the hint for the new level
	await get_tree().create_timer(Voice.say(["write_retry"]) + 0.2).timeout
	if lv == LearnBalance.WRITE_HINT_REMODEL:
		await _remodel()
		return
	var ids: Array = _turn_prompt()
	if lv >= LearnBalance.WRITE_HINT_TRACE:
		ids = ["write_hint_3"]
	elif lv >= LearnBalance.WRITE_HINT_START_DOT:
		ids = ["write_hint_1"]
	_start_write(ids)


## The child's letter lifts out of the sand as a letter stone.
func _lift_stone() -> void:
	if _lifted and not _pile.has(_lifted):
		_lifted.queue_free()
	var p: Vector3 = main.rig.ground_point(pad.ink_bounds().get_center(), main.world.write_patch.y)
	p.y = main.world.write_patch.y
	_lifted = Stone.new()
	_lifted.setup(Game.label(skill), skill)
	add_child(_lifted)
	_lifted.scale = Vector3.ONE * GameTune.WRITE_STONE_SCALE
	_lifted.global_position = p - Vector3(0, 1.0, 0)
	_lifted.rotation.y = main.rig.cam.global_rotation.y
	_lifted.home = p
	(
		create_tween()
		. tween_property(_lifted, "global_position", p, 0.5)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	main.burst(p + Vector3(0, 0.6, 0))


## The stone rolls off toward the bridge and joins the pile there.
func _roll_to_bridge(st: Stone) -> void:
	if st == null:
		return
	var from: Vector3 = st.global_position
	var dir: Vector3 = main.world.bridge_start - from
	dir.y = 0.0
	dir = dir.normalized()
	var to: Vector3 = from + dir * GameTune.WRITE_STONE_ROLL_M
	var axis: Vector3 = Vector3.UP.cross(dir).normalized()
	var b0: Basis = st.global_basis
	Voice.sfx("whoosh")
	rolling = true
	var tw: Tween = create_tween()
	tw.tween_method(
		func(k: float) -> void:
			var q: Vector3 = from.lerp(to, k)
			q.y = main.world.ground_y(q) + absf(sin(k * PI * 4.0)) * 0.25
			st.global_position = q
			st.global_basis = Basis(axis, k * TAU * 2.0) * b0,
		0.0,
		1.0,
		1.3
	)
	await tw.finished
	rolling = false
	_pile.append(st)
	var k: int = _pile.size() - 1
	var spot: Vector3 = (
		_pile_center() + Vector3(1.4 * float(k % 3) - 1.4, 0, 1.25 * floorf(float(k) / 3.0))
	)
	spot = main.world.on_ground(spot.x, spot.z)
	st.global_basis = Basis()
	st.scale = Vector3.ONE * GameTune.PILE_STONE_SCALE
	st.global_position = spot
	st.home = spot


func _pile_center() -> Vector3:
	var b: Vector3 = main.world.bridge_start
	var d: Vector3 = (main.world.bridge_end - b).normalized()
	var p: Vector3 = b - d * 1.6 + Vector3(-d.z, 0, d.x) * 1.5
	return main.world.on_ground(p.x, p.z)


## For the screenshot bot: the model letter as screen-space strokes.
func model_screen_strokes() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for s: PackedVector2Array in model:
		var pts: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in s:
			pts.append(pad.to_screen(p) + Vector2(-60, 30))
		out.append(pts)
	return out
