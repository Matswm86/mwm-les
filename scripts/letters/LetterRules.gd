class_name LetterRules
extends RefCounted
## Which letters are in play, which one is the target and which tiles show.
## Pure logic, no nodes and no sound, so the headless test can drive it.
## All numbers for the one-screen letter game live in the consts here.

const ORDER: Array[String] = ["a", "s", "i", "l", "o", "m"]
const START_COUNT: int = 2  # a and s
const STREAK_TO_ADD: int = 4  # correct first tries in a row before the next letter
const MAX_TILES: int = 3
const MAX_SAME_TARGET: int = 2  # never the same target 3 times in a row
const CORRECT_PAUSE_SEC: float = 1.0  # after the chime, before the next item
const AFTER_CLIP_GAP_SEC: float = 0.15  # silence between two clips in a row
const INTRO_GAP_SEC: float = 0.35  # between letters in the first-time intro

var count: int = START_COUNT
var streak: int = 0
var heard: Array[String] = []  # letters whose held sound has been played in an intro
var recent: Array[String] = []  # last targets, newest last
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func letters() -> Array[String]:
	return ORDER.slice(0, count)


func tile_count() -> int:
	return mini(count, MAX_TILES)


## Letters in the set the child has not heard in an intro yet.
func pending_intro() -> Array[String]:
	var out: Array[String] = []
	for l: String in letters():
		if not heard.has(l):
			out.append(l)
	return out


func mark_heard(l: String) -> void:
	if not heard.has(l):
		heard.append(l)


func pick_target() -> String:
	var pool: Array[String] = letters()
	if recent.size() >= MAX_SAME_TARGET:
		var last: String = recent[recent.size() - 1]
		var all_same: bool = true
		for k in range(recent.size() - MAX_SAME_TARGET, recent.size()):
			if recent[k] != last:
				all_same = false
		if all_same:
			pool.erase(last)
	var t: String = pool[rng.randi_range(0, pool.size() - 1)]
	recent.append(t)
	if recent.size() > 4:
		recent.pop_front()
	return t


## The target, every letter that must be shown (intro), then random fill.
func pick_tiles(target: String, must: Array[String]) -> Array[String]:
	var out: Array[String] = [target]
	for l: String in must:
		if not out.has(l) and out.size() < tile_count():
			out.append(l)
	var rest: Array[String] = []
	for l: String in letters():
		if not out.has(l):
			rest.append(l)
	while out.size() < tile_count() and not rest.is_empty():
		out.append(rest.pop_at(rng.randi_range(0, rest.size() - 1)))
	for k in range(out.size() - 1, 0, -1):  # Fisher-Yates with our own rng
		var j: int = rng.randi_range(0, k)
		var tmp: String = out[k]
		out[k] = out[j]
		out[j] = tmp
	return out


## Call once per item when the right tile is tapped. Returns the letter that
## was added to the set, or "".
func record(first_try: bool) -> String:
	if not first_try:
		streak = 0
		return ""
	streak += 1
	if streak >= STREAK_TO_ADD and count < ORDER.size():
		count += 1
		streak = 0
		return ORDER[count - 1]
	return ""


func to_dict() -> Dictionary:
	return {"count": count, "heard": heard}


func from_dict(d: Dictionary) -> void:
	count = clampi(int(d.get("count", START_COUNT)), START_COUNT, ORDER.size())
	heard.clear()
	for v: Variant in d.get("heard", []):
		if ORDER.has(str(v)):
			heard.append(str(v))
