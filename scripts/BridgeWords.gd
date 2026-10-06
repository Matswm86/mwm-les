class_name BridgeWords
extends RefCounted
## The words the child builds on the bridge, and which ones today. Pure logic,
## no nodes and no sound, so the headless test can drive it.
## Every word has two recordings: hook_<id> (the story line that motivates it,
## said while its picture shows) and bridge_word_<id> (the sounding-out clip;
## letter onsets in content/nb_reading/clip_marks.json). File ids spell å as
## "aa": the word båt has id "baat" and letters b, aa, t.
## One play is six levels, one word each, in LEVELS order; lam is always the
## last: bridge_done says "Der står det lam." and the lamb walks over. A
## level's new letters are the word's letters the child has not learned yet.

const LAST: String = "lam"
const LEVELS: Array[String] = ["sol", "sel", "les", "mat", "baat", "lam"]
## id -> letters (letter ids) and the picture shown while the hook line plays
const WORDS: Dictionary = {
	"sol": {"letters": ["s", "o", "l"], "picture": "sun"},
	"sel": {"letters": ["s", "e", "l"], "picture": "seal"},
	"baat": {"letters": ["b", "aa", "t"], "picture": "boat"},
	"mat": {"letters": ["m", "a", "t"], "picture": "food"},
	"les": {"letters": ["l", "e", "s"], "picture": "book"},
	"lam": {"letters": ["l", "a", "m"], "picture": "lamb"},
}


static func letters_of(id: String) -> Array[String]:
	var out: Array[String] = []
	for l: Variant in (WORDS.get(id, {}) as Dictionary).get("letters", []):
		out.append(str(l))
	return out


static func hook_clip(id: String) -> String:
	return "hook_" + id


static func word_clip(id: String) -> String:
	return "bridge_word_" + id


static func known_count(id: String, known: Array[String]) -> int:
	var n: int = 0
	for l: String in letters_of(id):
		if known.has(l):
			n += 1
	return n


static func done_clip(id: String) -> String:
	return "done_" + id


## Letters of word `id` that are not in `learned`, in word order.
static func new_letters(id: String, learned: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for l: String in letters_of(id):
		if not learned.has(l):
			out.append(l)
	return out


## Every letter the levels before `level` brought in.
static func learned_before(level: int) -> Array[String]:
	var out: Array[String] = []
	for k in mini(level, LEVELS.size()):
		for l: String in letters_of(LEVELS[k]):
			if not out.has(l):
				out.append(l)
	return out
