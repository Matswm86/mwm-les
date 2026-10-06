extends Node
## Screenshot bot for the one-screen letter game. Real touch events. Run under
## Xvfb (studio CLAUDE.md):
##   CAPTURE_DIR=/tmp/shots godot --audio-driver Dummy --display-driver x11 \
##     --resolution 1920x1080 res://tests/capture_letters.tscn

var out_dir: String = OS.get_environment("CAPTURE_DIR")
var screen: LetterScreen
var _shots: int = 0


func _ready() -> void:
	if out_dir == "":
		out_dir = "user://shots_letters"
	DirAccess.make_dir_recursive_absolute(out_dir)
	screen = (load("res://scenes/LetterScreen.tscn") as PackedScene).instantiate() as LetterScreen
	screen.persist = false
	screen.rules.rng.seed = 3
	add_child(screen)
	while screen.audio.played.is_empty():
		await _frames(1)
	await _wait(0.6)
	await _shot("01a_first_intro_pulse")
	await _until_ready()
	await _wait(0.4)
	await _shot("01b_first_screen_prompt")
	print("first item: target %s tiles %s" % [screen.target, screen.tile_letters()])
	# wrong answer
	var wrong: String = ""
	for l: String in screen.tile_letters():
		if l != screen.target:
			wrong = l
	await _tap_letter(wrong, "03_wrong_answer_wobble")
	await _until_ready()
	# right answer
	await _tap_letter(screen.target, "02_right_answer_glow")
	# four right first tries in a row adds letter i: three tiles
	while screen.rules.count < 3:
		await _until_ready()
		await _tap_letter(screen.target, "")
	await _until_ready()
	await _wait(0.4)
	await _shot("04_three_tiles")
	print("3-tile item: target %s tiles %s" % [screen.target, screen.tile_letters()])
	print("clips: %s" % ", ".join(screen.audio.played))
	# layout check only (not a game state): the three later letters on tiles
	screen.busy = true
	screen.call("_show_tiles", ["l", "o", "m"] as Array[String])
	await _wait(0.3)
	await _shot("05_layout_check_l_o_m")
	print("CAPTURE DONE: %d shots" % _shots)
	get_tree().quit()


func _tap_letter(l: String, shot_name: String) -> void:
	var t: LetterTile = screen.tile_for(l)
	var pos: Vector2 = t.get_global_rect().get_center()
	_touch(pos, true)
	await _frames(3)
	_touch(pos, false)
	if shot_name != "":
		await _wait(0.15)
		await _shot(shot_name)
	await _frames(3)


func _touch(pos: Vector2, pressed: bool) -> void:
	var e: InputEventScreenTouch = InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _until_ready() -> void:
	var start: int = Time.get_ticks_msec()
	while screen.busy:
		if Time.get_ticks_msec() - start > 15000:
			print("TIMEOUT waiting for the prompt")
			return
		await get_tree().process_frame


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	img.save_png(out_dir.path_join(shot_name + ".png"))
	_shots += 1
	print("shot %s" % shot_name)
