class_name BridgeWords
extends RefCounted
## The words the child builds on the bridge, and which ones today. Pure logic,
## no nodes and no sound, so the headless test can drive it.
## Every word has two recordings: hook_<id> (the story line that motivates it,
## said while its picture shows) and bridge_word_<id> (the sounding-out clip;
## letter onsets in content/nb_reading/clip_marks.json). File ids spell å as
## "aa": the word båt has id "baat" and letters b, aa, t.
## A visit builds up to MAX_STORY_WORDS story words and then lam, always last:
## bridge_done says "Der står det lam." and the lamb walks over.

const LAST: String = "lam"
const MAX_STORY_WORDS: int = 2
const MAX_WRITE: int = 6  # letters written in the sand per session; the rest lie ready
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


## Today's words, lam last. A story word is eligible when the child knows at
## least one of its letters and its clips exist (`available`). Words from the
## last visit wait one visit when there are others, so the child meets every
## word; then the most known letters first, then the least used, then the
## order in WORDS.
static func pick(
	known: Array[String], uses: Dictionary, last: Array[String], available: Array[String]
) -> Array[String]:
	var eligible: Array[String] = []
	for id: String in WORDS:
		if id != LAST and available.has(id) and known_count(id, known) > 0:
			eligible.append(id)
	var order: Array = WORDS.keys()
	var rank: Callable = func(a: String, b: String) -> bool:
		var ka: int = known_count(a, known)
		var kb: int = known_count(b, known)
		if ka != kb:
			return ka > kb
		var ua: int = int(uses.get(a, 0))
		var ub: int = int(uses.get(b, 0))
		if ua != ub:
			return ua < ub
		return order.find(a) < order.find(b)
	var fresh: Array[String] = []
	var rested: Array[String] = []
	for id: String in eligible:
		if last.has(id):
			rested.append(id)
		else:
			fresh.append(id)
	fresh.sort_custom(rank)
	rested.sort_custom(rank)
	var out: Array[String] = []
	for id: String in fresh + rested:
		if out.size() < MAX_STORY_WORDS:
			out.append(id)
	if available.has(LAST):
		out.append(LAST)
	return out


## The plan for one visit: per word its letters and the slots the child fills
## (letters the child knows; the others lie ready as planks). At most
## MAX_WRITE letters are written: picked round-robin over the words so every
## word keeps a letter to lay, the rest lie ready. `stones` is the writing
## order: each letter's occurrences together, so a repeat comes right after
## the first one ("Skriv den en gang til.").
static func plan(ids: Array[String], known: Array[String]) -> Dictionary:
	var cand: Array = []  # per word: slot indexes the child could fill
	for id: String in ids:
		var c: Array[int] = []
		var ls: Array[String] = letters_of(id)
		for i in ls.size():
			if known.has(ls[i]):
				c.append(i)
		cand.append(c)
	var chosen: Array = []
	for w in ids.size():
		chosen.append([] as Array[int])
	var total: int = 0
	var round_i: int = 0
	var more: bool = true
	while more and total < MAX_WRITE:
		more = false
		for w in ids.size():
			var c2: Array[int] = cand[w]
			if round_i < c2.size():
				more = true
				if total < MAX_WRITE:
					(chosen[w] as Array[int]).append(c2[round_i])
					total += 1
		round_i += 1
	var words: Array[Dictionary] = []
	var in_order: Array[String] = []
	for w in ids.size():
		var miss: Array[int] = chosen[w]
		miss.sort()
		var ls2: Array[String] = letters_of(ids[w])
		for i: int in miss:
			in_order.append(ls2[i])
		words.append({"id": ids[w], "letters": ls2, "missing": miss})
	var stones: Array[String] = []
	for l: String in in_order:
		if not stones.has(l):
			for l2: String in in_order:
				if l2 == l:
					stones.append(l2)
	return {"words": words, "stones": stones}
