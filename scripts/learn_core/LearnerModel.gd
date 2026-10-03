class_name LearnerModel
extends RefCounted
## Per-skill Bayesian Knowledge Tracing (GDD 5.2). One P(L) per skill id.
## Skill ids are opaque strings: this class never reads what a skill means.

const STATUS_NOT_STARTED: StringName = &"not_started"
const STATUS_PRACTISING: StringName = &"practising"
const STATUS_SECURE: StringName = &"secure"

var session_index: int = 1
var _p: Dictionary = {}  # String -> float
var _opportunities: Dictionary = {}  # String -> int
## skill -> session indexes with a correct, unhinted first attempt
var _clean_sessions: Dictionary = {}
var _introduced: Array[String] = []
var _introduced_this_session: int = 0


static func guess_chance(choices: int) -> float:
	return 1.0 / float(maxi(choices, 2))


## P(correct) for a learner with P(L) = p_l facing `choices` options.
static func predict(p_l: float, choices: int, slip: float = LearnBalance.P_SLIP) -> float:
	var g: float = guess_chance(choices)
	return p_l * (1.0 - slip) + (1.0 - p_l) * g


func p_known(skill: String) -> float:
	return float(_p.get(skill, LearnBalance.P_INIT))


func opportunities(skill: String) -> int:
	return int(_opportunities.get(skill, 0))


func set_p(skill: String, value: float) -> void:
	_p[skill] = clampf(value, 0.0, 1.0)


## One scored first attempt. Returns the new P(L).
func update(skill: String, correct: bool, choices: int, hint_level: int) -> float:
	var p_l: float = p_known(skill)
	var g: float = guess_chance(choices)
	var s: float = LearnBalance.P_SLIP
	var post: float
	if correct:
		post = p_l * (1.0 - s) / (p_l * (1.0 - s) + (1.0 - p_l) * g)
	else:
		post = p_l * s / (p_l * s + (1.0 - p_l) * (1.0 - g))
	post = post + (1.0 - post) * LearnBalance.P_TRANSIT
	var level: int = clampi(hint_level, 0, LearnBalance.HINT_MAX)
	var w: float
	if correct:
		w = LearnBalance.HINT_EVIDENCE[level]
	else:
		w = 1.0 if level <= 1 else LearnBalance.WRONG_EVIDENCE_AFTER_HINT
	p_l = p_l + w * (post - p_l)
	_p[skill] = p_l
	_opportunities[skill] = opportunities(skill) + 1
	if correct and level == 0:
		var sessions: Array = _clean_sessions.get(skill, [])
		if not sessions.has(session_index):
			sessions.append(session_index)
		_clean_sessions[skill] = sessions
	return p_l


func is_mastered(skill: String) -> bool:
	var sessions: Array = _clean_sessions.get(skill, [])
	return (
		p_known(skill) >= LearnBalance.MASTERY_P
		and sessions.size() >= LearnBalance.MASTERY_SESSIONS
	)


func status(skill: String) -> StringName:
	if opportunities(skill) == 0:
		return STATUS_NOT_STARTED
	if is_mastered(skill):
		return STATUS_SECURE
	return STATUS_PRACTISING


func is_introduced(skill: String) -> bool:
	return _introduced.has(skill)


func introduced() -> Array[String]:
	return _introduced.duplicate()


func introduced_this_session() -> int:
	return _introduced_this_session


func introduce(skill: String) -> void:
	if _introduced.has(skill):
		return
	_introduced.append(skill)
	_introduced_this_session += 1


func start_session() -> void:
	session_index += 1
	_introduced_this_session = 0


func to_dict() -> Dictionary:
	return {
		"session_index": session_index,
		"p": _p.duplicate(),
		"opportunities": _opportunities.duplicate(),
		"clean_sessions": _clean_sessions.duplicate(true),
		"introduced": _introduced.duplicate(),
	}


func from_dict(d: Dictionary) -> void:
	session_index = int(d.get("session_index", 1))
	_p = {}
	var p_in: Dictionary = d.get("p", {})
	for k: Variant in p_in:
		_p[str(k)] = float(p_in[k])
	_opportunities = {}
	var o_in: Dictionary = d.get("opportunities", {})
	for k: Variant in o_in:
		_opportunities[str(k)] = int(o_in[k])
	_clean_sessions = {}
	var c_in: Dictionary = d.get("clean_sessions", {})
	for k: Variant in c_in:
		var arr: Array = []
		for v: Variant in c_in[k]:
			arr.append(int(v))
		_clean_sessions[str(k)] = arr
	_introduced.clear()
	for s: Variant in d.get("introduced", []):
		_introduced.append(str(s))
	_introduced_this_session = 0
