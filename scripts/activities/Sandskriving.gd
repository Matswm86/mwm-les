class_name Sandskriving
extends Activity
## Sandskriving, "watch then write". The child writes the letters that become
## the bridge stones this session (Main.plan(), every one is used on the
## bridge). For a letter's first time Pip's pen draws the model while the
## letter's held sound plays, the model fades, the child writes it with a
## finger. The same letter again right after: write_again and its held sound,
## then the child writes it from memory (no model). Lenient check (WriteCheck.judge; the third
## try only has to be near, the fourth any letter-sized ink). An accepted
## letter lifts out of the sand as a stone and rolls off toward the bridge.
## Sound: write_in (first letter) or write_next (a new letter after one),
## [held sound while drawing], write_turn; a repeat: write_again + held sound.
## write_retry on a miss, write_right when accepted, write_done at the end.

signal ink_done

enum Phase { IDLE, WATCH, WRITE, CHECK, DONE }

var pad: WritePad
var phase: Phase = Phase.IDLE
var letter: String = ""
var model: Array[PackedVector2Array] = []
var to_write: Array[String] = []
var written: Array[String] = []
var attempts: int = 0
var from_memory: bool = false  # this letter was written before today: no model
var rolling: bool = false  # a stone is rolling to the bridge (screenshot bot)
var lifted: Stone
var _others: Array = []
var _finger_down: bool = false
var _since_up: float = -1.0


func activity_id() -> String:
	return "skriv"


func hub_line() -> String:
	return "hub_write"


func camera_pose() -> Dictionary:
	return {
		"target": main.world.write_patch + Vector3(0.6, 0, -0.4),
		"distance": GameTune.CAM_WRITE_DISTANCE,
		"pitch": GameTune.CAM_WRITE_PITCH_DEG,
	}


func begin() -> void:
	super.begin()
	if pad == null:
		pad = WritePad.new()
		main.hud.add_overlay(pad)
		main.hud.root.move_child(pad, 0)
	pad.visible = true
	pad.clear_ink()
	pad.model_alpha = 0.0
	create_tween().tween_property(pad, "patch_alpha", 1.0, 0.5)
	to_write = main.plan()["stones"]
	written.clear()


func run() -> void:
	active = true
	for i in to_write.size():
		await _write_one(to_write[i], i == 0, to_write.slice(0, i).has(to_write[i]))
	phase = Phase.DONE
	create_tween().tween_property(pad, "patch_alpha", 0.0, 0.4)
	_mark("done")
	await say_wait(["write_done"], 0.3)
	active = false


func end() -> void:
	super.end()
	phase = Phase.IDLE
	if pad:
		pad.visible = false
		pad.patch_alpha = 0.0
		pad.clear_ink()
		pad.model_alpha = 0.0
		pad.show_start_dot = false
		pad.show_trace = false


func _write_one(l: String, first: bool, again: bool) -> void:
	letter = l
	var sk: String = Game.skill_for_label(l)
	model = WriteCheck.strokes_from_json(Game.engine.pack.skill(sk).get("strokes", []))
	pad.model = model
	_others = other_models(sk)
	attempts = 0
	from_memory = again
	pad.clear_ink()
	pad.show_start_dot = false
	pad.show_trace = false
	create_tween().tween_property(pad, "patch_alpha", 1.0, 0.3)
	if first:
		_mark("in")
		await say_wait(["write_in"], 0.2)
	if again:
		phase = Phase.WATCH
		_mark("again")
		await say_wait(["write_again", Voice.held_id(l)], 0.2)
	else:
		if not first:
			_mark("next")
			await say_wait(["write_next"], 0.2)
		await _watch()
	while true:
		_start_write(attempts == 0 and not again)
		await ink_done
		phase = Phase.CHECK
		attempts += 1
		if _judge():
			break
		await _retry()
	await _accepted()


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


## Pip points at the sand; the pen draws the model in time with the held sound.
func _watch() -> void:
	phase = Phase.WATCH
	main.pip.point_at(main.world.write_patch + Vector3(1.5, 0.5, 0))
	_mark("model")
	await draw_model()
	await wait(LearnBalance.MODEL_HOLD_SEC)
	var fade: Tween = create_tween()
	fade.tween_property(pad, "model_alpha", 0.0, LearnBalance.MODEL_FADE_SEC)
	await fade.finished
	main.pip.go_home()


## The pen draws every stroke; the whole model takes as long as the held
## sound (time per stroke follows its length).
func draw_model() -> void:
	var held: String = Voice.held_id(letter)
	var total: float = maxf(Voice.length(held), 1.4)
	var lens: Array[float] = []
	var sum: float = 0.0
	for s: PackedVector2Array in model:
		var one: Array[PackedVector2Array] = [s]
		var len_s: float = maxf(WriteCheck.ink_length(one), 0.05)
		lens.append(len_s)
		sum += len_s
	pad.model_alpha = 1.0
	pad.model_progress = 0.0
	Voice.say([held])
	for si in model.size():
		var sec: float = maxf(0.35, total * lens[si] / sum)
		var tw: Tween = create_tween()
		tw.tween_property(pad, "model_progress", float(si + 1), sec).from(float(si))
		await tw.finished


func _start_write(first_try: bool) -> void:
	phase = Phase.WRITE
	pad.clear_ink()
	pad.ink_alpha = 1.0
	if first_try:
		Voice.say(["write_turn"])
	_since_up = -1.0
	_mark("turn")


func touch(event: InputEvent) -> void:
	if phase != Phase.WRITE:
		return
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		if t.pressed and pad.inside(t.position):
			_finger_down = true
			_since_up = -1.0
			pad.begin_stroke(t.position)
		elif not t.pressed and _finger_down:
			_finger_down = false
			_since_up = 0.0
	elif event is InputEventScreenDrag and _finger_down:
		pad.extend_stroke((event as InputEventScreenDrag).position)


func _process(delta: float) -> void:
	if phase == Phase.WRITE and _since_up >= 0.0 and not _finger_down:
		_since_up += delta
		if _since_up >= LearnBalance.WRITE_DONE_IDLE_SEC:
			_since_up = -1.0
			if not pad.ink.is_empty():
				ink_done.emit()


## The test and the screenshot bot hand in a whole letter here.
func submit(ink: Array[PackedVector2Array]) -> void:
	if phase != Phase.WRITE:
		return
	pad.ink = ink
	pad.queue_redraw()
	_since_up = -1.0
	ink_done.emit()


func _judge() -> bool:
	var level: int = mini(attempts - 1, LearnBalance.WRITE_HINT_TRACE)
	var res: Dictionary = WriteCheck.judge(pad.ink, model, _others, level, false)
	var ok: bool = bool(res["accepted"])
	if attempts >= LearnBalance.WRITE_NEAR_ATTEMPT and bool(res["near"]):
		ok = true
	if attempts >= LearnBalance.WRITE_ANY_INK_ATTEMPT and bool(res["letter_sized"]):
		ok = true
	return ok


## The sand smooths, Pip says write_retry; from the second miss a start dot,
## from the third the dotted trace.
func _retry() -> void:
	_mark("retry")
	var tw: Tween = create_tween()
	tw.tween_property(pad, "ink_alpha", 0.0, LearnBalance.WRITE_SMOOTH_SEC)
	await say_wait(["write_retry"], 0.2)
	pad.clear_ink()
	pad.show_start_dot = attempts >= 1
	pad.show_trace = attempts >= 2


func _accepted() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(pad, "compare_alpha", 1.0, 0.2)
	tw.parallel().tween_property(pad, "ink_gold", 1.0, 0.2)
	await wait(LearnBalance.WRITE_COMPARE_SEC)
	var tw2: Tween = create_tween()
	tw2.tween_property(pad, "compare_alpha", 0.0, 0.3)
	tw2.parallel().tween_property(pad, "ink_alpha", 0.0, 0.5)
	tw2.parallel().tween_property(pad, "patch_alpha", 0.0, 0.5)  # the stone shows under it
	pad.show_start_dot = false
	pad.show_trace = false
	_lift_stone()
	_mark("stone")
	main.pip.giggle()
	await say_wait([Voice.chime_id(), "write_right"], 0.2)
	await _roll_to_bridge(lifted)
	written.append(letter)


## The child's letter lifts out of the sand as a letter stone.
func _lift_stone() -> void:
	var p: Vector3 = main.rig.ground_point(pad.ink_bounds().get_center(), main.world.write_patch.y)
	p.y = main.world.write_patch.y
	lifted = Stone.new()
	lifted.setup(letter, Game.skill_for_label(letter))
	add_child(lifted)
	lifted.scale = Vector3.ONE * GameTune.WRITE_STONE_SCALE
	lifted.global_position = p - Vector3(0, 1.0, 0)
	lifted.rotation.y = main.rig.cam.global_rotation.y
	lifted.home = p
	(
		create_tween()
		. tween_property(lifted, "global_position", p, 0.5)
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
	main.add_to_pile(st)


## For the screenshot bot and the test: the model letter as screen strokes.
func model_screen_strokes() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for s: PackedVector2Array in model:
		var pts: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in s:
			pts.append(pad.to_screen(p) + Vector2(-60, 30))
		out.append(pts)
	return out
