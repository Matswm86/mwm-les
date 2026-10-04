extends Node
## Autoload "Voice": Pip's spoken lines (a queue of clips played back to back),
## letter sounds on touch, and small sound effects. Timing runs on clip
## lengths, not on playback callbacks, so it behaves the same with the Dummy
## audio driver in tests.
## Slot clips ([lyd:x], [ord:x], [lydering:x] in docs/SCRIPT.md) only ever come
## last in a sequence, after a short pause: nothing is played after a slot.

const CLIP_PATH: String = "res://assets/audio/tts_%s.mp3"
const SFX_PATH: String = "res://assets/audio/sfx_%s.wav"
const MARKS_PATH: String = "res://content/nb_reading/clip_marks.json"
const SLOT_PREFIXES: Array[String] = ["lyd_", "ord_", "lydering_"]
const GAP_SEC: float = 0.12
const SLOT_PAUSE_SEC: float = 0.3  # extra pause before a slot clip
const MISSING_SEC: float = 0.4

var sequence_errors: int = 0  # sequences that put a clip after a slot (tests read this)
var _voice: AudioStreamPlayer
var _sound: AudioStreamPlayer
var _fx: AudioStreamPlayer
var _queue: Array[String] = []
var _busy_until: float = 0.0
var _sound_until: float = 0.0
var _last_prompt: Array[String] = []
var _cache: Dictionary = {}
var _chime_step: int = 0
var _playing: String = ""
var _marks: Dictionary = {}  # clip id -> Array of sound start times (s)


func _ready() -> void:
	if FileAccess.file_exists(MARKS_PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(MARKS_PATH))
		if d is Dictionary:
			_marks = (d as Dictionary).get("marks", {})
	_voice = AudioStreamPlayer.new()
	_sound = AudioStreamPlayer.new()
	_fx = AudioStreamPlayer.new()
	_fx.volume_db = -6.0
	for p: AudioStreamPlayer in [_voice, _sound, _fx]:
		add_child(p)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func stream(id: String) -> AudioStream:
	if _cache.has(id):
		return _cache[id]
	var path: String = CLIP_PATH % id
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path) as AudioStream
	else:
		push_warning("Voice: missing clip %s" % id)
	_cache[id] = s
	return s


func length(id: String) -> float:
	var s: AudioStream = stream(id)
	return s.get_length() if s else MISSING_SEC


func total_length(ids: Array) -> float:
	var t: float = 0.0
	for k in ids.size():
		t += length(str(ids[k])) + GAP_SEC
		if k + 1 < ids.size() and is_slot(str(ids[k + 1])):
			t += SLOT_PAUSE_SEC
	return t


## Seconds from the start of a sequence until clip `index` in it begins.
func offset_of(ids: Array, index: int) -> float:
	return (
		total_length(ids.slice(0, index))
		+ (SLOT_PAUSE_SEC if index > 0 and is_slot(str(ids[index])) else 0.0)
	)


static func is_slot(id: String) -> bool:
	for p: String in SLOT_PREFIXES:
		if id.begins_with(p):
			return true
	return false


## Start times of the sounds inside a [lydering:x] clip (data, see MARKS_PATH).
func marks(id: String) -> Array[float]:
	var out: Array[float] = []
	for m: Variant in _marks.get(id, []):
		out.append(float(m))
	return out


## The rule from SCRIPT.md: a slot is always the last clip of a sequence.
func _check(ids: Array) -> void:
	for k in range(ids.size() - 1):
		if is_slot(str(ids[k])):
			sequence_errors += 1
			push_error("Voice: %s plays after the slot %s" % [ids[k + 1], ids[k]])
			return


## Say a sequence of clips now, replacing anything queued. Returns its length.
func say(ids: Array, is_prompt: bool = false) -> float:
	_check(ids)
	_queue.clear()
	for id: Variant in ids:
		_queue.append(str(id))
	if is_prompt:
		_last_prompt = _queue.duplicate()
	_voice.stop()
	_busy_until = 0.0
	_next()
	return total_length(ids)


## Append clips after whatever is being said (never after a slot).
func then(ids: Array) -> void:
	var tail: Array = _queue.duplicate()
	if tail.is_empty() and is_busy() and _playing != "":
		tail = [_playing]
	tail.append_array(ids)
	_check(tail)
	for id: Variant in ids:
		_queue.append(str(id))
	if not is_busy():
		_next()


func repeat_prompt() -> float:
	if _last_prompt.is_empty():
		return 0.0
	return say(_last_prompt)


func set_prompt(ids: Array) -> void:
	_check(ids)
	_last_prompt.clear()
	for id: Variant in ids:
		_last_prompt.append(str(id))


## A letter sound on touch: its own channel, never queued behind Pip.
func sound(id: String) -> float:
	var s: AudioStream = stream(id)
	_sound.stream = s
	if s:
		_sound.play()
	_sound_until = _now() + length(id)
	return length(id)


func sound_playing() -> bool:
	return _now() < _sound_until


func sfx(name: String) -> void:
	var path: String = SFX_PATH % name
	if not ResourceLoader.exists(path):
		return
	_fx.stream = load(path) as AudioStream
	_fx.play()


## Pentatonic chime whose pitch rises within an activity (GDD 11).
func chime() -> void:
	sfx("chime_%d" % mini(_chime_step, 5))
	_chime_step += 1


func reset_chime() -> void:
	_chime_step = 0


func is_busy() -> bool:
	return _now() < _busy_until or not _queue.is_empty()


func wait_idle() -> void:
	while is_busy():
		await get_tree().process_frame


func stop() -> void:
	_queue.clear()
	_voice.stop()
	_busy_until = 0.0
	_playing = ""


func _process(_delta: float) -> void:
	if not _queue.is_empty() and _now() >= _busy_until:
		_next()


func _next() -> void:
	if _queue.is_empty():
		return
	var id: String = _queue.pop_front()
	var s: AudioStream = stream(id)
	_voice.stream = s
	if s:
		_voice.play()
	_playing = id
	_busy_until = _now() + length(id) + GAP_SEC
	if not _queue.is_empty() and is_slot(_queue[0]):
		_busy_until += SLOT_PAUSE_SEC
