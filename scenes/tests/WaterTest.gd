extends Node3D
## Standalone test of the studio stylized water (and a small grass patch).
## Not part of the game: Main.tscn does not load it.
## Tap the sea to start a ripple. Bobbing boxes ring the water on their own.
## WATER_DEPTH=1 compiles the water with depth-texture foam (WATER_DEPTH_FOAM);
## default is the phone-safe floater-circle foam.
## WATER_CAPTURE_DIR=<dir> taps the sea itself, saves two PNGs and quits.

const WATER_SHADER: Shader = preload("res://shaders/stylized_water.gdshader")
const GRASS_SHADER: Shader = preload("res://shaders/stylized_grass.gdshader")

# test-scene numbers, in one place
const CAM_TARGET: Vector3 = Vector3(0.5, 0.0, 0.0)
const CAM_DISTANCE: float = 16.0
const CAM_PITCH_DEG: float = 26.0
const SEA_SIZE: float = 420.0
const SEA_SUBDIV: int = 64
const MAX_RIPPLES: int = 8
const BOB_HEIGHT: float = 0.18
const BOB_SPEED: float = 1.6
const BOB_RIPPLE_SEC: float = 3.2
const ISLAND_POS: Vector3 = Vector3(5.5, 0.0, -3.5)
const ISLAND_RADIUS: float = 2.6
const GRASS_COUNT: int = 1400
const GRASS_WIDTH: float = 0.11
const GRASS_LEN_MIN: float = 0.35
const GRASS_LEN_MAX: float = 0.6

var rig: CameraRig
var water: ShaderMaterial
var _clock: float = 0.0
var _ripples: Array[Vector4] = []
# each: {node, radius (waterline), bob (bool), phase, next_ripple}
var _floaters: Array[Dictionary] = []
var _capture_dir: String = OS.get_environment("WATER_CAPTURE_DIR")


func _ready() -> void:
	_build_environment()
	rig = CameraRig.new()
	add_child(rig)
	rig.set_pose(CAM_TARGET, CAM_DISTANCE, CAM_PITCH_DEG, 0.0)
	_build_sea()
	_add_floater(Props.make("boat"), Vector3(-3.2, 0.0, 1.2), 1.5, true, 0.0)
	_add_floater(_box(Color(0.80, 0.58, 0.34), 0.9), Vector3(1.4, 0.0, 2.6), 0.62, true, 1.3)
	_add_floater(_box(Color(0.95, 0.30, 0.30), 0.7), Vector3(-0.6, 0.0, -2.4), 0.48, true, 2.4)
	_add_floater(_rock(1.1), Vector3(2.6, -0.35, -0.6), 1.0, false, 0.0)
	_add_floater(_rock(0.7), Vector3(-5.5, -0.2, -1.8), 0.62, false, 0.0)
	_build_island()
	if _capture_dir != "":
		_capture()


func _process(delta: float) -> void:
	_clock += delta
	var fl: PackedVector4Array = PackedVector4Array()
	for f: Dictionary in _floaters:
		var n: Node3D = f["node"]
		if f["bob"]:
			var ph: float = float(f["phase"])
			n.position.y = sin(_clock * BOB_SPEED + ph) * BOB_HEIGHT
			n.rotation.z = sin(_clock * BOB_SPEED * 0.7 + ph) * 0.08
			if _clock >= float(f["next_ripple"]):
				f["next_ripple"] = _clock + BOB_RIPPLE_SEC
				add_ripple(n.position, 0.6)
		fl.append(Vector4(n.position.x, n.position.z, float(f["radius"]), 1.0))
	water.set_shader_parameter("floaters", fl)
	water.set_shader_parameter("floater_count", fl.size())
	water.set_shader_parameter("ripple_now", _clock)


func _unhandled_input(event: InputEvent) -> void:
	var t: InputEventScreenTouch = event as InputEventScreenTouch
	if t != null and t.pressed and t.index == 0:
		add_ripple(rig.ground_point(t.position, 0.0), 1.0)


## Ring buffer of 8 ripples: x, z, start time, strength (shader contract).
func add_ripple(at: Vector3, strength: float) -> void:
	if _ripples.size() >= MAX_RIPPLES:
		_ripples.pop_front()
	_ripples.append(Vector4(at.x, at.z, _clock, strength))
	water.set_shader_parameter("ripples", PackedVector4Array(_ripples))
	water.set_shader_parameter("ripple_count", _ripples.size())


func _build_environment() -> void:
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = GameTune.SKY_TOP
	sky_mat.sky_horizon_color = GameTune.SKY_HORIZON
	sky_mat.ground_bottom_color = GameTune.SEA_DEEP
	sky_mat.ground_horizon_color = GameTune.SKY_HORIZON
	sky_mat.sky_curve = 0.12
	sky_mat.sun_angle_max = 0.0
	var sky: Sky = Sky.new()
	sky.sky_material = sky_mat
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = GameTune.SKY_HORIZON
	env.ambient_light_energy = GameTune.AMBIENT_ENERGY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(GameTune.SUN_PITCH_DEG, GameTune.SUN_YAW_DEG, 0.0)
	sun.light_energy = GameTune.SUN_ENERGY
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = GameTune.SHADOW_MAX_DISTANCE
	sun.shadow_bias = 0.15
	sun.shadow_normal_bias = 3.5
	add_child(sun)


func _build_sea() -> void:
	var shader: Shader = WATER_SHADER
	if OS.get_environment("WATER_DEPTH") == "1":
		shader = Shader.new()
		shader.code = WATER_SHADER.code.replace(
			"// #define WATER_DEPTH_FOAM", "#define WATER_DEPTH_FOAM"
		)
		print("WaterTest: depth-texture foam ON")
	water = ShaderMaterial.new()
	water.shader = shader
	# Les palette (DESIGN 3) on the source's cel pattern; opaque, no seabed
	water.set_shader_parameter("deep_color", GameTune.SEA_DEEP)
	water.set_shader_parameter("mid_color", GameTune.SEA_SHALLOW)
	water.set_shader_parameter("highlight_color", GameTune.FOAM)
	water.set_shader_parameter("foam_line_color", GameTune.FOAM)
	water.set_shader_parameter("deep_opacity", 1.0)
	water.set_shader_parameter("horizon_color", GameTune.SKY_HORIZON)
	water.set_shader_parameter("horizon_mix", 0.75)
	water.set_shader_parameter("fade_alpha", 0.0)
	water.set_shader_parameter("fade_distance", 170.0)
	water.set_shader_parameter("wave_height", 0.05)
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(SEA_SIZE, SEA_SIZE)
	plane.subdivide_width = SEA_SUBDIV
	plane.subdivide_depth = SEA_SUBDIV
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = water
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _add_floater(n: Node3D, pos: Vector3, radius: float, bob: bool, phase: float) -> void:
	n.position = pos
	add_child(n)
	_floaters.append(
		{"node": n, "radius": radius, "bob": bob, "phase": phase, "next_ripple": 0.4 + phase}
	)


func _box(col: Color, size: float) -> Node3D:
	var root: Node3D = Node3D.new()
	var mat: ShaderMaterial = MeshKit.with_outline(MeshKit.toon(col, false))
	var mi: MeshInstance3D = MeshKit.instance(MeshKit.box(Vector3.ONE * size), mat, root)
	mi.rotation_degrees = Vector3(0.0, 25.0, 0.0)
	return root


func _rock(r: float) -> Node3D:
	var root: Node3D = Node3D.new()
	var mi: MeshInstance3D = MeshKit.instance(
		MeshKit.sphere(r, 10, 6), MeshKit.toon(GameTune.ROCK, false), root
	)
	mi.scale = Vector3(1.0, 0.75, 0.85)
	return root


func _build_island() -> void:
	var root: Node3D = Node3D.new()
	root.position = ISLAND_POS
	add_child(root)
	MeshKit.instance(
		MeshKit.cylinder(ISLAND_RADIUS, ISLAND_RADIUS + 0.5, 1.2, 28),
		MeshKit.toon(GameTune.SAND, false),
		root,
		Vector3(0.0, -0.3, 0.0)
	)
	var top: float = 0.32
	MeshKit.instance(
		MeshKit.cylinder(ISLAND_RADIUS - 0.4, ISLAND_RADIUS - 0.3, 0.1, 28),
		MeshKit.toon(GameTune.GRASS_SHADE, false),
		root,
		Vector3(0.0, top - 0.05, 0.0)
	)
	_floaters.append(
		{"node": root, "radius": ISLAND_RADIUS + 0.4, "bob": false, "phase": 0.0, "next_ripple": 0.0}
	)
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _blade_mesh()
	mm.instance_count = GRASS_COUNT
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for i in GRASS_COUNT:
		var a: float = rng.randf() * TAU
		var d: float = sqrt(rng.randf()) * (ISLAND_RADIUS - 0.5)
		var b: Basis = Basis(Vector3.UP, rng.randf() * TAU).scaled(
			Vector3(GRASS_WIDTH, rng.randf_range(GRASS_LEN_MIN, GRASS_LEN_MAX), 1.0)
		)
		mm.set_instance_transform(i, Transform3D(b, Vector3(cos(a) * d, top, sin(a) * d)))
	var grass: ShaderMaterial = ShaderMaterial.new()
	grass.shader = GRASS_SHADER
	grass.set_shader_parameter("color_bottom", GameTune.GRASS_SHADE)
	grass.set_shader_parameter("color_top", GameTune.GRASS)
	grass.set_shader_parameter("ground_color", GameTune.GRASS_SHADE)
	grass.set_shader_parameter("ground_blend", 0.8)
	grass.set_shader_parameter("brightness", 1.0)
	grass.set_shader_parameter("wind_strength", 0.25)
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = grass
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


## One blade, 3 segments (7 vertices, 5 triangles), base y = 0, tip y = 1,
## half-width 0.5 * (1 - t)^1.2 as in the source geometry.
func _blade_mesh() -> ArrayMesh:
	var seg: int = 3
	var verts: PackedVector3Array = PackedVector3Array()
	for i in seg:
		var t: float = float(i) / float(seg)
		var w: float = 0.5 * pow(1.0 - t, 1.2)
		verts.append(Vector3(-w, t, 0.0))
		verts.append(Vector3(w, t, 0.0))
	verts.append(Vector3(0.0, 1.0, 0.0))
	var idx: PackedInt32Array = PackedInt32Array()
	for i in seg - 1:
		var l: int = i * 2
		idx.append_array([l, l + 2, l + 1, l + 1, l + 2, l + 3])
	var last: int = (seg - 1) * 2
	idx.append_array([last, seg * 2, last + 1])
	var normals: PackedVector3Array = PackedVector3Array()
	for v in verts.size():
		normals.append(Vector3(0.0, 0.0, 1.0))
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = idx
	var am: ArrayMesh = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


## Screenshot bot: real InputEventScreenTouch into the input pipeline, then PNGs.
func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	await get_tree().create_timer(1.5).timeout
	var vp: Vector2 = get_viewport().get_visible_rect().size
	for p: Vector2 in [vp * Vector2(0.62, 0.78), vp * Vector2(0.30, 0.62)]:
		var ev: InputEventScreenTouch = InputEventScreenTouch.new()
		ev.index = 0
		ev.position = p
		ev.pressed = true
		Input.parse_input_event(ev)
		var up: InputEventScreenTouch = ev.duplicate() as InputEventScreenTouch
		up.pressed = false
		Input.parse_input_event(up)
		await get_tree().create_timer(0.35).timeout
	await get_tree().create_timer(0.6).timeout
	_shot("water_a.png")
	await get_tree().create_timer(1.4).timeout
	_shot("water_b.png")
	get_tree().quit()


func _shot(name: String) -> void:
	var path: String = _capture_dir.path_join(name)
	get_viewport().get_texture().get_image().save_png(path)
	print("WaterTest: saved ", path, " ripples=", _ripples.size())
