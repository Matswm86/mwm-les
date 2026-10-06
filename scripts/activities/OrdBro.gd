class_name OrdBro
extends Activity
## Ordbroa: the child lays the letter stones as a bridge that spells `lam`, so
## the lamb on the islet can walk over. Letters the child has not met yet lie
## ready as planks; the ones written in the sand today are missing (Main.plan()).
## Sound: bridge_in, bridge_word_lam (the l, a, m planks light at the measured
## sound onsets, content/nb_reading/clip_marks.json), then for each missing
## plank bridge_ask and the plank's held sound last. A stone plays its short
## sound when touched. Right: chime, bridge_right. Wrong: the stone's short
## sound, tok, the plank's held sound again. Then bridge_done, the letters
## sink into the planks, and bridge_walk while the lamb crosses.

signal slot_filled

const WORD: String = "lam"
const WORD_CLIP: String = "bridge_word_lam"
const DRAG_START_PX: float = 18.0
const STONE_LIFT: float = 0.9
const IDLE_HINT_SEC: float = 9.0

var graphemes: Array[String] = []
var stones: Array[Stone] = []
var slots: Array[Stone] = []  # filled plank per slot, null while empty
var slot_pos: Array[Vector3] = []
var missing: Array[int] = []  # slot indexes the child fills, left to right
var cur: int = -1  # slot to fill now
var busy: bool = true
var pitch_m: float = 1.4
var walking: bool = false  # the lamb crosses (screenshot bot)
var lit: int = -1  # slot lit by the sounding-out (-2 = all)
var _sockets: Array[Node3D] = []
var _socket_mats: Array[StandardMaterial3D] = []
var _deck: MeshInstance3D
var _raft: MeshInstance3D
var _drag: Stone
var _drag_from: Vector2
var _dragging: bool = false
var _t: float = 0.0
var _idle: float = 0.0


func activity_id() -> String:
	return "ordbro"


func hub_line() -> String:
	return "hub_bridge"


func camera_pose() -> Dictionary:
	var w: World = main.world
	var mid: Vector3 = (w.bridge_start + w.bridge_end) * 0.5
	return {
		"target": mid + GameTune.BRIDGE_CAM_OFFSET,
		"distance": GameTune.BRIDGE_CAM_DISTANCE,
		"pitch": GameTune.BRIDGE_CAM_PITCH_DEG
	}


func begin() -> void:
	super.begin()
	_clear()
	main.pip.home_offset = GameTune.PIP_BRIDGE_OFFSET
	main.hide_pile()
	var plan: Dictionary = main.plan()
	graphemes.clear()
	for c: String in WORD:
		graphemes.append(c)
	var n: int = graphemes.size()
	_layout_slots(n)
	_build_deck()
	missing.clear()
	for i in n:
		slots.append(null)
		_add_socket(i)
		if (plan["missing"] as Array).has(graphemes[i]):
			missing.append(i)
		else:
			_preplace(i)
	var row: Array[String] = []
	for l: Variant in plan["stones"]:
		row.append(str(l))
	row.shuffle()  # the right stone is not always first on the raft
	_place_stones(row)
	_place_lamb()


func run() -> void:
	active = true
	await wait(0.9)
	_mark("in")
	await say_wait(["bridge_in"], 0.2)
	await _sound_out()
	for i: int in missing:
		cur = i
		_ask()
		if Game.demo_due(activity_id()):
			_show_ghost()
		await slot_filled
	cur = -1
	busy = true
	lit = -2
	_mark("done")
	main.burst(slot_pos[slot_pos.size() / 2] + Vector3(0, 0.8, 0))
	await say_wait(["bridge_done"], 0.2)
	lit = -1
	_sink_letters()
	for st: Stone in stones:  # the spare stone and the raft go away too
		if not st.placed:
			create_tween().tween_property(st, "global_position:y", st.global_position.y - 2.0, 0.5)
	if _raft:
		create_tween().tween_property(_raft, "position:y", _raft.position.y - 2.0, 0.5)
	await wait(0.6)
	var sec: float = Voice.say(["bridge_walk"])
	walking = true
	_mark("walk")
	await _lamb_home()
	walking = false
	await wait(maxf(0.0, sec - 2.0))
	await Voice.wait_idle()
	active = false


func end() -> void:
	super.end()
	main.pip.home_offset = GameTune.PIP_SCREEN_OFFSET
	_clear()


## The word clip: each plank lights at its sound, all of them at the word.
func _sound_out() -> void:
	busy = true
	var total: float = Voice.say([WORD_CLIP])
	_mark("word")
	var marks: Array[float] = Voice.marks(WORD_CLIP)
	var n: int = graphemes.size()
	if marks.size() != n:
		marks.clear()
		for i in n:
			marks.append(Voice.length(WORD_CLIP) * float(i) / float(n))
	var t0: float = 0.0
	for i in n:
		await wait(marks[i] - t0)
		t0 = marks[i]
		lit = i
		if slots[i]:
			slots[i].glyph.pop()
		_mark("lit_%d" % i)
	var w_at: float = Voice.word_at(WORD_CLIP)
	if w_at > t0:
		await wait(w_at - t0)
		t0 = w_at
		lit = -2
	await wait(maxf(total - t0, 0.0))
	lit = -1


func _ask() -> void:
	var ids: Array[String] = ["bridge_ask", Voice.held_id(graphemes[cur])]
	Voice.say(ids)
	_idle = 0.0
	busy = false
	_mark("ask")


## Pip and the speaker button: the question and the plank's sound again.
func replay() -> void:
	if busy or cur < 0:
		return
	_ask()


# ---------------------------------------------------------------- input


func touch(event: InputEvent) -> void:
	if busy:
		return
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		if t.pressed:
			_drag = _stone_at(t.position)
			_drag_from = t.position
			_dragging = false
			if _drag:
				grab(_drag)
		elif _drag:
			var st: Stone = _drag
			_drag = null
			if _dragging:
				var si: int = _slot_at(t.position)
				if si >= 0:
					drop(st, si)
				else:
					st.slide_home()
			else:
				st.slide_home()
	elif event is InputEventScreenDrag and _drag:
		var d: InputEventScreenDrag = event as InputEventScreenDrag
		if not _dragging and d.position.distance_to(_drag_from) > DRAG_START_PX:
			_dragging = true
		if _dragging:
			var p: Vector3 = main.rig.ground_point(d.position + Vector2(0, 40), STONE_LIFT)
			_drag.global_position = p - Vector3(0, 0.3, 0)
			_idle = 0.0


## A finger lands on a stone: it says its short sound.
func grab(st: Stone) -> void:
	_idle = 0.0
	main.hud.ghost.stop()
	Voice.say([Voice.short_id(st.letter)])
	st.glyph.tap_bounce()


## A stone is let go over slot `si` (the touch path and the test land here).
func drop(st: Stone, si: int) -> void:
	if busy or st.placed:
		return
	if si != cur:
		st.slide_home()
		return
	busy = true
	_seq += 1
	main.hud.ghost.stop()
	if st.letter == graphemes[si]:
		Game.mark_demo(activity_id())
		_place(st, si)
		_mark("right")
		await Voice.wait_idle()  # the stone's own sound from the grab ends first
		await say_wait([Voice.chime_id(), "bridge_right"], 0.2)
		slot_filled.emit()
	else:
		_mark("wrong")
		var tw: Tween = create_tween()
		tw.tween_property(st, "global_position", slot_pos[si] + Vector3(0, 0.25, 0), 0.2)
		var sec: float = Voice.say([Voice.short_id(st.letter)])
		st.wobble()
		await wait(sec + LetterRules.AFTER_CLIP_GAP_SEC)
		st.slide_home()
		await say_wait(["sfx_tok"], 0.1)
		Voice.say([Voice.held_id(graphemes[si])])
		_idle = 0.0
		busy = false


func _process(delta: float) -> void:
	_t += delta
	_glow()
	if active and not busy and cur >= 0 and not Voice.is_busy() and _drag == null:
		_idle += delta
		if _idle >= IDLE_HINT_SEC:
			_idle = 0.0
			_show_ghost()
			replay()


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


func _slot_at(pos: Vector2) -> int:
	var best: int = -1
	var best_d: float = INF
	for i in slots.size():
		if slots[i] != null:
			continue
		var d: float = pos.distance_to(slot_screen_pos(i))
		if d < _slot_radius_px(i) and d < best_d:
			best_d = d
			best = i
	return best


func _slot_radius_px(i: int) -> float:
	var sp: Vector2 = slot_screen_pos(i)
	var edge: Vector2 = main.rig.cam.unproject_position(slot_pos[i] + _bridge_dir() * pitch_m * 0.5)
	return maxf(LearnBalance.SNAP_RADIUS_PX, sp.distance_to(edge) * 1.3)


func _place(st: Stone, si: int) -> void:
	slots[si] = st
	_sockets[si].visible = false
	st.home = slot_pos[si]
	st.scale = Vector3.ONE * GameTune.BRIDGE_STONE_SCALE
	create_tween().tween_property(st, "global_position", slot_pos[si], 0.25)
	st.become_plank(pitch_m * GameTune.BRIDGE_SLOT_FILL / GameTune.BRIDGE_STONE_SCALE)
	main.burst(slot_pos[si] + Vector3(0, 0.6, 0))


## The ghost hand drags the right stone to the plank to fill, again and again.
func _show_ghost() -> void:
	if cur < 0:
		return
	var want: String = graphemes[cur]
	main.hud.ghost.drag(
		func() -> Vector2:
			var st: Stone = stone_for(want)
			return st.screen_pos(main.rig.cam) if st else Vector2(-500, -500),
		func() -> Vector2: return slot_screen_pos(maxi(cur, 0))
	)


# ---------------------------------------------------------------- glow


func _glow() -> void:
	for i in _sockets.size():
		var sock: Node3D = _sockets[i]
		if not sock.visible:
			continue
		var hm: ShaderMaterial = sock.get_meta("halo")
		var dashes: MeshInstance3D = sock.get_meta("dashes")
		var k: float = 0.5 + 0.5 * sin(_t * TAU / GameTune.HINT_PULSE_PERIOD_SEC)
		var strength: float = 0.25 + 0.15 * k
		var bright: float = 0.75
		dashes.scale = Vector3.ONE
		if i == lit or lit == -2:
			strength = 1.0
			bright = 1.0
		elif i == cur and not busy:
			strength = 0.45 + 0.4 * k
			bright = 0.8 + 0.2 * k
			dashes.scale = Vector3.ONE * (1.0 + 0.06 * k)
		hm.set_shader_parameter("strength", strength)
		_socket_mats[i].albedo_color = (
			Color(1.0, 0.86, 0.25) * bright + Color(0, 0, 0, 1) * (1.0 - bright)
		)
	for i in slots.size():
		if slots[i] and slots[i].glyph:
			slots[i].glyph.hint_pulse = i == lit or lit == -2


# ---------------------------------------------------------------- layout


func _bridge_dir() -> Vector3:
	return (main.world.bridge_end - main.world.bridge_start).normalized()


func _layout_slots(n: int) -> void:
	var a: Vector3 = main.world.bridge_start
	var b: Vector3 = main.world.bridge_end
	var length: float = a.distance_to(b)
	pitch_m = clampf(
		(length - 2.0 * GameTune.BRIDGE_END_MARGIN_M) / float(n),
		GameTune.BRIDGE_PITCH_MIN_M,
		GameTune.BRIDGE_PITCH_MAX_M
	)
	var mid: Vector3 = (a + b) * 0.5
	slot_pos.clear()
	for i in n:
		var off: float = (float(i) - float(n - 1) * 0.5) * pitch_m
		var p: Vector3 = mid + _bridge_dir() * off
		p.y = GameTune.BRIDGE_DECK_Y
		slot_pos.append(p)


## Fixed deck boards from each end of the bridge to the letter planks.
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


## The stones written today in a neat row on a raft along the bottom.
func _place_stones(letters: Array[String]) -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var n: int = letters.size()
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


## The lamb waits on the islet, at a fixed place on screen right of the
## bridge end, so it is always fully visible from the bridge camera.
func _place_lamb() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var feet: Vector2 = Vector2(
		vp.x - GameTune.PICTURE_FROM_RIGHT_PX, vp.y * GameTune.PICTURE_FEET_Y
	)
	var pose: Dictionary = camera_pose()
	# the camera may still be flying: place by the station pose, not the live camera
	var cam: Camera3D = Camera3D.new()
	cam.fov = GameTune.CAM_FOV
	add_child(cam)
	var p: float = deg_to_rad(float(pose["pitch"]))
	var tgt: Vector3 = pose["target"]
	cam.global_position = tgt + Vector3(0, sin(p), cos(p)) * float(pose["distance"])
	cam.look_at(tgt, Vector3.UP)
	var o: Vector3 = cam.project_ray_origin(feet)
	var d: Vector3 = cam.project_ray_normal(feet)
	cam.queue_free()
	var spot: Vector3 = o + d * ((GameTune.BRIDGE_DECK_Y - o.y) / d.y)
	spot = main.world.on_ground(spot.x, spot.z)
	main.lamb.global_position = spot
	main.lamb.rotation.y = PI  # faces the main island, ready to come over


## Every letter sinks into its plank, so the lamb never walks through one.
func _sink_letters() -> void:
	for st: Stone in slots:
		if st and st.glyph:
			var g: GlowLetter = st.glyph
			var tw: Tween = create_tween()
			tw.tween_property(g, "position:y", g.position.y - 1.6, 0.5).set_trans(Tween.TRANS_SINE)
			tw.tween_callback(g.hide)


## The lamb trots home over the planks, a hop on every one, and stops on the
## main island next to Pip.
func _lamb_home() -> void:
	var lamb: Node3D = main.lamb
	var path: Array[Vector3] = []
	var on: Vector3 = main.world.bridge_end
	on.y = GameTune.BRIDGE_DECK_Y
	path.append(on)
	for i in range(slot_pos.size() - 1, -1, -1):
		path.append(slot_pos[i] + Vector3(0, 0.08, 0))
	var land: Vector3 = main.world.bridge_start - _bridge_dir() * 1.4
	path.append(main.world.on_ground(land.x, land.z))
	var tw: Tween = create_tween()
	var prev: Vector3 = lamb.global_position
	for p: Vector3 in path:
		var mid: Vector3 = (prev + p) * 0.5
		var half: float = maxf(0.22, prev.distance_to(p) * 0.09)
		tw.tween_property(lamb, "global_position", mid + Vector3(0, 0.4, 0), half)
		tw.tween_property(lamb, "global_position", p, half)
		prev = p
	await tw.finished


func _clear() -> void:
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
	lit = -1
	cur = -1
	busy = true


# ---------------------------------------------------------------- bot helpers


func stone_for(l: String) -> Stone:
	for st: Stone in stones:
		if not st.placed and st.visible and st.letter == l:
			return st
	return null


func slot_screen_pos(si: int) -> Vector2:
	return main.rig.cam.unproject_position(slot_pos[si])
