class_name HorOgFinn
extends Activity
## Hør og finn: hear a letter sound, tap the letter that says it. The task
## logic is LetterRules (tested in tests/test_letter_mapping.gd): a and s
## first, one more letter after four right first tries, at most three tiles,
## never the same target three times in a row. Here the letters stand on
## round sand tiles on the beach.
## Sound: find_in at the start. Each item: find_ask, then the target's held
## sound last (nothing after it). A tap plays the tapped letter's short
## sound. Right: a chime, and find_right after every right. Wrong: the
## tapped letter's short sound, tok, find_wrong, then the target's held sound.
## A new letter: its intro take while its tile pulses, then intro_again and
## its held sound (t, b: the short one) once more. Long-press any tile:
## its name, then its held sound. find_done after ITEMS items.

signal item_started(target: String, letters: Array[String])
signal prompt_played(target: String, ids: Array[String])
signal item_finished

const ITEMS: int = 10
const LONG_PRESS_SEC: float = 0.6
const IDLE_REPEAT_SEC: float = 8.0
const SAVE_PATH: String = "user://letters.json"  # shared with the one-screen letter game
const RIGHT_LINE_EVERY: int = 1  # praise after every right answer (owner 2026-10-06)

var rules: LetterRules = LetterRules.new()
var target: String = ""
var letters: Array[GlowLetter] = []
var items_done: int = 0
var rights: int = 0
var busy: bool = true  # taps ignored (intro or feedback running)
var found: Array[String] = []  # letters answered right this visit
var last_wrong: String = ""  # screenshot bot
var _tiles: Array[Node3D] = []
var _missed: bool = false
var _press: GlowLetter
var _press_t: float = 0.0
var _idle: float = 0.0
var _demo: bool = false


func activity_id() -> String:
	return "hor_og_finn"


func hub_line() -> String:
	return "hub_find"


func camera_pose() -> Dictionary:
	return {
		"target": _center() + Vector3(0, GameTune.FIND_CAM_LIFT, 0),
		"distance": GameTune.FIND_CAM_DISTANCE,
		"pitch": GameTune.FIND_CAM_PITCH_DEG,
		"yaw": GameTune.FIND_CAM_YAW_DEG
	}


func _center() -> Vector3:
	return main.world.zone_centers[0]


func _right() -> Vector3:
	var r: Vector3 = main.rig.cam.global_basis.x
	r.y = 0.0
	return r.normalized()


func begin() -> void:
	super.begin()
	_load()
	rules.begin_visit()  # a new letter, if one is due, comes only at a visit start
	items_done = 0
	rights = 0
	found.clear()
	_demo = rules.heard.is_empty()  # the very first item ever: the ghost hand shows a tap


func run() -> void:
	active = true
	while items_done < ITEMS:
		_next_item(items_done == 0)
		await item_finished
	busy = true
	_clear()
	_mark("done")
	await say_wait(["find_done"], 0.3)
	active = false


func end() -> void:
	super.end()
	_seq += 1
	busy = true
	_clear()


# ---------------------------------------------------------------- item


func _next_item(first: bool) -> void:
	_seq += 1
	var my: int = _seq
	busy = true
	_missed = false
	last_wrong = ""
	var intro: Array[String] = rules.pending_intro()
	target = rules.pick_target()
	_show(rules.pick_tiles(target, intro))
	item_started.emit(target, tile_letters())
	await wait(1.5)
	if first:
		_mark("in")
		await say_wait(["find_in"], 0.3)
	for l: String in intro:
		if my != _seq:
			return
		var gl: GlowLetter = letter_node(l)
		var sec: float = Voice.say(["intro_" + l])
		if gl:
			_pulse(gl, sec)
		_mark("intro_" + l)
		rules.mark_heard(l)
		await wait(sec + LetterRules.INTRO_GAP_SEC)
		if my != _seq:
			return
		# "Hør en gang til." and the new sound once more on its own
		var again: float = Voice.say(["intro_again", Voice.held_id(l)])
		if gl:
			_pulse(gl, again)
		await wait(again + LetterRules.INTRO_GAP_SEC)
	_save()
	if my != _seq:
		return
	_prompt()
	if _demo:
		var gl2: GlowLetter = letter_node(target)
		main.hud.ghost.tap(func() -> Vector2: return gl2.screen_pos(main.rig.cam))


func _prompt() -> void:
	var ids: Array[String] = ["find_ask", Voice.held_id(target)]
	Voice.say(ids)
	_idle = 0.0
	busy = false
	_mark("prompt")
	prompt_played.emit(target, ids)


## Pip and the speaker button: hear the question and the sound again.
func replay() -> void:
	if busy:
		return
	_seq += 1
	_prompt()


## A short tap on a letter (the touch path and the test both land here).
func tap(l: String) -> void:
	if busy or letter_node(l) == null:
		return
	busy = true
	_seq += 1
	var my: int = _seq
	_idle = 0.0
	_demo = false
	main.hud.ghost.stop()
	var gl: GlowLetter = letter_node(l)
	var sec: float = Voice.say([Voice.short_id(l)])
	if l == target:
		gl.hint_pulse = true
		gl.pop()
		main.burst(gl.center_world())
		rules.record(not _missed)
		items_done += 1
		rights += 1
		if not found.has(l):
			found.append(l)
		_save()
		await wait(sec + LetterRules.AFTER_CLIP_GAP_SEC)
		if my != _seq:
			return
		var ids: Array = [Voice.chime_id()]
		if rights % RIGHT_LINE_EVERY == 0:
			ids.append("find_right")
		_mark("right")
		await say_wait(ids, 0.2)
		if my != _seq:
			return
		await wait(LetterRules.CORRECT_PAUSE_SEC)
		if my != _seq:
			return
		for g: GlowLetter in letters:
			g.sink(4.0)
		await wait(0.8)
		if my != _seq:
			return
		item_finished.emit()
	else:
		_missed = true
		last_wrong = l
		gl.wobble()
		_mark("wrong")
		await wait(sec + LetterRules.AFTER_CLIP_GAP_SEC)
		if my != _seq:
			return
		await say_wait(["sfx_tok"], 0.1)
		if my != _seq:
			return
		var ids2: Array[String] = ["find_wrong", Voice.held_id(target)]
		Voice.say(ids2)
		_idle = 0.0
		busy = false
		prompt_played.emit(target, ids2)


## Long-press on a letter: its name, then its held sound.
func long_press(l: String) -> void:
	if busy or letter_node(l) == null:
		return
	_seq += 1
	_idle = 0.0
	letter_node(l).pop()
	Voice.say(["navn_" + l, Voice.held_id(l)])
	_mark("name_" + l)


func _process(delta: float) -> void:
	if _press:
		_press_t += minf(delta, 0.1)  # a frame hitch never turns a tap into a long-press
		if _press_t >= LONG_PRESS_SEC:
			var l: String = _press.letter
			_press = null
			long_press(l)
	if active and not busy and not Voice.is_busy():
		_idle += delta
		if _idle >= IDLE_REPEAT_SEC:
			replay()


func touch(event: InputEvent) -> void:
	var t: InputEventScreenTouch = event as InputEventScreenTouch
	if t == null:
		return
	if t.pressed:
		_press = _letter_at(t.position) if not busy else null
		_press_t = 0.0
	elif _press:
		var l: String = _press.letter
		_press = null
		tap(l)


# ---------------------------------------------------------------- pieces


func tile_letters() -> Array[String]:
	var out: Array[String] = []
	for g: GlowLetter in letters:
		out.append(g.letter)
	return out


func letter_node(l: String) -> GlowLetter:
	for g: GlowLetter in letters:
		if g.letter == l:
			return g
	return null


func _show(want: Array[String]) -> void:
	_clear()
	var n: int = want.size()
	var spacing: float = GameTune.FIND_SPACING_M * (1.0 if n <= 2 else 0.85)
	for i in n:
		var off: float = (float(i) - float(n - 1) * 0.5) * spacing
		var p: Vector3 = _tile_spot(_center() + _right() * off)
		_add_tile(p, 0.12 * float(i))
		var gl: GlowLetter = GlowLetter.new()
		gl.setup(want[i], GameTune.FIND_LETTER_M)
		gl.idle_motion = false
		add_child(gl)
		gl.global_position = p + Vector3(0, GameTune.TILE_TOP_M, 0)
		gl.set_base_y(gl.position.y)
		gl.rotation.y = main.rig.cam.global_rotation.y
		gl.rise_from(2.6, 0.12 * float(i))
		letters.append(gl)


## The tile grows and glows while its intro take plays.
func _pulse(gl: GlowLetter, sec: float) -> void:
	gl.hint_pulse = true
	var tw: Tween = create_tween()
	tw.tween_property(gl, "scale", Vector3.ONE * 1.25, 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(maxf(sec - 0.6, 0.0))
	tw.tween_property(gl, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: gl.hint_pulse = false)


## A spot whose height is the highest ground under a whole tile, so the
## disc never cuts into a slope.
func _tile_spot(p: Vector3) -> Vector3:
	var top: float = main.world.ground_y(p)
	for k in 8:
		var a: float = TAU * float(k) / 8.0
		var q: Vector3 = p + Vector3(cos(a), 0, sin(a)) * GameTune.TILE_RADIUS_M
		top = maxf(top, main.world.ground_y(q))
	return Vector3(p.x, top, p.z)


## A round sand tile under a letter: flat disc with a darker rim.
func _add_tile(at: Vector3, delay: float) -> void:
	var parts: Array = [
		[
			MeshKit.cylinder(GameTune.TILE_RADIUS_M, GameTune.TILE_RADIUS_M + 0.08, 0.16, 32),
			MeshKit.xf(Vector3(0, 0.0, 0)),
			GameTune.SAND_WET
		],
		[
			MeshKit.cylinder(GameTune.TILE_RADIUS_M - 0.14, GameTune.TILE_RADIUS_M - 0.1, 0.18, 32),
			MeshKit.xf(Vector3(0, 0.02, 0)),
			GameTune.SAND
		],
	]
	var tile: Node3D = Node3D.new()
	add_child(tile)
	MeshKit.instance(MeshKit.merge(parts), MeshKit.with_outline(MeshKit.char_toon(), 0.003), tile)
	tile.global_position = at + Vector3(0, -0.6, 0)
	var tw: Tween = create_tween()
	tw.tween_interval(delay)
	tw.tween_property(tile, "global_position", at + Vector3(0, 0.02, 0), 0.4).set_trans(
		Tween.TRANS_BACK
	)
	_tiles.append(tile)


## Nearest letter whose touch radius covers the point.
func _letter_at(pos: Vector2) -> GlowLetter:
	var best: GlowLetter = null
	var best_d: float = INF
	for gl: GlowLetter in letters:
		var d: float = pos.distance_to(gl.screen_pos(main.rig.cam))
		if d < gl.screen_radius(main.rig.cam) and d < best_d:
			best_d = d
			best = gl
	return best


func _clear() -> void:
	for gl: GlowLetter in letters:
		gl.queue_free()
	letters.clear()
	for tl: Node3D in _tiles:
		if is_instance_valid(tl):
			var tw: Tween = tl.create_tween()
			tw.tween_property(tl, "position:y", tl.position.y - 0.8, 0.4)
			tw.tween_callback(tl.queue_free)
	_tiles.clear()
	_press = null


func letter_screen_pos(l: String) -> Vector2:
	var gl: GlowLetter = letter_node(l)
	return gl.screen_pos(main.rig.cam) if gl else Vector2(-1, -1)


func _load() -> void:
	if not Game.persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if d is Dictionary:
		rules.from_dict(d as Dictionary)


func _save() -> void:
	if not Game.persist:
		return
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(rules.to_dict()))
