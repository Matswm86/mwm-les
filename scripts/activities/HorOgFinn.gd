class_name HorOgFinn
extends Activity
## Hør og finn (GDD 6.2): Pip says a sound, the child taps the matching gold
## letter among 2-3 on the beach. Wrong: the letter says its own sound and
## wobbles (control of error). Hints: repeat, pulse + remove one, Pip points,
## the right letter comes forward.

var letters: Array[GlowLetter] = []
var target: GlowLetter
var target_skill: String = ""
var _skill_of: Dictionary = {}  # GlowLetter -> skill id
var _explained_wrong: bool = false
var _correct_total: int = 0


func activity_id() -> String:
	return "hor_og_finn"


func camera_pose() -> Dictionary:
	var c: Vector3 = main.world.zone_centers[0]
	return {
		"target": c + Vector3(0, 0.9, 0),
		"distance": GameTune.CAM_STATION_DISTANCE,
		"pitch": GameTune.CAM_PITCH_DEG
	}


func start_item(p_item: Dictionary, p_format: Dictionary, hint_start: int) -> void:
	super.start_item(p_item, p_format, hint_start)
	active = false
	_clear()
	_explained_wrong = false
	target_skill = Game.engine.tested_skills(item)[0]
	var skills: Array[String] = [target_skill]
	for d: Variant in format.get("distractors", []):
		skills.append(str(d))
	skills.shuffle()
	last_choices = skills.size()
	var c: Vector3 = main.world.zone_centers[0]
	var right: Vector3 = main.rig.cam.global_basis.x
	right.y = 0.0
	right = right.normalized()
	for i in skills.size():
		var off: float = (float(i) - float(skills.size() - 1) * 0.5) * GameTune.LETTER_SPACING
		var p: Vector3 = c + right * off
		p = main.world.on_ground(p.x, p.z)
		var gl: GlowLetter = GlowLetter.new()
		gl.setup(Game.label(skills[i]))
		add_child(gl)
		gl.global_position = p
		gl.set_base_y(p.y)
		gl.rotation.y = main.rig.cam.global_rotation.y
		gl.rise_from(2.2, 0.12 * float(i))
		letters.append(gl)
		_skill_of[gl] = skills[i]
		if skills[i] == target_skill:
			target = gl
	await get_tree().create_timer(0.8).timeout
	_say_prompt()
	active = true
	if hints.level > 0:
		_apply(hints.level, false)


func _say_prompt() -> void:
	var ph: String = Game.phoneme_clip(target_skill)
	var ids: Array = ["find_prompt", ph]
	if hints.level >= 1:
		ids.append(ph)
	var d: float = Voice.say(ids, true)
	mark_prompt_end(d)


func apply_hint(level: int) -> void:
	_apply(level, true)


func _apply(level: int, speak: bool) -> void:
	if target == null:
		return
	if speak and level >= 1:
		_say_prompt()
	if level >= 2:
		target.hint_pulse = true
		_sink_farthest()
	if level >= 3:
		main.pip.point_at(target.center_world())
		if speak:
			Voice.then([Game.phoneme_clip(target_skill)])
	if level >= 4:
		var toward: Vector3 = main.rig.cam.global_position - target.global_position
		toward.y = 0.0
		var goal: Vector3 = target.global_position + toward.normalized() * 1.6
		create_tween().tween_property(target, "global_position", goal, 0.8).set_trans(
			Tween.TRANS_SINE
		)


func _sink_farthest() -> void:
	if letters.size() < 3:
		return
	var far: GlowLetter = null
	var best: float = -1.0
	for gl: GlowLetter in letters:
		if gl == target or not gl.visible:
			continue
		var d: float = gl.global_position.distance_to(target.global_position)
		if d > best:
			best = d
			far = gl
	if far:
		far.sink(2.5).finished.connect(func() -> void: far.visible = false)


func touch(event: InputEvent) -> void:
	if not active or frozen:
		return
	var t: InputEventScreenTouch = event as InputEventScreenTouch
	if t == null or not t.pressed:
		return
	var hit: GlowLetter = _letter_at(t.position)
	if hit == null:
		return
	reset_idle()
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
	Voice.sound(Game.phoneme_clip(target_skill))
	target.hint_pulse = false
	target.pop()
	main.burst(target.center_world())
	Voice.chime()
	_correct_total += 1
	main.pip.giggle()
	if _correct_total % GameTune.PRAISE_EVERY_N_CORRECT == 0:
		Voice.then(["found"])
	await get_tree().create_timer(1.6).timeout
	await Voice.wait_idle()
	main.pip.go_home()
	for gl: GlowLetter in letters:
		gl.sink(2.4)
	await get_tree().create_timer(0.5).timeout
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
	var lv: int = hints.on_wrong()
	if not _explained_wrong:
		_explained_wrong = true
		await get_tree().create_timer(d + 0.3).timeout
		Voice.say(["den_sa", Game.phoneme_clip(own), "vi_leter", Game.phoneme_clip(target_skill)])
		await Voice.wait_idle()
	apply_hint(lv)


func end_visit() -> void:
	super.end_visit()
	main.pip.go_home()
	_clear()


func _clear() -> void:
	for gl: GlowLetter in letters:
		gl.queue_free()
	letters.clear()
	_skill_of.clear()
	target = null


## For the screenshot bot: screen position of a letter (the target or a distractor).
func letter_screen_pos(want_target: bool) -> Vector2:
	for gl: GlowLetter in letters:
		if (gl == target) == want_target and gl.visible:
			return gl.screen_pos(main.rig.cam)
	return Vector2(-1, -1)
