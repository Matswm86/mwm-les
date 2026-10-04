class_name HorOgFinn
extends Activity
## Hør og finn (GDD 6.2). Pip: "Hvor er /sss/? Trykk på /sss/!" The child
## taps the matching letter among 2-3 big, front-facing letters, each on its
## own round sand tile. The first time a letter is met, an intro beat comes
## first (period 1): the capital and small letter alone in the middle, Pip
## names it once and says its sound, the child taps the small one.
## Hints are unmistakable: the right letter jumps, grows 1.4x and glows with a
## ring; after the second miss the ghost hand taps it. Wrong = the letter says
## its own sound and wobbles (control of error). Right = big pop, the letter
## flies to Pip, Pip says the sound again.

var letters: Array[GlowLetter] = []
var target: GlowLetter
var target_skill: String = ""
var flower: SleepyFlower
var _skill_of: Dictionary = {}  # GlowLetter -> skill id
var _tiles: Array[Node3D] = []
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _emphasis: Tween
var _explained_wrong: bool = false
var _correct_total: int = 0
var _intro_letter: GlowLetter  # the tappable small letter during the intro beat
var _intro_nodes: Array[Node3D] = []
var _intro_tapped: bool = false


func activity_id() -> String:
	return "hor_og_finn"


func camera_pose() -> Dictionary:
	return {
		"target": _center() + Vector3(0, GameTune.FIND_CAM_LIFT, 0),
		"distance": GameTune.FIND_CAM_DISTANCE,
		"pitch": GameTune.FIND_CAM_PITCH_DEG
	}


func _center() -> Vector3:
	return main.world.zone_centers[0]


func _right() -> Vector3:
	var r: Vector3 = main.rig.cam.global_basis.x
	r.y = 0.0
	return r.normalized()


func begin_visit() -> void:
	super.begin_visit()
	if flower == null:
		flower = SleepyFlower.new()
		add_child(flower)
		flower.global_position = main.world.flower_spot
		flower.scale = Vector3.ONE * 1.6
	flower.rotation.y = main.rig.cam.global_rotation.y
	flower.visible = true
	flower.sleep_now()


func end_visit() -> void:
	super.end_visit()
	main.pip.go_home()
	main.hud.ghost.stop()
	_clear()
	_clear_intro()


# ---------------------------------------------------------------- story


func story_intro(first_task: Dictionary) -> void:
	var sk: String = str(first_task.get("skill", ""))
	main.pip.point_at(flower.global_position + Vector3(0, 2.0, 0))
	var d: float = Voice.say(["story_find_1", Game.phoneme_clip(sk), "story_find_2"])
	await get_tree().create_timer(d + 0.2).timeout
	main.pip.go_home()


func story_payoff() -> void:
	main.pip.point_at(flower.global_position + Vector3(0, 2.0, 0))
	flower.wake()
	main.burst(flower.global_position + Vector3(0, 2.3, 0))
	Voice.sfx("fanfare")
	var d: float = Voice.say(["payoff_find"])
	await get_tree().create_timer(maxf(d, 2.0) + 0.6).timeout
	main.pip.go_home()


# ---------------------------------------------------------------- item


func start_item(p_item: Dictionary, p_format: Dictionary, hint_start: int) -> void:
	super.start_item(p_item, p_format, hint_start)
	active = false
	_clear()
	_explained_wrong = false
	target_skill = Game.engine.tested_skills(item)[0]
	var letter: String = Game.label(target_skill)
	if not Game.named_letters.has(letter):
		await _intro_beat(letter)
	# the intro beat (or an earlier one) did the modelling; the child gets a
	# fair first try and the ladder climbs from here on a miss or idle
	hints.level = 0
	hints.highest = 0
	var skills: Array[String] = [target_skill]
	for dsk: Variant in format.get("distractors", []):
		skills.append(str(dsk))
	skills.shuffle()
	last_choices = skills.size()
	var spacing: float = GameTune.FIND_SPACING_M * (1.0 if skills.size() <= 2 else 0.85)
	for i in skills.size():
		var off: float = (float(i) - float(skills.size() - 1) * 0.5) * spacing
		var p: Vector3 = _tile_spot(_center() + _right() * off)
		_add_tile(p, 0.12 * float(i))
		var gl: GlowLetter = GlowLetter.new()
		gl.setup(Game.label(skills[i]), GameTune.FIND_LETTER_M)
		gl.idle_motion = false
		add_child(gl)
		gl.global_position = p + Vector3(0, GameTune.TILE_TOP_M, 0)
		gl.set_base_y(gl.position.y)
		gl.rotation.y = main.rig.cam.global_rotation.y
		gl.rise_from(2.6, 0.12 * float(i))
		letters.append(gl)
		_skill_of[gl] = skills[i]
		if skills[i] == target_skill:
			target = gl
	await get_tree().create_timer(0.8).timeout
	_say_prompt()
	active = true


func _say_prompt() -> void:
	var ph: String = Game.phoneme_clip(target_skill)
	mark_prompt_end(Voice.say(["find_where", ph, "find_tap", ph], true))


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


# ---------------------------------------------------------------- intro beat (period 1)


## Capital behind-left, small letter in front, alone in the middle. Pip names
## the letter once ("Denne heter ess. Store S og lille s. De sier sss.") and
## the child taps the small one. The first time ever, the ghost hand shows it.
func _intro_beat(letter: String) -> void:
	_intro_tapped = false
	var c: Vector3 = _tile_spot(_center())
	_add_tile(c, 0.0)
	var big: GlowLetter = GlowLetter.new()
	big.setup(letter.to_upper(), GameTune.FIND_LETTER_M * 1.05)
	big.idle_motion = false
	add_child(big)
	big.global_position = c - _right() * 0.95 + Vector3(0, GameTune.TILE_TOP_M, -0.7)
	big.set_base_y(big.position.y)
	big.rotation.y = main.rig.cam.global_rotation.y
	big.rise_from(2.6, 0.0)
	var small: GlowLetter = GlowLetter.new()
	small.setup(letter, GameTune.FIND_LETTER_M)
	small.idle_motion = false
	add_child(small)
	small.global_position = c + _right() * 0.75 + Vector3(0, GameTune.TILE_TOP_M, 0.35)
	small.set_base_y(small.position.y)
	small.rotation.y = main.rig.cam.global_rotation.y
	small.rise_from(2.6, 0.15)
	_intro_nodes = [big, small]
	_intro_letter = small
	await get_tree().create_timer(0.8).timeout
	var ph: String = Game.phoneme_clip(Game.skill_for_label(letter))
	var d: float = Voice.say(["intro_" + letter, "de_sier", ph, "tap_small"], true)
	big.pop()
	await get_tree().create_timer(d * 0.45).timeout
	small.pop()
	await get_tree().create_timer(d * 0.55).timeout
	active = true
	if Game.demo_due(activity_id()):
		main.hud.ghost.tap(func() -> Vector2: return small.screen_pos(main.rig.cam))
	var waited: float = 0.0
	while not _intro_tapped:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if waited > LearnBalance.IDLE_HINT_SEC and not main.hud.ghost.showing():
			main.hud.ghost.tap(func() -> Vector2: return small.screen_pos(main.rig.cam))
			Voice.repeat_prompt()
	active = false
	main.hud.ghost.stop()
	Game.mark_demo(activity_id())
	Game.named_letters.append(letter)
	Game.save()
	Voice.say([ph])
	small.pop()
	main.burst(small.center_world())
	Voice.chime()
	await get_tree().create_timer(1.4).timeout
	for n: Node3D in _intro_nodes:
		(n as GlowLetter).sink(4.5)
	await get_tree().create_timer(0.6).timeout
	_clear_intro()
	_clear_tiles()


func _clear_intro() -> void:
	for n: Node3D in _intro_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_intro_nodes.clear()
	_intro_letter = null


# ---------------------------------------------------------------- hints


func apply_hint(level: int) -> void:
	if target == null:
		return
	if level >= 1:
		_say_prompt()
		_emphasize()
	if level >= 2:
		main.pip.point_at(target.center_world())
		main.hud.ghost.tap(func() -> Vector2: return target.screen_pos(main.rig.cam))


## The right letter jumps, grows to 1.4x and glows bright inside a gold ring.
func _emphasize() -> void:
	if _emphasis and _emphasis.is_valid():
		return
	target.hint_pulse = true
	create_tween().tween_property(target, "scale", Vector3.ONE * 1.4, 0.3).set_trans(
		Tween.TRANS_BACK
	)
	_emphasis = create_tween().set_loops()
	var y0: float = target.position.y
	(
		_emphasis
		. tween_property(target, "position:y", y0 + 0.7, 0.28)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	_emphasis.tween_property(target, "position:y", y0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN
	)
	_emphasis.tween_interval(0.35)
	if _ring == null:
		var torus: TorusMesh = TorusMesh.new()
		torus.inner_radius = GameTune.TILE_RADIUS_M * 0.92
		torus.outer_radius = GameTune.TILE_RADIUS_M * 1.12
		torus.rings = 40
		torus.ring_segments = 8
		_ring_mat = StandardMaterial3D.new()
		_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ring_mat.albedo_color = Color(1.0, 0.92, 0.35)
		_ring = MeshKit.instance(torus, _ring_mat, self)
		_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = true
	_ring.global_position = Vector3(
		target.global_position.x, target.global_position.y - 0.05, target.global_position.z
	)
	_ring.scale = Vector3(1, 0.4, 1)
	var pulse: Tween = create_tween().set_loops()
	pulse.tween_property(_ring, "scale", Vector3(1.12, 0.4, 1.12), 0.45)
	pulse.tween_property(_ring, "scale", Vector3(0.95, 0.4, 0.95), 0.45)
	_ring.set_meta("pulse", pulse)


func _stop_emphasis() -> void:
	if _emphasis and _emphasis.is_valid():
		_emphasis.kill()
	_emphasis = null
	if _ring:
		if _ring.has_meta("pulse"):
			var pt: Tween = _ring.get_meta("pulse")
			if pt and pt.is_valid():
				pt.kill()
		_ring.visible = false


# ---------------------------------------------------------------- input


func touch(event: InputEvent) -> void:
	if not active or frozen:
		return
	var t: InputEventScreenTouch = event as InputEventScreenTouch
	if t == null or not t.pressed:
		return
	if _intro_letter:
		var r: float = _intro_letter.screen_radius(main.rig.cam)
		if t.position.distance_to(_intro_letter.screen_pos(main.rig.cam)) < r:
			_intro_tapped = true
		return
	var hit: GlowLetter = _letter_at(t.position)
	if hit == null:
		return
	reset_idle()
	main.hud.ghost.stop()
	if hit == target:
		_on_right()
	else:
		_on_wrong(hit)


## Nearest visible letter whose touch radius covers the point.
func _letter_at(pos: Vector2) -> GlowLetter:
	var best: GlowLetter = null
	var best_d: float = INF
	for gl: GlowLetter in letters:
		if not gl.visible:
			continue
		var d: float = pos.distance_to(gl.screen_pos(main.rig.cam))
		if d < gl.screen_radius(main.rig.cam) and d < best_d:
			best_d = d
			best = gl
	return best


func _on_right() -> void:
	active = false
	report([target_skill], true, hints.level)
	Voice.stop()
	_stop_emphasis()
	target.hint_pulse = false
	Voice.sound(Game.phoneme_clip(target_skill))
	main.burst(target.center_world())
	Voice.chime()
	# big pop
	var pop: Tween = create_tween()
	(
		pop
		. tween_property(target, "scale", Vector3.ONE * 1.7, 0.22)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	for gl: GlowLetter in letters:
		if gl != target:
			var sk: Tween = gl.sink(4.5)
			sk.tween_callback(gl.hide)
	await pop.finished
	await get_tree().create_timer(0.25).timeout
	# the letter flies to Pip, Pip says its sound again
	var to: Vector3 = main.pip.global_position + Vector3(0, 0.2, 0)
	var fly: Tween = create_tween().set_parallel(true)
	fly.tween_property(target, "global_position", to, 0.6).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN
	)
	fly.tween_property(target, "scale", Vector3.ONE * 0.2, 0.6)
	await fly.finished
	target.visible = false
	main.pip.giggle()
	_correct_total += 1
	var ids: Array = [Game.phoneme_clip(target_skill)]
	if _correct_total % GameTune.PRAISE_EVERY_N_CORRECT == 0:
		ids.append("found")
	await get_tree().create_timer(Voice.say(ids) + 0.2).timeout
	main.pip.go_home()
	_clear_tiles()
	await get_tree().create_timer(0.4).timeout
	item_done.emit()


func _on_wrong(hit: GlowLetter) -> void:
	var own: String = str(_skill_of[hit])
	report([target_skill], false, hints.level)
	Voice.stop()
	var d: float = Voice.sound(Game.phoneme_clip(own))
	hit.wobble()
	get_tree().create_timer(d + 0.1).timeout.connect(func() -> void: Voice.sfx("tok"))
	if Game.engine.wrong_tap(Time.get_ticks_msec() / 1000.0):
		disengaged.emit(StringName(str(item.get("id", ""))))
		return
	frozen = true
	var lv: int = hints.on_wrong()
	if not _explained_wrong:
		_explained_wrong = true
		await get_tree().create_timer(d + 0.3).timeout
		Voice.say(["den_sa", Game.phoneme_clip(own), "vi_leter", Game.phoneme_clip(target_skill)])
		await Voice.wait_idle()
	frozen = false
	apply_hint(lv)


# ---------------------------------------------------------------- cleanup


func _clear() -> void:
	_stop_emphasis()
	for gl: GlowLetter in letters:
		gl.queue_free()
	letters.clear()
	_skill_of.clear()
	target = null
	_clear_tiles()


func _clear_tiles() -> void:
	for tl: Node3D in _tiles:
		if is_instance_valid(tl):
			var tw: Tween = tl.create_tween()
			tw.tween_property(tl, "position:y", tl.position.y - 0.8, 0.4)
			tw.tween_callback(tl.queue_free)
	_tiles.clear()


## For the screenshot bot: screen position of a letter (the target or a distractor).
func letter_screen_pos(want_target: bool) -> Vector2:
	for gl: GlowLetter in letters:
		if (gl == target) == want_target and gl.visible:
			return gl.screen_pos(main.rig.cam)
	return Vector2(-1, -1)


func intro_screen_pos() -> Vector2:
	if _intro_letter == null:
		return Vector2(-1, -1)
	return _intro_letter.screen_pos(main.rig.cam)


func in_intro() -> bool:
	return _intro_letter != null
