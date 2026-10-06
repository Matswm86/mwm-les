extends RefCounted
## Plays the whole game headless through the real Main scene: the opening,
## the hub, Hør og finn, Sandskriving, Ordbroa, goodnight, then a second
## session (hub_back). Every action goes through the same function a touch
## calls. Checks, from the Voice clip log (the stream actually put on the one
## player):
## - only owner recordings and the non-voice effects ever play (no tts_*,
##   nothing refused, every file is in assets/audio/rec or an sfx_* file);
## - every letter prompt, tap and long-press plays only its own letter's files;
## - every scene plays its listed line ids, and only those;
## - no sentence after a letter sound inside one sequence.
## Prints the clip sequence per scene.

const SPEED: float = 20.0
const SESSIONS: int = 3
## Letters in play per session. Session 2 adds i (intro inside the station,
## three tiles); session 3 has all six, so the bridge misses l, a and m.
const SESSION_COUNT: Array[int] = [2, 3, 6]
const SENTENCES: Dictionary = {
	"opening": ["op_1", "op_2", "op_3", "op_4", "op_5"],
	"hub": ["hub_find", "hub_write", "hub_bridge", "hub_back", "hub_idle"],
	"find": ["find_in", "intro_again", "find_ask", "find_right", "find_wrong", "find_done"],
	"write": ["write_in", "write_turn", "write_retry", "write_right", "write_done"],
	"bridge":
	["bridge_in", "bridge_word_lam", "bridge_ask", "bridge_right", "bridge_done", "bridge_walk"],
	"end": ["end_bye"],
}
const OTHER_OK: Dictionary = {
	"opening": [],
	"hub": [],
	"find": ["lyd_", "navn_", "intro_", "sfx_chime_", "sfx_tok"],
	"write": ["lyd_", "sfx_chime_"],
	"bridge": ["lyd_", "sfx_chime_", "sfx_tok"],
	"end": [],
}

var failures: Array[String] = []
var tree: SceneTree
var main: MainScene
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var counts: Dictionary = {}  # what was exercised
var find_items_started: int = 0


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
	Voice.sequence_errors = 0
	main = (load("res://scenes/Main.tscn") as PackedScene).instantiate() as MainScene
	tree.root.add_child(main)
	var find: HorOgFinn = main.stations[0] as HorOgFinn
	find.rules.rng.seed = 11
	find.step.connect(_on_find_step)
	find.item_started.connect(func(_t: String, _l: Array[String]) -> void: find_items_started += 1)
	(main.stations[1] as Sandskriving).step.connect(_on_write_step)
	(main.stations[2] as OrdBro).step.connect(_on_bridge_step)
	await _opening()
	for s in SESSIONS:
		print("--- session %d" % (s + 1))
		find.rules.count = maxi(find.rules.count, SESSION_COUNT[s])
		if s == 2:
			for l: String in ["i", "l", "o"]:
				find.rules.mark_heard(l)
		await _hub_go(0, s == 0)
		await _find()
		await _hub_go(1, false)
		await _write(s == 0)
		await _hub_go(2, false)
		await _bridge()
		await _until(func() -> bool: return main.mode == MainScene.Mode.END, 60.0, "goodnight")
		if s + 1 < SESSIONS:
			main.new_session()
	await _frames(5)
	_report()
	main.queue_free()
	await _frames(3)
	Engine.time_scale = 1.0


# ---------------------------------------------------------------- opening and hub


func _opening() -> void:
	await _until(
		func() -> bool: return main.story != null and main.story.waiting_for_pip, 60.0, "op_5"
	)
	await _idle_voice()
	main.story.tap_pip()
	counts["opening"] = 1


func _hub_go(i: int, wait_idle_line: bool) -> void:
	await _until(
		func() -> bool: return main.mode == MainScene.Mode.HUB and main._next == i,
		60.0,
		"hub %d" % i
	)
	check(main.beacons[i].visible, "hub: station %d not lit" % i)
	await _idle_voice()
	if wait_idle_line:
		var before: int = Voice.clip_log.size()
		await _until(func() -> bool: return Voice.clip_log.size() > before, 30.0, "hub_idle")
		check(_id_at(before) == "hub_idle", "hub idle played %s" % _id_at(before))
		check(main.hud.ghost.showing(), "hub idle: no ghost finger on the lit station")
		await _idle_voice()
	main.choose_station()
	await _until(func() -> bool: return main.mode == MainScene.Mode.STATION, 30.0, "station %d" % i)


# ---------------------------------------------------------------- find


func _on_find_step(name: String) -> void:
	var find: HorOgFinn = main.stations[0] as HorOgFinn
	if name.begins_with("intro_"):
		var l: String = name.trim_prefix("intro_")
		check(_last_id() == "intro_" + l, "intro of %s played %s" % [l, _last_id()])
		var gl: GlowLetter = find.letter_node(l)
		check(gl != null and gl.hint_pulse, "intro of %s: its tile does not pulse" % l)
		counts["intro"] = int(counts.get("intro", 0)) + 1


func _find() -> void:
	var find: HorOgFinn = main.stations[0] as HorOgFinn
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
		check(
			tiles.size() == find.rules.tile_count(),
			"find: %d tiles for %d letters" % [tiles.size(), find.rules.count]
		)
		# the prompt that just ended: question first, the target's held sound last
		var last: int = Voice.clip_log.size() - 1
		check(
			(
				_id_at(last) == Voice.held_id(target)
				and _id_at(last - 1) in ["find_ask", "find_wrong"]
			),
			"find prompt for %s ended %s, %s" % [target, _id_at(last - 1), _id_at(last)]
		)
		counts["find_prompt"] = int(counts.get("find_prompt", 0)) + 1
		if find_items_started == 1:
			check(main.hud.ghost.showing(), "first item ever: no ghost finger on the target")
		if rng.randf() < 0.3:
			var lp: String = tiles[rng.randi_range(0, tiles.size() - 1)]
			var b: int = Voice.clip_log.size()
			find.long_press(lp)
			await _idle_voice()
			check(
				_id_at(b) == "navn_" + lp and _id_at(b + 1) == Voice.held_id(lp),
				"long-press %s played %s, %s" % [lp, _id_at(b), _id_at(b + 1)]
			)
			check(Voice.clip_log.size() == b + 2, "long-press %s: more than name + sound" % lp)
			counts["long_press"] = int(counts.get("long_press", 0)) + 1
		if (items == 0 or rng.randf() < 0.3) and tiles.size() > 1:
			var wrong: Array[String] = []
			for l: String in tiles:
				if l != target:
					wrong.append(l)
			var w: String = wrong[rng.randi_range(0, wrong.size() - 1)]
			var b2: int = Voice.clip_log.size()
			find.tap(w)
			await _until(func() -> bool: return not find.busy, 30.0, "after wrong")
			await _idle_voice()
			var got: Array[String] = _ids_from(b2)
			var want: Array[String] = [
				Voice.short_id(w), "sfx_tok", "find_wrong", Voice.held_id(target)
			]
			check(got == want, "wrong tap %s (target %s) played %s" % [w, target, got])
			counts["find_wrong"] = int(counts.get("find_wrong", 0)) + 1
		var b3: int = Voice.clip_log.size()
		var done_before: int = find.items_done
		find.tap(target)
		await _frames(1)
		check(_id_at(b3) == Voice.short_id(target), "tap on %s played %s" % [target, _id_at(b3)])
		await _until(
			func() -> bool: return find.items_done > done_before and find.busy, 10.0, "right"
		)
		await _until(
			func() -> bool: return Voice.clip_log.size() >= b3 + 2 or not find.active, 30.0, ""
		)
		var after: String = _id_at(b3 + 1)
		check(
			after.begins_with("sfx_chime_"), "right answer: %s after the sound, not a chime" % after
		)
		if find.rights % HorOgFinn.RIGHT_LINE_EVERY == 0:
			await _until(func() -> bool: return Voice.clip_log.size() >= b3 + 3, 30.0, "find_right")
			check(_id_at(b3 + 2) == "find_right", "3rd right: %s" % _id_at(b3 + 2))
		items += 1
		var started: int = find_items_started
		await _until(
			func() -> bool: return find_items_started > started or not find.active,
			30.0,
			"next item"
		)
	print("find: %d items, letters in set %s" % [items, find.rules.letters()])
	counts["find_items"] = int(counts.get("find_items", 0)) + items


# ---------------------------------------------------------------- write


func _on_write_step(name: String) -> void:
	var w: Sandskriving = main.stations[1] as Sandskriving
	if name == "model":
		await _frames(1)
		check(
			_last_id() == Voice.held_id(w.letter), "model for %s played %s" % [w.letter, _last_id()]
		)


func _write(scribble_first: bool) -> void:
	var w: Sandskriving = main.stations[1] as Sandskriving
	var plan: Array = main.plan()["stones"]
	var done: int = 0
	while w.active:
		var ok: bool = await _until(
			func() -> bool:
				return (w.phase == Sandskriving.Phase.WRITE and not Voice.is_busy()) or not w.active,
			60.0,
			"write turn"
		)
		if not ok or not w.active:
			break
		if scribble_first and done == 0 and w.attempts == 0:
			var c: Vector2 = w.pad.box.get_center()
			var line: PackedVector2Array = PackedVector2Array()
			for k in 20:
				line.append(c + Vector2(-220 + 22 * k, 140))
			var b: int = Voice.clip_log.size()
			w.submit([line] as Array[PackedVector2Array])
			await _until(func() -> bool: return Voice.clip_log.size() > b, 20.0, "retry line")
			check(_id_at(b) == "write_retry", "scribble got %s, not write_retry" % _id_at(b))
			continue
		var letter: String = w.letter
		var before: int = w.written.size()
		w.submit(w.model_screen_strokes())
		await _until(func() -> bool: return w.written.size() > before, 40.0, "stone %s" % letter)
		done += 1
	check(done == plan.size(), "write: %d stones, plan %s" % [done, plan])
	print("write: stones %s" % [w.written])


# ---------------------------------------------------------------- bridge


func _on_bridge_step(name: String) -> void:
	var br: OrdBro = main.stations[2] as OrdBro
	if name.begins_with("lit_"):
		var i: int = int(name.trim_prefix("lit_"))
		check(_last_id() == "bridge_word_lam", "plank %d lit outside the word clip" % i)
		counts["planks_lit"] = int(counts.get("planks_lit", 0)) + 1
	if name == "walk":
		check(_last_id() == "bridge_walk", "lamb walks during %s" % _last_id())
		counts["walk_slots_sunk"] = br.slots.size()


func _bridge() -> void:
	var br: OrdBro = main.stations[2] as OrdBro
	var plan: Dictionary = main.plan()
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
		check((plan["missing"] as Array).has(want), "bridge asks %s, not missing" % want)
		var last: int = Voice.clip_log.size() - 1
		check(
			_id_at(last) == Voice.held_id(want) and _id_at(last - 1) in ["bridge_ask"],
			"bridge prompt for %s ended %s, %s" % [want, _id_at(last - 1), _id_at(last)]
		)
		var wrong: Stone = null
		for st: Stone in br.stones:
			if not st.placed and st.letter != want:
				wrong = st
		if wrong:
			var b: int = Voice.clip_log.size()
			br.grab(wrong)
			await _frames(1)
			check(
				_id_at(b) == Voice.short_id(wrong.letter), "grab %s: %s" % [wrong.letter, _id_at(b)]
			)
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
		await _frames(1)
		check(_id_at(b2) == Voice.short_id(want), "grab %s: %s" % [want, _id_at(b2)])
		br.drop(st2, br.cur)
		await _until(func() -> bool: return Voice.clip_log.size() >= b2 + 3, 30.0, "right stone")
		check(
			_id_at(b2 + 1).begins_with("sfx_chime_") and _id_at(b2 + 2) == "bridge_right",
			"right stone: %s, %s" % [_id_at(b2 + 1), _id_at(b2 + 2)]
		)
		await _until(
			func() -> bool: return br.busy == false or br.cur != -1 or not br.active, 5.0, ""
		)
		await _until(func() -> bool: return br.cur == -1 or Voice.is_busy(), 10.0, "")
	var walked: bool = main.lamb.global_position.distance_to(main.world.bridge_start) < 3.0
	check(walked, "the lamb did not come over (at %s)" % main.lamb.global_position)


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
		check(FileAccess.file_exists(path) or ResourceLoader.exists(path), "no file %s" % path)
	# nothing the game says on its own is cut short: a clip may only be cut by
	# a letter sound the child set off (a tap or a grabbed stone)
	var cut: int = 0
	for k in range(Voice.clip_log.size() - 1):
		var a: Dictionary = Voice.clip_log[k]
		var b: Dictionary = Voice.clip_log[k + 1]
		var ends: float = float(a["t"]) + Voice.length(str(a["id"])) - 0.03
		if float(b["t"]) < ends:
			var by_child: bool = (
				str(b["id"]).begins_with("lyd_") and not str(b["id"]).ends_with("_held")
			)
			check(
				by_child,
				(
					"[%s] %s cut short by %s after %.2fs"
					% [a["scene"], a["id"], b["id"], float(b["t"]) - float(a["t"])]
				)
			)
			cut += 1
	print("clips cut short by a child's tap or grab: %d" % cut)
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
			check(ids.has(want), "scene %s never played %s" % [sc, want])
	var op: Array = by_scene.get("opening", [])
	check(op.slice(0, 5) == SENTENCES["opening"], "opening order %s" % [op])
	print("exercised: %s" % [counts])
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
