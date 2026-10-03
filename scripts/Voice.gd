extends Node
## Autoload "Voice": Pip's spoken lines (a queue of clips played back to back),
## letter sounds on touch, and small sound effects. Timing runs on clip
## lengths, not on playback callbacks, so it behaves the same with the Dummy
## audio driver in tests.

const CLIP_PATH: String = "res://assets/audio/tts_%s.mp3"
const SFX_PATH: String = "res://assets/audio/sfx_%s.wav"
const GAP_SEC: float = 0.12
const MISSING_SEC: float = 0.4

var _voice: AudioStreamPlayer
var _sound: AudioStreamPlayer
var _fx: AudioStreamPlayer
var _queue: Array[String] = []
var _busy_until: float = 0.0
var _sound_until: float = 0.0
var _last_prompt: Array[String] = []
var _cache: Dictionary = {}
var _chime_step: int = 0


func _ready() -> void:
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
	for id: Variant in ids:
		t += length(str(id)) + GAP_SEC
	return t


## Say a sequence of clips now, replacing anything queued. Returns its length.
func say(ids: Array, is_prompt: bool = false) -> float:
	_queue.clear()
	for id: Variant in ids:
		_queue.append(str(id))
	if is_prompt:
		_last_prompt = _queue.duplicate()
	_voice.stop()
	_busy_until = 0.0
	_next()
	return total_length(ids)


## Append clips after whatever is being said.
func then(ids: Array) -> void:
	for id: Variant in ids:
		_queue.append(str(id))
	if not is_busy():
		_next()


func repeat_prompt() -> float:
	if _last_prompt.is_empty():
		return 0.0
	return say(_last_prompt)


func set_prompt(ids: Array) -> void:
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
	_busy_until = _now() + length(id) + GAP_SEC
