class_name Beacon
extends Node3D
## A lit station marker: a floating gold gem with a halo. Lit stations are
## the ones the child can tap (GDD 2: choose one of 2-3 lit stations).

const HALO_SHADER: Shader = preload("res://shaders/halo.gdshader")

var station: int = 0
var _gem: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_t = float(station) * 1.7
	var parts: Array = [
		[MeshKit.cylinder(0.0, 0.42, 0.5, 6), MeshKit.xf(Vector3(0, 0.25, 0)), GameTune.GOLD],
		[MeshKit.cylinder(0.42, 0.0, 0.75, 6), MeshKit.xf(Vector3(0, -0.375, 0)), GameTune.GOLD],
	]
	var mat: ShaderMaterial = MeshKit.with_outline(MeshKit.char_toon(), 0.0035)
	mat.set_shader_parameter("emission", Color(0.45, 0.3, 0.0))
	mat.set_shader_parameter("rim_strength", 0.35)
	mat.set_shader_parameter("ramp_edge", 0.0)
	_gem = MeshKit.instance(MeshKit.merge(parts), mat, self)
	var q: QuadMesh = QuadMesh.new()
	q.size = Vector2(2.6, 2.6)
	var hm: ShaderMaterial = ShaderMaterial.new()
	hm.shader = HALO_SHADER
	hm.set_shader_parameter("color", GameTune.GOLD)
	hm.set_shader_parameter("strength", 0.55)
	var halo: MeshInstance3D = MeshKit.instance(q, hm, self)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	_t += delta
	_gem.position.y = sin(_t * 1.6) * 0.18
	_gem.rotation.y += delta * 0.9


func hit(cam: Camera3D, pos: Vector2) -> bool:
	if not visible:
		return false
	var c: Vector2 = cam.unproject_position(global_position)
	var top: Vector2 = cam.unproject_position(global_position + Vector3(0, 1.0, 0))
	return pos.distance_to(c) < maxf(c.distance_to(top) * 1.6, GameTune.TAP_RADIUS_MIN_PX)
