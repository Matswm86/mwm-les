class_name HintLadder
extends RefCounted
## Contingent hint state machine (GDD 5.4). Levels 0-4; what a level LOOKS like
## is the activity's job. Fading: the next start for a skill depends on the
## highest level used last time and on whether the first attempt was wrong.

var level: int = 0
var highest: int = 0
var wrongs: int = 0
var idle_steps: int = 0
var _skill: String = ""
var _start_level: int = 0
var _first_wrong: bool = false
var _starts: Dictionary = {}  # String -> int


func start_for(skill: String) -> int:
	return int(_starts.get(skill, 0))


func begin(skill: String, is_new_skill: bool) -> int:
	_skill = skill
	_start_level = start_for(skill)
	if is_new_skill:
		_start_level = maxi(_start_level, LearnBalance.HINT_START_NEW_SKILL)
	level = _start_level
	highest = level
	wrongs = 0
	idle_steps = 0
	_first_wrong = false
	return level


## A wrong answer on this item. Returns the new level.
func on_wrong() -> int:
	wrongs += 1
	if wrongs == 1:
		_first_wrong = true
	level = maxi(level, mini(wrongs, LearnBalance.HINT_MAX))
	highest = maxi(highest, level)
	return level


## The child has been idle for IDLE_HINT_SEC. Idle alone climbs to level 2 at most.
func on_idle() -> int:
	idle_steps += 1
	if level < LearnBalance.IDLE_HINT_MAX_LEVEL:
		level += 1
	highest = maxi(highest, level)
	return level


## Item finished: store the faded start for the next item of this skill.
func finish() -> int:
	var next: int = maxi(0, highest - 1)
	if _first_wrong:
		next = maxi(next, _start_level + 1)
	next = mini(next, LearnBalance.HINT_START_MAX)
	_starts[_skill] = next
	return next


func to_dict() -> Dictionary:
	return _starts.duplicate()


func from_dict(d: Dictionary) -> void:
	_starts = {}
	for k: Variant in d:
		_starts[str(k)] = int(d[k])
