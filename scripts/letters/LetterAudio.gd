class_name LetterAudio
extends Node
## The only sound source of the letter screen: one player, so a new clip
## always stops the one before it. Plays the owner's recorded letter sounds
## (assets/audio/rec) and two synthesized non-voice effects. Every clip that
## starts is logged by the file name of the stream actually put on the player.

signal clip_started(file: String)

const SHORT_PATH: String = "res://assets/audio/rec/lyd_%s.wav"
const HELD_PATH: String = "res://assets/audio/rec/lyd_%s_held.wav"
const CHIME_PATH: String = "res://assets/audio/sfx_chime_2.wav"
const TOK_PATH: String = "res://assets/audio/sfx_tok.wav"
const SFX_DB: float = -8.0
const MISSING_SEC: float = 0.4

var played: Array[String] = []
var _player: AudioStreamPlayer
var _cache: Dictionary = {}


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)


## Plays the held (long) sound of a letter (t and b: their short take, they
## have no held one). Returns its length in seconds.
func held(letter: String) -> float:
	if LetterRules.STOPS.has(letter):
		return short(letter)
	return _play(HELD_PATH % letter, 0.0)


## Plays the short sound of a letter. Returns its length in seconds.
func short(letter: String) -> float:
	return _play(SHORT_PATH % letter, 0.0)


func chime() -> float:
	return _play(CHIME_PATH, SFX_DB)


func tok() -> float:
	return _play(TOK_PATH, SFX_DB)


func stop() -> void:
	_player.stop()


func current_file() -> String:
	return _player.stream.resource_path.get_file() if _player.stream else ""


func _play(path: String, db: float) -> float:
	var s: AudioStream = _load(path)
	_player.stop()
	_player.stream = s
	_player.volume_db = db
	if s == null:
		push_error("LetterAudio: missing %s" % path)
		played.append("MISSING:" + path.get_file())
		return MISSING_SEC
	_player.play()
	var file: String = current_file()
	played.append(file)
	clip_started.emit(file)
	return s.get_length()


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _cache[path]
