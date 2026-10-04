class_name MainScene
extends Node3D
## Enhjørningenga, first playable slice: the island hub with three lit
## stations, the station visits (engine -> activity -> engine), colour
## restoration, the read-to-a-grown-up step and the parent gate.

enum Mode { INTRO, HUB, FLYING, ACTIVITY, GROWNUP, PARENT, SUNSET, STORY }

const STATIONS: Array[String] = ["hor_og_finn", "skriv", "ordbro"]
const NEXT_LINES: Array[String] = ["next_find", "next_write", "next_bridge"]
const HUB_GHOST_AFTER_SEC: float = 7.0

var mode: Mode = Mode.INTRO
var world: World
var rig: CameraRig
var pip: Pip
var hero: Hero
var unicorn: Unicorn
var hud: Hud
var beacons: Array[Beacon] = []
var activities: Array[Activity] = []
var current: Activity
var current_station: int = -1
var visits_done: Array[bool] = [false, false, false]
var _overlay: Control
var _visit_abort: bool = false
var _story: OpeningStory
var _hub_idle: float = 0.0
var _next: int = -1


func _ready() -> void:
	world = World.new()
	add_child(world)
	rig = CameraRig.new()
	add_child(rig)
	hero = Hero.new()
	add_child(hero)
	hero.global_position = world.knight_spot
	hero.face(world.knight_spot + Vector3(-0.6, 0, 1.0))
	unicorn = Unicorn.new()
	add_child(unicorn)
	unicorn.stripes = Game.unicorn_stripes
	unicorn.global_position = world.unicorn_spot
	unicorn.rotation.y = deg_to_rad(-20.0)
	pip = Pip.new()
	add_child(pip)
	pip.cam = rig.cam
	hud = Hud.new()
	add_child(hud)
	hud.replay_pressed.connect(_on_replay)
	hud.home_pressed.connect(_on_home)
	hud.parent_pressed.connect(open_parent_gate)
	hud.story_pressed.connect(_replay_story)
	for i in 3:
		var b: Beacon = Beacon.new()
		b.station = i
		add_child(b)
		var c: Vector3 = world.zone_centers[i]
		b.global_position = c + Vector3(0, 3.2, 0)
		beacons.append(b)
	activities = [HorOgFinn.new(), Sandskriving.new(), OrdBro.new()]
	for a: Activity in activities:
		a.main = self
		a.hints = Game.engine.hints if a.scored() else HintLadder.new()
		add_child(a)
		a.answered.connect(_on_answered)
		a.disengaged.connect(_on_disengaged)
	for i in 3:
		if Game.restored[i]:
			world.set_zone_now(i, 1.0)
	if Game.unicorn_stripes == 0:
		unicorn.sad.call_deferred()
	if Game.story_seen:
		_intro()
	else:
		_play_story(false)


# ---------------------------------------------------------------- hub


func hub_pose() -> Dictionary:
	return {
		"target": GameTune.CAM_HUB_TARGET,
		"distance": GameTune.CAM_HUB_DISTANCE,
		"pitch": GameTune.CAM_HUB_PITCH_DEG
	}


func _intro() -> void:
	mode = Mode.INTRO
	hud.hide_all()
	var hp: Dictionary = hub_pose()
	rig.set_pose(hp["target"] + Vector3(0, 6, -10), float(hp["distance"]) * 1.6, 12.0, -18.0)
	pip.snap_home()
	var tw: Tween = rig.fly_to(
		hp["target"], hp["distance"], hp["pitch"], 0.0, GameTune.CAM_INTRO_SEC
	)
	await tw.finished
	pip.giggle()
	await get_tree().create_timer(Voice.say(["pip_hello"]) + 0.2).timeout
	_enter_hub()


## The opening story (GDD 9). First launch: it plays through and only a tap
## on Pip ends it. From the hub button it can be replayed and skipped.
func _play_story(replay: bool) -> void:
	mode = Mode.STORY
	for b: Beacon in beacons:
		b.visible = false
	_story = OpeningStory.new()
	_story.main = self
	_story.skippable = Game.story_seen
	add_child(_story)
	await _story.play()
	_story = null
	Game.story_seen = true
	Game.save()
	if not replay:
		pip.giggle()
	_enter_hub()


func _replay_story() -> void:
	if mode != Mode.HUB:
		return
	hud.hide_all()
	_play_story(true)


## Only the next station is lit; Pip swims over to it and says why.
func _enter_hub() -> void:
	mode = Mode.HUB
	hud.show_hub()
	_hub_idle = 0.0
	_next = Game.next_station(visits_done)
	for i in 3:
		beacons[i].visible = i == _next
	if _next < 0:
		pip.go_home()
		return
	pip.guide_to(_guide_spot(beacons[_next]))
	Voice.say([NEXT_LINES[_next]], true)


## A spot on the camera ray to the beacon, close enough that Pip stays big,
## just left of and below the beacon on screen.
func _guide_spot(b: Beacon) -> Vector3:
	var cam_pos: Vector3 = rig.cam.global_position
	var dir: Vector3 = (b.global_position - cam_pos).normalized()
	return cam_pos + dir * 11.0 - rig.cam.global_basis.x * 1.9 - Vector3(0, 1.1, 0)


func _process(delta: float) -> void:
	if mode != Mode.HUB or _next < 0 or hud.ghost.showing():
		return
	_hub_idle += delta
	if _hub_idle >= HUB_GHOST_AFTER_SEC and not Voice.is_busy():
		var b: Beacon = beacons[_next]
		hud.ghost.tap(func() -> Vector2: return rig.cam.unproject_position(b.global_position))
		Voice.repeat_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	match mode:
		Mode.STORY:
			if _story:
				_story.touch(event)
		Mode.HUB:
			_hub_touch(event)
		Mode.ACTIVITY:
			var t: InputEventScreenTouch = event as InputEventScreenTouch
			if t and t.pressed and pip.hit(t.position):
				pip.giggle()
				Voice.repeat_prompt()
				return
			if current:
				current.touch(event)
		Mode.SUNSET:
			var t2: InputEventScreenTouch = event as InputEventScreenTouch
			if t2 and t2.pressed:
				_new_session()


func _hub_touch(event: InputEvent) -> void:
	var t: InputEventScreenTouch = event as InputEventScreenTouch
	if t == null or not t.pressed:
		return
	_hub_idle = 0.0
	hud.ghost.stop()
	for i in 3:
		if beacons[i].hit(rig.cam, t.position):
			start_station(i)
			return
	if pip.hit(t.position):
		pip.giggle()
		if _next >= 0:
			Voice.repeat_prompt()
		else:
			Voice.say(["pip_hello"])
		return
	var hp: Vector2 = rig.cam.unproject_position(hero.global_position + Vector3(0, 0.8, 0))
	if t.position.distance_to(hp) < 150.0:
		hero.cheer()


# ---------------------------------------------------------------- stations


func start_station(i: int) -> void:
	if mode != Mode.HUB:
		return
	mode = Mode.FLYING
	current_station = i
	current = activities[i]
	var act: Activity = current
	for b: Beacon in beacons:
		b.visible = false
	hud.hide_all()
	Voice.stop()
	pip.go_home()
	Voice.sfx("whoosh")
	var pose: Dictionary = act.camera_pose()
	await rig.fly_to(pose["target"], pose["distance"], pose["pitch"], 0.0).finished
	mode = Mode.ACTIVITY
	hud.show_activity()
	_visit_abort = false
	act.begin_visit()
	var n: int = int(GameTune.ITEMS_PER_VISIT[STATIONS[i]])
	var max_choices: int = int(GameTune.MAX_CHOICES[STATIONS[i]])
	if not Game.stations_done[i]:
		max_choices = mini(max_choices, 2)  # the very first visit: two choices
	var used: Array[String] = []
	var finished_all: bool = true
	var first: Dictionary = act.adjust_task(Game.engine.next_task(STATIONS[i], max_choices, used))
	if not first.is_empty():
		await act.story_intro(first)
	for k in n:
		var task: Dictionary = (
			first
			if k == 0
			else act.adjust_task(Game.engine.next_task(STATIONS[i], max_choices, used))
		)
		if task.is_empty():
			break
		var it: Dictionary = task["item"]
		used.append(str(it["id"]))
		var level: int = 0
		if act.scored():
			level = maxi(Game.engine.begin_item(str(task["skill"])), int(task["hint_start"]))
		act.start_item(it, task, level)
		await act.item_done
		if act.scored():
			Game.engine.finish_item()
		if _visit_abort:
			finished_all = false
			break
	if finished_all and not _visit_abort:
		await act.story_payoff()
		Game.stations_done[i] = true
	act.end_visit()
	Game.save()
	if finished_all and not _visit_abort:
		await _restore(i)
	current = null
	mode = Mode.FLYING
	hud.hide_all()
	await (
		rig.fly_to(hub_pose()["target"], hub_pose()["distance"], hub_pose()["pitch"], 0.0).finished
	)
	if _visit_abort:
		_enter_hub()
		return
	visits_done[i] = true
	if _session_should_end():
		_grownup_step()
	else:
		_enter_hub()


func _restore(i: int) -> void:
	var c: Vector3 = world.zone_centers[i]
	await rig.fly_to(c + Vector3(0, 0.5, -1.5), 16.0, 34.0, 0.0, 1.2).finished
	world.restore_zone(i)
	Game.restored[i] = true
	Game.save()
	Voice.sfx("fanfare")
	Voice.say(["restore"])
	hero.cheer()
	await get_tree().create_timer(GameTune.ZONE_RESTORE_SEC + 0.6).timeout


func _session_should_end() -> bool:
	var all_done: bool = visits_done[0] and visits_done[1] and visits_done[2]
	var cap: float = LearnBalance.SESSION_SOFT_END_SEC - LearnBalance.GROWNUP_CARD_BEFORE_END_SEC
	return all_done or Game.session_seconds() >= cap


func _on_answered(
	item_id: StringName,
	skill_ids: Array[StringName],
	correct: bool,
	hint_level: int,
	first_attempt: bool,
	_latency: float
) -> void:
	var ids: Array[String] = []
	for s: StringName in skill_ids:
		ids.append(str(s))
	Game.note_answer(ids)
	var choices: int = current.last_choices if current else 2
	var r: Dictionary = Game.engine.record_answer(
		str(item_id), ids, correct, hint_level, first_attempt, choices
	)
	if bool(r.get("break", false)) and current:
		_movement_break()


func _on_disengaged(item_id: StringName) -> void:
	Game.engine.record_disengaged(str(item_id))
	Voice.say(["break"])
	if current:
		current.freeze_for(GameTune.FREEZE_AFTER_RANDOM_TAPS_SEC + Voice.length("break"))


## Movement break stub (GDD 5.3/6.9): Pip invites a breather, objects rest.
func _movement_break() -> void:
	Voice.then(["break"])
	pip.giggle()
	current.freeze_for(GameTune.FREEZE_AFTER_RANDOM_TAPS_SEC + Voice.length("break"))


func _on_replay() -> void:
	pip.giggle()
	Voice.repeat_prompt()


func _on_home() -> void:
	if mode != Mode.ACTIVITY or current == null:
		return
	_visit_abort = true
	Voice.stop()
	current.active = false
	current.item_done.emit()


# ---------------------------------------------------------------- end of session


func _grownup_step() -> void:
	mode = Mode.GROWNUP
	hud.hide_all()
	var card: GrownupCard = GrownupCard.new()
	card.words = Game.grownup_words()
	hud.add_overlay(card)
	_overlay = card
	Voice.say(["grownup_read"], true)
	card.heard.connect(func() -> void: _end_grownup(true))
	card.no_adult.connect(func() -> void: _end_grownup(false))


func _end_grownup(heard: bool) -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	if heard:
		Game.words_read_to_adult = Game.words_today.duplicate()
		Voice.sfx("fanfare")
		Voice.say(["grownup_thanks"])
	else:
		Voice.say(["grownup_later"])
	await Voice.wait_idle()
	_sunset()


## Yawn, one offline idea, warm light. A new session needs a fresh tap.
func _sunset() -> void:
	mode = Mode.SUNSET
	var line: Dictionary = Game.pick_offline_line()
	var ids: Array = ["yawn"]
	ids.append_array(line.get("audio", []))
	Voice.say(ids)
	create_tween().tween_method(world.set_sunset, 0.0, 1.0, 3.0)
	rig.fly_to(
		hub_pose()["target"] + Vector3(0, 2, -6),
		float(hub_pose()["distance"]) * 1.15,
		14.0,
		0.0,
		3.0
	)
	Game.save()


func _new_session() -> void:
	create_tween().tween_method(world.set_sunset, 1.0, 0.0, 1.0)
	visits_done = [false, false, false]
	Game.words_today.clear()
	Game.practised_today.clear()
	Game.engine.model.start_session()
	await (
		rig.fly_to(hub_pose()["target"], hub_pose()["distance"], hub_pose()["pitch"], 0.0).finished
	)
	_enter_hub()


# ---------------------------------------------------------------- parent area


func open_parent_gate() -> void:
	if mode != Mode.HUB:
		return
	mode = Mode.PARENT
	hud.hide_all()
	var gate: ParentGate = ParentGate.new()
	hud.add_overlay(gate)
	_overlay = gate
	gate.closed.connect(_close_overlay)
	gate.passed.connect(_open_parent_page)


func _open_parent_page() -> void:
	if _overlay:
		_overlay.queue_free()
	var page: ParentPage = ParentPage.new()
	hud.add_overlay(page)
	_overlay = page
	page.closed.connect(_close_overlay)


func _close_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	_enter_hub()


# ---------------------------------------------------------------- effects


func burst(at: Vector3) -> void:
	var p: CPUParticles3D = CPUParticles3D.new()
	p.one_shot = true
	p.amount = 16
	p.lifetime = 0.9
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -6, 0)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.4
	var q: QuadMesh = QuadMesh.new()
	q.size = Vector2(0.18, 0.18)
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = GameTune.GOLD
	m.emission_enabled = false
	q.material = m
	p.mesh = q
	add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)
