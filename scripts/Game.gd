extends Node
## Autoload "Game": the learning engine for this device, the content pack,
## restored zones and what happened this session. Saves to user:// only.

const PACK_DIR: String = "res://content/nb_reading"
const SAVE_PATH: String = "user://learner.json"
const LOG_PATH: String = "user://evidence.log"

var engine: LearnEngine = LearnEngine.new()
var offline_lines: Array[Dictionary] = []
var restored: Array[bool] = [false, false, false]
var words_today: Array[String] = []
var words_read_to_adult: Array[String] = []
var practised_today: Dictionary = {}  # skill -> answers this session
var offline_today: Dictionary = {}
var persist: bool = true
var _session_start_ms: int = 0


func _ready() -> void:
	_session_start_ms = Time.get_ticks_msec()
	engine.setup(PACK_DIR)
	_load_offline()
	if OS.get_environment("MWM_LES_FRESH") != "":
		persist = false
	if persist:
		engine.log_path = LOG_PATH
		_load()
	start_session_content()


func start_session_content() -> void:
	if GameTune.SLICE_OPEN_ALL_SOUNDS:
		for sid: String in engine.pack.unlock_order:
			engine.model.introduce(sid)
	else:
		engine.introduce_ready()


## Fresh learner, nothing restored (screenshot bot and the parent "reset").
func reset_progress() -> void:
	engine = LearnEngine.new()
	engine.setup(PACK_DIR)
	if persist:
		engine.log_path = LOG_PATH
	restored = [false, false, false]
	words_today.clear()
	practised_today.clear()
	start_session_content()
	save()


func session_seconds() -> float:
	return (Time.get_ticks_msec() - _session_start_ms) / 1000.0


func label(skill_id: String) -> String:
	return str(engine.pack.skill(skill_id).get("label", "?"))


func phoneme_clip(skill_id: String) -> String:
	var audio: Dictionary = engine.pack.skill(skill_id).get("audio", {})
	return str(audio.get("short", ""))


func skill_for_label(text: String) -> String:
	for s: Dictionary in engine.pack.skills:
		if str(s.get("label", "")) == text:
			return str(s["id"])
	return ""


func note_answer(skill_ids: Array[String]) -> void:
	for s: String in skill_ids:
		practised_today[s] = int(practised_today.get(s, 0)) + 1


func note_word_built(word: String) -> void:
	if not words_today.has(word):
		words_today.append(word)


## Words for the read-to-a-grown-up card: today's words first, topped up with
## other decodable words from the pack.
func grownup_words() -> Array[String]:
	var out: Array[String] = words_today.duplicate()
	for it: Dictionary in engine.pack.items:
		if out.size() >= LearnBalance.GROWNUP_CARD_WORDS_MIN:
			break
		if str(it.get("kind", "")) != "word" or (it.get("activities", []) as Array).is_empty():
			continue
		var w: String = str(it["text"])
		if not out.has(w):
			out.append(w)
	return out.slice(0, LearnBalance.GROWNUP_CARD_WORDS_MAX)


## The offline follow-up for the sound practised most today (GDD 10.1).
func pick_offline_line() -> Dictionary:
	var best: String = ""
	var best_n: int = -1
	for s: Variant in practised_today:
		if int(practised_today[s]) > best_n:
			best_n = int(practised_today[s])
			best = str(s)
	var pool: Array[Dictionary] = []
	for line: Dictionary in offline_lines:
		if str(line.get("skill", "")) == best:
			pool.append(line)
	if pool.is_empty():
		for line: Dictionary in offline_lines:
			if str(line.get("skill", "")) == "":
				pool.append(line)
	if pool.is_empty():
		return {}
	offline_today = pool[engine.model.session_index % pool.size()]
	return offline_today


func save() -> void:
	if not persist:
		return
	var d: Dictionary = engine.to_dict()
	d["restored"] = restored
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not d is Dictionary:
		return
	var dd: Dictionary = d
	engine.from_dict(dd)
	engine.model.start_session()
	var r: Array = dd.get("restored", [])
	for i in mini(r.size(), 3):
		restored[i] = bool(r[i])


func _load_offline() -> void:
	var path: String = PACK_DIR.path_join("offline.json")
	if not FileAccess.file_exists(path):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if d is Dictionary:
		for line: Variant in (d as Dictionary).get("lines", []):
			offline_lines.append(line as Dictionary)
