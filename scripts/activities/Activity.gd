class_name Activity
extends Node3D
## Base for mini-game templates (GDD 5.1 contract). The station runner calls
## start_item(); the activity reports `answered` / `disengaged` and emits
## `item_done` when the item has ended on a success.

signal answered(
	item_id: StringName,
	skill_ids: Array[StringName],
	correct: bool,
	hint_level: int,
	first_attempt: bool,
	latency_sec: float
)
signal disengaged(item_id: StringName)
signal item_done

var main: MainScene
var hints: HintLadder
var item: Dictionary = {}
var format: Dictionary = {}
var active: bool = false
var frozen: bool = false
var praise_count: int = 0
var last_choices: int = 2  # options the child had for the last answer (guess chance)
var _idle: float = 0.0
var _prompt_end_ms: int = 0
var _answered_once: bool = false


func activity_id() -> String:
	return ""


## Scored activities share the engine's hint ladder (fading per skill);
## unscored ones (writing) keep their own.
func scored() -> bool:
	return true


## Camera pose for this station: target, distance, pitch, yaw.
func camera_pose() -> Dictionary:
	return {}


func begin_visit() -> void:
	praise_count = 0
	Voice.reset_chime()


func end_visit() -> void:
	active = false


func start_item(p_item: Dictionary, p_format: Dictionary, hint_start: int) -> void:
	item = p_item
	format = p_format
	_answered_once = false
	_idle = 0.0
	hints.level = maxi(hints.level, hint_start)
	hints.highest = maxi(hints.highest, hints.level)
	active = true


func touch(_event: InputEvent) -> void:
	pass


func apply_hint(_level: int) -> void:
	pass


func reset_idle() -> void:
	_idle = 0.0


func mark_prompt_end(seconds_from_now: float) -> void:
	_prompt_end_ms = Time.get_ticks_msec() + int(seconds_from_now * 1000.0)


## Report one answer; only the first answer of an item is evidence.
func report(skill_ids: Array[String], correct: bool, level: int) -> void:
	report_with(skill_ids, correct, level, not _answered_once)
	_answered_once = true


## Report with an explicit first-attempt flag (activities with several slots).
func report_with(skill_ids: Array[String], correct: bool, level: int, first: bool) -> void:
	var names: Array[StringName] = []
	for s: String in skill_ids:
		names.append(StringName(s))
	var latency: float = maxf(0.0, (Time.get_ticks_msec() - _prompt_end_ms) / 1000.0)
	answered.emit(StringName(str(item.get("id", ""))), names, correct, level, first, latency)


func _process(delta: float) -> void:
	if not active or frozen or Voice.is_busy():
		return
	_idle += delta
	if _idle >= LearnBalance.IDLE_HINT_SEC:
		_idle = 0.0
		var before: int = hints.level
		var lv: int = hints.on_idle()
		if lv != before:
			apply_hint(lv)
		else:
			Voice.repeat_prompt()


func freeze_for(sec: float) -> void:
	frozen = true
	await get_tree().create_timer(sec).timeout
	frozen = false
	Voice.repeat_prompt()
