class_name LetterScreen
extends Node3D
## The one screen of this build: hear a letter sound, tap the matching letter.
## Island in the background, two or three big letter tiles, one speaker
## button. No story, no speech, no score, no timers. Only the owner's
## recorded letter sounds plus a soft chime and a wooden "tok".

signal item_started(target: String, letters: Array[String])
signal prompt_played(target: String, file: String)

const SAVE_PATH: String = "user://letters.json"
const TILE_HEIGHT_SHARE: float = 0.34  # of screen height (spec: at least 0.25)
const FONT_SHARE: float = 0.80  # letter size vs tile side
const SPEAKER_HEIGHT_SHARE: float = 0.20
const TILE_GAP_SHARE: float = 0.07  # of screen width

var persist: bool = true
var rules: LetterRules = LetterRules.new()
var audio: LetterAudio
var world: World
var rig: CameraRig
var tiles: Array[LetterTile] = []
var speaker: SpeakerButton
var target: String = ""
var items_done: int = 0
var busy: bool = true  # taps ignored (intro or feedback running)
var _ui: Control
var _seq: int = 0  # bumped by every new action; older awaits then stop
var _missed: bool = false  # a wrong tap on the current item


func _ready() -> void:
	if OS.get_environment("MWM_LES_FRESH") != "":
		persist = false
	world = World.new()
	add_child(world)
	world.set_colour_all(1.0)
	rig = CameraRig.new()
	add_child(rig)
	rig.set_pose(GameTune.CAM_HUB_TARGET, GameTune.CAM_HUB_DISTANCE, GameTune.CAM_HUB_PITCH_DEG)
	audio = LetterAudio.new()
	add_child(audio)
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)
	var vs: Vector2 = get_viewport().get_visible_rect().size
	speaker = SpeakerButton.new().setup(vs.y * SPEAKER_HEIGHT_SHARE)
	speaker.position = Vector2(vs.x * 0.5 - speaker.size.x * 0.5, vs.y * 0.07)
	speaker.pressed.connect(replay)
	_ui.add_child(speaker)
	_load()
	next_item()


func next_item() -> void:
	_seq += 1
	var my: int = _seq
	busy = true
	_missed = false
	rules.begin_visit()  # this screen has no stations: every item is a visit
	var intro: Array[String] = rules.pending_intro()
	target = rules.pick_target()
	_show_tiles(rules.pick_tiles(target, intro))
	item_started.emit(target, tile_letters())
	if not intro.is_empty():
		await get_tree().create_timer(0.5).timeout
		for l: String in intro:
			if my != _seq:
				return
			var sec: float = audio.held(l)
			var t: LetterTile = tile_for(l)
			if t:
				t.pulse(sec)
			rules.mark_heard(l)
			await get_tree().create_timer(sec + LetterRules.INTRO_GAP_SEC).timeout
		_save()
	else:
		await get_tree().create_timer(0.35).timeout
	if my != _seq:
		return
	_prompt()


func _prompt() -> void:
	audio.held(target)
	busy = false
	prompt_played.emit(target, audio.current_file())


## Speaker button: hear the target again.
func replay() -> void:
	if busy:
		return
	_seq += 1
	_prompt()


func _on_tapped(tile: LetterTile) -> void:
	if busy:
		return
	busy = true
	_seq += 1
	var my: int = _seq
	var sec: float = audio.short(tile.letter)
	if tile.letter == target:
		tile.celebrate()
		rules.record(not _missed)
		items_done += 1
		_save()
		await get_tree().create_timer(sec + LetterRules.AFTER_CLIP_GAP_SEC).timeout
		if my != _seq:
			return
		audio.chime()
		await get_tree().create_timer(LetterRules.CORRECT_PAUSE_SEC).timeout
		if my != _seq:
			return
		next_item()
	else:
		_missed = true
		tile.wobble()
		await get_tree().create_timer(sec + LetterRules.AFTER_CLIP_GAP_SEC).timeout
		if my != _seq:
			return
		var tok_sec: float = audio.tok()
		await get_tree().create_timer(tok_sec + LetterRules.AFTER_CLIP_GAP_SEC).timeout
		if my != _seq:
			return
		_prompt()


func tile_letters() -> Array[String]:
	var out: Array[String] = []
	for t: LetterTile in tiles:
		out.append(t.letter)
	return out


func tile_for(l: String) -> LetterTile:
	for t: LetterTile in tiles:
		if t.letter == l:
			return t
	return null


func _show_tiles(letters: Array[String]) -> void:
	for t: LetterTile in tiles:
		t.queue_free()
	tiles.clear()
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var side: float = vs.y * TILE_HEIGHT_SHARE
	var gap: float = vs.x * TILE_GAP_SHARE
	var total: float = letters.size() * side + (letters.size() - 1) * gap
	var x: float = (vs.x - total) * 0.5
	var y: float = vs.y * 0.52
	for l: String in letters:
		var t: LetterTile = LetterTile.new().setup(l, side, int(side * FONT_SHARE))
		t.position = Vector2(x, y)
		t.remember_place()
		t.tapped.connect(_on_tapped)
		_ui.add_child(t)
		tiles.append(t)
		x += side + gap


func _load() -> void:
	if not persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if d is Dictionary:
		rules.from_dict(d as Dictionary)


func _save() -> void:
	if not persist:
		return
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(rules.to_dict()))
