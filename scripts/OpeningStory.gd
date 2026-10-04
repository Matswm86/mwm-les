class_name OpeningStory
extends Node3D
## The opening story (GDD 9, first launch, about 45 s, voiced). Night: the
## island glows with its letter sounds and the unicorn has a rainbow mane.
## Kaptein Hysj's ship glides past ("Hysj! For mye bråk!"), the sounds float
## out as little glowing letters into her big jar, the island turns grey and
## the unicorn goes white and sad. Morning: Pip pops up and asks the child for
## help; the child taps Pip to start. Replayable from the hub; a tap skips it
## only when it has been seen before.

signal finished

const CAPTAIN: PackedScene = preload("res://assets/characters/hysj/PirateCaptain.glb")
const LETTERS: Array[String] = ["a", "s", "i", "l", "o", "m"]
const ISLAND_VIEW: Vector3 = Vector3(1.0, 1.0, 0.0)

var main: MainScene
var skippable: bool = false
var ship: Node3D
var jar: Node3D
var hysj_anim: AnimationPlayer
var _letters: Array[GlowLetter] = []
var _skip: bool = false
var _waiting_for_pip: bool = false
var _done: bool = false
var _tweens: Array[Tween] = []


## Runs the whole story; returns when the child has tapped Pip (or skipped).
func play() -> void:
	_build_ship()
	main.hud.hide_all()
	main.world.set_night(1.0)
	main.world.set_colour_all(1.0)
	main.unicorn.set_stripes(Unicorn.STRIPES)
	main.unicorn.set_colour(1.0)
	main.unicorn.happy()
	main.pip.visible = false
	_spawn_letters()
	main.rig.set_pose(ISLAND_VIEW + Vector3(0, 2, 6), 38.0, 10.0, -6.0)
	ship.global_position = Vector3(-50.0, 0.0, GameTune.STORY_SHIP_Z)
	var skipped: bool = await _night()
	if not skipped:
		skipped = await _theft()
	if not skipped:
		skipped = await _morning()
	if not skipped:
		Voice.say(["tap_me"], true)
		_waiting_for_pip = true
		main.hud.ghost.tap(func() -> Vector2: return main.pip.screen_pos())
		while _waiting_for_pip and not _skip:
			await get_tree().process_frame
	_finish()


## 1. The island sings at night; the unicorn has its rainbow mane.
func _night() -> bool:
	main.rig.fly_to(ISLAND_VIEW, 28.0, 14.0, 0.0, 4.0)
	for k in LETTERS.size():
		if await _beat(0.55):
			return true
		Voice.sound("ph_" + LETTERS[k])
	var u: Unicorn = main.unicorn
	main.rig.fly_to(u.global_position + Vector3(0, 1.0, 0), 5.2, 12.0, 0.0, 1.6)
	return await _beat(3.4)


## 2-4. Hysj's ship glides in, the sounds float into her jar, the island
## greys and the unicorn goes white and sad; the ship sails away.
func _theft() -> bool:
	main.rig.fly_to(Vector3(0.0, 1.0, 6.0), 34.0, 13.0, 0.0, 2.0)
	_keep(create_tween()).tween_property(ship, "global_position:x", -2.0, 6.0).set_trans(
		Tween.TRANS_SINE
	)
	if await _beat(5.2):
		return true
	_hysj_clip("No")
	if await _beat(Voice.say(["hysj_shush"]) + 0.2):
		return true
	_hysj_clip("Wave")
	Voice.then(["hysj_jar"])
	_keep(create_tween()).tween_method(main.world.set_colour_all, 1.0, 0.0, 5.5)
	for k in _letters.size():
		_fly_to_jar(_letters[k], 0.7 * float(k))
	if await _beat(2.6):
		return true
	var u: Unicorn = main.unicorn
	u.set_stripes(0)
	u.set_colour(0.0)
	u.sad()
	if await _beat(3.6):
		return true
	_keep(create_tween()).tween_property(ship, "global_position:x", 60.0, 9.0).set_trans(
		Tween.TRANS_SINE
	)
	main.rig.fly_to(u.global_position + Vector3(0, 1.0, 0), 5.2, 14.0, 0.0, 2.6)
	return await _beat(5.0)


## 5. Morning: Pip pops up and asks for help.
func _morning() -> bool:
	var hp: Dictionary = main.hub_pose()
	_keep(create_tween()).tween_method(main.world.set_night, 1.0, 0.0, 3.0)
	main.rig.fly_to(hp["target"], hp["distance"], hp["pitch"], 0.0, 3.0)
	if await _beat(3.2):
		return true
	main.pip.visible = true
	main.pip.snap_home()
	main.pip.pop_up()
	Voice.sfx("pop")
	if await _beat(0.6):
		return true
	return await _beat(Voice.say(["story_pip_1", "story_pip_2", "story_pip_3"]) + 0.2)


func _keep(tw: Tween) -> Tween:
	_tweens.append(tw)
	return tw


## Waits `sec`; returns true when the child skipped.
func _beat(sec: float) -> bool:
	var end_ms: int = Time.get_ticks_msec() + int(sec * 1000.0)
	while Time.get_ticks_msec() < end_ms:
		if _skip:
			return true
		await get_tree().process_frame
	return _skip


func touch(event: InputEvent) -> void:
	var t: InputEventScreenTouch = event as InputEventScreenTouch
	if t == null or not t.pressed:
		return
	if _waiting_for_pip and main.pip.hit(t.position):
		main.pip.giggle()
		_waiting_for_pip = false
	elif skippable:
		_skip = true


func is_waiting_for_pip() -> bool:
	return _waiting_for_pip


## Back to the real state of the island: grey except restored zones, the
## unicorn with the ribbons it has earned, daylight.
func _finish() -> void:
	if _done:
		return
	_done = true
	for tw: Tween in _tweens:
		if tw and tw.is_valid():
			tw.kill()
	Voice.stop()
	main.hud.ghost.stop()
	var hp: Dictionary = main.hub_pose()
	if _skip:
		main.rig.set_pose(hp["target"], hp["distance"], hp["pitch"], 0.0)
	main.world.set_night(0.0)
	main.world.set_colour_all(0.0)
	for i in 3:
		if Game.restored[i]:
			main.world.set_zone_now(i, 1.0)
	var u: Unicorn = main.unicorn
	u.set_stripes(Game.unicorn_stripes)
	u.set_colour(1.0)
	if Game.unicorn_stripes == 0:
		u.sad()
	else:
		u.happy()
	main.pip.visible = true
	main.pip.go_home()
	for gl: GlowLetter in _letters:
		gl.queue_free()
	_letters.clear()
	finished.emit()
	queue_free()


# ---------------------------------------------------------------- pieces


func _spawn_letters() -> void:
	var spots: Array[Vector3] = []
	for c: Vector3 in main.world.zone_centers:
		spots.append(c)
	spots.append(main.world.on_ground(4.0, -5.0))
	spots.append(main.world.on_ground(-3.0, -2.0))
	spots.append(main.world.on_ground(-6.0, 3.0))
	for k in LETTERS.size():
		var gl: GlowLetter = GlowLetter.new()
		gl.setup(LETTERS[k], 1.8)
		add_child(gl)
		var p: Vector3 = spots[k % spots.size()] + Vector3(0, 3.0 + 0.4 * float(k % 2), 0)
		gl.global_position = p
		gl.set_base_y(gl.position.y)
		gl.rotation.y = 0.0
		_letters.append(gl)


func _fly_to_jar(gl: GlowLetter, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if _done or not is_instance_valid(gl):
		return
	gl.idle_motion = false
	Voice.sound("ph_" + gl.letter)
	var from: Vector3 = gl.global_position
	var tw: Tween = create_tween()
	tw.tween_method(
		func(k: float) -> void:
			if not is_instance_valid(gl) or not is_instance_valid(jar):
				return
			var to: Vector3 = jar.global_position + Vector3(0, 1.0, 0)
			var p: Vector3 = from.lerp(to, k)
			p.y += sin(k * PI) * 5.0
			gl.global_position = p
			gl.scale = Vector3.ONE * lerpf(1.0, 0.22, k),
		0.0,
		1.0,
		2.0
	)
	await tw.finished
	if is_instance_valid(gl) and is_instance_valid(jar):
		# stays in the jar, small and asleep
		var rest: Vector3 = (
			jar.global_position + Vector3(-0.35 + 0.14 * float(_letters.find(gl)), 0.35, 0.0)
		)
		gl.reparent(jar)
		gl.global_position = rest
		gl.set_base_y(gl.position.y)


func _build_ship() -> void:
	ship = Node3D.new()
	add_child(ship)
	var wood: Color = Color(0.62, 0.38, 0.20)
	var parts: Array = [
		[MeshKit.box(Vector3(5.6, 1.3, 2.4)), MeshKit.xf(Vector3(0, 0.65, 0)), wood],
		[
			MeshKit.sphere(1.2, 16, 10),
			MeshKit.xf(Vector3(2.8, 0.75, 0), Vector3(1.6, 0.75, 1.0)),
			wood
		],
		[
			MeshKit.sphere(1.2, 16, 10),
			MeshKit.xf(Vector3(-2.8, 0.85, 0), Vector3(0.7, 0.8, 1.0)),
			wood
		],
		[MeshKit.box(Vector3(5.7, 0.28, 2.5)), MeshKit.xf(Vector3(0, 1.15, 0)), GameTune.HERO_RED],
		[
			MeshKit.cylinder(0.13, 0.16, 6.2, 8),
			MeshKit.xf(Vector3(-0.3, 4.1, 0)),
			wood.darkened(0.25)
		],
		[
			MeshKit.sphere(1.0, 16, 10),
			MeshKit.xf(Vector3(-0.15, 4.2, 0), Vector3(0.22, 1.5, 1.35)),
			Color(0.98, 0.95, 0.86)
		],
		[
			MeshKit.box(Vector3(1.1, 0.7, 0.06)),
			MeshKit.xf(Vector3(0.3, 6.95, 0)),
			Color(0.15, 0.17, 0.3)
		],
		[MeshKit.sphere(0.16, 10, 6), MeshKit.xf(Vector3(0.3, 6.95, 0.06)), Color(1, 1, 1)],
	]
	for k in 4:  # portholes
		parts.append(
			[
				MeshKit.cylinder(0.18, 0.18, 0.08, 12),
				MeshKit.xf(
					Vector3(-1.8 + 1.2 * float(k), 0.6, 1.22), Vector3.ONE, Vector3(90, 0, 0)
				),
				Color(1.0, 0.9, 0.55)
			]
		)
	MeshKit.instance(MeshKit.merge(parts), MeshKit.with_outline(MeshKit.toon(), 0.003), ship)
	# the big sound jar on deck: glass with a cork lid
	jar = Node3D.new()
	ship.add_child(jar)
	jar.position = Vector3(1.7, 1.3, 0.2)
	jar.scale = Vector3.ONE * 1.2
	var glass: StandardMaterial3D = StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.75, 0.9, 1.0, 0.38)
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var body: MeshInstance3D = MeshKit.instance(MeshKit.cylinder(0.8, 0.8, 1.7, 20), glass, jar)
	body.position.y = 0.85
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cork: MeshInstance3D = MeshKit.instance(
		MeshKit.cylinder(0.55, 0.6, 0.35, 16), MeshKit.toon(Color(0.8, 0.62, 0.4), false), jar
	)
	cork.position.y = 1.85
	# Kaptein Hysj (Quaternius Pirate Captain, CC0), no cutlass
	var cap: Node3D = CAPTAIN.instantiate() as Node3D
	ship.add_child(cap)
	cap.position = Vector3(-1.6, 1.3, 0.3)
	for n: Node in cap.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n as MeshInstance3D
		if mi.name.contains("Cutlass"):
			mi.visible = false
			continue
		var src: StandardMaterial3D = mi.mesh.surface_get_material(0) as StandardMaterial3D
		var m: ShaderMaterial = MeshKit.with_outline(
			MeshKit.char_toon(Color(1, 1, 1), false), 0.0028
		)
		if src and src.albedo_texture:
			m.set_shader_parameter("albedo_tex", src.albedo_texture)
		mi.material_override = m
	cap.scale = Vector3.ONE * GameTune.HYSJ_SCALE
	hysj_anim = cap.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_hysj_clip("Idle")


func _hysj_clip(part: String) -> void:
	if hysj_anim == null:
		return
	for a: StringName in hysj_anim.get_animation_list():
		if str(a).contains("|" + part + "|") or str(a).ends_with(part):
			hysj_anim.play(a, 0.2)
			if part == "Idle":
				hysj_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
			return
