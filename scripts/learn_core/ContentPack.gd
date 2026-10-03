class_name ContentPack
extends RefCounted
## Loads skills.json + items.json of one content pack. Fields the engine reads:
## skills: id, gated, prereq, group, label. items: id, skills, activities.
## Every other field passes through untouched for the activities.
## The unlock order (`unlock_order` in skills.json) lives only in the pack.

var pack_id: String = ""
var unlock_order: Array[String] = []
var first_group_size: int = 1
var skills: Array[Dictionary] = []
var items: Array[Dictionary] = []
var _skill_by_id: Dictionary = {}
var _item_by_id: Dictionary = {}


func load_dir(dir: String) -> bool:
	var s: Variant = _read_json(dir.path_join("skills.json"))
	var i: Variant = _read_json(dir.path_join("items.json"))
	if not (s is Dictionary and i is Dictionary):
		push_error("ContentPack: cannot read pack at %s" % dir)
		return false
	return load_data(s as Dictionary, i as Dictionary)


func load_data(skills_doc: Dictionary, items_doc: Dictionary) -> bool:
	pack_id = str(skills_doc.get("pack", ""))
	first_group_size = int(skills_doc.get("first_group_size", 1))
	unlock_order.clear()
	for sid: Variant in skills_doc.get("unlock_order", []):
		unlock_order.append(str(sid))
	skills.clear()
	_skill_by_id.clear()
	for raw: Variant in skills_doc.get("skills", []):
		var d: Dictionary = raw
		skills.append(d)
		_skill_by_id[str(d["id"])] = d
	items.clear()
	_item_by_id.clear()
	for raw: Variant in items_doc.get("items", []):
		var d: Dictionary = raw
		items.append(d)
		_item_by_id[str(d["id"])] = d
	for sid: String in unlock_order:
		if not _skill_by_id.has(sid):
			push_error("ContentPack: unlock_order names unknown skill %s" % sid)
			return false
	return true


func skill(id: String) -> Dictionary:
	return _skill_by_id.get(id, {})


func item(id: String) -> Dictionary:
	return _item_by_id.get(id, {})


func has_skill(id: String) -> bool:
	return _skill_by_id.has(id)


func is_gated(id: String) -> bool:
	return bool(skill(id).get("gated", false))


func prereqs(id: String) -> Array[String]:
	var out: Array[String] = []
	for p: Variant in skill(id).get("prereq", []):
		out.append(str(p))
	return out


func group(id: String) -> String:
	return str(skill(id).get("group", ""))


func item_skills(it: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for s: Variant in it.get("skills", []):
		out.append(str(s))
	return out


func items_for_activity(activity: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for it: Dictionary in items:
		var acts: Array = it.get("activities", [])
		if acts.has(activity):
			out.append(it)
	return out


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))
