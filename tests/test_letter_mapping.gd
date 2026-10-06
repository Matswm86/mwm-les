extends SceneTree
## Headless mapping test for the one-screen letter game. Run:
##   godot --headless --audio-driver Dummy -s res://tests/test_letter_mapping.gd
## Plays 50 items through the real LetterScreen (tile taps go through the same
## LetterTile.press() a touch calls) and checks, from the stream actually put
## on the audio player, that a letter never plays another letter's sound.
## Then plays the whole game (opening, hub, the three stations, goodnight,
## and a second session) through tests/full_flow_check.gd.

const ITEMS: int = 50
const SPEED: float = 25.0
const ALLOWED_SFX: Array[String] = ["sfx_chime_2.wav", "sfx_tok.wav"]

var screen: LetterScreen
var clips: Array[String] = []
var log_items: Array[Dictionary] = []
var cur: Dictionary = {}
var failures: Array[String] = []
var prompts_checked: int = 0
var taps_checked: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
		print("FAIL: " + msg)


func _run() -> void:
	rng.seed = 20261006
	Engine.time_scale = SPEED
	screen = (load("res://scenes/LetterScreen.tscn") as PackedScene).instantiate() as LetterScreen
	screen.persist = false
	screen.rules.rng.seed = 7
	screen.item_started.connect(_on_item)
	screen.prompt_played.connect(_on_prompt)
	root.add_child(screen)
	screen.audio.clip_started.connect(func(f: String) -> void: clips.append(f))
	for n in ITEMS:
		await _until_ready()
		var item: Dictionary = cur
		_check_tiles(item)
		if rng.randf() < 0.15:
			screen.replay()
			_check(clips[-1] == _held_file(item["target"]), "replay played %s" % clips[-1])
			await _frames(2)
		if rng.randf() < 0.1 and item["tiles"].size() > 1:
			var wrong: Array = item["tiles"].filter(
				func(l: String) -> bool: return l != item["target"]
			)
			await _tap(wrong[rng.randi_range(0, wrong.size() - 1)])
			await _until_ready()
		await _tap(item["target"])
		await _until(func() -> bool: return screen.items_done == n + 1 and cur != item)
	await _until_ready()
	_report()
	screen.queue_free()
	await _frames(3)
	var flow: RefCounted = load("res://tests/full_flow_check.gd").new()
	await flow.run(self)
	failures.append_array(flow.failures)
	print("OVERALL: %s" % ("PASS" if failures.is_empty() else "FAIL (%d)" % failures.size()))
	quit(1 if not failures.is_empty() else 0)


func _on_item(target: String, letters: Array[String]) -> void:
	cur = {
		"n": log_items.size() + 1,
		"target": target,
		"tiles": letters.duplicate(),
		"set": screen.rules.letters().size(),
		"intro": [],
		"prompts": [],
		"taps": []
	}
	log_items.append(cur)
	cur["clip_start"] = clips.size()


func _on_prompt(target: String, file: String) -> void:
	prompts_checked += 1
	cur["prompts"].append(file)
	_check(target == cur["target"], "prompt target %s != item target %s" % [target, cur["target"]])
	_check(
		file == _held_file(cur["target"]),
		"item %d prompt %s for target %s" % [cur["n"], file, cur["target"]]
	)
	_check(clips[-1] == file, "player log %s != prompt %s" % [clips[-1], file])
	# intro clips: every clip between item start and the prompt
	var intro: Array = clips.slice(int(cur["clip_start"]), clips.size() - 1)
	if cur["intro"].is_empty() and cur["prompts"].size() == 1:
		cur["intro"] = intro
		for f: String in intro:
			var l: String = f.trim_prefix("lyd_").trim_suffix(".wav").trim_suffix("_held")
			_check(
				f == _held_file(l) and cur["tiles"].has(l),
				"intro clip %s not a shown tile's held sound" % f
			)


func _check_tiles(item: Dictionary) -> void:
	_check(
		item["tiles"].has(item["target"]),
		"item %d target %s not among tiles %s" % [item["n"], item["target"], item["tiles"]]
	)
	var want: int = mini(int(item["set"]), 3)
	_check(
		item["tiles"].size() == want,
		"item %d shows %d tiles, want %d" % [item["n"], item["tiles"].size(), want]
	)
	for t: LetterTile in screen.tiles:
		_check(
			t.label.text == LetterRules.glyph(t.letter),
			"tile label %s != tile letter %s" % [t.label.text, t.letter]
		)


## The held take of a letter; t and b have none and play their short take.
func _held_file(l: String) -> String:
	return ("lyd_%s.wav" if LetterRules.STOPS.has(l) else "lyd_%s_held.wav") % l


func _tap(letter: String) -> void:
	var tile: LetterTile = screen.tile_for(letter)
	_check(tile != null, "no tile for %s" % letter)
	if tile == null:
		return
	var before: int = clips.size()
	tile.press()
	var got: String = clips[before] if clips.size() > before else "(nothing)"
	cur["taps"].append([letter, got])
	taps_checked += 1
	_check(got == "lyd_%s.wav" % letter, "item %d tap on %s played %s" % [cur["n"], letter, got])
	await _frames(2)


func _until_ready() -> void:
	await _until(func() -> bool: return not screen.busy)


func _until(cond: Callable) -> void:
	var start: int = Time.get_ticks_msec()
	while not bool(cond.call()):
		if Time.get_ticks_msec() - start > 20000:
			_check(false, "timeout (item %d)" % log_items.size())
			_report()
			quit(1)
			return
		await process_frame


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _report() -> void:
	for it: Dictionary in log_items:
		var taps: Array[String] = []
		for p: Array in it["taps"]:
			taps.append("%s->%s" % [p[0], p[1]])
		print(
			(
				"item %02d target=%s tiles=%s prompt=%s intro=%s taps=[%s]"
				% [
					it["n"],
					it["target"],
					",".join(it["tiles"]),
					",".join(it["prompts"]),
					",".join(it["intro"]),
					" ".join(taps)
				]
			)
		)
	# never the same target 3 times in a row
	for k in range(2, log_items.size()):
		var a: String = log_items[k]["target"]
		_check(
			not (a == log_items[k - 1]["target"] and a == log_items[k - 2]["target"]),
			"target %s 3x in a row at item %d" % [a, k + 1]
		)
	# only the 12 recorded clips and the two non-voice effects ever play
	var kinds: Dictionary = {}
	for f: String in clips:
		kinds[f] = int(kinds.get(f, 0)) + 1
		var ok: bool = ALLOWED_SFX.has(f) or f.begins_with("lyd_")
		_check(ok and not f.begins_with("tts_"), "unexpected clip %s" % f)
		if f.begins_with("lyd_"):
			_check(
				FileAccess.file_exists("res://assets/audio/rec/" + f),
				"clip %s not in assets/audio/rec" % f
			)
	var max_tiles: int = 0
	for it: Dictionary in log_items:
		max_tiles = maxi(max_tiles, it["tiles"].size())
	_check(max_tiles == 3, "never reached the 3-tile stage")
	print("clips played: %s" % str(kinds))
	print("letters in set at end: %s" % ",".join(screen.rules.letters()))
	print(
		(
			(
				"items answered %d (item %d on screen, untapped), prompts checked %d, "
				+ "taps checked %d, failures %d"
			)
			% [screen.items_done, log_items.size(), prompts_checked, taps_checked, failures.size()]
		)
	)
	print("RESULT: %s" % ("PASS" if failures.is_empty() else "FAIL"))
