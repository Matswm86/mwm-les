extends Node
## Autoload "Game": the learning engine for this device, the content pack,
## restored zones and what happened this session. Saves to user:// only.

const PACK_DIR: String = "res://content/nb_reading"
const SAVE_PATH: String = "user://learner.json"
const LOG_PATH: String = "user://evidence.log"

var engine: LearnEngine = LearnEngine.new()
var offline_lines: Array[Dictionary] = []
var restored: Array[bool] = [false, false, false]
# Progress that shapes what the child sees next (saved with the learner)
var story_seen: bool = false  # the opening story has been watched once
var stations_done: Array[bool] = [false, false, false]  # each station finished at least once
var named_letters: Array[String] = []  # letters introduced by name (period 1, GDD 4.2)
var demos_seen: Array[String] = []  # activity templates whose ghost demo has run (GDD 6.0)
var bridge_items_done: int = 0  # finished word bridges, drives the bridge scaffold
var bridge_words_met: Array[String] = []  # bridge words whose story has been told once
var bridge_word_uses: Dictionary = {}  # word id -> bridge visits it was built on (BridgeWords)
var bridge_last_words: Array[String] = []  # the words of the last bridge visit
var words_today: Array[String] = []
var found_today: Array[String] = []  # sound labels found in Hør og finn this session
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
	story_seen = false
	stations_done = [false, false, false]
	named_letters.clear()
	demos_seen.clear()
	bridge_items_done = 0
	bridge_words_met.clear()
	bridge_word_uses.clear()
	bridge_last_words.clear()
	words_today.clear()
	found_today.clear()
	practised_today.clear()
	start_session_content()
	save()


## Station order (owner report 2026-10-03): Hør og finn, then Sandskriving,
## and the word bridge only after both have been done once. After that the
## child goes round the stations not yet visited this session, in order.
func next_station(visited: Array[bool]) -> int:
	for i in 3:
		if not stations_done[i]:
			return i
	for i in 3:
		if not visited[i]:
			return i
	return -1


func demo_due(activity: String) -> bool:
	return LearnBalance.GHOST_DEMO_FIRST_USE and not demos_seen.has(activity)


func mark_demo(activity: String) -> void:
	if not demos_seen.has(activity):
		demos_seen.append(activity)


func session_seconds() -> float:
	return (Time.get_ticks_msec() - _session_start_ms) / 1000.0


func label(skill_id: String) -> String:
	return str(engine.pack.skill(skill_id).get("label", "?"))


func phoneme_clip(skill_id: String) -> String:
	return sound_clip(skill_id, "short")


## A clip tied to one sound: short, hold, intro, link, back (skills.json "audio").
func sound_clip(skill_id: String, kind: String) -> String:
	var audio: Dictionary = engine.pack.skill(skill_id).get("audio", {})
	return str(audio.get(kind, ""))


## The sound answered most often this session ("" if none).
func most_practised() -> String:
	var best: String = ""
	var best_n: int = 0
	for s: Variant in practised_today:
		if int(practised_today[s]) > best_n:
			best_n = int(practised_today[s])
			best = str(s)
	return best


## Skill id for a letter id or its glyph ("aa" and "å" both give gp_aa).
func skill_for_label(text: String) -> String:
	var shown: String = LetterRules.glyph(text)
	for s: Dictionary in engine.pack.skills:
		if str(s.get("label", "")) == shown:
			return str(s["id"])
	return ""


func note_answer(skill_ids: Array[String]) -> void:
	for s: String in skill_ids:
		practised_today[s] = int(practised_today.get(s, 0)) + 1


## Today's bridge words: counted for the rotation, remembered as the last visit.
func note_bridge_words(ids: Array[String]) -> void:
	for id: String in ids:
		bridge_word_uses[id] = int(bridge_word_uses.get(id, 0)) + 1
	bridge_last_words = ids.duplicate()
	save()


func note_word_built(word: String) -> void:
	if not words_today.has(word):
		words_today.append(word)


## Words for the read-to-a-grown-up card: today's words first, topped up with
## the pack's card words (is, lam, lama, sol: each has its own [ord:x] clip).
func grownup_words() -> Array[String]:
	var out: Array[String] = words_today.duplicate()
	for it: Dictionary in engine.pack.items:
		if out.size() >= LearnBalance.GROWNUP_CARD_WORDS_MIN:
			break
		if str(it.get("kind", "")) != "word" or not bool(it.get("card", false)):
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
	d["story_seen"] = story_seen
	d["stations_done"] = stations_done
	d["named_letters"] = named_letters
	d["demos_seen"] = demos_seen
	d["bridge_items_done"] = bridge_items_done
	d["bridge_words_met"] = bridge_words_met
	d["bridge_word_uses"] = bridge_word_uses
	d["bridge_last_words"] = bridge_last_words
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
	story_seen = bool(dd.get("story_seen", false))
	var sd: Array = dd.get("stations_done", [])
	for i in mini(sd.size(), 3):
		stations_done[i] = bool(sd[i])
	for l: Variant in dd.get("named_letters", []):
		named_letters.append(str(l))
	for a: Variant in dd.get("demos_seen", []):
		demos_seen.append(str(a))
	bridge_items_done = int(dd.get("bridge_items_done", 0))
	for w: Variant in dd.get("bridge_words_met", []):
		bridge_words_met.append(str(w))
	var wu: Variant = dd.get("bridge_word_uses", {})
	if wu is Dictionary:
		for k: Variant in wu:
			bridge_word_uses[str(k)] = int((wu as Dictionary)[k])
	for w2: Variant in dd.get("bridge_last_words", []):
		bridge_last_words.append(str(w2))


func _load_offline() -> void:
	var path: String = PACK_DIR.path_join("offline.json")
	if not FileAccess.file_exists(path):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if d is Dictionary:
		for line: Variant in (d as Dictionary).get("lines", []):
			offline_lines.append(line as Dictionary)
