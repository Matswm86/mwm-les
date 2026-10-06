class_name OrdBro
extends Activity
## Ordbroa: the child lays the letter stones as a bridge of words, so the lamb
## on the islet can walk over. Today's words come from Main.plan() (up to two
## story words, lam always last). All their slots are laid out along the
## bridge from the island side; a word's sockets appear when its turn comes,
## so the bridge grows toward the islet word by word, and the islet end of the
## deck is laid when lam is done. Letters the child has not met (or beyond
## today's writing cap) lie ready as planks; the ones written today are missing.
## Sound: bridge_in. Per word: hook_<w> while its picture shows, then
## bridge_word_<w> (its planks light at the measured sound onsets,
## content/nb_reading/clip_marks.json), then for each missing plank bridge_ask
## and the plank's held sound last. A stone plays its short sound when
## touched. Right: chime, bridge_right. Wrong: the stone's short sound, tok,
## the plank's held sound again. A finished word that is not the last:
## bridge_word_done, its letters sink into the planks, bridge_next. The last
## word (lam): bridge_done, the letters sink, bridge_walk while the lamb crosses.

signal slot_filled
const DRAG_START_PX: float = 18.0
const STONE_LIFT: float = 0.9
const IDLE_HINT_SEC: float = 9.0

var words: Array[Dictionary] = []  # today's words: {id, letters, missing (slot in word)}
var word_i: int = -1  # the word being built now
var word_start: Array[int] = []  # first slot of each word
var graphemes: Array[String] = []  # every slot's letter, all words in bridge order
var word_of: Array[int] = []  # slot -> word index
var built: Array[String] = []  # words finished this visit
var picture: Node3D  # the current word's hook picture
var stones: Array[Stone] = []
var slots: Array[Stone] = []  # filled plank per slot, null while empty
var slot_pos: Array[Vector3] = []
var missing: Array[int] = []  # slot indexes the child fills, left to right
var cur: int = -1  # slot to fill now
var busy: bool = true
var pitch_m: float = 1.4
var walking: bool = false  # the lamb crosses (screenshot bot)
var lit: int = -1  # slot lit by the sounding-out (-2 = all)
var stone_scale: float = GameTune.BRIDGE_STONE_SCALE  # planks and letters shrink with the pitch
var _sockets: Array[Node3D] = []  # per slot, null until its word starts or once filled
var _socket_mats: Array[StandardMaterial3D] = []
var _decks: Array[MeshInstance3D] = []
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
	words.clear()
	graphemes.clear()
	word_of.clear()
	word_start.clear()
	built.clear()
	for w: Variant in plan["words"]:
		var wd: Dictionary = w
		words.append(wd)
		word_start.append(graphemes.size())
		for l: Variant in wd["letters"]:
			graphemes.append(str(l))
			word_of.append(words.size() - 1)
	var n: int = graphemes.size()
	_layout_slots(n)
	_build_deck(-0.4, _edge(0, true))  # the island end; the rest grows word by word
	missing.clear()
	for i in n:
		slots.append(null)
		_sockets.append(null)
		_socket_mats.append(null)
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
	for k in words.size():
		await _build_word(k)
		if k < words.size() - 1:
			cur = -1
			busy = true
			lit = -3  # the finished word's planks
			_mark("word_done")
			main.burst(slot_pos[_word_mid(k)] + Vector3(0, 0.8, 0))
			await say_wait(["bridge_word_done"], 0.2)
			lit = -1
			_sink_letters(k)
			_drop_picture()
			_build_deck(_edge(word_start[k + 1] - 1, false), _edge(word_start[k + 1], true))
			_mark("next")
			await say_wait(["bridge_next"], 0.2)
	cur = -1
	busy = true
	_drop_picture()
	var length: float = main.world.bridge_start.distance_to(main.world.bridge_end)
	_build_deck(_edge(graphemes.size() - 1, false), length + 0.4)  # the bridge reaches the islet
	lit = -2
	_mark("done")
	main.burst(slot_pos[slot_pos.size() / 2] + Vector3(0, 0.8, 0))
	await say_wait(["bridge_done"], 0.2)
	lit = -1
	_sink_letters(words.size() - 1)
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


## One word: its picture and story line, its sockets and ready planks, the
## sounding-out, then each missing plank.
func _build_word(k: int) -> void:
	word_i = k
	busy = true
	var id: String = str(words[k]["id"])
	_show_picture(id)
	_mark("hook")
	await say_wait([BridgeWords.hook_clip(id)], 0.3)
	missing.clear()
	var miss: Array = words[k]["missing"]
	for j in (words[k]["letters"] as Array).size():
		var si: int = word_start[k] + j
		_add_socket(si)
		if miss.has(j):
			missing.append(si)
		else:
			_preplace(si)
	await wait(0.4)
	await _sound_out(k)
	for i: int in missing:
		cur = i
		_ask()
		if Game.demo_due(activity_id()):
			_show_ghost()
		await slot_filled
	built.append(id)


## The word clip: each plank lights at its sound, all of them at the word.
func _sound_out(k: int) -> void:
	busy = true
	var clip: String = BridgeWords.word_clip(str(words[k]["id"]))
	var total: float = Voice.say([clip])
	_mark("word")
	var n: int = (words[k]["letters"] as Array).size()
	var marks: Array[float] = Voice.marks(clip)
	if marks.size() != n:
		marks.clear()
		for i in n:
			marks.append(Voice.length(clip) * float(i) / float(n))
	var t0: float = 0.0
	for j in n:
		var i: int = word_start[k] + j
		await wait(marks[j] - t0)
		t0 = marks[j]
		lit = i
		if slots[i]:
			slots[i].glyph.pop()
		_mark("lit_%d" % i)
	var w_at: float = Voice.word_at(clip)
	if w_at > t0:
		await wait(w_at - t0)
		t0 = w_at
		lit = -3
	await wait(maxf(total - t0, 0.0))
	lit = -1


## Lit by the sounding-out: slot i alone, the current word (-3), everything (-2).
func _is_lit(i: int) -> bool:
	return i == lit or lit == -2 or (lit == -3 and word_of[i] == word_i)


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


## A stone under the finger wins over Pip next to the raft.
func claims_touch(pos: Vector2) -> bool:
	return not busy and _stone_at(pos) != null


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
	st.scale = Vector3.ONE * stone_scale
	create_tween().tween_property(st, "global_position", slot_pos[si], 0.25)
	st.become_plank(pitch_m * GameTune.BRIDGE_SLOT_FILL / stone_scale)
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
		if sock == null or not sock.visible:
			continue
		var hm: ShaderMaterial = sock.get_meta("halo")
		var dashes: MeshInstance3D = sock.get_meta("dashes")
		var k: float = 0.5 + 0.5 * sin(_t * TAU / GameTune.HINT_PULSE_PERIOD_SEC)
		var strength: float = 0.25 + 0.15 * k
		var bright: float = 0.75
		dashes.scale = Vector3.ONE
		if _is_lit(i):
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
			slots[i].glyph.hint_pulse = _is_lit(i)


# ---------------------------------------------------------------- layout


func _bridge_dir() -> Vector3:
	return (main.world.bridge_end - main.world.bridge_start).normalized()


## Every slot of today's words along the bridge, centred, a short deck gap
## between two words. With several words the pitch goes below
## BRIDGE_PITCH_MIN_M (down to BRIDGE_PITCH_MULTI_MIN_M) and the planks and
## letters shrink with it.
func _layout_slots(n: int) -> void:
	var a: Vector3 = main.world.bridge_start
	var b: Vector3 = main.world.bridge_end
	var length: float = a.distance_to(b)
	var gaps: float = GameTune.BRIDGE_WORD_GAP_M * float(maxi(words.size() - 1, 0))
	var floor_m: float = (
		GameTune.BRIDGE_PITCH_MIN_M if words.size() <= 1 else GameTune.BRIDGE_PITCH_MULTI_MIN_M
	)
	pitch_m = clampf(
		(length - 2.0 * GameTune.BRIDGE_END_MARGIN_M - gaps) / float(n),
		floor_m,
		GameTune.BRIDGE_PITCH_MAX_M
	)
	stone_scale = GameTune.BRIDGE_STONE_SCALE * minf(1.0, pitch_m / GameTune.BRIDGE_FULL_PITCH_M)
	var total: float = pitch_m * float(n) + gaps
	var x0: float = (length - total) * 0.5
	slot_pos.clear()
	for i in n:
		var x: float = (
			x0 + pitch_m * (float(i) + 0.5) + GameTune.BRIDGE_WORD_GAP_M * float(word_of[i])
		)
		var p: Vector3 = a + _bridge_dir() * x
		p.y = GameTune.BRIDGE_DECK_Y
		slot_pos.append(p)


## Distance along the bridge of slot i's island-side (or islet-side) edge.
func _edge(i: int, near: bool) -> float:
	var x: float = main.world.bridge_start.distance_to(slot_pos[i])
	return x - pitch_m * 0.5 if near else x + pitch_m * 0.5


func _word_mid(k: int) -> int:
	return word_start[k] + (words[k]["letters"] as Array).size() / 2


## Fixed deck boards between two distances along the bridge.
func _build_deck(from_x: float, to_x: float) -> void:
	var a: Vector3 = main.world.bridge_start
	var dir: Vector3 = _bridge_dir()
	var parts: Array = []
	var yaw: float = rad_to_deg(atan2(-dir.z, dir.x))
	var x: float = from_x
	while x < to_x - 0.1:
		var p: Vector3 = a + dir * (x + 0.15)
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
	var deck: MeshInstance3D = MeshKit.instance(
		MeshKit.merge(parts), MeshKit.with_outline(MeshKit.toon(), 0.003), self
	)
	deck.scale = Vector3(1, 0.2, 1)
	create_tween().tween_property(deck, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	_decks.append(deck)


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
	_sockets[i] = root
	_socket_mats[i] = mat


func _preplace(i: int) -> void:
	var st: Stone = Stone.new()
	st.setup(graphemes[i], Game.skill_for_label(graphemes[i]))
	add_child(st)
	st.scale = Vector3.ONE * stone_scale
	st.global_position = slot_pos[i]
	st.home = slot_pos[i]
	st.become_plank(pitch_m * GameTune.BRIDGE_SLOT_FILL / stone_scale)
	slots[i] = st
	_sockets[i].visible = false


## The stones written today in a neat row on a raft along the bottom.
func _place_stones(letters: Array[String]) -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var n: int = letters.size()
	var gap: float = minf(GameTune.BRIDGE_STONE_GAP_PX, (vp.x - 360.0) / float(maxi(n, 1)))
	var k_size: float = gap / GameTune.BRIDGE_STONE_GAP_PX
	if k_size < 1.0:  # wide letters (m, b) would touch their neighbours
		k_size *= GameTune.BRIDGE_STONE_CROWD_SCALE
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


## The letters of word k sink into their planks, so the lamb never walks
## through one; the planks stay as built bridge.
func _sink_letters(k: int) -> void:
	for i in slots.size():
		var st: Stone = slots[i]
		if word_of[i] == k and st and st.glyph:
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
		if s:
			s.queue_free()
	_sockets.clear()
	_socket_mats.clear()
	for d: MeshInstance3D in _decks:
		d.queue_free()
	_decks.clear()
	if picture:
		picture.queue_free()
		picture = null
	word_i = -1
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


# ---------------------------------------------------------------- word pictures


## The picture that goes with word `id`'s story line pops up: the sun in the
## sky, a seal and a boat in the water, food by the lamb, a book by Pip. lam:
## the lamb itself hops.
func _show_picture(id: String) -> void:
	_drop_picture()
	var kind: String = str((BridgeWords.WORDS.get(id, {}) as Dictionary).get("picture", ""))
	if kind == "lamb":
		var l: Node3D = main.lamb
		var y0: float = l.global_position.y
		var hop: Tween = create_tween()
		for k in 2:
			hop.tween_property(l, "global_position:y", y0 + 0.5, 0.18).set_trans(Tween.TRANS_SINE)
			hop.tween_property(l, "global_position:y", y0, 0.18).set_trans(Tween.TRANS_SINE)
		return
	var pic: Node3D = Props.make(kind)
	if pic == null:
		return
	add_child(pic)
	var spot: Dictionary = GameTune.WORD_PICTURES.get(kind, {})
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var cam: Camera3D = main.rig.cam
	var at: Vector2 = spot.get("screen", Vector2(0.5, 0.4))
	var scr: Vector2 = Vector2(at.x * vp.x, at.y * vp.y)
	var where: String = str(spot.get("on", "water"))
	if where == "sky":
		pic.global_position = (
			cam.project_ray_origin(scr)
			+ cam.project_ray_normal(scr) * float(spot.get("dist", 14.0))
		)
	elif where == "pip":
		pic.global_position = (
			cam.global_transform * (main.pip.home_offset + spot.get("off", Vector3.ZERO))
		)
	else:
		var g: Vector3 = main.rig.ground_point(scr, 0.0)
		if where == "ground":  # the ray meets the raised ground nearer than the sea level
			for k in 3:
				g = main.rig.ground_point(scr, main.world.ground_y(g))
			g = main.world.on_ground(g.x, g.z)
		pic.global_position = g
	var face: Vector3 = cam.global_position - pic.global_position
	pic.rotation.y = atan2(face.x, face.z) + deg_to_rad(float(spot.get("turn", 0.0)))
	var size: float = float(spot.get("scale", 1.0))
	pic.scale = Vector3.ONE * 0.01
	(
		create_tween()
		. tween_property(pic, "scale", Vector3.ONE * size, 0.45)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	if kind == "boat":  # it sails slowly across the bay
		var tw: Tween = create_tween()
		var side: Vector3 = cam.global_basis.x
		side.y = 0.0
		tw.tween_property(
			pic, "global_position", pic.global_position + side.normalized() * 2.5, 8.0
		)
	picture = pic


func _drop_picture() -> void:
	if picture == null:
		return
	var pic: Node3D = picture
	picture = null
	var tw: Tween = create_tween()
	tw.tween_property(pic, "scale", Vector3.ONE * 0.01, 0.35).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_IN
	)
	tw.tween_callback(pic.queue_free)
