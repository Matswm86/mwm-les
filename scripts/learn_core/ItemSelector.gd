class_name ItemSelector
extends RefCounted
## Picks the next skill and the item format so predicted success lands in the
## ZPD band (GDD 5.3), plus the rolling step-down/step-up check and the
## wrong-streak break. Skills and items are opaque ids here.

## Format ladder, easiest first. One "knob" step = one rung.
const FORMATS: Array[Dictionary] = [
	{"choices": 2, "similarity": "far"},
	{"choices": 2, "similarity": "near"},
	{"choices": 3, "similarity": "far"},
	{"choices": 3, "similarity": "near"},
	{"choices": 4, "similarity": "far"},
	{"choices": 4, "similarity": "near"},
]
const STEP_NONE: int = 0
const STEP_DOWN: int = -1
const STEP_UP: int = 1

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var difficulty_offset: int = 0
var warm_win_pending: bool = false
var break_pending: bool = false
var wrong_streak: int = 0
var _recent_skills: Array[String] = []
var _rolling: Array[bool] = []
var _last_used: Dictionary = {}  # skill -> pick counter
var _pick_counter: int = 0


static func predicted(p_l: float, fmt: Dictionary) -> float:
	var slip: float = LearnBalance.P_SLIP
	if str(fmt["similarity"]) == "near":
		slip += LearnBalance.NEAR_SLIP_EXTRA
	return LearnerModel.predict(p_l, int(fmt["choices"]), slip)


## Session mix: new/fragile, practice, easy. Interleaving: never the same skill
## more than MAX_SAME_SKILL_IN_A_ROW times. A pending warm win picks the easiest.
func choose_skill(model: LearnerModel, eligible: Array[String]) -> String:
	if eligible.is_empty():
		return ""
	var pool: Array[String] = []
	for s: String in eligible:
		if not _would_repeat_too_often(s):
			pool.append(s)
	if pool.is_empty():
		pool = eligible.duplicate()
	if warm_win_pending:
		warm_win_pending = false
		return _mark(_highest_p(model, pool))
	var fresh: Array[String] = []
	var practice: Array[String] = []
	var easy: Array[String] = []
	for s: String in pool:
		var p: float = model.p_known(s)
		if p < LearnBalance.FRAGILE_BELOW_P:
			fresh.append(s)
		elif p < LearnBalance.MASTERY_P:
			practice.append(s)
		else:
			easy.append(s)
	var buckets: Array = [fresh, practice, easy]
	var weights: Array[float] = [
		LearnBalance.MIX_NEW, LearnBalance.MIX_PRACTICE, LearnBalance.MIX_EASY
	]
	var total: float = 0.0
	for b in 3:
		if not (buckets[b] as Array).is_empty():
			total += weights[b]
	var roll: float = rng.randf() * total
	for b in 3:
		var bucket: Array = buckets[b]
		if bucket.is_empty():
			continue
		roll -= weights[b]
		if roll <= 0.0:
			return _mark(_least_recent(bucket))
	return _mark(_least_recent(pool))


## Hardest format whose predicted success is at least TARGET_SUCCESS_LOW,
## shifted by the rolling difficulty offset. Below rung 0 the offset turns
## into extra hint start. Returns choices, similarity, hint_start, predicted.
func choose_format(p_l: float, max_choices: int, hint_floor: int) -> Dictionary:
	var top: int = -1
	for i in FORMATS.size():
		if int(FORMATS[i]["choices"]) > max_choices:
			break
		top = i
	top = maxi(top, 0)
	var best: int = -1
	for i in top + 1:
		if predicted(p_l, FORMATS[i]) >= LearnBalance.TARGET_SUCCESS_LOW:
			best = i
	var hint_start: int = hint_floor
	if best < 0:
		best = 0
		hint_start = maxi(hint_start, LearnBalance.HINT_START_NEW_SKILL)
	var rung: int = best + difficulty_offset
	if rung < 0:
		hint_start += -rung
		rung = 0
	rung = mini(rung, top)
	hint_start = mini(hint_start, LearnBalance.HINT_START_MAX)
	var fmt: Dictionary = FORMATS[rung].duplicate()
	fmt["hint_start"] = hint_start
	fmt["predicted"] = predicted(p_l, fmt)
	return fmt


## A scored first attempt. Returns STEP_DOWN / STEP_UP / STEP_NONE.
func record(correct: bool) -> int:
	wrong_streak = 0 if correct else wrong_streak + 1
	if wrong_streak >= LearnBalance.WRONG_STREAK_BREAK:
		break_pending = true
		warm_win_pending = true
		wrong_streak = 0
	_rolling.append(correct)
	if _rolling.size() > LearnBalance.ROLLING_WINDOW:
		_rolling.pop_front()
	if _rolling.size() < LearnBalance.ROLLING_WINDOW:
		return STEP_NONE
	var rate: float = rolling_success()
	if rate < LearnBalance.STEP_DOWN_BELOW:
		difficulty_offset -= 1
		warm_win_pending = true
		_rolling.clear()
		return STEP_DOWN
	if rate > LearnBalance.STEP_UP_ABOVE:
		difficulty_offset += 1
		_rolling.clear()
		return STEP_UP
	return STEP_NONE


func rolling_success() -> float:
	if _rolling.is_empty():
		return 0.0
	var n: int = 0
	for c: bool in _rolling:
		if c:
			n += 1
	return float(n) / float(_rolling.size())


func take_break() -> bool:
	var b: bool = break_pending
	break_pending = false
	return b


func _would_repeat_too_often(skill: String) -> bool:
	var n: int = LearnBalance.MAX_SAME_SKILL_IN_A_ROW
	if _recent_skills.size() < n:
		return false
	for i in n:
		if _recent_skills[_recent_skills.size() - 1 - i] != skill:
			return false
	return true


func _mark(skill: String) -> String:
	_recent_skills.append(skill)
	if _recent_skills.size() > 8:
		_recent_skills.pop_front()
	_pick_counter += 1
	_last_used[skill] = _pick_counter
	return skill


func _least_recent(pool: Array) -> String:
	var best: String = str(pool[0])
	var best_t: int = 1 << 30
	for s: Variant in pool:
		var t: int = int(_last_used.get(str(s), -1))
		if t < best_t:
			best_t = t
			best = str(s)
	return best


func _highest_p(model: LearnerModel, pool: Array[String]) -> String:
	var best: String = pool[0]
	for s: String in pool:
		if model.p_known(s) > model.p_known(best):
			best = s
	return best
