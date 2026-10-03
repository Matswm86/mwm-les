class_name SessionPlanner
extends RefCounted
## New-skill gate (GDD 5.6). The order comes from the pack's unlock_order;
## the first `first_group_size` skills are introduced together.


static func next_skill(model: LearnerModel, pack: ContentPack) -> String:
	for sid: String in pack.unlock_order:
		if not model.is_introduced(sid):
			return sid
	return ""


static func can_introduce_next(model: LearnerModel, pack: ContentPack) -> bool:
	if next_skill(model, pack) == "":
		return false
	var intro: Array[String] = model.introduced()
	if intro.size() < pack.first_group_size:
		return true
	if model.introduced_this_session() >= LearnBalance.MAX_NEW_SKILLS_PER_SESSION:
		return false
	for sid: String in intro:
		if model.p_known(sid) < LearnBalance.INTRO_NEXT_P:
			return false
	return true
