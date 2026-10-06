extends Node
## Autoload "Voice": the only sound source of the game. One player, so two
## clips never overlap: a new sequence stops the one before it. Plays only the
## owner's own recordings (assets/audio/rec) and the synthesized non-voice
## effects (assets/audio/sfx_*). Any other id is refused, logged and counted.
## Timing runs on clip lengths and the scaled game clock, not on playback
## callbacks, so it behaves the same with the Dummy audio driver in tests.
## Rule: inside one sequence no sentence comes after a letter sound.

signal clip_started(id: String, file: String, scene: String)

const REC_PATH: String = "res://assets/audio/rec/%s.wav"
const SFX_PATH: String = "res://assets/audio/%s.wav"
const MARKS_PATH: String = "res://content/nb_reading/clip_marks.json"
const LETTERS: Array[String] = LetterRules.ORDER
## Every recorded sentence the game may play (letter clips are built from LETTERS).
const LINES: Array[String] = [
	"op_1",
	"op_2",
	"op_3",
	"op_4",
	"op_5",
	"hub_find",
	"hub_write",
	"hub_bridge",
	"hub_back",
	"hub_idle",
	"intro_again",
	"find_in",
	"find_ask",
	"find_right",
	"find_wrong",
	"find_done",
	"write_in",
	"write_turn",
	"write_retry",
	"write_right",
	"write_next",
	"write_again",
	"write_show_again",
	"write_trace",
	"write_alone",
	"write_done",
	"bridge_in",
	"hook_sol",
	"hook_sel",
	"hook_baat",
	"hook_mat",
	"hook_les",
	"hook_lam",
	"bridge_word_sol",
	"bridge_word_sel",
	"bridge_word_baat",
	"bridge_word_mat",
	"bridge_word_les",
	"bridge_word_lam",
	"bridge_word_done",
	"bridge_next",
	"done_sol",
	"done_sel",
	"done_les",
	"done_mat",
	"done_baat",
	"level_next",
	"level_back",
	"levels_intro",
	"lamb_baa",
	"mid_sol",
	"mid_sel",
	"mid_les",
	"mid_mat",
	"mid_baat",
	"final_party",
	"bridge_ask",
	"bridge_right",
	"bridge_done",
	"bridge_walk",
	"end_bye",
]
const SFX: Array[String] = [
	"sfx_chime_0",
	"sfx_chime_1",
	"sfx_chime_2",
	"sfx_chime_3",
	"sfx_chime_4",
	"sfx_chime_5",
	"sfx_tok",
	"sfx_pop",
	"sfx_whoosh",
	"sfx_fanfare",
]
const GAP_SEC: float = 0.15  # silence between two clips of one sequence
const SFX_DB: float = -8.0
const MISSING_SEC: float = 0.4

var scene: String = ""  # tag for the clip log (opening, hub, find, write, bridge, end)
var clip_log: Array[Dictionary] = []  # {scene, id, file, t} for every clip that started
var sequence_errors: int = 0  # sequences with a sentence after a letter sound
var refused: Array[String] = []  # ids that are not owner recordings or effects
var missing: Array[String] = []  # listed recordings whose file is not there yet (skipped)
var _player: AudioStreamPlayer
var _queue: Array[String] = []
var _clock: float = 0.0  # scaled game time
var _busy_until: float = 0.0
var _cache: Dictionary = {}
var _marks: Dictionary = {}
var _word_at: Dictionary = {}
var _chime_step: int = 0
var _playing: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	if FileAccess.file_exists(MARKS_PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(MARKS_PATH))
		if d is Dictionary:
			_marks = (d as Dictionary).get("marks", {})
			_word_at = (d as Dictionary).get("word_at", {})


# ---------------------------------------------------------------- ids


static func is_letter_sound(id: String) -> bool:
	return id.begins_with("lyd_")


static func is_known(id: String) -> bool:
	if LINES.has(id) or SFX.has(id):
		return true
	for l: String in LETTERS:
		if id in ["lyd_" + l, "navn_" + l, "intro_" + l]:
			return true
		if id == "lyd_%s_held" % l and not LetterRules.STOPS.has(l):
			return true
	return false


## A spoken sentence (not a letter sound, a letter name or an effect).
static func is_sentence(id: String) -> bool:
	return LINES.has(id) or id.begins_with("intro_")


static func short_id(l: String) -> String:
	return "lyd_" + l


## The held take; t and b have none, so their short take stands in.
static func held_id(l: String) -> String:
	if LetterRules.STOPS.has(l):
		return short_id(l)
	return "lyd_%s_held" % l


func path_of(id: String) -> String:
	return (SFX_PATH if id.begins_with("sfx_") else REC_PATH) % id


func stream(id: String) -> AudioStream:
	if not _cache.has(id):
		var p: String = path_of(id)
		_cache[id] = load(p) as AudioStream if ResourceLoader.exists(p) else null
	return _cache[id]


func length(id: String) -> float:
	var s: AudioStream = stream(id) if is_known(id) else null
	return s.get_length() if s else MISSING_SEC


func total_length(ids: Array) -> float:
	var t: float = 0.0
	for id: Variant in ids:
		t += length(str(id)) + GAP_SEC
	return t


## Seconds from the start of a sequence until clip `index` in it begins.
func offset_of(ids: Array, index: int) -> float:
	return total_length(ids.slice(0, index))


## Start times of the letter sounds inside a sounding-out clip.
func marks(id: String) -> Array[float]:
	var out: Array[float] = []
	for m: Variant in _marks.get(id, []):
		out.append(float(m))
	return out


## Where the whole word is said at the end of a sounding-out clip (-1 = none).
func word_at(id: String) -> float:
	return float(_word_at.get(id, -1.0))


# ---------------------------------------------------------------- play


## Stops anything playing and says `ids` back to back. Returns the length.
func say(ids: Array) -> float:
	var clean: Array[String] = []
	var after_sound: bool = false
	var bad_order: bool = false
	for v: Variant in ids:
		var id: String = str(v)
		if not is_known(id):
			refused.append(id)
			push_error("Voice: refused clip %s (not an owner recording)" % id)
			continue
		if stream(id) == null:  # listed but not recorded yet: skipped, never a stand-in
			if not missing.has(id):
				missing.append(id)
				push_warning("Voice: no recording for %s yet, skipped" % id)
			continue
		if after_sound and is_sentence(id):
			bad_order = true
		if is_letter_sound(id):
			after_sound = true
		clean.append(id)
	if bad_order:
		sequence_errors += 1
		push_error("Voice: a sentence after a letter sound in %s" % str(ids))
	_queue = clean.duplicate()
	_player.stop()
	_busy_until = 0.0
	_next()
	return total_length(clean)


## Says `ids` and returns when the sequence is over.
func say_wait(ids: Array, extra: float = 0.0) -> void:
	var sec: float = say(ids)
	await get_tree().create_timer(sec + extra).timeout


## A non-voice effect. Never interrupts speech: skipped while something plays.
func sfx(name: String) -> void:
	if is_busy():
		return
	say(["sfx_" + name])


## Soft chime whose pitch rises within a station.
func chime_id() -> String:
	var id: String = "sfx_chime_%d" % mini(_chime_step, 5)
	_chime_step += 1
	return id


func reset_chime() -> void:
	_chime_step = 0


func is_busy() -> bool:
	return _clock < _busy_until or not _queue.is_empty()


func wait_idle() -> void:
	while is_busy():
		await get_tree().process_frame


func stop() -> void:
	_queue.clear()
	_player.stop()
	_busy_until = 0.0


func current_id() -> String:
	return _playing


func _process(delta: float) -> void:
	_clock += delta
	if not _queue.is_empty() and _clock >= _busy_until:
		_next()
	elif _queue.is_empty() and _clock >= _busy_until:
		_playing = ""


func _next() -> void:
	if _queue.is_empty():
		return
	var id: String = _queue.pop_front()
	var s: AudioStream = stream(id)
	_player.stream = s
	_player.volume_db = SFX_DB if id.begins_with("sfx_") else 0.0
	_playing = id
	_busy_until = _clock + length(id) + GAP_SEC
	var file: String = "MISSING:" + id
	if s:
		_player.play()
		file = s.resource_path.get_file()
	else:
		push_error("Voice: missing file for %s" % id)
	clip_log.append({"scene": scene, "id": id, "file": file, "t": _clock})
	clip_started.emit(id, file, scene)
