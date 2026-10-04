class_name OpeningStory
extends Node3D
## The opening story (docs/SCRIPT.md scene 0, first launch, about 45 s).
## Night: the island glows and each letter makes its sound. Kaptein Hysj's ship
## glides in ("Hysj! For mye bråk!"), she lifts the jar lid, the letters fly
## into the jar one at a time, each sounding as it leaves, and the island turns
## grey. The ship drops anchor in the bay and Hysj falls asleep by the jar.
## Morning: Pip pops up and asks the child for help; the child taps Pip to
## start. Replayable from the hub; a tap skips it only when it has been seen.

signal finished

const LETTERS: Array[String] = ["a", "s", "i", "l", "o", "m"]
const ISLAND_VIEW: Vector3 = Vector3(1.0, 1.0, 0.0)

var main: MainScene
var skippable: bool = false
var ship: Ship
var stage: String = ""  # current beat, for the screenshot bot
var _letters: Array[GlowLetter] = []
var _skip: bool = false
var _waiting_for_pip: bool = false
var _done: bool = false
var _tweens: Array[Tween] = []


## Runs the whole story; returns when the child has tapped Pip (or skipped).
func play() -> void:
	ship = main.ship
	main.hud.hide_all()
	main.world.set_night(1.0)
	main.world.set_colour_all(1.0)
	main.hide_things()
	main.pip.visible = false
	ship.clear_jar()
	ship.wake()
	ship.global_position = _glide_start()
	_spawn_letters()
	main.rig.set_pose(ISLAND_VIEW + Vector3(0, 2, 6), 38.0, 10.0, -6.0)
	var skipped: bool = await _night()
	if not skipped:
		skipped = await _theft()
	if not skipped:
		skipped = await _sleep()
	if not skipped:
		skipped = await _morning()
	if not skipped:
		Voice.say(["op_pip_6"], true)
		_waiting_for_pip = true
		main.hud.ghost.tap(func() -> Vector2: return main.pip.screen_pos())
		while _waiting_for_pip and not _skip:
			await get_tree().process_frame
	_finish()


func _glide_start() -> Vector3:
	var along: Vector3 = Vector3(cos(main.world.ship_yaw), 0, -sin(main.world.ship_yaw))
	return main.world.ship_anchor - along * GameTune.STORY_SHIP_GLIDE_M


## 1. Night: the island sings, each letter makes its sound in turn (op_night).
func _night() -> bool:
	stage = "night"
	main.rig.fly_to(ISLAND_VIEW, 28.0, 14.0, 0.0, 4.0)
	for k in LETTERS.size():
		if await _beat(0.55):
			return true
		Voice.sound("lyd_" + LETTERS[k])
		_letters[k].pop()
	return await _beat(1.6)


## 2-4. The ship glides in, Hysj shushes, lifts the jar lid, and the sounds
## fly into the jar one at a time while the island turns grey.
func _theft() -> bool:
	var anchor: Vector3 = main.world.ship_anchor
	main.rig.fly_to(anchor.lerp(Vector3(0, 1, 0), 0.45) + Vector3(0, 1, 0), 30.0, 13.0, 0.0, 2.5)
	(
		_keep(create_tween())
		. tween_property(ship, "global_position", anchor, 6.0)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	if await _beat(5.4):
		return true
	stage = "shush"
	ship.clip("No")
	if await _beat(Voice.say(["op_hysj_1"]) + 0.3):
		return true
	ship.clip("Wave")
	ship.pop_lid()
	if await _beat(Voice.say(["op_hysj_2"]) + 0.3):
		return true
	stage = "theft"
	_keep(create_tween()).tween_method(main.world.set_colour_all, 1.0, 0.0, 5.5)
	for k in _letters.size():
		_fly_to_jar(_letters[k], 0.75 * float(k))
	return await _beat(0.75 * float(_letters.size()) + 1.6)


## 5-6. The island is grey; the ship drops anchor; Hysj sits down by the jar,
## yawns and snores.
func _sleep() -> bool:
	# from the island side, where Hysj sits by the jar facing the shore
	var yaw: float = wrapf(rad_to_deg(main.world.ship_yaw), -180.0, 180.0)
	main.rig.fly_to(ship.global_position + Vector3(0, 2.2, 0), 13.0, 14.0, yaw, 2.0)
	stage = "anchor"
	Voice.sfx("tok")
	if await _beat(Voice.say(["op_hysj_3"]) + 0.3):
		return true
	ship.clip("Yes")
	if await _beat(Voice.say(["op_hysj_4"]) + 0.2):
		return true
	ship.sleep()
	stage = "asleep"
	return await _beat(2.4)


## 7. Morning: Pip pops up and asks for help.
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
	if await _beat(Voice.say(["op_pip_1", "op_pip_2"]) + 0.1):
		return true
	main.pip.point_toward(main.world.zone_centers[1] + Vector3(0, 2.5, 0))
	if await _beat(Voice.say(["op_pip_3"]) + 0.1):
		return true
	main.pip.point_toward(ship.jar_mouth())
	stage = "pip_jar"
	if await _beat(Voice.say(["op_pip_4"]) + 0.1):
		return true
	main.pip.go_home()
	return await _beat(Voice.say(["op_pip_5"]) + 0.2)


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


## Back to the real state of the island: grey except restored zones, daylight,
## the ship at anchor with Hysj asleep by the full jar.
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
	main.anchor_ship()
	main.show_things()
	main.pip.visible = true
	main.pip.go_home()
	for gl: GlowLetter in _letters:
		if is_instance_valid(gl):
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


## One letter leaves its place with its sound and flies into the jar (op_theft).
func _fly_to_jar(gl: GlowLetter, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if _done or not is_instance_valid(gl):
		return
	gl.idle_motion = false
	Voice.sound("lyd_" + gl.letter)
	var from: Vector3 = gl.global_position
	var tw: Tween = create_tween()
	tw.tween_method(
		func(k: float) -> void:
			if not is_instance_valid(gl):
				return
			var p: Vector3 = from.lerp(ship.jar_mouth(), k)
			p.y += sin(k * PI) * 5.0
			gl.global_position = p
			gl.scale = Vector3.ONE * lerpf(1.0, 0.22, k),
		0.0,
		1.0,
		2.0
	)
	await tw.finished
	if _done or not is_instance_valid(gl):
		return
	gl.visible = false
	ship.add_jar_letter(gl.letter)
