class_name Pip
extends Node3D
## Pip the narwhal, built from primitives into one vertex-coloured mesh
## (placeholder until a modelled Pip exists). Floats at a spot in the lower
## left of the camera view, bobs, and can fly over to point at something.

var cam: Camera3D
var home_offset: Vector3 = GameTune.PIP_SCREEN_OFFSET  # camera-local resting spot
var rise: float = 0.0  # extra height, tweened by pop_up()
var _body: Node3D
var _horn_mat: ShaderMaterial
var _t: float = 0.0
var _target: Vector3 = Vector3.ZERO
var _pointing: bool = false
var _spin: float = 0.0


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var mat: ShaderMaterial = MeshKit.with_outline(MeshKit.char_toon(), 0.004)
	mat.set_shader_parameter("rim_strength", 0.25)
	MeshKit.instance(_build_mesh(), mat, _body)
	var horn: CylinderMesh = MeshKit.cylinder(0.0, 0.075, 0.85, 10)
	_horn_mat = MeshKit.with_outline(MeshKit.char_toon(GameTune.PIP_HORN, false), 0.004)
	_horn_mat.set_shader_parameter("emission", Color(0.35, 0.28, 0.08))
	var hi: MeshInstance3D = MeshKit.instance(horn, _horn_mat, _body)
	var dir: Vector3 = Vector3(1.0, 0.8, 0.0).normalized()
	hi.position = Vector3(0.6, 0.22, 0.0) + dir * 0.4
	hi.rotation = Vector3(0, 0, -atan2(dir.x, dir.y))
	scale = Vector3.ONE * 0.58


func _build_mesh() -> ArrayMesh:
	var p: Array = []
	p.append(
		[
			MeshKit.sphere(0.5, 20, 12),
			MeshKit.xf(Vector3.ZERO, Vector3(1.45, 1.0, 1.05)),
			GameTune.PIP_BACK
		]
	)
	p.append(
		[
			MeshKit.sphere(0.46, 20, 12),
			MeshKit.xf(Vector3(0.08, -0.14, 0.08), Vector3(1.3, 0.78, 0.98)),
			GameTune.PIP_BELLY
		]
	)
	for z: float in [0.33, -0.33]:
		var e: Vector3 = Vector3(0.5, 0.12, z)
		p.append([MeshKit.sphere(0.095, 12, 8), MeshKit.xf(e), GameTune.EYE])
		p.append(
			[
				MeshKit.sphere(0.032, 8, 6),
				MeshKit.xf(e + Vector3(0.04, 0.04, 0.07 if z > 0.0 else -0.07)),
				Color(1, 1, 1)
			]
		)
		p.append(
			[
				MeshKit.sphere(0.075, 10, 6),
				MeshKit.xf(Vector3(0.52, -0.06, z * 1.12), Vector3(1.0, 0.55, 0.5)),
				GameTune.PIP_CHEEK
			]
		)
		p.append(
			[
				MeshKit.sphere(0.3, 12, 6),
				MeshKit.xf(
					Vector3(0.1, -0.28, z * 1.45), Vector3(0.75, 0.18, 0.45), Vector3(0, 0, -25)
				),
				GameTune.PIP_BACK
			]
		)
	p.append(
		[
			MeshKit.sphere(0.28, 12, 8),
			MeshKit.xf(Vector3(-0.72, 0.06, 0), Vector3(1.3, 0.65, 0.7)),
			GameTune.PIP_BACK
		]
	)
	for z2: float in [0.22, -0.22]:
		p.append(
			[
				MeshKit.sphere(0.25, 12, 6),
				MeshKit.xf(
					Vector3(-1.0, 0.14, z2),
					Vector3(0.75, 0.16, 1.0),
					Vector3(0, 35.0 if z2 > 0.0 else -35.0, 0)
				),
				GameTune.PIP_SPOT
			]
		)
	for sp: Vector3 in [
		Vector3(-0.2, 0.43, 0.12), Vector3(0.1, 0.46, -0.08), Vector3(-0.42, 0.36, -0.14)
	]:
		p.append(
			[MeshKit.sphere(0.07, 8, 5), MeshKit.xf(sp, Vector3(1.0, 0.35, 1.0)), GameTune.PIP_SPOT]
		)
	return MeshKit.merge(p)


func _process(delta: float) -> void:
	_t += delta
	if cam == null:
		return
	var home: Vector3 = cam.global_transform * home_offset
	var goal: Vector3 = _target if _pointing else home
	var k: float = 1.0 - exp(-GameTune.PIP_FOLLOW_RATE * delta)
	global_position = global_position.lerp(goal, k)
	var bob: float = sin(_t * TAU * GameTune.PIP_BOB_HZ) * GameTune.PIP_BOB_HEIGHT
	_body.position.y = bob + rise
	var face: Basis = Basis.looking_at(-cam.global_basis.z, Vector3.UP)
	global_basis = (
		face * Basis.from_euler(Vector3(0, deg_to_rad(-55.0), 0)) * Basis.from_scale(scale)
	)
	_spin = maxf(0.0, _spin - delta * 2.0)
	_body.rotation = Vector3(sin(_t * 1.3) * 0.06, _spin * TAU, sin(_t * 0.9) * 0.08)


func snap_home() -> void:
	if cam:
		global_position = cam.global_transform * home_offset


## Swim to an exact spot and stay there (hub guide, story).
func guide_to(world_pos: Vector3) -> void:
	_target = world_pos
	_pointing = true
	_set_horn_glow(true)


## Pop out of the water at the current spot (story).
func pop_up() -> void:
	rise = -1.6
	var tw: Tween = create_tween()
	tw.tween_property(self, "rise", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	giggle()


func point_at(world_pos: Vector3) -> void:
	_target = world_pos + Vector3(-1.2, 1.4, 0.6)
	_pointing = true
	_set_horn_glow(true)


func go_home() -> void:
	_pointing = false
	_set_horn_glow(false)


func giggle() -> void:
	_spin = 1.0


func _set_horn_glow(on: bool) -> void:
	_horn_mat.set_shader_parameter(
		"emission", Color(0.9, 0.7, 0.2) if on else Color(0.35, 0.28, 0.08)
	)


func screen_pos() -> Vector2:
	return cam.unproject_position(global_position + Vector3(0, 0.2, 0))


func hit(pos: Vector2) -> bool:
	return cam != null and pos.distance_to(screen_pos()) < 170.0
