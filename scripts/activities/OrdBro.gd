class_name OrdBro
extends Activity
## Ordbroa, the word bridge (GDD 6.6, reworked after the owner's play test).
## The camera is close, the bridge fills the middle of the screen. Every
## letter has its own big plank slot; missing ones are outlined sockets that
## glow, the one to fill next pulses and says its sound when tapped. The
## word's picture is stuck on the little island and comes home over the
## finished bridge. Letter stones sit in a neat row on a raft at the bottom.
## Pip models first: the word, then each sound slowly while its slot lights,
## then the word again. Scaffold: first only the last letter is missing
## (one stone, then a choice of two), then two, then the whole word.
## Hints: a wrong stone says its own sound and slides back; then the right
## stone glows and bounces; after two misses the ghost hand drags it.

const DRAG_START_PX: float = 18.0
const STONE_LIFT: float = 0.9

var stones: Array[Stone] = []
var slots: Array[Stone] = []  # filled plank per slot, null while empty
var slot_pos: Array[Vector3] = []
var graphemes: Array[String] = []
var word: String = ""
var picture: Node3D
var pitch_m: float = 1.4
var _missing_from: int = 0  # slots >= this start empty
var _sockets: Array[Node3D] = []
var _socket_mats: Array[StandardMaterial3D] = []
var _deck: MeshInstance3D
var _raft: MeshInstance3D
var _drag: Stone
var _drag_from: Vector2
var _dragging: bool = false
var _slot_tried: Array[bool] = []
var _explained: bool = false
var _demo: bool = false
var _modelling: bool = false
var _lit: int = -1  # slot lit by Pip's sounding-out
var _first_of_visit: bool = true
var _t: float = 0.0
var _glow_tween: Tween
var _ring: MeshInstance3D


func activity_id() -> String:
	return "ordbro"


func camera_pose() -> Dictionary:
	var w: World = main.world
	var mid: Vector3 = (w.bridge_start + w.bridge_end) * 0.5
	return {
		"target": mid + GameTune.BRIDGE_CAM_OFFSET,
		"distance": GameTune.BRIDGE_CAM_DISTANCE,
		"pitch": GameTune.BRIDGE_CAM_PITCH_DEG
	}


func begin_visit() -> void:
	super.begin_visit()
	_first_of_visit = true
	main.pip.home_offset = GameTune.PIP_BRIDGE_OFFSET


func end_visit() -> void:
	super.end_visit()
	main.hud.ghost.stop()
	main.pip.home_offset = GameTune.PIP_SCREEN_OFFSET
	_clear()
	if picture:
		picture.queue_free()
		picture = null


## The first bridges ever use a fixed, easy word order (is, sol, lam).
func adjust_task(task: Dictionary) -> Dictionary:
	var done: int = Game.bridge_items_done
	if done >= GameTune.BRIDGE_FIRST_WORDS.size():
		return task
	var it: Dictionary = Game.engine.pack.item(GameTune.BRIDGE_FIRST_WORDS[done])
	if it.is_empty():
		return task
	for sk: String in Game.engine.pack.item_skills(it):
		if not Game.engine.is_skill_available(sk):
			return task
	var out: Dictionary = task.duplicate()
	out["item"] = it
	out["skill"] = Game.engine.tested_skills(it)[0]
	return out


## Missing letters and distractors for the child's n-th bridge.
static func stage_for(done: int) -> Dictionary:
	var pick: Dictionary = GameTune.BRIDGE_STAGES[0]
	for st: Dictionary in GameTune.BRIDGE_STAGES:
		if done >= int(st["after"]):
			pick = st
	return pick


# ---------------------------------------------------------------- story


func story_intro(_first_task: Dictionary) -> void:
	pass  # the bridge tells its story per word, see _story()


func _story() -> void:
	var ids: Array = [str(item.get("story_audio", ""))]
	if _first_of_visit:
		ids.append("build_" + str(item.get("pronoun", "det")))
	_first_of_visit = false
	main.pip.point_at(picture.global_position + Vector3(0, 2.4, 0))
	var tw: Tween = create_tween()  # the stuck picture hops on the spot
	var y0: float = picture.position.y
	for k in 2:
		tw.tween_property(picture, "position:y", y0 + 0.4, 0.18)
		tw.tween_property(picture, "position:y", y0, 0.18)
	await get_tree().create_timer(Voice.say(ids) + 0.3).timeout
	main.pip.go_home()


# ---------------------------------------------------------------- item


func start_item(p_item: Dictionary, p_format: Dictionary, hint_start: int) -> void:
	super.start_item(p_item, p_format, hint_start)
	active = false
	_clear()
	_explained = false
	hints.level = 0  # Pip models first; the ladder climbs on a miss or idle
	hints.highest = 0
	word = str(item["text"])
	graphemes.clear()
	for g: Variant in item.get("graphemes", []):
		graphemes.append(str(g))
	var n: int = graphemes.size()
	var stage: Dictionary = stage_for(Game.bridge_items_done)
	var missing: int = clampi(int(stage["missing"]), 1, n)
	_missing_from = n - missing
	_layout_slots(n)
	_build_deck()
	slots.clear()
	_slot_tried.clear()
	for i in n:
		slots.append(null)
		_slot_tried.append(false)
		_add_socket(i)
	for i in _missing_from:
		_preplace(i)
	var letters: Array[String] = []
	for i in range(_missing_from, n):
		letters.append(graphemes[i])
	for d: String in _distractors(int(stage["distractors"])):
		letters.append(d)
	letters.shuffle()
	last_choices = maxi(letters.size(), 1)
	_place_stones(letters)
	_show_picture(str(item.get("picture", "")))
	await get_tree().create_timer(0.9).timeout
	await _story()
	await _model_word()
	_say_prompt()
	active = true
	if Game.demo_due(activity_id()):
		_demo = true
		_show_ghost()


func _say_prompt() -> void:
	var ids: Array = [str(item.get("audio", "w_" + word)), "bridge_drag"]
	mark_prompt_end(Voice.say(ids, true))


## Pip models: the word, then each sound slowly while its slot lights, then
## the word again.
func _model_word() -> void:
	_modelling = true
	var w: String = str(item.get("audio", "w_" + word))
	main.pip.giggle()
	await get_tree().create_timer(Voice.say(["bridge_listen", w]) + 0.3).timeout
	for i in graphemes.size():
		_lit = i
		if slots[i]:
			slots[i].glyph.pop()
		var d: float = Voice.say([Game.phoneme_clip(Game.skill_for_label(graphemes[i]))])
		await get_tree().create_timer(maxf(d, 0.7) + 0.15).timeout
	_lit = -1
	await get_tree().create_timer(Voice.say([w]) + 0.3).timeout
	_modelling = false


func _distractors(count: int) -> Array[String]:
	var out: Array[String] = []
	if count <= 0:
		return out
	var pool: Array[String] = []
	for sid: String in Game.engine.model.introduced():
		var l: String = Game.label(sid)
		if not graphemes.has(l) and not pool.has(l):
			pool.append(l)
	pool.shuffle()
	return pool.slice(0, count)


# ---------------------------------------------------------------- layout


func _bridge_dir() -> Vector3:
	return (main.world.bridge_end - main.world.bridge_start).normalized()


func _pitch_for(n: int) -> float:
	var length: float = main.world.bridge_start.distance_to(main.world.bridge_end)
	return clampf(
		(length - 2.0 * GameTune.BRIDGE_END_MARGIN_M) / float(n),
		GameTune.BRIDGE_PITCH_MIN_M,
		GameTune.BRIDGE_PITCH_MAX_M
	)


func _layout_slots(n: int) -> void:
	var a: Vector3 = main.world.bridge_start
	var b: Vector3 = main.world.bridge_end
	pitch_m = _pitch_for(n)
	var mid: Vector3 = (a + b) * 0.5
	slot_pos.clear()
	for i in n:
		var off: float = (float(i) - float(n - 1) * 0.5) * pitch_m
		var p: Vector3 = mid + _bridge_dir() * off
		p.y = GameTune.BRIDGE_DECK_Y
		slot_pos.append(p)


## Fixed deck boards from each end of the bridge to the slots.
func _build_deck() -> void:
	var a: Vector3 = main.world.bridge_start
	var b: Vector3 = main.world.bridge_end
	var dir: Vector3 = _bridge_dir()
	var first_edge: float = a.distance_to(slot_pos[0]) - pitch_m * 0.5
	var last_edge: float = a.distance_to(slot_pos[slot_pos.size() - 1]) + pitch_m * 0.5
	var total: float = a.distance_to(b)
	var parts: Array = []
	var yaw: float = rad_to_deg(atan2(-dir.z, dir.x))
	var x: float = -0.4
	while x < total + 0.4:
		if x < first_edge - 0.1 or x > last_edge + 0.1:
			var p: Vector3 = a + dir * x
			p.y = GameTune.BRIDGE_DECK_Y - 0.04
			var shade: Color = GameTune.WOOD_LIGHT if int(x * 3.0) % 2 == 0 else GameTune.WOOD
			parts.append(
				[
					MeshKit.box(Vector3(0.3, 0.14, 1.5)),
					MeshKit.xf(p, Vector3.ONE, Vector3(0, yaw, 0)),
					shade
				]
			)
		x += 0.36
	if parts.is_empty():
		return
	_deck = MeshKit.instance(
		MeshKit.merge(parts), MeshKit.with_outline(MeshKit.toon(), 0.003), self
	)


## An empty plank socket: a dark slot with a dashed gold outline and a glow.
func _add_socket(i: int) -> void:
	var root: Node3D = Node3D.new()
	add_child(root)
	root.global_position = slot_pos[i]
	var w: float = pitch_m * GameTune.BRIDGE_SLOT_FILL
	var depth: float = 1.5
	MeshKit.instance(
		MeshKit.box(Vector3(w, 0.06, depth)), MeshKit.toon(Color(0.12, 0.30, 0.42), false), root
	)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.86, 0.25)
	var parts: Array = []
	var dash: float = 0.2
	var gap: float = 0.13
	for side: int in 4:
		var horizontal: bool = side < 2
		var span: float = w if horizontal else depth
		var fixed: float = (
			(depth * 0.5 if side == 0 else -depth * 0.5)
			if horizontal
			else (w * 0.5 if side == 2 else -w * 0.5)
		)
		var u: float = -span * 0.5 + 0.05
		while u + dash <= span * 0.5 + 0.001:
			var c: float = u + dash * 0.5
			var pos: Vector3 = Vector3(c, 0.06, fixed) if horizontal else Vector3(fixed, 0.06, c)
			var size: Vector3 = (
				Vector3(dash, 0.07, 0.09) if horizontal else Vector3(0.09, 0.07, dash)
			)
			parts.append([MeshKit.box(size), MeshKit.xf(pos), Color(1, 1, 1)])
			u += dash + gap
	var dashes: MeshInstance3D = MeshKit.instance(MeshKit.merge(parts), mat, root)
	dashes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var q: QuadMesh = QuadMesh.new()
	q.size = Vector2(w * 1.6, w * 1.6)
	var hm: ShaderMaterial = ShaderMaterial.new()
	hm.shader = preload("res://shaders/halo.gdshader")
	hm.set_shader_parameter("color", GameTune.GOLD)
	hm.set_shader_parameter("strength", 0.0)
	var halo: MeshInstance3D = MeshKit.instance(q, hm, root)
	halo.position = Vector3(0, 0.3, 0)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.set_meta("halo", hm)
	root.set_meta("dashes", dashes)
	_sockets.append(root)
	_socket_mats.append(mat)


func _preplace(i: int) -> void:
	var st: Stone = Stone.new()
	st.setup(graphemes[i], Game.skill_for_label(graphemes[i]))
	add_child(st)
	st.scale = Vector3.ONE * GameTune.BRIDGE_STONE_SCALE
	st.global_position = slot_pos[i]
	st.home = slot_pos[i]
	st.become_plank(pitch_m * GameTune.BRIDGE_SLOT_FILL / GameTune.BRIDGE_STONE_SCALE)
	slots[i] = st
	_sockets[i].visible = false


## Stones in a neat row on a raft along the bottom of the screen.
func _place_stones(letters: Array[String]) -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var n: int = letters.size()
	# a long word's stones share the row: narrower gap, slightly smaller stones
	var gap: float = minf(GameTune.BRIDGE_STONE_GAP_PX, (vp.x - 360.0) / float(maxi(n, 1)))
	var k_size: float = gap / GameTune.BRIDGE_STONE_GAP_PX
	var y: float = vp.y - GameTune.BRIDGE_STONE_ROW_FROM_BOTTOM_PX
	var first: Vector3 = Vector3.ZERO
	var last: Vector3 = Vector3.ZERO
	for i in n:
		var sx: float = vp.x * 0.5 + (float(i) - float(n - 1) * 0.5) * gap
		var p: Vector3 = main.rig.ground_point(Vector2(sx, y), GameTune.RAFT_Y)
		var st: Stone = Stone.new()
		st.setup(letters[i], Game.skill_for_label(letters[i]))
		add_child(st)
		st.scale = Vector3.ONE * GameTune.BRIDGE_STONE_SCALE * k_size
		st.set_meta("base_scale", st.scale)
		st.global_position = p + Vector3(0, -1.2, 0)
		st.home = p
		(
			create_tween()
			. tween_property(st, "global_position", p, 0.5)
			. set_delay(0.1 * i)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
		stones.append(st)
		if i == 0:
			first = p
		last = p
	var span: float = first.distance_to(last) + 2.2 * GameTune.BRIDGE_STONE_SCALE
	var mid: Vector3 = (first + last) * 0.5
	var parts: Array = []
	var k: float = -span * 0.5
	var idx: int = 0
	while k < span * 0.5:
		var pp: Vector3 = mid + Vector3(k + 0.3, -0.12, 0)
		var col: Color = GameTune.WOOD if idx % 2 == 0 else GameTune.WOOD_LIGHT
		parts.append([MeshKit.box(Vector3(0.58, 0.2, 1.7)), MeshKit.xf(pp), col])
		k += 0.6
		idx += 1
	_raft = MeshKit.instance(
		MeshKit.merge(parts), MeshKit.with_outline(MeshKit.toon(), 0.003), self
	)


func _show_picture(kind: String) -> void:
	if picture:
		picture.queue_free()
		picture = null
	picture = Props.make(kind)
	if picture == null:
		return
	add_child(picture)
	# feet on the islet right of the bridge end, at a fixed place on screen so
	# the picture is always fully visible (clear of the home button)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var feet: Vector2 = Vector2(
		vp.x - GameTune.PICTURE_FROM_RIGHT_PX, vp.y * GameTune.PICTURE_FEET_Y
	)
	var spot: Vector3 = main.rig.ground_point(feet, GameTune.BRIDGE_DECK_Y)
	spot = main.world.on_ground(spot.x, spot.z)
	var lift: float = 0.75 if kind == "sun" else 0.0  # the sun floats, the rest stand
	picture.global_position = spot + Vector3(0, -2.5, 0)
	picture.scale = Vector3.ONE * GameTune.PICTURE_SCALE
	picture.rotation.y = main.rig.cam.global_rotation.y - 0.25
	(
		create_tween()
		. tween_property(picture, "global_position:y", spot.y + lift, 0.7)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)


# ---------------------------------------------------------------- glow


func _process(delta: float) -> void:
	super._process(delta)
	_t += delta
	var cur: int = _next_empty()
	for i in _sockets.size():
		var sock: Node3D = _sockets[i]
		if not sock.visible:
			continue
		var hm: ShaderMaterial = sock.get_meta("halo")
		var dashes: MeshInstance3D = sock.get_meta("dashes")
		var k: float = 0.5 + 0.5 * sin(_t * TAU / GameTune.HINT_PULSE_PERIOD_SEC)
		var strength: float = 0.25 + 0.15 * k
		var bright: float = 0.75
		if i == _lit:
			strength = 1.0
			bright = 1.0
		elif i == cur and not _modelling:
			strength = 0.45 + 0.4 * k
			bright = 0.8 + 0.2 * k
			dashes.scale = Vector3.ONE * (1.0 + 0.06 * k)
		hm.set_shader_parameter("strength", strength)
		_socket_mats[i].albedo_color = (
			Color(1.0, 0.86, 0.25) * bright + Color(0, 0, 0, 1) * (1.0 - bright)
		)
	for i in slots.size():
		if slots[i] and i == _lit:
			slots[i].glyph.hint_pulse = true
		elif slots[i]:
			slots[i].glyph.hint_pulse = false


func _next_empty() -> int:
	for i in slots.size():
		if slots[i] == null:
			return i
	return -1


func _target_stone(slot_i: int) -> Stone:
	if slot_i < 0:
		return null
	for st: Stone in stones:
		if not st.placed and st.visible and st.letter == graphemes[slot_i]:
			return st
	return null


# ---------------------------------------------------------------- hints


func apply_hint(level: int) -> void:
	var si: int = _next_empty()
	var tgt: Stone = _target_stone(si)
	if tgt == null:
		return
	if level >= 1:
		_say_prompt()
		_glow_stone(tgt)
	if level >= 2:
		main.pip.point_at(tgt.global_position + Vector3(0, 0.6, 0))
		_show_ghost()


## The right stone glows and bounces.
func _glow_stone(st: Stone) -> void:
	st.glyph.hint_pulse = true
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	st.scale = (st.get_meta("base_scale", st.scale) as Vector3) * 1.2
	_glow_tween = create_tween().set_loops()
	var y0: float = st.home.y
	_glow_tween.tween_property(st, "global_position:y", y0 + 0.5, 0.25).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(st, "global_position:y", y0, 0.25).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_interval(0.4)
	if _ring == null:
		var torus: TorusMesh = TorusMesh.new()
		torus.inner_radius = 0.75
		torus.outer_radius = 0.95
		torus.rings = 40
		torus.ring_segments = 8
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.92, 0.35)
		_ring = MeshKit.instance(torus, m, self)
		_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = true
	_ring.global_position = st.home + Vector3(0, 0.05, 0)
	_ring.scale = Vector3(1.0, 0.4, 1.0) * GameTune.BRIDGE_STONE_SCALE


func _stop_glow() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = null
	if _ring:
		_ring.visible = false
	for st: Stone in stones:
		if not st.placed:
			st.scale = st.get_meta("base_scale", st.scale)
			st.glyph.hint_pulse = false


## The ghost hand drags the right stone into the slot to fill, again and again.
func _show_ghost() -> void:
	main.hud.ghost.drag(
		func() -> Vector2:
			var st: Stone = _target_stone(_next_empty())
			return st.screen_pos(main.rig.cam) if st else Vector2(-500, -500),
		func() -> Vector2:
			var si: int = _next_empty()
			return slot_screen_pos(maxi(si, 0))
	)


# ---------------------------------------------------------------- input


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
				if _demo:
					_demo = false
					Game.mark_demo(activity_id())
					Game.save()
				main.hud.ghost.stop()
				_stop_glow_tween_only()
				Voice.sound(Game.phoneme_clip(_drag.skill))
				_drag.glyph.tap_bounce()
			else:
				_tap_socket(t.position)
		elif _drag:
			var st: Stone = _drag
			_drag = null
			if _dragging:
				_drop(st, t.position)
			else:
				st.slide_home()
	elif event is InputEventScreenDrag and _drag:
		var d: InputEventScreenDrag = event as InputEventScreenDrag
		if not _dragging and d.position.distance_to(_drag_from) > DRAG_START_PX:
			_dragging = true
		if _dragging:
			var p: Vector3 = main.rig.ground_point(d.position + Vector2(0, 40), STONE_LIFT)
			_drag.global_position = p - Vector3(0, 0.3, 0)
			reset_idle()


## The bouncing stops while the child holds a stone (it stays big and glowing).
func _stop_glow_tween_only() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = null


## Tapping an empty slot plays the sound that belongs there.
func _tap_socket(pos: Vector2) -> void:
	for i in slots.size():
		if slots[i] != null:
			continue
		if pos.distance_to(slot_screen_pos(i)) < _slot_radius_px(i):
			reset_idle()
			Voice.sound(Game.phoneme_clip(Game.skill_for_label(graphemes[i])))
			var sock: Node3D = _sockets[i]
			var tw: Tween = create_tween()
			tw.tween_property(sock, "scale", Vector3.ONE * 1.15, 0.12)
			tw.tween_property(sock, "scale", Vector3.ONE, 0.2)
			return


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


func _slot_radius_px(i: int) -> float:
	var sp: Vector2 = slot_screen_pos(i)
	var edge: Vector2 = main.rig.cam.unproject_position(slot_pos[i] + _bridge_dir() * pitch_m * 0.5)
	return maxf(LearnBalance.SNAP_RADIUS_PX, sp.distance_to(edge) * 1.3)


func _drop(st: Stone, finger: Vector2) -> void:
	var best: int = -1
	var best_d: float = INF
	for i in slots.size():
		if slots[i] != null:
			continue
		var d: float = finger.distance_to(slot_screen_pos(i))
		if d < _slot_radius_px(i) and d < best_d:
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
	_stop_glow()
	main.hud.ghost.stop()
	slots[slot_i] = st
	_sockets[slot_i].visible = false
	st.home = slot_pos[slot_i]
	st.scale = Vector3.ONE * GameTune.BRIDGE_STONE_SCALE
	var tw: Tween = create_tween()
	tw.tween_property(st, "global_position", slot_pos[slot_i], 0.25)
	st.become_plank(pitch_m * GameTune.BRIDGE_SLOT_FILL / GameTune.BRIDGE_STONE_SCALE)
	Voice.sound(Game.phoneme_clip(st.skill))
	Voice.chime()
	main.pip.go_home()
	reset_idle()
	hints.level = 0  # the next slot starts fresh
	if _next_empty() < 0:
		active = false
		await tw.finished
		await _complete()


func _wrong(st: Stone, slot_i: int) -> void:
	frozen = true
	var tw: Tween = create_tween()
	tw.tween_property(st, "global_position", slot_pos[slot_i] + Vector3(0, 0.25, 0), 0.2)
	await tw.finished
	var d: float = Voice.sound(Game.phoneme_clip(st.skill))
	await st.wobble().finished
	get_tree().create_timer(maxf(d - 0.4, 0.0) + 0.1).timeout.connect(
		func() -> void: Voice.sfx("tok")
	)
	await st.slide_home().finished
	if Game.engine.wrong_tap(Time.get_ticks_msec() / 1000.0):
		frozen = false
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
	frozen = false
	apply_hint(lv)


func _complete() -> void:
	main.hud.ghost.stop()
	await get_tree().create_timer(0.3).timeout
	for i in slots.size():
		_lit = i
		var st: Stone = slots[i]
		st.glyph.pop()
		var d: float = Voice.sound(Game.phoneme_clip(st.skill))
		await get_tree().create_timer(maxf(d, GameTune.BRIDGE_LIGHT_STEP_SEC)).timeout
	_lit = -1
	var wd: float = Voice.say([str(item.get("audio", "w_" + word))])
	Game.note_word_built(word)
	Game.bridge_items_done += 1
	Game.save()
	main.burst(slot_pos[slot_pos.size() / 2] + Vector3(0, 0.8, 0))
	Voice.sfx("fanfare")
	await get_tree().create_timer(wd + 0.2).timeout
	await _picture_home()
	main.hero.cheer()
	var home_line: String = "home_" + str(item.get("pronoun", "det"))
	await get_tree().create_timer(Voice.say([home_line]) + 0.6).timeout
	for st: Stone in stones:
		create_tween().tween_property(st, "global_position:y", st.global_position.y - 1.5, 0.5)
	if picture:
		create_tween().tween_property(picture, "scale", Vector3.ONE * 0.01, 0.5)
	await get_tree().create_timer(0.5).timeout
	item_done.emit()


## The picture trots home over the finished bridge, hopping on every plank.
func _picture_home() -> void:
	if picture == null:
		return
	var path: Array[Vector3] = []
	for i in range(slot_pos.size() - 1, -1, -1):
		path.append(slot_pos[i] + Vector3(0, 0.08, -0.15))
	var land: Vector3 = main.world.bridge_start - _bridge_dir() * 1.2
	land = main.world.on_ground(land.x, land.z)
	path.append(land)
	var start_y: float = picture.global_position.y
	var tw: Tween = create_tween()
	var on: Vector3 = main.world.bridge_end + Vector3(0, GameTune.BRIDGE_DECK_Y - 0.02, 0)
	tw.tween_property(picture, "global_position", Vector3(on.x, maxf(on.y, start_y), on.z), 0.5)
	for p: Vector3 in path:
		var mid: Vector3 = (picture.global_position + p) * 0.5
		tw.tween_property(picture, "global_position", mid + Vector3(0, 0.5, 0), 0.16)
		tw.tween_property(picture, "global_position", p, 0.16)
	await tw.finished


func _clear() -> void:
	_stop_glow()
	for st: Stone in stones:
		if is_instance_valid(st) and not slots.has(st):
			st.queue_free()
	for st2: Stone in slots:
		if st2 and is_instance_valid(st2):
			st2.queue_free()
	stones.clear()
	slots.clear()
	for s: Node3D in _sockets:
		s.queue_free()
	_sockets.clear()
	_socket_mats.clear()
	if _deck:
		_deck.queue_free()
		_deck = null
	if _raft:
		_raft.queue_free()
		_raft = null
	_drag = null
	_lit = -1


## For the screenshot bot.
func stone_screen_pos_for_slot(slot_i: int, want_right: bool) -> Vector2:
	for st: Stone in stones:
		if st.placed or not st.visible:
			continue
		if (st.letter == graphemes[slot_i]) == want_right:
			return st.screen_pos(main.rig.cam)
	return Vector2(-1, -1)


func slot_screen_pos(slot_i: int) -> Vector2:
	return main.rig.cam.unproject_position(slot_pos[slot_i])


func slot_screen_width(slot_i: int) -> float:
	var half: Vector3 = _bridge_dir() * pitch_m * GameTune.BRIDGE_SLOT_FILL * 0.5
	var a: Vector2 = main.rig.cam.unproject_position(slot_pos[slot_i] - half)
	var b: Vector2 = main.rig.cam.unproject_position(slot_pos[slot_i] + half)
	return a.distance_to(b)


## Narrowest slot on screen for a word of n letters (size check in the bot).
func min_slot_px_for(n: int) -> float:
	var p: float = _pitch_for(n)
	var mid: Vector3 = (main.world.bridge_start + main.world.bridge_end) * 0.5
	var best: float = INF
	for i in n:
		var c: Vector3 = mid + _bridge_dir() * (float(i) - float(n - 1) * 0.5) * p
		c.y = GameTune.BRIDGE_DECK_Y
		var half: Vector3 = _bridge_dir() * p * GameTune.BRIDGE_SLOT_FILL * 0.5
		var w: float = main.rig.cam.unproject_position(c - half).distance_to(
			main.rig.cam.unproject_position(c + half)
		)
		best = minf(best, w)
	return best


func first_missing() -> int:
	return _missing_from


func is_modelling() -> bool:
	return _modelling


func lit_slot() -> int:
	return _lit
