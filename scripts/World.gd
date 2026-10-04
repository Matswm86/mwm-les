class_name World
extends Node3D
## Builds Enhjørningenga (World 1 island) procedurally: sea, sky, island,
## islet, foam, trees, flowers, clouds, bridge frame. Owns the colour zones.

signal zone_restored(index: int)

const SEA_SHADER: Shader = preload("res://shaders/sea.gdshader")
const FOAM_SHADER: Shader = preload("res://shaders/foam.gdshader")
const CLOUD_SHADER: Shader = preload("res://shaders/cloud.gdshader")
const ZONE_GLOBALS: Array[StringName] = [&"zone_a", &"zone_b", &"zone_c"]
const MAIN_HILLS: Array = [
	Vector4(-3.5, -4.0, 3.2, 4.2), Vector4(2.5, -6.0, 2.0, 3.4), Vector4(-6.5, 1.0, 1.1, 3.0)
]
const ISLET_HILLS: Array = [Vector4(0.6, -0.8, 0.5, 1.6)]

var zone_centers: Array[Vector3] = []
var zone_amount: Array[float] = [0.0, 0.0, 0.0]
var bridge_start: Vector3
var bridge_end: Vector3
var islet_picture_spot: Vector3
var unicorn_spot: Vector3
var ship_anchor: Vector3  # Hysj's ship in the bay off the Hør og finn beach
var ship_yaw: float = 0.0  # radians; the hull lies along the coast
var thing_spots: Dictionary = {}  # sound label -> where its found thing appears
var write_patch: Vector3
var knight_spot: Vector3
var sun: DirectionalLight3D
var _flowers: Array[MultiMeshInstance3D] = []
var _flower_xforms: Array = []  # per zone: Array[Transform3D]
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _sky_mat: ProceduralSkyMaterial
var _sea_mat: ShaderMaterial
var _foam_mats: Array[ShaderMaterial] = []
var _cloud_mat: ShaderMaterial
var _env: Environment


func _ready() -> void:
	_rng.seed = 20261003
	_build_environment()
	_build_sea()
	_layout()
	_build_island_meshes()
	_build_trees()
	_build_flowers()
	_build_clouds()
	_build_distant_islands()
	_build_bridge_frame()
	for i in 3:
		_set_zone(0.0, i)
	RenderingServer.global_shader_parameter_set(&"world_color", 0.0)


# ---------------------------------------------------------------- shape


static func coast(theta: float, radius: float) -> float:
	var k: float = radius / GameTune.ISLAND_RADIUS
	return (
		radius
		+ k * (0.9 * sin(2.0 * theta + 0.7) + 0.6 * sin(3.0 * theta + 2.1))
		+ k * 0.35 * sin(5.0 * theta + 0.4)
	)


## Height of an island at a local offset (x, z) from its centre.
static func island_height(x: float, z: float, radius: float, hills: Array) -> float:
	var r: float = sqrt(x * x + z * z)
	var theta: float = atan2(z, x)
	var rn: float = r / coast(theta, radius)
	if rn >= 1.0:
		return -0.25 - (rn - 1.0) * 7.0
	var h: float = lerpf(-0.25, 0.32, smoothstep(1.0, 0.88, rn))
	h += 0.7 * smoothstep(0.80, 0.71, rn)
	var inland: float = smoothstep(0.78, 0.5, rn)
	for hill: Vector4 in hills:
		var dx: float = x - hill.x
		var dz: float = z - hill.y
		h += hill.z * exp(-(dx * dx + dz * dz) / (hill.w * hill.w)) * inland
	h += 0.07 * sin(x * 1.3) * sin(z * 1.1) * inland
	return h


func ground_y(p: Vector3) -> float:
	var li: Vector3 = p - GameTune.ISLET_CENTER
	if Vector2(li.x, li.z).length() < GameTune.ISLET_RADIUS * 1.3:
		return maxf(island_height(li.x, li.z, GameTune.ISLET_RADIUS, ISLET_HILLS), 0.0)
	return maxf(island_height(p.x, p.z, GameTune.ISLAND_RADIUS, MAIN_HILLS), 0.0)


func on_ground(x: float, z: float) -> Vector3:
	var p: Vector3 = Vector3(x, 0.0, z)
	p.y = ground_y(p)
	return p


func station_point(angle_deg: float, inset: float = GameTune.STATION_INSET) -> Vector3:
	var t: float = deg_to_rad(angle_deg)
	var r: float = coast(t, GameTune.ISLAND_RADIUS) * inset
	return on_ground(cos(t) * r, sin(t) * r)


func _layout() -> void:
	zone_centers = [
		station_point(GameTune.ZONE_A_ANGLE),
		station_point(GameTune.ZONE_B_ANGLE, 0.84),
		station_point(GameTune.ZONE_C_ANGLE, 0.80),
	]
	write_patch = station_point(GameTune.ZONE_B_ANGLE, 0.86)
	var to_islet: Vector3 = GameTune.ISLET_CENTER - Vector3.ZERO
	to_islet.y = 0.0
	var dir: Vector3 = to_islet.normalized()
	var theta: float = atan2(dir.z, dir.x)
	var main_edge: float = coast(theta, GameTune.ISLAND_RADIUS)
	bridge_start = dir * (main_edge * 0.97)
	var islet_edge: float = coast(theta + PI, GameTune.ISLET_RADIUS)
	bridge_end = GameTune.ISLET_CENTER - dir * (islet_edge * 0.93)
	bridge_start.y = 0.35
	bridge_end.y = 0.35
	islet_picture_spot = GameTune.ISLET_CENTER + Vector3(0.3, 2.6, -0.4)
	unicorn_spot = station_point(GameTune.UNICORN_ANGLE, GameTune.UNICORN_INSET)
	var ts: float = deg_to_rad(GameTune.SHIP_ANGLE_DEG)
	var out: Vector3 = Vector3(cos(ts), 0, sin(ts))
	var along: Vector3 = Vector3(-sin(ts), 0, cos(ts))
	ship_anchor = out * (coast(ts, GameTune.ISLAND_RADIUS) + GameTune.SHIP_OFFSHORE_M)
	# the hull lies along the coast, its deck side (+z) toward the island
	ship_yaw = atan2(-along.z, along.x)
	for l: String in GameTune.THING_SPOTS:
		var spot: Vector3 = GameTune.THING_SPOTS[l]
		if l == "l":  # the lamb stands on the little island
			thing_spots[l] = on_ground(
				GameTune.ISLET_CENTER.x + spot.x, GameTune.ISLET_CENTER.z + spot.z
			)
		elif l == "s":  # the sun rises over the sea, ahead of the Hør og finn view
			var y: float = deg_to_rad(GameTune.FIND_CAM_YAW_DEG)
			var ahead: Vector3 = Vector3(-sin(y), 0, -cos(y))
			var right: Vector3 = Vector3(cos(y), 0, -sin(y))
			thing_spots[l] = (
				Vector3(zone_centers[0].x, spot.y, zone_centers[0].z)
				+ ahead * spot.x
				+ right * spot.z
			)
		else:
			var p: Vector3 = station_point(spot.x, spot.y)
			p.y += spot.z
			thing_spots[l] = p
	knight_spot = on_ground(bridge_start.x - dir.x * 1.6 - 1.4, bridge_start.z - 1.6)


# ---------------------------------------------------------------- environment


## 0 = day, 1 = sunset (end of session): warm sky, low warm sun.
func set_sunset(k: float) -> void:
	_sky_mat.sky_top_color = GameTune.SKY_TOP.lerp(Color(0.98, 0.62, 0.55), k)
	_sky_mat.sky_horizon_color = GameTune.SKY_HORIZON.lerp(Color(1.0, 0.82, 0.55), k)
	_sky_mat.ground_horizon_color = _sky_mat.sky_horizon_color
	sun.light_color = Color(1.0, 0.97, 0.9).lerp(Color(1.0, 0.68, 0.42), k)
	sun.rotation_degrees.x = lerpf(GameTune.SUN_PITCH_DEG, -20.0, k)
	_env.ambient_light_color = GameTune.SKY_HORIZON.lerp(Color(1.0, 0.75, 0.6), k)


## 0 = day, 1 = night (the opening story): deep blue sky, moonlight.
func set_night(k: float) -> void:
	_sky_mat.sky_top_color = GameTune.SKY_TOP.lerp(Color(0.05, 0.08, 0.22), k)
	_sky_mat.sky_horizon_color = GameTune.SKY_HORIZON.lerp(Color(0.20, 0.27, 0.50), k)
	_sky_mat.ground_horizon_color = _sky_mat.sky_horizon_color
	sun.light_color = Color(1.0, 0.97, 0.9).lerp(Color(0.55, 0.65, 1.0), k)
	sun.light_energy = lerpf(GameTune.SUN_ENERGY, 0.22, k)
	_env.ambient_light_color = GameTune.SKY_HORIZON.lerp(Color(0.22, 0.28, 0.55), k)
	_env.ambient_light_energy = lerpf(GameTune.AMBIENT_ENERGY, 0.2, k)
	# the sea and the foam are unlit shaders: blue-shift and darken them directly
	_sea_mat.set_shader_parameter("deep", GameTune.SEA_DEEP.lerp(Color(0.03, 0.07, 0.20), k))
	_sea_mat.set_shader_parameter("shallow", GameTune.SEA_SHALLOW.lerp(Color(0.07, 0.16, 0.34), k))
	_sea_mat.set_shader_parameter("foam", GameTune.FOAM.lerp(Color(0.32, 0.40, 0.62), k))
	_sea_mat.set_shader_parameter("horizon", GameTune.SKY_HORIZON.lerp(Color(0.12, 0.17, 0.38), k))
	_cloud_mat.set_shader_parameter("top", GameTune.FOAM.lerp(Color(0.30, 0.36, 0.58), k))
	_cloud_mat.set_shader_parameter(
		"under", Color(0.74, 0.85, 0.96).lerp(Color(0.16, 0.20, 0.40), k)
	)
	for fm: ShaderMaterial in _foam_mats:
		fm.set_shader_parameter("foam", GameTune.FOAM.lerp(Color(0.32, 0.40, 0.62), k))


## Whole-island colour for the story: 1 = every zone in colour, 0 = grey.
func set_colour_all(k: float) -> void:
	for i in 3:
		set_zone_now(i, k)


func _build_environment() -> void:
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	_sky_mat = sky_mat
	sky_mat.sky_top_color = GameTune.SKY_TOP
	sky_mat.sky_horizon_color = GameTune.SKY_HORIZON
	sky_mat.ground_bottom_color = GameTune.SEA_DEEP
	sky_mat.ground_horizon_color = GameTune.SKY_HORIZON
	sky_mat.sky_curve = 0.12
	sky_mat.sun_angle_max = 0.0
	sky_mat.sky_energy_multiplier = 1.0
	var sky: Sky = Sky.new()
	sky.sky_material = sky_mat
	var env: Environment = Environment.new()
	_env = env
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = GameTune.SKY_HORIZON
	env.ambient_light_energy = GameTune.AMBIENT_ENERGY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	env.ssao_enabled = false
	env.fog_enabled = false
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(GameTune.SUN_PITCH_DEG, GameTune.SUN_YAW_DEG, 0.0)
	sun.light_energy = GameTune.SUN_ENERGY
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = GameTune.SHADOW_MAX_DISTANCE
	sun.shadow_blur = 0.0
	sun.shadow_bias = 0.15
	sun.shadow_normal_bias = 3.5
	add_child(sun)


func _build_sea() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(420, 420)
	plane.subdivide_width = 48
	plane.subdivide_depth = 48
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = SEA_SHADER
	m.set_shader_parameter("deep", GameTune.SEA_DEEP)
	m.set_shader_parameter("shallow", GameTune.SEA_SHALLOW)
	m.set_shader_parameter("foam", GameTune.FOAM)
	m.set_shader_parameter("horizon", GameTune.SKY_HORIZON)
	var isl: PackedVector4Array = PackedVector4Array(
		[
			Vector4(0, 0, GameTune.ISLAND_RADIUS, 0),
			Vector4(GameTune.ISLET_CENTER.x, GameTune.ISLET_CENTER.z, GameTune.ISLET_RADIUS, 0),
			Vector4(0, 0, 0, 0),
		]
	)
	m.set_shader_parameter("islands", isl)
	_sea_mat = m
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


# ---------------------------------------------------------------- islands


func _build_island_meshes() -> void:
	_add_island(Vector3.ZERO, GameTune.ISLAND_RADIUS, MAIN_HILLS, 46, 120, true)
	_add_island(GameTune.ISLET_CENTER, GameTune.ISLET_RADIUS, ISLET_HILLS, 14, 48, true)


func _add_island(
	center: Vector3, radius: float, hills: Array, rings: int, segs: int, zoned: bool
) -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var max_rn: float = 1.16
	var grid: Array = []
	for ri in rings + 1:
		var t: float = float(ri) / float(rings)
		var rn: float = max_rn * pow(t, 0.75)
		var row: Array = []
		for si in segs:
			var theta: float = TAU * float(si) / float(segs)
			var r: float = rn * coast(theta, radius)
			var x: float = cos(theta) * r
			var z: float = sin(theta) * r
			row.append(Vector3(x, island_height(x, z, radius, hills), z))
		grid.append(row)
	var idx: int = 0
	var index_of: Dictionary = {}
	for ri in rings + 1:
		for si in segs:
			var p: Vector3 = grid[ri][si]
			var n: Vector3 = _normal_at(p.x, p.z, radius, hills)
			st.set_normal(n)
			st.set_color(_ground_color(p, n, radius))
			st.add_vertex(p + center)
			index_of[Vector2i(ri, si)] = idx
			idx += 1
	for ri in rings:
		for si in segs:
			var s2: int = (si + 1) % segs
			var a: int = index_of[Vector2i(ri, si)]
			var b: int = index_of[Vector2i(ri, s2)]
			var c: int = index_of[Vector2i(ri + 1, si)]
			var d: int = index_of[Vector2i(ri + 1, s2)]
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c)
			st.add_index(d)
	var mesh: ArrayMesh = st.commit()
	var mat: ShaderMaterial = (
		MeshKit.world_toon(Color(1, 1, 1), true) if zoned else MeshKit.toon(Color(1, 1, 1), true)
	)
	mat.set_shader_parameter("ramp_edge", 0.12)
	var ground: MeshInstance3D = MeshKit.instance(mesh, mat, self)
	# terrain receives tree/prop shadows but casts none: self-shadow on gentle
	# slopes made stair-step acne, and the toon band already shades the hills
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_foam_ring(center, radius)


func _normal_at(x: float, z: float, radius: float, hills: Array) -> Vector3:
	var e: float = 0.15
	var hx: float = island_height(x + e, z, radius, hills) - island_height(x - e, z, radius, hills)
	var hz: float = island_height(x, z + e, radius, hills) - island_height(x, z - e, radius, hills)
	return Vector3(-hx, 2.0 * e, -hz).normalized()


func _ground_color(p: Vector3, n: Vector3, radius: float) -> Color:
	if p.y < 0.5:
		var wet: float = clampf(-p.y * 3.0, 0.0, 1.0)
		return GameTune.SAND.lerp(GameTune.SAND_WET, wet)
	if n.y < 0.62:
		return GameTune.ROCK
	var patch: float = 0.5 + 0.5 * sin(p.x * 0.55 + 1.3) * sin(p.z * 0.7 - 0.4)
	var g: Color = GameTune.GRASS.lerp(GameTune.GRASS.lightened(0.12), patch * 0.6)
	if radius < 5.0:
		g = g.lerp(GameTune.UNICORN_PINK, 0.0)
	return g


func _add_foam_ring(center: Vector3, radius: float) -> void:
	var segs: int = 96
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner: float = 0.97
	var outer: float = 1.0 + 2.2 / radius
	for si in segs + 1:
		var u: float = float(si) / float(segs)
		var theta: float = TAU * u
		var c: float = coast(theta, radius)
		var dir: Vector3 = Vector3(cos(theta), 0.0, sin(theta))
		st.set_uv(Vector2(u, 0.0))
		st.set_normal(Vector3.UP)
		st.add_vertex(center + dir * c * inner + Vector3(0, 0.1, 0))
		st.set_uv(Vector2(u, 1.0))
		st.set_normal(Vector3.UP)
		st.add_vertex(center + dir * c * outer + Vector3(0, 0.1, 0))
	for si in segs:
		var a: int = si * 2
		st.add_index(a)
		st.add_index(a + 2)
		st.add_index(a + 1)
		st.add_index(a + 1)
		st.add_index(a + 2)
		st.add_index(a + 3)
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = FOAM_SHADER
	m.set_shader_parameter("foam", GameTune.FOAM)
	_foam_mats.append(m)
	var mi: MeshInstance3D = MeshKit.instance(st.commit(), m, self)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ---------------------------------------------------------------- props


static func round_tree(
	parts: Array, base: Vector3, size: float, rng: RandomNumberGenerator
) -> void:
	var trunk_h: float = 1.3 * size
	parts.append(
		[
			MeshKit.cylinder(0.13 * size, 0.22 * size, trunk_h, 8),
			MeshKit.xf(base + Vector3(0, trunk_h * 0.5, 0)),
			GameTune.WOOD
		]
	)
	var top: Vector3 = base + Vector3(0, trunk_h + 0.55 * size, 0)
	var blobs: Array = [
		[Vector3(0, 0.25, 0), 1.0],
		[Vector3(0.55, -0.1, 0.2), 0.72],
		[Vector3(-0.5, -0.05, -0.15), 0.75],
		[Vector3(0.05, -0.15, 0.55), 0.68]
	]
	for b: Array in blobs:
		var col: Color = GameTune.LEAF.lerp(GameTune.LEAF_DARK, rng.randf() * 0.5)
		parts.append(
			[
				MeshKit.sphere(float(b[1]) * size, 12, 8),
				MeshKit.xf(top + (b[0] as Vector3) * size),
				col
			]
		)


static func palm_tree(parts: Array, base: Vector3, size: float, lean: Vector3) -> void:
	var p: Vector3 = base
	var segs: int = 6
	for i in segs:
		var t: float = float(i) / float(segs)
		var seg_h: float = 0.42 * size
		var c: Vector3 = p + Vector3(0, seg_h * 0.5, 0) + lean * (t * t) * size * 0.4
		parts.append(
			[
				MeshKit.cylinder(0.12 * size, 0.15 * size, seg_h * 1.05, 8),
				MeshKit.xf(c, Vector3.ONE, Vector3(lean.z * 12.0 * t, 0, -lean.x * 12.0 * t)),
				GameTune.WOOD_LIGHT if i % 2 == 0 else GameTune.WOOD
			]
		)
		p = c + Vector3(0, seg_h * 0.5, 0)
	for k in 7:
		var yaw: float = float(k) * 360.0 / 7.0
		var leaf_dir: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0, sin(deg_to_rad(yaw)))
		parts.append(
			[
				MeshKit.sphere(0.5, 10, 6),
				MeshKit.xf(
					p + leaf_dir * 0.75 * size + Vector3(0, -0.1 * size, 0),
					Vector3(1.6, 0.16, 0.42) * size,
					Vector3(0, -yaw, -22.0)
				),
				GameTune.LEAF if k % 2 == 0 else GameTune.LEAF_DARK
			]
		)
	parts.append(
		[
			MeshKit.sphere(0.14 * size, 8, 6),
			MeshKit.xf(p + Vector3(0.12, -0.15, 0.1) * size),
			GameTune.WOOD
		]
	)


static func rock(parts: Array, base: Vector3, size: float, rng: RandomNumberGenerator) -> void:
	parts.append(
		[
			MeshKit.sphere(0.5, 7, 4),
			MeshKit.xf(
				base,
				Vector3(1.3, 0.75, 1.0) * size,
				Vector3(rng.randf_range(-10, 10), rng.randf_range(0, 360), 0)
			),
			GameTune.ROCK.lerp(Color(0.7, 0.66, 0.6), rng.randf() * 0.5)
		]
	)


func _far_from_stations(p: Vector3, min_d: float) -> bool:
	for c: Vector3 in zone_centers:
		if Vector2(p.x - c.x, p.z - c.z).length() < min_d:
			return false
	if Vector2(p.x - bridge_start.x, p.z - bridge_start.z).length() < 4.5:
		return false
	if Vector2(p.x - unicorn_spot.x, p.z - unicorn_spot.z).length() < 3.0:
		return false
	return true


func _build_trees() -> void:
	var parts: Array = []
	var placed: int = 0
	var tries: int = 0
	while placed < 16 and tries < 400:
		tries += 1
		var a: float = _rng.randf() * TAU
		var rn: float = sqrt(_rng.randf()) * 0.62
		var r: float = rn * coast(a, GameTune.ISLAND_RADIUS)
		var p: Vector3 = on_ground(cos(a) * r, sin(a) * r)
		if p.z > 3.0 and absf(p.x) < 6.0:
			continue  # keep the middle foreground clear
		if not _far_from_stations(p, 4.0):
			continue
		round_tree(parts, p, _rng.randf_range(0.85, 1.25), _rng)
		placed += 1
	for a_deg: float in [150.0, 196.0, 228.0, 300.0, 330.0]:
		var t: float = deg_to_rad(a_deg)
		var r2: float = coast(t, GameTune.ISLAND_RADIUS) * 0.8
		var p2: Vector3 = on_ground(cos(t) * r2, sin(t) * r2)
		if _far_from_stations(p2, 3.5):
			palm_tree(parts, p2, 1.0, Vector3(cos(t), 0, sin(t)))
	for k in 14:
		var a3: float = _rng.randf() * TAU
		var r3: float = coast(a3, GameTune.ISLAND_RADIUS) * _rng.randf_range(0.72, 0.9)
		var p3: Vector3 = on_ground(cos(a3) * r3, sin(a3) * r3)
		if _far_from_stations(p3, 3.0):
			rock(parts, p3, _rng.randf_range(0.5, 1.1), _rng)
	# islet: two palms and a rock
	palm_tree(parts, GameTune.ISLET_CENTER + Vector3(1.3, 0.55, -1.2), 0.9, Vector3(0.5, 0, -0.6))
	rock(parts, GameTune.ISLET_CENTER + Vector3(-1.0, 0.3, 1.4), 0.7, _rng)
	var mesh: ArrayMesh = MeshKit.merge(parts)
	MeshKit.instance(mesh, MeshKit.world_toon(), self)


func _build_flowers() -> void:
	var flower_parts: Array = []
	for k in 5:
		var a: float = TAU * float(k) / 5.0
		flower_parts.append(
			[
				MeshKit.sphere(0.09, 8, 5),
				MeshKit.xf(Vector3(cos(a) * 0.1, 0.2, sin(a) * 0.1), Vector3(1, 0.5, 1)),
				Color(1, 1, 1)
			]
		)
	flower_parts.append(
		[MeshKit.sphere(0.07, 8, 5), MeshKit.xf(Vector3(0, 0.22, 0)), Color(1.0, 0.85, 0.3)]
	)
	flower_parts.append(
		[MeshKit.cylinder(0.02, 0.02, 0.2, 4), MeshKit.xf(Vector3(0, 0.1, 0)), GameTune.LEAF_DARK]
	)
	var flower_mesh: ArrayMesh = MeshKit.merge(flower_parts)
	for zi in 3:
		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = flower_mesh
		var xforms: Array[Transform3D] = []
		var c: Vector3 = zone_centers[zi]
		var tries: int = 0
		while xforms.size() < 26 and tries < 600:
			tries += 1
			var off: Vector2 = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * 7.0
			var p: Vector3 = on_ground(c.x + off.x, c.z + off.y)
			if p.y < 0.36 or Vector2(off.x, off.y).length() < 2.5:
				continue
			var t: Transform3D = MeshKit.xf(
				p, Vector3.ONE * _rng.randf_range(1.3, 1.9), Vector3(0, _rng.randf() * 360.0, 0)
			)
			xforms.append(t)
		mm.instance_count = xforms.size()
		for i in xforms.size():
			mm.set_instance_transform(i, xforms[i].scaled_local(Vector3.ONE * 0.001))
			mm.set_instance_color(
				i, GameTune.FLOWER_COLORS[_rng.randi() % GameTune.FLOWER_COLORS.size()]
			)
		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = MeshKit.toon()
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_flowers.append(mmi)
		_flower_xforms.append(xforms)


func _build_clouds() -> void:
	var parts: Array = []
	var spots: Array = [
		Vector3(-60, 13, -125),
		Vector3(-15, 16, -150),
		Vector3(35, 12, -130),
		Vector3(85, 15, -120),
		Vector3(-105, 11, -100),
		Vector3(125, 10, -95),
		Vector3(5, 20, -180),
		Vector3(60, 22, -185),
	]
	for s: Vector3 in spots:
		var size: float = _rng.randf_range(5.0, 9.0)
		for k in 5:
			var off: Vector3 = Vector3(float(k) - 2.0, 0, 0) * size * 0.55
			off.y = (1.0 - absf(float(k) - 2.0) * 0.45) * size * 0.35
			off.z = _rng.randf_range(-1, 1) * size * 0.2
			var r: float = size * (0.62 - absf(float(k) - 2.0) * 0.1)
			parts.append(
				[
					MeshKit.sphere(r, 14, 8),
					MeshKit.xf(s + off, Vector3(1, 0.8, 0.8)),
					Color(1, 1, 1)
				]
			)
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = CLOUD_SHADER
	m.set_shader_parameter("top", GameTune.FOAM)
	_cloud_mat = m
	var mi: MeshInstance3D = MeshKit.instance(MeshKit.merge(parts), m, self)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_distant_islands() -> void:
	var spots: Array = [[Vector3(-62, 0, -88), 9.0], [Vector3(66, 0, -96), 6.5]]
	for s: Array in spots:
		var c: Vector3 = s[0]
		var r: float = s[1]
		_add_island(c, r, [Vector4(0, 0, r * 0.35, r * 0.5)], 10, 40, false)
		var parts: Array = []
		for k in 4:
			var a: float = float(k) * 1.6
			var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * r * 0.35
			p.y = island_height(p.x - c.x, p.z - c.z, r, [Vector4(0, 0, r * 0.35, r * 0.5)])
			round_tree(parts, p, 1.6, _rng)
		MeshKit.instance(MeshKit.merge(parts), MeshKit.toon(), self)


func _build_bridge_frame() -> void:
	var parts: Array = []
	var dir: Vector3 = (bridge_end - bridge_start).normalized()
	var side: Vector3 = Vector3(-dir.z, 0, dir.x)
	for end: Vector3 in [bridge_start, bridge_end]:
		for s: float in [-1.0, 1.0]:
			var p: Vector3 = end + side * s * 0.8
			p.y = 0.2
			parts.append(
				[
					MeshKit.cylinder(0.11, 0.13, 1.8, 8),
					MeshKit.xf(p + Vector3(0, 0.5, 0)),
					GameTune.WOOD
				]
			)
			parts.append(
				[
					MeshKit.sphere(0.15, 8, 6),
					MeshKit.xf(p + Vector3(0, 1.42, 0)),
					GameTune.WOOD_LIGHT
				]
			)
	var length: float = bridge_start.distance_to(bridge_end)
	var mid: Vector3 = (bridge_start + bridge_end) * 0.5
	var yaw: float = rad_to_deg(atan2(-dir.z, dir.x))
	# one rope rail on the far side only: a near rail would cross the letters
	for s: float in [1.0 if side.z < 0.0 else -1.0]:
		var rp: Vector3 = mid + side * s * 0.8 + Vector3(0, 0.95, 0)
		parts.append(
			[
				MeshKit.cylinder(0.035, 0.035, length, 6),
				MeshKit.xf(rp, Vector3.ONE, Vector3(0, yaw, 90)),
				Color(0.86, 0.74, 0.52)
			]
		)
	MeshKit.instance(MeshKit.merge(parts), MeshKit.world_toon(), self)


# ---------------------------------------------------------------- zones


func restore_zone(index: int) -> void:
	if zone_amount[index] >= 1.0:
		return
	var tw: Tween = create_tween()
	tw.tween_method(_set_zone.bind(index), zone_amount[index], 1.0, GameTune.ZONE_RESTORE_SEC)
	tw.set_trans(Tween.TRANS_SINE)
	_grow_flowers(index)
	var restored: int = 0
	for a: float in zone_amount:
		if a > 0.0:
			restored += 1
	restored += 1
	var wc: float = clampf(float(restored) / 3.0, 0.0, 1.0)
	var tw2: Tween = create_tween()
	tw2.tween_method(
		func(v: float) -> void: RenderingServer.global_shader_parameter_set(&"world_color", v),
		float(restored - 1) / 3.0,
		wc,
		GameTune.ZONE_RESTORE_SEC
	)
	tw.finished.connect(func() -> void: zone_restored.emit(index))


func set_zone_now(index: int, amount: float) -> void:
	_set_zone(amount, index)
	var mm: MultiMesh = _flowers[index].multimesh
	var xforms: Array = _flower_xforms[index]
	for i in xforms.size():
		var t: Transform3D = xforms[i]
		mm.set_instance_transform(i, t if amount > 0.5 else t.scaled_local(Vector3.ONE * 0.001))
	var restored: float = 0.0
	for a: float in zone_amount:
		restored += a
	RenderingServer.global_shader_parameter_set(&"world_color", restored / 3.0)


func _set_zone(amount: float, index: int) -> void:
	zone_amount[index] = amount
	var c: Vector3 = zone_centers[index]
	RenderingServer.global_shader_parameter_set(
		ZONE_GLOBALS[index], Vector4(c.x, GameTune.ZONE_RADIUS, c.z, amount)
	)


func _grow_flowers(index: int) -> void:
	var mm: MultiMesh = _flowers[index].multimesh
	var xforms: Array = _flower_xforms[index]
	for i in xforms.size():
		var t: Transform3D = xforms[i]
		var tw: Tween = create_tween()
		tw.tween_interval(GameTune.PLANT_STAGGER_SEC * float(i))
		(
			tw
			. tween_method(
				func(k: float) -> void:
					mm.set_instance_transform(i, t.scaled_local(Vector3.ONE * maxf(k, 0.001))),
				0.0,
				1.0,
				0.5
			)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
