class_name OpeningStory
extends Node3D
## The opening (first launch only), all in Pip's own recorded voice:
## op_1 Pip pops up and says hello; op_2 the camera shows the lamb on the
## little islet (Pip's best friend); op_3 the camera pulls back to the gap in
## the water (the lamb cannot swim, Pip wants to build a bridge); op_4 three
## faint letters float over the gap (the bridge will be made of letters);
## op_5 back by Pip, the ghost finger taps Pip until the child does.

signal finished

const REPEAT_SEC: float = 7.0
const GAP_LETTERS: Array[String] = ["l", "a", "m"]

var main: MainScene
var stage: String = ""  # current beat, for the screenshot bot and the test
var waiting_for_pip: bool = false
var _letters: Array[GlowLetter] = []
var _idle: float = 0.0


func play() -> void:
	main.hud.hide_all()
	var hp: Dictionary = main.hub_pose()
	main.rig.set_pose(hp["target"], hp["distance"], hp["pitch"], 0.0)
	main.pip.visible = false
	await _wait(0.8)
	# op_1: Pip pops up out of the water
	stage = "op_1"
	main.pip.visible = true
	main.pip.snap_home()
	main.pip.pop_up()
	await _wait(0.5)
	await Voice.say_wait(["op_1"], 0.3)
	# op_2: the lamb on the little islet
	stage = "op_2"
	var lamb_at: Vector3 = main.lamb.global_position
	main.rig.fly_to(lamb_at + Vector3(-1.2, 0.9, 0), 10.0, 14.0, -8.0, 1.6)
	_hop_lamb()
	await Voice.say_wait(["op_2"], 0.3)
	# op_3 and op_4: the gap in the water between the island and the islet
	stage = "op_3"
	var mid: Vector3 = (main.world.bridge_start + main.world.bridge_end) * 0.5
	main.rig.fly_to(mid + Vector3(1.0, 0.0, 0.0), 17.0, 24.0, 0.0, 1.8)
	await Voice.say_wait(["op_3"], 0.3)
	stage = "op_4"
	_spawn_gap_letters(mid)
	await Voice.say_wait(["op_4"], 0.3)
	# op_5: back by Pip; the ghost finger shows where to tap
	stage = "op_5"
	for gl: GlowLetter in _letters:
		gl.sink(3.0)
	await main.rig.fly_to(hp["target"], hp["distance"], hp["pitch"], 0.0, 1.6).finished
	Voice.say(["op_5"])
	waiting_for_pip = true
	_idle = 0.0
	main.hud.ghost.tap(func() -> Vector2: return main.pip.screen_pos())
	while waiting_for_pip:
		await get_tree().process_frame
		if not Voice.is_busy():
			_idle += get_process_delta_time()
			if _idle >= REPEAT_SEC:
				_idle = 0.0
				Voice.say(["op_5"])
	_finish()


func touch(event: InputEvent) -> void:
	var t: InputEventScreenTouch = event as InputEventScreenTouch
	if t and t.pressed and waiting_for_pip and main.pip.hit(t.position):
		tap_pip()


## The child taps Pip (touch path and test).
func tap_pip() -> void:
	if not waiting_for_pip:
		return
	waiting_for_pip = false
	main.pip.giggle()


func _finish() -> void:
	Voice.stop()
	main.hud.ghost.stop()
	for gl: GlowLetter in _letters:
		if is_instance_valid(gl):
			gl.queue_free()
	_letters.clear()
	stage = "done"
	finished.emit()
	queue_free()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _hop_lamb() -> void:
	var lamb: Node3D = main.lamb
	var y0: float = lamb.position.y
	var tw: Tween = create_tween()
	tw.tween_interval(1.4)
	for k in 2:
		tw.tween_property(lamb, "position:y", y0 + 0.35, 0.18).set_trans(Tween.TRANS_SINE)
		tw.tween_property(lamb, "position:y", y0, 0.2).set_trans(Tween.TRANS_BOUNCE)


## l, a, m float up out of the water in the gap, where the bridge will be.
func _spawn_gap_letters(mid: Vector3) -> void:
	var dir: Vector3 = (main.world.bridge_end - main.world.bridge_start).normalized()
	for k in GAP_LETTERS.size():
		var gl: GlowLetter = GlowLetter.new()
		gl.setup(GAP_LETTERS[k], 1.6)
		add_child(gl)
		gl.global_position = mid + dir * (float(k) - 1.0) * 2.2 + Vector3(0, 0.6, 0)
		gl.set_base_y(gl.position.y)
		gl.rise_from(2.5, 0.25 * float(k))
		_letters.append(gl)
