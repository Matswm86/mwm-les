class_name LetterRules
extends RefCounted
## Which letters are in play, which one is the target and which tiles show.
## Pure logic, no nodes and no sound, so the headless test can drive it.
## All numbers for the one-screen letter game live in the consts here.

## Letter ids. File ids spell å as "aa" (lyd_aa, intro_aa); glyph() gives what is shown.
const ORDER: Array[String] = ["a", "s", "i", "l", "o", "m", "e", "t", "b", "aa"]
const GLYPHS: Dictionary = {"aa": "å"}
## Stops cannot be held: they have a short take only, played wherever a held sound would be.
const STOPS: Array[String] = ["t", "b"]
const START_COUNT: int = 2  # a and s
const STREAK_TO_ADD: int = 8  # correct first tries in a row before the next letter is due
const MAX_TILES: int = 3
const MAX_SAME_TARGET: int = 2  # never the same target 3 times in a row
const FOCUS_AFTER_INTRO: int = 2  # the first targets after an intro are the new letter
const NEWEST_WEIGHT: int = 2  # the newest letter is this many times as likely as the others
const CORRECT_PAUSE_SEC: float = 1.5  # after the chime, before the next item
const AFTER_CLIP_GAP_SEC: float = 0.4  # silence between two clips in a row
const INTRO_GAP_SEC: float = 1.0  # between an intro take and the sound heard again

var count: int = START_COUNT
var streak: int = 0
var due: bool = false  # enough first tries: the next letter comes at the next visit start
var focus: Array[String] = []  # targets that come first (a letter just introduced)
var heard: Array[String] = []  # letters whose held sound has been played in an intro
var recent: Array[String] = []  # last targets, newest last
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


## What a letter id looks like on screen ("aa" -> "å").
static func glyph(l: String) -> String:
	return str(GLYPHS.get(l, l))


## The letter id for a shown glyph or a label ("å" -> "aa").
static func id_of(text: String) -> String:
	for k: Variant in GLYPHS:
		if str(GLYPHS[k]) == text:
			return str(k)
	return text


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


## Call at the start of a visit: adds the next letter if it is due (at most
## one new letter per visit, never in the middle of one). Returns it or "".
func begin_visit() -> String:
	if not due or count >= ORDER.size():
		return ""
	due = false
	count += 1
	return ORDER[count - 1]


func mark_heard(l: String) -> void:
	if heard.has(l):
		return
	heard.append(l)
	if count > START_COUNT:  # a and s come together; later letters get their own run
		for k in FOCUS_AFTER_INTRO - 1:  # the intro item itself already asks for it
			focus.append(l)


func pick_target() -> String:
	var pending: Array[String] = pending_intro()
	if count > START_COUNT and not pending.is_empty():
		focus.push_front(pending[pending.size() - 1])  # the item that introduces a letter asks for it
	if not focus.is_empty():
		var f: String = focus.pop_front()
		recent.append(f)
		if recent.size() > 4:
			recent.pop_front()
		return f
	var pool: Array[String] = letters()
	if count > START_COUNT:
		for k in NEWEST_WEIGHT - 1:
			pool.append(ORDER[count - 1])
	if recent.size() >= MAX_SAME_TARGET:
		var last: String = recent[recent.size() - 1]
		var all_same: bool = true
		for k in range(recent.size() - MAX_SAME_TARGET, recent.size()):
			if recent[k] != last:
				all_same = false
		if all_same:
			while pool.has(last):
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


## Call once per item when the right tile is tapped. After STREAK_TO_ADD
## first tries in a row the next letter is due (added by begin_visit).
func record(first_try: bool) -> void:
	if not first_try:
		streak = 0
		return
	streak += 1
	if streak >= STREAK_TO_ADD and count < ORDER.size():
		due = true
		streak = 0


func to_dict() -> Dictionary:
	return {"count": count, "heard": heard, "due": due}


func from_dict(d: Dictionary) -> void:
	count = clampi(int(d.get("count", START_COUNT)), START_COUNT, ORDER.size())
	due = bool(d.get("due", false))
	heard.clear()
	for v: Variant in d.get("heard", []):
		if ORDER.has(str(v)):
			heard.append(str(v))
