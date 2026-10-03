class_name OrdBro
extends Activity
## Ordbroa, the word bridge (GDD 6.6): Pip says a word, the child drags letter
## stones into the plank slots. A wrong stone says its own sound, wobbles and
## slides back. A finished bridge is read left to right, the word's picture
## comes alive and the hero walks across.

const DRAG_START_PX: float = 18.0
const STONE_LIFT: float = 0.9

var stones: Array[Stone] = []
var slots: Array[Stone] = []  # null while empty
var graphemes: Array[String] = []
var word: String = ""
var picture: Node3D
var _drag: Stone
var _drag_from: Vector2
var _dragging: bool = false
var _slot_tried: Array[bool] = []
var _explained: bool = false
var _hero_across: bool = false


func activity_id() -> String:
	return "ordbro"


func camera_pose() -> Dictionary:
	var w: World = main.world
	var t: Vector3 = (w.bridge_start + w.bridge_end) * 0.5 + Vector3(-2.6, 0.0, 1.6)
	return {"target": t, "distance": GameTune.CAM_BRIDGE_DISTANCE, "pitch": GameTune.CAM_PITCH_DEG}


func start_item(p_item: Dictionary, p_format: Dictionary, hint_start: int) -> void:
	super.start_item(p_item, p_format, hint_start)
	active = false
	_clear()
	_explained = false
	if _hero_across:
		_hero_across = false
		main.hero.walk_to(main.world.knight_spot)
	word = str(item["text"])
	graphemes.clear()
	for g: Variant in item.get("graphemes", []):
		graphemes.append(str(g))
	slots.clear()
	_slot_tried.clear()
	for i in graphemes.size():
		slots.append(null)
		_slot_tried.append(false)
	var letters: Array[String] = graphemes.duplicate()
	for d: Variant in format.get("distractors", []):
		letters.append(Game.label(str(d)))
	letters.shuffle()
	var spots: Array[Vector3] = main.world.stone_spots
	for i in mini(letters.size(), spots.size()):
		var st: Stone = Stone.new()
		st.setup(letters[i], Game.skill_for_label(letters[i]))
		add_child(st)
		st.global_position = spots[i] + Vector3(0, -1.2, 0)
		st.home = spots[i]
		(
			create_tween()
			. tween_property(st, "global_position", spots[i], 0.5)
			. set_delay(0.1 * i)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
		stones.append(st)
	_show_picture(str(item.get("picture", "")))
	await get_tree().create_timer(0.8).timeout
	_say_prompt()
	active = true
	if hints.level >= 2:
		_apply(hints.level, false)


func _say_prompt() -> void:
	var ids: Array = ["bridge_prompt", str(item.get("audio", "w_" + word))]
	if hints.level >= 1:
		for g: String in graphemes:
			ids.append(Game.phoneme_clip(Game.skill_for_label(g)))
	mark_prompt_end(Voice.say(ids, true))


func _show_picture(kind: String) -> void:
	if picture:
		picture.queue_free()
		picture = null
	picture = Props.make(kind)
	if picture == null:
		return
	add_child(picture)
	picture.global_position = (
		main.world.islet_picture_spot
		+ (Vector3(0, -1.6, 0) if kind == "sun" else Vector3(0, -2.6, 0))
	)
	picture.scale = Vector3.ONE * (0.8 if kind == "sun" else 1.0)
	picture.rotation.y = main.rig.cam.global_rotation.y + (0.0 if kind == "sun" else -0.6)


func _next_empty() -> int:
	for i in slots.size():
		if slots[i] == null:
			return i
	return -1


func _target_stone(slot_i: int) -> Stone:
	for st: Stone in stones:
		if not st.placed and st.visible and st.letter == graphemes[slot_i]:
			return st
	return null


func apply_hint(level: int) -> void:
	_apply(level, true)


func _apply(level: int, speak: bool) -> void:
	var si: int = _next_empty()
	if si < 0:
		return
	var tgt: Stone = _target_stone(si)
	if speak and level >= 1:
		_say_prompt()
	if tgt == null:
		return
	if level >= 2:
		tgt.glyph.hint_pulse = true
		for st: Stone in stones:
			if not st.placed and st.visible and not graphemes.has(st.letter):
				st.visible = false
				break
	if level >= 3:
		main.pip.point_at(tgt.global_position)
		if speak:
			Voice.then([Game.phoneme_clip(tgt.skill)])
	if level >= 4:
		var half: Vector3 = tgt.home.lerp(main.world.bridge_slots[si] + Vector3(0, 0.2, 0), 0.5)
		tgt.home = half
		tgt.slide_home()


func touch(event: InputEvent) -> void:
	if not active or frozen:
		return
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		if t.pressed:
			_drag = _stone_at(t.position)
			_drag_from = t.position
			_dragging = false
			if _drag:
				reset_idle()
				Voice.sound(Game.phoneme_clip(_drag.skill))
				_drag.glyph.tap_bounce()
		elif _drag:
			var st: Stone = _drag
			_drag = null
			if _dragging:
				_drop(st, t.position)
			elif hints.level >= 4 and st == _target_stone(maxi(_next_empty(), 0)):
				_place(st, _next_empty())
	elif event is InputEventScreenDrag and _drag:
		var d: InputEventScreenDrag = event as InputEventScreenDrag
		if not _dragging and d.position.distance_to(_drag_from) > DRAG_START_PX:
			_dragging = true
		if _dragging:
			var p: Vector3 = main.rig.ground_point(d.position + Vector2(0, 40), STONE_LIFT)
			_drag.global_position = p - Vector3(0, 0.3, 0)
			reset_idle()


func _stone_at(pos: Vector2) -> Stone:
	var best: Stone = null
	var best_d: float = INF
	for st: Stone in stones:
		if st.placed or not st.visible:
			continue
		var d: float = pos.distance_to(st.screen_pos(main.rig.cam))
		if d < st.screen_radius(main.rig.cam) and d < best_d:
			best_d = d
			best = st
	return best


func _drop(st: Stone, finger: Vector2) -> void:
	var best: int = -1
	var best_d: float = INF
	for i in slots.size():
		if slots[i] != null:
			continue
		var sp: Vector2 = main.rig.cam.unproject_position(main.world.bridge_slots[i])
		var edge: Vector2 = main.rig.cam.unproject_position(
			main.world.bridge_slots[i] + Vector3(0.5, 0, 0)
		)
		var radius: float = maxf(LearnBalance.SNAP_RADIUS_PX, sp.distance_to(edge) * 1.2)
		var d: float = finger.distance_to(sp)
		if d < radius and d < best_d:
			best_d = d
			best = i
	if best < 0:
		st.slide_home()
		return
	last_choices = _stones_left()
	var expected: String = graphemes[best]
	var slot_skill: Array[String] = [Game.skill_for_label(expected)]
	var first: bool = not _slot_tried[best]
	_slot_tried[best] = true
	if st.letter == expected:
		report_with(slot_skill, true, hints.level, first)
		_place(st, best)
	else:
		report_with(slot_skill, false, hints.level, first)
		_wrong(st, best)


func _stones_left() -> int:
	var n: int = 0
	for st: Stone in stones:
		if not st.placed and st.visible:
			n += 1
	return maxi(n, 2)


func _place(st: Stone, slot_i: int) -> void:
	slots[slot_i] = st
	st.home = main.world.bridge_slots[slot_i]
	st.glyph.hint_pulse = false
	var tw: Tween = create_tween()
	tw.tween_property(st, "global_position", main.world.bridge_slots[slot_i], 0.25)
	st.become_plank()
	Voice.sound(Game.phoneme_clip(st.skill))
	Voice.chime()
	main.pip.go_home()
	reset_idle()
	if _next_empty() < 0:
		active = false
		await tw.finished
		await _complete()
	elif hints.level >= 2:
		await get_tree().create_timer(0.6).timeout
		_apply(hints.level, false)


func _wrong(st: Stone, slot_i: int) -> void:
	frozen = true
	var tw: Tween = create_tween()
	tw.tween_property(
		st, "global_position", main.world.bridge_slots[slot_i] + Vector3(0, 0.25, 0), 0.2
	)
	await tw.finished
	var d: float = Voice.sound(Game.phoneme_clip(st.skill))
	await st.wobble().finished
	get_tree().create_timer(maxf(d - 0.4, 0.0) + 0.1).timeout.connect(
		func() -> void: Voice.sfx("tok")
	)
	await st.slide_home().finished
	frozen = false
	if Game.engine.wrong_tap(Time.get_ticks_msec() / 1000.0):
		disengaged.emit(StringName(str(item.get("id", ""))))
		return
	var lv: int = hints.on_wrong()
	if not _explained:
		_explained = true
		var want: String = Game.phoneme_clip(Game.skill_for_label(graphemes[slot_i]))
		await (
			get_tree()
			. create_timer(Voice.say(["den_sa", Game.phoneme_clip(st.skill), "vi_leter", want]))
			. timeout
		)
	apply_hint(lv)


func _complete() -> void:
	await get_tree().create_timer(0.3).timeout
	for i in slots.size():
		var st: Stone = slots[i]
		st.glyph.pop()
		var d: float = Voice.sound(Game.phoneme_clip(st.skill))
		await get_tree().create_timer(maxf(d, GameTune.BRIDGE_LIGHT_STEP_SEC)).timeout
	var wd: float = Voice.say([str(item.get("audio", "w_" + word))])
	Game.note_word_built(word)
	main.burst(main.world.bridge_slots[1] + Vector3(0, 0.8, 0))
	Voice.sfx("fanfare")
	_animate_picture()
	await get_tree().create_timer(wd + 0.2).timeout
	_hero_across = true
	_hero_walk()
	praise_count += 1
	if praise_count % 2 == 1:
		await (
			get_tree()
			. create_timer(Voice.say(["bridge_done", str(item.get("audio", "w_" + word))]))
			. timeout
		)
	await get_tree().create_timer(2.4).timeout
	for st: Stone in stones:
		create_tween().tween_property(st, "global_position:y", st.global_position.y - 1.5, 0.5)
	await get_tree().create_timer(0.5).timeout
	item_done.emit()


func _hero_walk() -> void:
	await main.hero.walk_to(main.world.bridge_end + Vector3(0.9, 0.0, -0.3))
	main.hero.cheer()


func _animate_picture() -> void:
	if picture == null:
		return
	var kind_sun: bool = str(item.get("picture", "")) == "sun"
	var tw: Tween = create_tween()
	if kind_sun:
		(
			tw
			. tween_property(picture, "global_position:y", picture.global_position.y + 2.2, 1.4)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
		tw.parallel().tween_property(picture, "scale", Vector3.ONE * 1.15, 1.4)
	else:
		for k in 3:
			tw.tween_property(picture, "global_position:y", picture.global_position.y + 0.6, 0.18)
			tw.tween_property(picture, "global_position:y", picture.global_position.y, 0.18)


func end_visit() -> void:
	super.end_visit()
	_clear()
	if picture:
		picture.queue_free()
		picture = null
	if _hero_across:
		_hero_across = false
		main.hero.walk_to(main.world.knight_spot)


func _clear() -> void:
	for st: Stone in stones:
		st.queue_free()
	stones.clear()
	slots.clear()
	_drag = null


## For the screenshot bot.
func stone_screen_pos_for_slot(slot_i: int, want_right: bool) -> Vector2:
	for st: Stone in stones:
		if st.placed or not st.visible:
			continue
		if (st.letter == graphemes[slot_i]) == want_right:
			return st.screen_pos(main.rig.cam)
	return Vector2(-1, -1)


func slot_screen_pos(slot_i: int) -> Vector2:
	return main.rig.cam.unproject_position(main.world.bridge_slots[slot_i])
