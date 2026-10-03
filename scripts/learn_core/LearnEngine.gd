class_name LearnEngine
extends RefCounted
## Facade over the learner model, selector, hint ladder and planner.
## Contract with activities (GDD 5.1): the engine hands out a task
## (item + format + hint start); the activity reports answers back.
## No reading knowledge: ids, groups and "tests" lists come from the pack.

var pack: ContentPack = ContentPack.new()
var model: LearnerModel = LearnerModel.new()
var selector: ItemSelector = ItemSelector.new()
var hints: HintLadder = HintLadder.new()
var disengage: DisengageDetector = DisengageDetector.new()
var log_path: String = ""  # "" = no evidence log (tests)
var _item_last_used: Dictionary = {}
var _item_counter: int = 0


func setup(pack_dir: String, seed_value: int = 0) -> bool:
	if seed_value != 0:
		selector.rng.seed = seed_value
	else:
		selector.rng.randomize()
	return pack.load_dir(pack_dir)


func is_skill_available(id: String) -> bool:
	if not pack.has_skill(id):
		return false
	if pack.is_gated(id):
		return model.is_introduced(id)
	for p: String in pack.prereqs(id):
		if not is_skill_available(p):
			return false
	return true


## Skills an item is scored on: its "tests" list, else all of its skills.
func tested_skills(it: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for s: Variant in it.get("tests", it.get("skills", [])):
		out.append(str(s))
	return out


func usable_items(activity: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for it: Dictionary in pack.items_for_activity(activity):
		var ok: bool = true
		for s: String in pack.item_skills(it):
			if not is_skill_available(s):
				ok = false
				break
		if ok:
			out.append(it)
	return out


## Next task for an activity, or {} when nothing is usable yet.
## Keys: item, skill, choices, similarity, hint_start, predicted, distractors.
func next_task(activity: String, max_choices: int, avoid_items: Array[String] = []) -> Dictionary:
	var usable: Array[Dictionary] = usable_items(activity)
	if usable.is_empty():
		return {}
	var eligible: Array[String] = []
	for it: Dictionary in usable:
		for s: String in tested_skills(it):
			if not eligible.has(s):
				eligible.append(s)
	var skill: String = selector.choose_skill(model, eligible)
	var candidates: Array[Dictionary] = []
	for it: Dictionary in usable:
		if tested_skills(it).has(skill) and not avoid_items.has(str(it["id"])):
			candidates.append(it)
	if candidates.is_empty():
		for it: Dictionary in usable:
			if tested_skills(it).has(skill):
				candidates.append(it)
	var item: Dictionary = _least_recent_item(candidates)
	var is_new: bool = model.opportunities(skill) == 0
	var hint_floor: int = hints.start_for(skill)
	if is_new:
		hint_floor = maxi(hint_floor, LearnBalance.HINT_START_NEW_SKILL)
	var fmt: Dictionary = selector.choose_format(model.p_known(skill), max_choices, hint_floor)
	var exclude: Array[String] = pack.item_skills(item)
	fmt["distractors"] = distractor_skills(
		skill, exclude, int(fmt["choices"]) - 1, str(fmt["similarity"])
	)
	fmt["item"] = item
	fmt["skill"] = skill
	return fmt


## Gated, introduced skills to use as distractors. "near" = same pack group first.
func distractor_skills(
	target: String, exclude: Array[String], n: int, similarity: String
) -> Array[String]:
	var near: Array[String] = []
	var far: Array[String] = []
	var tgroup: String = pack.group(target)
	for sid: String in model.introduced():
		if sid == target or exclude.has(sid):
			continue
		if pack.group(sid) == tgroup:
			near.append(sid)
		else:
			far.append(sid)
	_shuffle(near)
	_shuffle(far)
	var ordered: Array[String] = []
	if similarity == "near":
		ordered.append_array(near)
		ordered.append_array(far)
	else:
		ordered.append_array(far)
		ordered.append_array(near)
	return ordered.slice(0, maxi(n, 0))


func begin_item(skill: String) -> int:
	return hints.begin(skill, model.opportunities(skill) == 0)


## Report one answer. Only first attempts are evidence (GDD 5.2).
func record_answer(
	item_id: String,
	skill_ids: Array[String],
	correct: bool,
	hint_level: int,
	first_attempt: bool,
	choices: int
) -> Dictionary:
	if not first_attempt:
		return {"scored": false, "step": ItemSelector.STEP_NONE, "break": false}
	for s: String in skill_ids:
		model.update(s, correct, choices, hint_level)
	var step: int = selector.record(correct)
	_log(
		{
			"t": "answer",
			"item": item_id,
			"skills": skill_ids,
			"ok": correct,
			"hint": hint_level,
			"choices": choices
		}
	)
	return {"scored": true, "step": step, "break": selector.take_break()}


## A wrong tap; returns true when the taps add up to random tapping.
func wrong_tap(now_sec: float) -> bool:
	return disengage.wrong_tap(now_sec)


## Random tapping is not evidence: it is logged as an event only.
func record_disengaged(item_id: String) -> void:
	_log({"t": "disengaged", "item": item_id})


func finish_item() -> int:
	return hints.finish()


## Introduce the next skill(s) from the pack order while the gate allows it.
func introduce_ready() -> Array[String]:
	var added: Array[String] = []
	while SessionPlanner.can_introduce_next(model, pack):
		var sid: String = SessionPlanner.next_skill(model, pack)
		model.introduce(sid)
		added.append(sid)
	return added


func to_dict() -> Dictionary:
	return {"model": model.to_dict(), "hints": hints.to_dict()}


func from_dict(d: Dictionary) -> void:
	model.from_dict(d.get("model", {}))
	hints.from_dict(d.get("hints", {}))


func save(path: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("LearnEngine: cannot save %s" % path)
		return
	f.store_string(JSON.stringify(to_dict()))


func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary:
		return false
	from_dict(d as Dictionary)
	return true


func _least_recent_item(pool: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = pool[0]
	var best_t: int = 1 << 30
	for it: Dictionary in pool:
		var t: int = int(_item_last_used.get(str(it["id"]), -1))
		if t < best_t:
			best_t = t
			best = it
	_item_counter += 1
	_item_last_used[str(best["id"])] = _item_counter
	return best


func _shuffle(arr: Array[String]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = selector.rng.randi_range(0, i)
		var tmp: String = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _log(entry: Dictionary) -> void:
	if log_path == "":
		return
	var mode: FileAccess.ModeFlags = (
		FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE
	)
	var f: FileAccess = FileAccess.open(log_path, mode)
	if f == null:
		return
	f.seek_end()
	entry["session"] = model.session_index
	f.store_line(JSON.stringify(entry))
