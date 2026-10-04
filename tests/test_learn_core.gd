extends SceneTree
## Headless tests for learn_core + the write check. Run:
##   godot --headless --audio-driver Dummy -s res://tests/test_learn_core.gd
## Replays scripted answer sequences and checks the numbers in GDD 5.2-5.6.

const PACK_DIR: String = "res://content/nb_reading"
const WRITE_LETTERS: Array[String] = ["gp_a", "gp_s", "gp_i", "gp_l", "gp_o", "gp_m"]
const FIXTURES_PER_LETTER: int = 12

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_test_pack()
	_test_bkt_streaks()
	_test_predict_table()
	_test_hint_weights()
	_test_first_attempt_only()
	_test_hint_ladder()
	_test_formats()
	_test_step_down_up()
	_test_wrong_streak_break()
	_test_interleaving()
	_test_new_skill_gate()
	_test_engine_is_content_free()
	_test_disengage()
	_test_next_task_reading()
	_test_simulated_children()
	_test_write_check()
	print("RESULT %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _ok(name: String, cond: bool, detail: String = "") -> void:
	if cond:
		_passed += 1
		print("PASS ", name)
	else:
		_failed += 1
		print("FAIL ", name, "  ", detail)


func _engine(seed_value: int = 7) -> LearnEngine:
	var e: LearnEngine = LearnEngine.new()
	e.setup(PACK_DIR, seed_value)
	return e


func _test_pack() -> void:
	var e: LearnEngine = _engine()
	_ok("pack loads 6 gated sounds", e.pack.unlock_order.size() == 6, str(e.pack.unlock_order))
	_ok("pack first group is a pair", e.pack.first_group_size == 2)
	var words: Array[Dictionary] = e.pack.items_for_activity("ordbro")
	_ok("pack has bridge words", words.size() >= 3, str(words.size()))
	var no_pic: Array[String] = []
	for w: Dictionary in words:
		var pic: Node3D = Props.make(str(w.get("picture", "")))
		if pic == null:
			no_pic.append(str(w["text"]))
		else:
			pic.free()
	_ok("every bridge word has a picture (no nonsense syllables)", no_pic.is_empty(), str(no_pic))
	var strokes: Array = e.pack.skill("gp_s").get("strokes", [])
	_ok("pack carries stroke models under 'strokes'", strokes.size() >= 1)


func _streak_to_mastery(choices: int) -> int:
	var m: LearnerModel = LearnerModel.new()
	for n in range(1, 30):
		if m.update("x", true, choices, 0) >= LearnBalance.MASTERY_P:
			return n
	return -1


func _test_bkt_streaks() -> void:
	# GDD 5.2 table (my calc there): 2 choices -> 7, 3 -> 5, 4 -> 4
	_ok(
		"BKT streak to 0.95 with 2 choices = 7",
		_streak_to_mastery(2) == 7,
		str(_streak_to_mastery(2))
	)
	_ok(
		"BKT streak to 0.95 with 3 choices = 5",
		_streak_to_mastery(3) == 5,
		str(_streak_to_mastery(3))
	)
	_ok(
		"BKT streak to 0.95 with 4 choices = 4",
		_streak_to_mastery(4) == 4,
		str(_streak_to_mastery(4))
	)


func _test_predict_table() -> void:
	var cases: Array = [
		[0.1, 2, 0.54], [0.1, 3, 0.39], [0.5, 2, 0.70], [0.7, 3, 0.73], [0.9, 4, 0.84]
	]
	var good: bool = true
	var got: Array[String] = []
	for c: Array in cases:
		var p: float = LearnerModel.predict(float(c[0]), int(c[1]))
		got.append("%.3f" % p)
		if absf(p - float(c[2])) > 0.006:
			good = false
	_ok("predict() matches GDD 5.2 table", good, str(got))


func _test_hint_weights() -> void:
	var a: LearnerModel = LearnerModel.new()
	a.update("x", true, 2, 3)
	_ok(
		"correct after hint 3 is no evidence",
		is_equal_approx(a.p_known("x"), LearnBalance.P_INIT),
		str(a.p_known("x"))
	)
	var b: LearnerModel = LearnerModel.new()
	b.set_p("x", 0.6)
	b.update("x", false, 2, 0)
	var c: LearnerModel = LearnerModel.new()
	c.set_p("x", 0.6)
	c.update("x", false, 2, 2)
	_ok(
		"wrong after hint 2 counts half",
		c.p_known("x") > b.p_known("x"),
		"%.3f vs %.3f" % [c.p_known("x"), b.p_known("x")]
	)
	var d: LearnerModel = LearnerModel.new()
	d.update("x", true, 2, 0)
	d.update("x", true, 2, 1)
	_ok(
		"hint 1 correct is weaker than hint 0 correct",
		d.p_known("x") < 0.62,
		"%.3f" % d.p_known("x")
	)


func _test_first_attempt_only() -> void:
	var e: LearnEngine = _engine()
	e.model.introduce("gp_a")
	var before: float = e.model.p_known("gp_a")
	var r: Dictionary = e.record_answer("g_a", ["gp_a"], true, 0, false, 3)
	_ok(
		"later attempts are not scored", not bool(r["scored"]) and e.model.p_known("gp_a") == before
	)


func _test_hint_ladder() -> void:
	var h: HintLadder = HintLadder.new()
	_ok("new skill starts at hint 2", h.begin("s", true) == 2)
	_ok("after a correct at 2 the next start fades to 1", h.finish() == 1)
	_ok("faded start is used", h.begin("s", false) == 1)
	_ok("after a correct at 1 the start fades to 0", h.finish() == 0)
	h.begin("s", false)
	_ok("1st wrong -> level 1", h.on_wrong() == 1)
	_ok("2nd wrong -> level 2", h.on_wrong() == 2)
	_ok("3rd wrong -> level 3 (demonstrate)", h.on_wrong() == 3)
	_ok("4th wrong -> level 4 (together)", h.on_wrong() == 4)
	_ok("5th wrong stays at 4", h.on_wrong() == 4)
	_ok("start after a hard item is capped at 2", h.finish() == 2)
	var g: HintLadder = HintLadder.new()
	g.begin("m", false)
	g.on_wrong()
	_ok("wrong first attempt raises next start by 1", g.finish() == 1)
	var i: HintLadder = HintLadder.new()
	i.begin("l", false)
	i.on_idle()
	i.on_idle()
	_ok("idle alone climbs to 2 and stops", i.on_idle() == 2)


func _test_formats() -> void:
	var s: ItemSelector = ItemSelector.new()
	var f0: Dictionary = s.choose_format(0.10, 3, 2)
	_ok(
		"new skill: 2 far choices + hint 2",
		int(f0["choices"]) == 2 and str(f0["similarity"]) == "far" and int(f0["hint_start"]) == 2,
		str(f0)
	)
	var f1: Dictionary = s.choose_format(0.90, 4, 0)
	_ok(
		"strong skill: hardest format (4 near)",
		int(f1["choices"]) == 4 and str(f1["similarity"]) == "near",
		str(f1)
	)
	_ok(
		"strong skill prediction in or above band",
		float(f1["predicted"]) >= LearnBalance.TARGET_SUCCESS_LOW
	)
	var f2: Dictionary = s.choose_format(0.60, 4, 0)
	_ok(
		"mid skill: chosen format predicts >= 0.70",
		float(f2["predicted"]) >= LearnBalance.TARGET_SUCCESS_LOW,
		str(f2)
	)
	var f3: Dictionary = s.choose_format(0.90, 2, 0)
	_ok("activity cap on choices is respected", int(f3["choices"]) == 2, str(f3))


func _test_step_down_up() -> void:
	var s: ItemSelector = ItemSelector.new()
	var seq: Array[bool] = [true, false, true, false, false, true, false, true]
	var step: int = ItemSelector.STEP_NONE
	for c: bool in seq:
		step = s.record(c)
	_ok("rolling 4/8 = 0.50 < 0.60 -> step down", step == ItemSelector.STEP_DOWN)
	_ok("step down queues a warm win", s.warm_win_pending)
	var f: Dictionary = s.choose_format(0.90, 4, 0)
	_ok(
		"step down makes the format one rung easier",
		int(f["choices"]) == 4 and str(f["similarity"]) == "far",
		str(f)
	)
	var g: Dictionary = s.choose_format(0.10, 3, 0)
	_ok("below rung 0 the step down adds hint (capped at 2)", int(g["hint_start"]) == 2, str(g))
	var u: ItemSelector = ItemSelector.new()
	var up: int = ItemSelector.STEP_NONE
	for i in 8:
		up = u.record(true)
	_ok("rolling 8/8 > 0.90 -> step up", up == ItemSelector.STEP_UP)
	var mid: ItemSelector = ItemSelector.new()
	var none: int = ItemSelector.STEP_NONE
	for c: bool in [true, true, false, true, true, true, false, true]:
		none = mid.record(c)
	_ok("rolling 6/8 = 0.75 -> no change", none == ItemSelector.STEP_NONE)


func _test_wrong_streak_break() -> void:
	var s: ItemSelector = ItemSelector.new()
	s.record(false)
	s.record(false)
	_ok("2 wrong in a row: no break yet", not s.break_pending)
	s.record(false)
	_ok("3 wrong in a row -> movement break", s.take_break())
	_ok("break is consumed once", not s.take_break())


func _test_interleaving() -> void:
	var e: LearnEngine = _engine(11)
	var eligible: Array[String] = ["a", "b", "c"]
	e.model.set_p("a", 0.3)
	e.model.set_p("b", 0.7)
	e.model.set_p("c", 0.97)
	var run: int = 1
	var worst: int = 1
	var last: String = ""
	var counts: Dictionary = {"a": 0, "b": 0, "c": 0}
	for i in 600:
		var k: String = e.selector.choose_skill(e.model, eligible)
		counts[k] = int(counts[k]) + 1
		run = run + 1 if k == last else 1
		worst = maxi(worst, run)
		last = k
	_ok(
		"never the same skill 3 times in a row",
		worst <= LearnBalance.MAX_SAME_SKILL_IN_A_ROW,
		"worst run %d" % worst
	)
	_ok(
		"practice bucket gets the most picks",
		int(counts["b"]) > int(counts["a"]) and int(counts["b"]) > int(counts["c"]),
		str(counts)
	)


func _test_new_skill_gate() -> void:
	var e: LearnEngine = _engine()
	var first: Array[String] = e.introduce_ready()
	_ok(
		"fresh learner gets the first pair from the pack",
		first == (["gp_a", "gp_s"] as Array[String]),
		str(first)
	)
	_ok("third sound waits for P(L) >= 0.80", e.introduce_ready().is_empty())
	e.model.set_p("gp_a", 0.85)
	e.model.set_p("gp_s", 0.85)
	_ok("same session: max 1 new sound (pair already used it)", e.introduce_ready().is_empty())
	e.model.start_session()
	var nxt: Array[String] = e.introduce_ready()
	_ok(
		"next session: exactly the next sound in pack order",
		nxt == (["gp_i"] as Array[String]),
		str(nxt)
	)
	_ok("only one new sound per session", e.introduce_ready().is_empty())


func _test_engine_is_content_free() -> void:
	var skills: Dictionary = {
		"pack": "fake_math",
		"unlock_order": ["n1", "n2", "n3"],
		"first_group_size": 2,
		"skills":
		[
			{"id": "n1", "gated": true, "group": "small"},
			{"id": "n2", "gated": true, "group": "small"},
			{"id": "n3", "gated": true, "group": "big"},
		],
	}
	var items: Dictionary = {
		"items":
		[
			{"id": "q1", "skills": ["n1"], "activities": ["count"]},
			{"id": "q2", "skills": ["n2"], "activities": ["count"]},
		]
	}
	var e: LearnEngine = LearnEngine.new()
	e.selector.rng.seed = 3
	_ok("engine loads a non-reading pack", e.pack.load_data(skills, items))
	e.introduce_ready()
	var t: Dictionary = e.next_task("count", 3)
	_ok(
		"engine serves a task from a non-reading pack",
		not t.is_empty() and str(t["skill"]) in ["n1", "n2"],
		str(t.get("skill", ""))
	)


func _test_disengage() -> void:
	var d: DisengageDetector = DisengageDetector.new()
	var hit: bool = false
	for t: float in [0.0, 0.3, 0.7, 1.1]:
		hit = d.wrong_tap(t)
	_ok("4 wrong taps in 1.1 s = disengaged", hit)
	var d2: DisengageDetector = DisengageDetector.new()
	var hit2: bool = false
	for t: float in [0.0, 1.0, 2.0, 3.0]:
		hit2 = hit2 or d2.wrong_tap(t)
	_ok("4 wrong taps over 3 s = engaged", not hit2)


func _test_next_task_reading() -> void:
	var e: LearnEngine = _engine(5)
	e.introduce_ready()
	var t: Dictionary = e.next_task("hor_og_finn", 3)
	_ok(
		"listen task targets an introduced sound",
		str(t["skill"]) in ["gp_a", "gp_s"],
		str(t.get("skill"))
	)
	_ok(
		"listen task for a new sound: 2 choices + hint 2",
		int(t["choices"]) == 2 and int(t["hint_start"]) == 2,
		str(t)
	)
	_ok(
		"listen task has 1 distractor",
		(t["distractors"] as Array).size() == 1,
		str(t["distractors"])
	)
	_ok("bridge has no word before i is introduced", e.next_task("ordbro", 4).is_empty())
	for sid: String in e.pack.unlock_order:
		e.model.introduce(sid)
	var b: Dictionary = e.next_task("ordbro", 4)
	_ok(
		"bridge serves a picturable word once all sounds are in",
		not b.is_empty() and str((b["item"] as Dictionary).get("picture", "")) != ""
	)


## GDD 5.2 simulated children (my calc there): typical learner ~12 attempts,
## mean success ~0.73. Loose bounds: this checks the engine, not the table.
func _test_simulated_children() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	for rate: float in [0.05, 0.12, 0.25]:
		var attempts_list: Array[int] = []
		var succ: int = 0
		var total: int = 0
		for run in 400:
			var e: LearnEngine = LearnEngine.new()
			var knows: bool = false
			var n: int = 0
			while n < 80:
				n += 1
				var fmt: Dictionary = e.selector.choose_format(
					e.model.p_known("x"), 4, e.hints.start_for("x")
				)
				var level: int = e.hints.begin("x", n == 1)
				var choices: int = int(fmt["choices"])
				var p_ok: float = 1.0 - LearnBalance.P_SLIP if knows else 1.0 / float(choices)
				if level >= 2 and not knows:
					p_ok = minf(1.0, p_ok + 0.25)
				var ok: bool = rng.randf() < p_ok
				if not ok:
					e.hints.on_wrong()
				e.hints.finish()
				e.model.update("x", ok, choices, level)
				e.selector.record(ok)
				total += 1
				succ += 1 if ok else 0
				if not knows and rng.randf() < rate:
					knows = true
				if e.model.p_known("x") >= LearnBalance.MASTERY_P:
					break
			attempts_list.append(n)
		attempts_list.sort()
		var median: int = attempts_list[attempts_list.size() / 2]
		var mean: float = float(succ) / float(total)
		print(
			(
				"  sim learn rate %.2f: median attempts to P(L)>=0.95 = %d, mean success = %.2f"
				% [rate, median, mean]
			)
		)
		if is_equal_approx(rate, 0.12):
			_ok(
				"typical child reaches mastery in 6-20 attempts",
				median >= 6 and median <= 20,
				str(median)
			)
			_ok(
				"typical child mean success near the band (0.60-0.85)",
				mean >= 0.60 and mean <= 0.85,
				"%.2f" % mean
			)


func _models(e: LearnEngine) -> Dictionary:
	var out: Dictionary = {}
	for sid: String in WRITE_LETTERS:
		out[sid] = WriteCheck.strokes_from_json(e.pack.skill(sid)["strokes"])
	return out


func _others(models: Dictionary, target: String) -> Array:
	var out: Array = []
	for sid: String in models:
		if sid != target:
			out.append(models[sid])
	return out


## Dense polyline (so wobble bends straight strokes too).
func _densify(s: PackedVector2Array, step: float) -> PackedVector2Array:
	if s.size() < 2:
		return s
	var out: PackedVector2Array = PackedVector2Array([s[0]])
	for i in range(1, s.size()):
		var n: int = maxi(1, int(s[i - 1].distance_to(s[i]) / step))
		for k in range(1, n + 1):
			out.append(s[i - 1].lerp(s[i], float(k) / float(n)))
	return out


## A sloppy-but-recognisable child letter in screen pixels: random size
## (small to oversized), place, slant, squash, low-frequency wobble, jitter,
## reversed strokes, shuffled order, and sometimes a lifted (split) stroke.
func _child_letter(
	model: Array[PackedVector2Array], rng: RandomNumberGenerator
) -> Array[PackedVector2Array]:
	var size: float = rng.randf_range(140.0, 900.0)
	var off: Vector2 = Vector2(rng.randf_range(0, 1200), rng.randf_range(0, 500))
	var rot: float = deg_to_rad(rng.randf_range(-12.0, 12.0))
	var sx: float = rng.randf_range(0.8, 1.25)
	var shear: float = rng.randf_range(-0.15, 0.15)
	var amp: float = rng.randf_range(0.015, 0.04)
	var f1: float = rng.randf_range(4.0, 9.0)
	var ph: float = rng.randf() * TAU
	var out: Array[PackedVector2Array] = []
	for st: PackedVector2Array in model:
		var dense: PackedVector2Array = _densify(st, 0.03)
		var t: PackedVector2Array = PackedVector2Array()
		for i in dense.size():
			var q: Vector2 = dense[i] - Vector2(0.5, 0.5)
			q = Vector2(q.x * sx + q.y * shear, q.y).rotated(rot)
			var u: float = float(i) / maxf(1.0, float(dense.size()))
			q += Vector2(sin(u * f1 + ph), cos(u * f1 * 1.3 + ph)) * amp
			q += Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.006
			t.append(q * size + off)
		if rng.randf() < 0.5:
			t.reverse()
		if t.size() > 8 and rng.randf() < 0.3:
			var cut: int = t.size() / 2
			out.append(t.slice(0, cut))
			out.append(t.slice(cut))
		else:
			out.append(t)
	if rng.randf() < 0.5:
		out.reverse()
	return out


func _scribble(rng: RandomNumberGenerator, kind: int) -> Array[PackedVector2Array]:
	var s: PackedVector2Array = PackedVector2Array()
	var c: Vector2 = Vector2(600, 400)
	match kind % 4:
		0:  # zigzag
			for k in 9:
				s.append(
					c + Vector2(k * 45.0, (k % 2) * 220.0) + Vector2(rng.randf_range(-20, 20), 0)
				)
		1:  # horizontal line
			s.append(c)
			s.append(c + Vector2(rng.randf_range(250, 450), rng.randf_range(-20, 20)))
		2:  # random walk
			var p: Vector2 = c
			for k in 14:
				p += Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120))
				s.append(p)
		3:  # a tap
			s.append(c)
			s.append(c + Vector2(6, 4))
	return [s]


func _test_write_check() -> void:
	var e: LearnEngine = _engine()
	var models: Dictionary = _models(e)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2026
	var pos_total: int = 0
	var pos_ok: int = 0
	var neg_total: int = 0
	var neg_ok: int = 0
	for sid: String in WRITE_LETTERS:
		var model: Array[PackedVector2Array] = models[sid]
		var others: Array = _others(models, sid)
		var orient: bool = LearnBalance.ORIENT_CHECK_LETTERS.has(_label_of(e, sid))
		var self_r: Dictionary = WriteCheck.judge(_child_scale(model), model, others, 0, orient)
		_ok("write %s: the clean model is accepted" % sid, bool(self_r["accepted"]), str(self_r))
		var passed: int = 0
		var worst: float = 0.0
		for k in FIXTURES_PER_LETTER:
			var ink: Array[PackedVector2Array] = _child_letter(model, rng)
			var r: Dictionary = WriteCheck.judge(ink, model, others, 0, orient)
			worst = maxf(worst, float(r["distance"]))
			if bool(r["accepted"]):
				passed += 1
			else:
				print("  rejected sloppy %s #%d: %s" % [sid, k, r])
		pos_total += FIXTURES_PER_LETTER
		pos_ok += passed
		print(
			(
				"  sloppy %s: %d/%d accepted (worst distance %.3f)"
				% [sid, passed, FIXTURES_PER_LETTER, worst]
			)
		)
		_ok(
			"write %s: every sloppy child letter is accepted" % sid,
			passed == FIXTURES_PER_LETTER,
			"%d/%d" % [passed, FIXTURES_PER_LETTER]
		)
		var rejected: int = 0
		var tried: int = 0
		for oid: String in WRITE_LETTERS:
			if oid == sid:
				continue
			for k in 3:
				tried += 1
				var other_ink: Array[PackedVector2Array] = _child_letter(models[oid], rng)
				var r2: Dictionary = WriteCheck.judge(other_ink, model, others, 0, orient)
				if not bool(r2["accepted"]):
					rejected += 1
				else:
					print("  accepted %s as %s: %s" % [oid, sid, r2])
		for k in 8:
			tried += 1
			var r3: Dictionary = WriteCheck.judge(_scribble(rng, k), model, others, 0, orient)
			if not bool(r3["accepted"]):
				rejected += 1
			else:
				print("  accepted scribble %d as %s: %s" % [k % 4, sid, r3])
		neg_total += tried
		neg_ok += rejected
		_ok(
			"write %s: other letters and scribbles are not accepted" % sid,
			rejected == tried,
			"%d/%d" % [rejected, tried]
		)
	print(
		(
			"  WRITE FIXTURES: sloppy letters accepted %d/%d, others+scribbles rejected %d/%d"
			% [pos_ok, pos_total, neg_ok, neg_total]
		)
	)
	# Mirrored s: flagged (gentle response), never accepted as a plain s.
	var model_s: Array[PackedVector2Array] = models["gp_s"]
	var mirror_flagged: int = 0
	var correct_flagged: int = 0
	for k in 10:
		var m_ink: Array[PackedVector2Array] = _child_letter(WriteCheck.mirrored(model_s), rng)
		var rm: Dictionary = WriteCheck.judge(m_ink, model_s, _others(models, "gp_s"), 0, true)
		if bool(rm["mirrored"]) and not bool(rm["accepted"]):
			mirror_flagged += 1
		var c_ink: Array[PackedVector2Array] = _child_letter(model_s, rng)
		var rc: Dictionary = WriteCheck.judge(c_ink, model_s, _others(models, "gp_s"), 0, true)
		if bool(rc["mirrored"]):
			correct_flagged += 1
	print("  mirrored s flagged %d/10, correct s flagged %d/10" % [mirror_flagged, correct_flagged])
	_ok("write: every mirrored s is flagged", mirror_flagged == 10, str(mirror_flagged))
	_ok("write: no correct s is flagged as mirrored", correct_flagged == 0, str(correct_flagged))
	# Third try: a rough but near letter counts as near.
	var rough: Array[PackedVector2Array] = _child_letter(models["gp_a"], rng)
	var rr: Dictionary = WriteCheck.judge(rough, models["gp_a"], [], 2, false)
	_ok("write: a rough a is near enough for the third try", bool(rr["near"]), str(rr))


func _child_scale(model: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for st: PackedVector2Array in model:
		var t: PackedVector2Array = PackedVector2Array()
		for q: Vector2 in st:
			t.append(q * 400.0 + Vector2(300, 100))
		out.append(t)
	return out


func _label_of(e: LearnEngine, sid: String) -> String:
	return str(e.pack.skill(sid).get("label", ""))
