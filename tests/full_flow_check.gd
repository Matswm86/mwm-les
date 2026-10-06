extends RefCounted
## Plays one whole play headless through the real Main scene: the opening,
## levels 1-3 (sol, sel, les), a relaunch in the middle of the play (a new
## Main, as after closing the app), levels 4-6 (mat, båt, lam), goodnight,
## then the first level of a review play. Every action goes through the same
## function a touch calls. Checks, from the Voice clip log (the stream
## actually put on the one player):
## - only owner recordings and the non-voice effects ever play (nothing
##   refused, every file is in assets/audio/rec or an sfx_* file); listed
##   lines not recorded yet are skipped and printed;
## - every scene plays only its own lines; no sentence after a letter sound
##   inside one sequence;
## - each level: the word's hook in the hub; in Hør og finn every letter of
##   the word asked exactly ASKS_PER_LETTER times (once in a review), tiles =
##   the word's letters + at most one learned letter, new letters introduced;
##   in Sandskriving a new letter is shown twice, traced, then written alone,
##   a learned one written once; every stone is laid in the level's word;
## - the six words are built in order, lam last, the lamb comes over;
## - the relaunch greets with level_back and goes on at the saved level.
## Prints the clip sequence per scene and the play's length on the game clock.

const SPEED: float = 20.0
const SENTENCES: Dictionary = {
	"opening": ["op_1", "op_2", "op_3", "op_4", "op_5"],
	"hub":
	[
		"hub_find",
		"hub_write",
		"hub_bridge",
		"hub_back",
		"hub_idle",
		"level_back",
		"levels_intro",
		"lamb_baa"
	],
	"find": ["find_in", "intro_again", "find_ask", "find_right", "find_wrong", "find_done"],
	"write":
	[
		"write_in",
		"write_next",
		"write_show_again",
		"write_trace",
		"write_alone",
		"write_retry",
		"write_right",
		"write_done"
	],
	"bridge":
	[
		"bridge_in",
		"bridge_ask",
		"bridge_right",
		"level_next",
		"bridge_done",
		"bridge_walk",
		"final_party"
	],
	"end": ["end_bye"],
}
const OTHER_OK: Dictionary = {
	"opening": [],
	"hub": ["hook_"],
	"find": ["lyd_", "navn_", "intro_", "sfx_chime_", "sfx_tok"],
	"write": ["lyd_", "sfx_chime_"],
	"bridge": ["lyd_", "sfx_chime_", "sfx_tok", "bridge_word_", "mid_", "done_"],
	"end": [],
}

var failures: Array[String] = []
var tree: SceneTree
var main: MainScene
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var counts: Dictionary = {}  # what was exercised
var built: Array[String] = []  # words whose bridge visit finished, in order
var play_sec: float = 0.0  # game clock from the first hub line to goodnight
var _steps: Array[String] = []  # write station steps of the current letter
var _relaunch_at: int = -1  # first clip after the relaunch (the old app's sound ends there)
var _snap: Dictionary = {}  # letter -> {shows, traced, steps} when its stone lifted


func check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
		print("FAIL: " + msg)


func run(p_tree: SceneTree) -> void:
	tree = p_tree
	rng.seed = 41
	Engine.time_scale = SPEED
	Game.persist = false
	Game.reset_progress()
	Voice.stop()
	Voice.clip_log.clear()
	Voice.refused.clear()
	Voice.missing.clear()
	Voice.sequence_errors = 0
	_new_main()
	await _opening()
	var t0: float = Voice._clock
	for k in 3:
		await _level(k, k == 0)
	# relaunch: the app is closed after level 3 and opened again
	await _until(
		func() -> bool: return main.mode == MainScene.Mode.HUB and main.level == 3,
		90.0,
		"level 4 hub"
	)
	check(Game.level == 3, "saved level after three levels is %d" % Game.level)
	main.queue_free()
	await _frames(3)
	Voice.stop()
	var relaunch_at: int = Voice.clip_log.size()
	_relaunch_at = relaunch_at
	_new_main()
	await _until(func() -> bool: return main.mode == MainScene.Mode.HUB, 60.0, "relaunch hub")
	await _frames(2)
	check(_id_at(relaunch_at) == "level_back", "relaunch greeted with %s" % _id_at(relaunch_at))
	check(main.level == 3, "relaunch went on at level %d, not 4" % (main.level + 1))
	for k in range(3, 6):
		await _level(k, false)
	await _until(func() -> bool: return main.mode == MainScene.Mode.END, 60.0, "goodnight")
	play_sec = Voice._clock - t0
	check(built == BridgeWords.LEVELS, "words built %s, want %s" % [built, BridgeWords.LEVELS])
	check(Game.plays_done == 1 and Game.level == 0, "play not marked done")
	# a tap after goodnight: a review play, first level only
	main.new_session()
	await _level(0, false)
	await _frames(5)
	_report()
	main.queue_free()
	await _frames(3)
	Engine.time_scale = 1.0


func _new_main() -> void:
	main = (load("res://scenes/Main.tscn") as PackedScene).instantiate() as MainScene
	tree.root.add_child(main)
	(main.stations[0] as HorOgFinn).rules.rng.seed = 11
	(main.stations[1] as Sandskriving).step.connect(_on_write_step)
	(main.stations[2] as OrdBro).step.connect(_on_bridge_step)


# ---------------------------------------------------------------- opening and hub


func _opening() -> void:
	await _until(
		func() -> bool: return main.story != null and main.story.waiting_for_pip, 60.0, "op_5"
	)
	await _idle_voice()
	main.story.tap_pip()
	counts["opening"] = 1


## One level: the three stations with the level's word.
func _level(k: int, wait_idle_line: bool) -> void:
	var w: String = BridgeWords.LEVELS[k]
	var hub_at: int = Voice.clip_log.size()
	await _hub_go(0, wait_idle_line)
	check(main.level == k, "level %d running, want %d" % [main.level, k])
	var hub_ids: Array[String] = _ids_from(hub_at)
	check(
		hub_ids.has(BridgeWords.hook_clip(w)) or Voice.stream(BridgeWords.hook_clip(w)) == null,
		"level %s: no hook in the hub (%s)" % [w, hub_ids]
	)
	await _find(w)
	await _hub_go(1, false)
	await _write(w)
	await _hub_go(2, false)
	await _bridge(w)
	counts["levels"] = int(counts.get("levels", 0)) + 1


func _hub_go(i: int, wait_idle_line: bool) -> void:
	await _until(
		func() -> bool: return main.mode == MainScene.Mode.HUB and main._next == i,
		90.0,
		"hub %d" % i
	)
	check(main.beacons[i].visible, "hub: station %d not lit" % i)
	await _idle_voice()
	if wait_idle_line:
		var before: int = Voice.clip_log.size()
		await _until(func() -> bool: return Voice.clip_log.size() > before, 30.0, "hub_idle")
		check(_id_at(before) == "hub_idle", "hub idle played %s" % _id_at(before))
		await _idle_voice()
	main.choose_station()
	await _until(func() -> bool: return main.mode == MainScene.Mode.STATION, 30.0, "station %d" % i)


# ---------------------------------------------------------------- find


func _find(w: String) -> void:
	var find: HorOgFinn = main.stations[0] as HorOgFinn
	var word: Array[String] = BridgeWords.letters_of(w)
	var plan: Dictionary = main.plan()
	var asked: Dictionary = {}
	var b0: int = Voice.clip_log.size()
	var items: int = 0
	while find.active:
		var ok: bool = await _until(
			func() -> bool: return (not find.busy and not Voice.is_busy()) or not find.active,
			60.0,
			"find item"
		)
		if not ok or not find.active:
			break
		var target: String = find.target
		var tiles: Array[String] = find.tile_letters()
		check(tiles.has(target), "find: target %s not on tiles %s" % [target, tiles])
		var extra: int = 0
		for l: String in tiles:
			if not word.has(l):
				extra += 1
				check(
					(plan["learned"] as Array).has(l), "find %s: distractor %s not learned" % [w, l]
				)
		for l: String in word:
			check(tiles.has(l), "find %s: letter %s not on the tiles %s" % [w, l, tiles])
		check(extra <= HorOgFinn.MAX_DISTRACTORS, "find %s: %d distractors" % [w, extra])
		var last: int = Voice.clip_log.size() - 1
		check(
			(
				_id_at(last) == Voice.held_id(target)
				and _id_at(last - 1) in ["find_ask", "find_wrong"]
			),
			"find prompt for %s ended %s, %s" % [target, _id_at(last - 1), _id_at(last)]
		)
		asked[target] = int(asked.get(target, 0)) + 1
		if (items == 0 or rng.randf() < 0.25) and tiles.size() > 1:
			var wrong: Array[String] = []
			for l: String in tiles:
				if l != target:
					wrong.append(l)
			var bad: String = wrong[rng.randi_range(0, wrong.size() - 1)]
			var b2: int = Voice.clip_log.size()
			find.tap(bad)
			await _until(func() -> bool: return not find.busy, 30.0, "after wrong")
			await _idle_voice()
			var got: Array[String] = _ids_from(b2)
			var want: Array[String] = [
				Voice.short_id(bad), "sfx_tok", "find_wrong", Voice.held_id(target)
			]
			check(got == want, "wrong tap %s (target %s) played %s" % [bad, target, got])
			counts["find_wrong"] = int(counts.get("find_wrong", 0)) + 1
		var b3: int = Voice.clip_log.size()
		var done_before: int = find.items_done
		find.tap(target)
		await _until(
			func() -> bool: return find.items_done > done_before and find.busy, 10.0, "right"
		)
		await _until(
			func() -> bool: return Voice.clip_log.size() >= b3 + 3 or not find.active, 30.0, ""
		)
		check(
			_id_at(b3 + 1).begins_with("sfx_chime_") and _id_at(b3 + 2) == "find_right",
			"right answer: %s, %s" % [_id_at(b3 + 1), _id_at(b3 + 2)]
		)
		items += 1
		await _until(
			func() -> bool: return find.busy == false or not find.active, 30.0, "next item"
		)
	var times: int = 1 if Game.review() else HorOgFinn.ASKS_PER_LETTER
	for l: String in word:
		check(
			int(asked.get(l, 0)) == times,
			"find %s: %s asked %d times, want %d" % [w, l, int(asked.get(l, 0)), times]
		)
	check(items == word.size() * times, "find %s: %d items" % [w, items])
	# new letters: intro, then intro_again and the held sound
	var ids: Array[String] = _ids_from(b0)
	for l: Variant in plan["new"]:
		var at: int = ids.find("intro_" + str(l))
		check(at >= 0, "find %s: no intro for %s" % [w, l])
		check(
			at >= 0 and ids[at + 1] == "intro_again" and ids[at + 2] == Voice.held_id(str(l)),
			"find %s: after intro_%s came %s" % [w, l, ids.slice(at + 1, at + 3)]
		)
		counts["intro"] = int(counts.get("intro", 0)) + 1
	print("find %s: %d items, asked %s, tiles %s" % [w, items, asked, find.tile_set])
	counts["find_items"] = int(counts.get("find_items", 0)) + items


# ---------------------------------------------------------------- write


func _on_write_step(name: String) -> void:
	var w: Sandskriving = main.stations[1] as Sandskriving
	if name in ["in", "next"]:
		_steps.clear()
	_steps.append(name)
	if name == "stone":
		_snap[w.letter] = {"shows": w.shows, "traced": w.traced, "steps": _steps.duplicate()}
	if name == "model":
		await _frames(1)
		check(
			_last_id() == Voice.held_id(w.letter), "model for %s played %s" % [w.letter, _last_id()]
		)


func _write(word_id: String) -> void:
	var w: Sandskriving = main.stations[1] as Sandskriving
	var plan: Dictionary = main.plan()
	var word: Array[String] = BridgeWords.letters_of(word_id)
	var done: int = 0
	var bad_trace_done: bool = false
	var per_letter: Dictionary = {}
	while w.active:
		var ok: bool = await _until(
			func() -> bool:
				var inking: bool = (
					w.phase == Sandskriving.Phase.WRITE or w.phase == Sandskriving.Phase.TRACE
				)
				return (inking and not Voice.is_busy()) or not w.active,
			60.0,
			"write turn"
		)
		if not ok or not w.active:
			break
		if w.phase == Sandskriving.Phase.TRACE:
			if not bad_trace_done:  # half a letter is not enough to count as traced
				bad_trace_done = true
				var half: Array[PackedVector2Array] = [w.model_screen_strokes()[0].slice(0, 6)]
				var b: int = Voice.clip_log.size()
				w.submit(half)
				await _until(func() -> bool: return Voice.clip_log.size() > b, 20.0, "retry")
				check(_id_at(b) == "write_retry", "half a trace got %s" % _id_at(b))
				continue
			w.submit(w.model_screen_strokes())
			await _until(func() -> bool: return w.traced, 20.0, "traced %s" % w.letter)
			continue
		var letter: String = w.letter
		var before: int = w.written.size()
		w.submit(w.model_screen_strokes())
		await _until(func() -> bool: return w.written.size() > before, 40.0, "stone %s" % letter)
		var is_new: bool = (plan["new"] as Array).has(letter)
		var snap: Dictionary = _snap.get(letter, {})
		var steps: Array = snap.get("steps", [])
		var shows: int = int(snap.get("shows", -1))
		var traced: bool = bool(snap.get("traced", false))
		if is_new:
			check(shows == Sandskriving.MODEL_SHOWS, "%s shown %d times" % [letter, shows])
			check(traced, "%s not traced" % letter)
			var want: Array[String] = ["model", "show_again", "model", "trace", "traced", "alone"]
			var got: Array[String] = []
			for st: String in steps:
				if st in want:
					got.append(st)
			check(got == want, "new letter %s steps %s" % [letter, steps])
			counts["write_new"] = int(counts.get("write_new", 0)) + 1
		else:
			check(shows == 0 and not traced, "learned letter %s was shown/traced" % letter)
			check(steps.has("quick"), "learned letter %s steps %s" % [letter, steps])
			counts["write_quick"] = int(counts.get("write_quick", 0)) + 1
		per_letter[letter] = int(per_letter.get(letter, 0)) + 1
		done += 1
	check(w.written == word, "write %s: stones %s, want the word's letters" % [word_id, w.written])
	print("write %s: stones %s, new %s" % [word_id, w.written, plan["new"]])


# ---------------------------------------------------------------- bridge


func _on_bridge_step(name: String) -> void:
	var br: OrdBro = main.stations[2] as OrdBro
	if name.begins_with("lit_"):
		var i: int = int(name.trim_prefix("lit_"))
		var clip: String = BridgeWords.word_clip(str(br.words[0]["id"]))
		check(_last_id() == clip, "plank %d lit outside %s (%s)" % [i, clip, _last_id()])
		counts["planks_lit"] = int(counts.get("planks_lit", 0)) + 1
	if name == "walk":
		check(_last_id() == "bridge_walk", "lamb walks during %s" % _last_id())


func _bridge(w: String) -> void:
	var br: OrdBro = main.stations[2] as OrdBro
	var b0: int = Voice.clip_log.size()
	while br.active:
		var ok: bool = await _until(
			func() -> bool:
				return (not br.busy and br.cur >= 0 and not Voice.is_busy()) or not br.active,
			60.0,
			"bridge ask"
		)
		if not ok or not br.active:
			break
		var want: String = br.graphemes[br.cur]
		var last: int = Voice.clip_log.size() - 1
		check(
			_id_at(last) == Voice.held_id(want) and _id_at(last - 1) in ["bridge_ask"],
			"bridge prompt for %s ended %s, %s" % [want, _id_at(last - 1), _id_at(last)]
		)
		var wrong: Stone = null
		for st: Stone in br.stones:
			if not st.placed and st.letter != want:
				wrong = st
		if wrong and rng.randf() < 0.4:
			var b: int = Voice.clip_log.size()
			br.grab(wrong)
			br.drop(wrong, br.cur)
			await _until(func() -> bool: return not br.busy, 30.0, "after wrong stone")
			await _idle_voice()
			var got: Array[String] = _ids_from(b + 1)
			var exp: Array[String] = [Voice.short_id(wrong.letter), "sfx_tok", Voice.held_id(want)]
			check(got == exp, "wrong stone %s on %s played %s" % [wrong.letter, want, got])
			counts["bridge_wrong"] = int(counts.get("bridge_wrong", 0)) + 1
		var st2: Stone = br.stone_for(want)
		var b2: int = Voice.clip_log.size()
		br.grab(st2)
		br.drop(st2, br.cur)
		await _until(func() -> bool: return Voice.clip_log.size() >= b2 + 3, 30.0, "right stone")
		check(
			_id_at(b2 + 1).begins_with("sfx_chime_") and _id_at(b2 + 2) == "bridge_right",
			"right stone: %s, %s" % [_id_at(b2 + 1), _id_at(b2 + 2)]
		)
		await _until(func() -> bool: return br.cur == -1 or Voice.is_busy(), 10.0, "")
	for st: Stone in br.stones:
		check(st.placed, "stone %s written but never laid in %s" % [st.letter, w])
	var ids: Array[String] = _ids_from(b0)
	var wc: String = BridgeWords.word_clip(w)
	check(ids.has(wc), "bridge %s: no %s" % [w, wc])
	if w == BridgeWords.LAST:
		check(ids.find("bridge_done") > ids.find(wc), "lam: bridge_done not after the word")
		var walked: bool = main.lamb.global_position.distance_to(main.world.bridge_start) < 3.0
		check(walked, "the lamb did not come over (at %s)" % main.lamb.global_position)
	else:
		var dc: String = BridgeWords.done_clip(w)
		check(ids.find(dc) > ids.find(wc), "bridge %s: %s not after the word (%s)" % [w, dc, ids])
		check(ids.find("level_next") > ids.find(dc), "bridge %s: level_next not last" % w)
		check(not ids.has("bridge_done"), "bridge_done before lam")
	if not Game.review():
		built.append(w)


# ---------------------------------------------------------------- report


func _report() -> void:
	var by_scene: Dictionary = {}
	for e: Dictionary in Voice.clip_log:
		var sc: String = str(e["scene"])
		if not by_scene.has(sc):
			by_scene[sc] = []
		(by_scene[sc] as Array).append(str(e["id"]))
		var id: String = str(e["id"])
		var file: String = str(e["file"])
		check(not id.begins_with("tts_") and not file.begins_with("tts_"), "tts clip %s" % id)
		check(Voice.is_known(id), "unknown clip %s" % id)
		check(file == id + ".wav", "clip %s played file %s" % [id, file])
		var path: String = Voice.path_of(id)
		check(
			path.begins_with("res://assets/audio/rec/") or id.begins_with("sfx_"),
			"clip %s not from assets/audio/rec" % id
		)
	# nothing the game says on its own is cut short: a clip may only be cut by
	# a letter sound the child set off (a tap or a grabbed stone)
	for k in range(Voice.clip_log.size() - 1):
		var a: Dictionary = Voice.clip_log[k]
		var b: Dictionary = Voice.clip_log[k + 1]
		var ends: float = float(a["t"]) + Voice.length(str(a["id"])) - 0.03
		if float(b["t"]) < ends:
			var by_child: bool = (
				str(b["id"]).begins_with("lyd_")
				and (not str(b["id"]).ends_with("_held") or LetterRules.STOPS.has(str(b["id"])))
			)
			check(
				by_child or str(a["scene"]) != str(b["scene"]) or k + 1 == _relaunch_at,
				(
					"[%s] %s cut short by %s after %.2fs"
					% [a["scene"], a["id"], b["id"], float(b["t"]) - float(a["t"])]
				)
			)
	check(Voice.refused.is_empty(), "refused ids %s" % [Voice.refused])
	check(
		Voice.sequence_errors == 0,
		"%d sequences with a sentence after a sound" % Voice.sequence_errors
	)
	for sc: String in ["opening", "hub", "find", "write", "bridge", "end"]:
		var ids: Array = by_scene.get(sc, [])
		print("[%s] %d clips: %s" % [sc, ids.size(), " ".join(ids)])
		var allowed: Array = SENTENCES[sc]
		for id: Variant in ids:
			var s: String = str(id)
			var ok: bool = allowed.has(s)
			for pre: Variant in OTHER_OK[sc]:
				if s.begins_with(str(pre)):
					ok = true
			check(ok, "scene %s played %s (not one of its lines)" % [sc, s])
		for want: Variant in allowed:
			var recorded: bool = Voice.stream(str(want)) != null
			check(
				ids.has(want) or not recorded or want in ["hub_back"],
				"scene %s never played %s" % [sc, want]
			)
	print("not recorded yet (skipped): %s" % [Voice.missing])
	print("exercised: %s" % [counts])
	print(
		(
			"one full play: %.0f s on the game clock (%.1f min), child answers instant"
			% [play_sec, play_sec / 60.0]
		)
	)
	print("full flow: %d clips, failures %d" % [Voice.clip_log.size(), failures.size()])
	print("FULL FLOW RESULT: %s" % ("PASS" if failures.is_empty() else "FAIL"))


# ---------------------------------------------------------------- helpers


func _id_at(i: int) -> String:
	if i < 0 or i >= Voice.clip_log.size():
		return "(none)"
	return str(Voice.clip_log[i]["id"])


func _last_id() -> String:
	return _id_at(Voice.clip_log.size() - 1)


func _ids_from(i: int) -> Array[String]:
	var out: Array[String] = []
	for k in range(i, Voice.clip_log.size()):
		out.append(_id_at(k))
	return out


func _idle_voice() -> void:
	await _until(func() -> bool: return not Voice.is_busy(), 30.0, "voice idle")


func _until(cond: Callable, timeout_sec: float, what: String) -> bool:
	var start: int = Time.get_ticks_msec()
	while not bool(cond.call()):
		if Time.get_ticks_msec() - start > int(timeout_sec * 1000.0):
			if what != "":
				check(false, "timeout waiting for %s (mode %d)" % [what, main.mode])
			return false
		await tree.process_frame
	return true


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame
