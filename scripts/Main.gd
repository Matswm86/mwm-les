class_name MainScene
extends Node3D
## MWM Les: the island, Pip, and the lamb on the little islet across the
## water. Pip's best friend, the lamb, cannot swim, so Pip and the child build
## a bridge of letters: find letters (Hør og finn), write them in the sand
## where they become stones (Sandskriving), lay the stones as a bridge that
## spells lam (Ordbroa). Then the lamb walks over. Every spoken line is one of
## the owner's own recordings (Voice autoload, docs/SCRIPT.md).
## First launch: the opening (op_1..op_5). Later launches: hub_back.

signal station_chosen

enum Mode { START, OPENING, HUB, FLYING, STATION, END }

const SCENES: Array[String] = ["find", "write", "bridge"]
const HUB_IDLE_SEC: float = 7.0
const BRIDGE_WORD: String = "lam"
const BEACON_SCALE: float = 1.6  # the lit station must read from across the island

var mode: Mode = Mode.START
var world: World
var rig: CameraRig
var pip: Pip
var lamb: Node3D
var hud: Hud
var beacons: Array[Beacon] = []
var stations: Array[Activity] = []
var current: Activity
var story: OpeningStory
var sessions: int = 0
var _next: int = -1
var _hub_ids: Array[String] = []
var _hub_idle: float = 0.0
var _plan: Dictionary = {}
var _pile: Array[Stone] = []


func _ready() -> void:
	world = World.new()
	add_child(world)
	world.set_colour_all(1.0)  # the island is always in full colour
	rig = CameraRig.new()
	add_child(rig)
	var hp: Dictionary = hub_pose()
	rig.set_pose(hp["target"], hp["distance"], hp["pitch"], 0.0)
	lamb = Props.make("lamb")
	add_child(lamb)
	reset_lamb()
	pip = Pip.new()
	add_child(pip)
	pip.cam = rig.cam
	hud = Hud.new()
	add_child(hud)
	hud.hide_all()
	hud.replay_pressed.connect(_on_replay)
	for i in 3:
		var b: Beacon = Beacon.new()
		b.station = i
		add_child(b)
		b.global_position = world.zone_centers[i] + Vector3(0, 3.2, 0)
		b.scale = Vector3.ONE * BEACON_SCALE
		b.visible = false
		beacons.append(b)
	stations = [HorOgFinn.new(), Sandskriving.new(), OrdBro.new()]
	for a: Activity in stations:
		a.main = self
		add_child(a)
	_start.call_deferred()


func hub_pose() -> Dictionary:
	return {
		"target": GameTune.CAM_HUB_TARGET,
		"distance": GameTune.CAM_HUB_DISTANCE,
		"pitch": GameTune.CAM_HUB_PITCH_DEG
	}


func _start() -> void:
	pip.snap_home()
	var greet: String = "hub_back"
	if not Game.story_seen:
		greet = ""
		mode = Mode.OPENING
		Voice.scene = "opening"
		story = OpeningStory.new()
		story.main = self
		add_child(story)
		await story.play()
		story = null
		Game.story_seen = true
		Game.save()
	_session(greet)


## One session: the three stations in order, then goodnight.
func _session(greet: String) -> void:
	sessions += 1
	_plan = {}
	for i in 3:
		await _hub(i, greet)
		greet = ""
		await _station(i)
	await _end()


# ---------------------------------------------------------------- hub


## Only station i is lit; Pip swims over to it and says why.
func _hub(i: int, greet: String) -> void:
	mode = Mode.HUB
	Voice.scene = "hub"
	hud.hide_all()
	_next = i
	_hub_idle = 0.0
	for k in 3:
		beacons[k].visible = k == i
	pip.guide_to(_guide_spot(beacons[i]))
	_hub_ids.clear()
	if greet != "":
		_hub_ids.append(greet)
	_hub_ids.append(stations[i].hub_line())
	Voice.say(_hub_ids)
	await station_chosen


## A spot on the camera ray to the beacon, close enough that Pip stays big,
## just left of and below the beacon on screen.
func _guide_spot(b: Beacon) -> Vector3:
	var cam_pos: Vector3 = rig.cam.global_position
	var dir: Vector3 = (b.global_position - cam_pos).normalized()
	return cam_pos + dir * 11.0 - rig.cam.global_basis.x * 1.9 - Vector3(0, 1.1, 0)


## The child taps the lit station (touch path and test).
func choose_station() -> void:
	if mode != Mode.HUB:
		return
	hud.ghost.stop()
	station_chosen.emit()


func _process(delta: float) -> void:
	if mode != Mode.HUB:
		return
	if Voice.is_busy():
		_hub_idle = 0.0
		return
	_hub_idle += delta
	if _hub_idle >= HUB_IDLE_SEC:
		_hub_idle = 0.0
		var b: Beacon = beacons[_next]
		hud.ghost.tap(func() -> Vector2: return rig.cam.unproject_position(b.global_position))
		Voice.say(["hub_idle"])


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	var t: InputEventScreenTouch = event as InputEventScreenTouch
	match mode:
		Mode.OPENING:
			if story:
				story.touch(event)
		Mode.HUB:
			if t and t.pressed:
				_hub_idle = 0.0
				if beacons[_next].hit(rig.cam, t.position):
					choose_station()
				elif pip.hit(t.position):
					pip.giggle()
					Voice.say(_hub_ids)
		Mode.STATION:
			if t and t.pressed and pip.hit(t.position) and not current is Sandskriving:
				pip.giggle()
				current.replay()
				return
			if current:
				current.touch(event)
		Mode.END:
			if t and t.pressed and not Voice.is_busy():
				new_session()


func _on_replay() -> void:
	if mode == Mode.STATION and current:
		pip.giggle()
		current.replay()


# ---------------------------------------------------------------- stations


func _station(i: int) -> void:
	mode = Mode.FLYING
	current = stations[i]
	for b: Beacon in beacons:
		b.visible = false
	hud.hide_all()
	Voice.stop()
	pip.go_home()
	var pose: Dictionary = current.camera_pose()
	Voice.scene = SCENES[i]
	await rig.fly_to(pose["target"], pose["distance"], pose["pitch"], pose.get("yaw", 0.0)).finished
	mode = Mode.STATION
	hud.replay_btn.visible = i != 1  # writing has no sound to hear again
	current.begin()
	await current.run()
	current.end()
	hud.hide_all()
	current = null
	mode = Mode.FLYING
	var hp: Dictionary = hub_pose()
	await rig.fly_to(hp["target"], hp["distance"], hp["pitch"], 0.0).finished


## What the bridge needs this session: the letters of `lam` the child has met
## are missing from the bridge and get written in the sand. Only letters the
## bridge uses are written, so every stone ends up in the bridge.
func plan() -> Dictionary:
	if _plan.is_empty():
		var known: Array[String] = (stations[0] as HorOgFinn).rules.letters()
		var miss: Array[String] = []
		for c: String in BRIDGE_WORD:
			if known.has(c):
				miss.append(c)
		_plan = {"missing": miss, "stones": miss.duplicate()}
	return _plan


# ---------------------------------------------------------------- end


func _end() -> void:
	mode = Mode.FLYING
	Voice.scene = "end"
	hud.hide_all()
	for b: Beacon in beacons:
		b.visible = false
	create_tween().tween_method(world.set_sunset, 0.0, 1.0, 3.0)
	var hp: Dictionary = hub_pose()
	await (
		rig
		. fly_to(hp["target"] + Vector3(4, 1, -4), float(hp["distance"]) * 0.8, 14.0, 0.0, 2.5)
		. finished
	)
	pip.giggle()
	await Voice.say_wait(["end_bye"], 0.3)
	mode = Mode.END


## A tap after goodnight: a new day, the lamb is back on its islet.
func new_session() -> void:
	if mode != Mode.END:
		return
	mode = Mode.FLYING
	create_tween().tween_method(world.set_sunset, 1.0, 0.0, 1.0)
	reset_lamb()
	_clear_pile()
	var hp: Dictionary = hub_pose()
	await rig.fly_to(hp["target"], hp["distance"], hp["pitch"], 0.0).finished
	_session("hub_back")


# ---------------------------------------------------------------- lamb and stones


func reset_lamb() -> void:
	var at: Vector3 = world.thing_spots.get("l", GameTune.ISLET_CENTER)
	lamb.global_position = at
	lamb.scale = Vector3.ONE * float(GameTune.THING_SCALES.get("l", 0.75))
	lamb.rotation.y = PI  # looks across the water toward the island


## A written stone rolls in and lies by the bridge until it is laid.
func add_to_pile(st: Stone) -> void:
	st.reparent(self)
	var b: Vector3 = world.bridge_start
	var d: Vector3 = (world.bridge_end - b).normalized()
	var c: Vector3 = b - d * 1.6 + Vector3(-d.z, 0, d.x) * 1.5
	var k: int = _pile.size()
	var spot: Vector3 = c + Vector3(1.4 * float(k % 3) - 1.4, 0, 1.25 * floorf(float(k) / 3.0))
	st.global_basis = Basis()
	st.scale = Vector3.ONE * GameTune.PILE_STONE_SCALE
	st.global_position = world.on_ground(spot.x, spot.z)
	_pile.append(st)


func hide_pile() -> void:
	for st: Stone in _pile:
		st.visible = false


func _clear_pile() -> void:
	for st: Stone in _pile:
		st.queue_free()
	_pile.clear()


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
	q.material = m
	p.mesh = q
	add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)
