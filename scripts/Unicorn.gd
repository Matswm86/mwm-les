class_name Unicorn
extends Node3D
## The meadow's unicorn: the Quaternius White Horse (CC0) with our own gold
## horn and a mane of six colour ribbons (DESIGN, GDD 9: the unicorns get their
## rainbow manes back one colour per sound). Sad = grey ribbons, head low.

const MODEL: PackedScene = preload("res://assets/characters/unicorn/WhiteHorse.glb")
const HEIGHT_M: float = 1.9
const STRIPES: int = 6
const STRIPE_COLORS: Array[Color] = [
	Color(1.00, 0.42, 0.45),
	Color(1.00, 0.66, 0.30),
	Color(1.00, 0.88, 0.32),
	Color(0.48, 0.85, 0.42),
	Color(0.38, 0.70, 1.00),
	Color(1.00, 0.56, 0.75),
]
const GREY: Color = Color(0.80, 0.80, 0.82)
# per glTF surface: Main, Hair, Muzzle, Hooves, Main_Light, Eye_Black, Eye_White
const SURFACE_COLORS: Array[Color] = [
	Color(0.98, 0.97, 1.00),
	Color(1.00, 0.72, 0.85),
	Color(1.00, 0.85, 0.88),
	Color(1.00, 0.80, 0.30),
	Color(0.93, 0.93, 1.00),
	Color(0.08, 0.10, 0.16),
	Color(1.00, 1.00, 1.00),
]

var anim: AnimationPlayer
var stripes: int = 0
var _model: Node3D
var _skel: Skeleton3D
var _ribbon_mats: Array[ShaderMaterial] = []
var _hair_mat: ShaderMaterial
var _body_mats: Array[ShaderMaterial] = []
var _colour: float = 1.0  # 0 = grey and sad, 1 = full colour


func _ready() -> void:
	_model = MODEL.instantiate() as Node3D
	add_child(_model)
	_model.scale = Vector3.ONE * (HEIGHT_M / 4.8)
	_skel = _model.find_child("Skeleton3D", true, false) as Skeleton3D
	var mi: MeshInstance3D = _model.find_child("Horse", true, false) as MeshInstance3D
	for k in mi.mesh.get_surface_count():
		var col: Color = SURFACE_COLORS[mini(k, SURFACE_COLORS.size() - 1)]
		var m: ShaderMaterial = MeshKit.with_outline(MeshKit.char_toon(col, false), 0.0028)
		m.set_shader_parameter("rim_strength", 0.25)
		mi.set_surface_override_material(k, m)
		_body_mats.append(m)
		if k == 1:
			_hair_mat = m
	_add_horn()
	_add_mane()
	anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for clip: StringName in [&"Idle", &"Idle_Headlow", &"Walk", &"Eating"]:
		if anim.has_animation(clip):
			anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	set_stripes(stripes)
	play(&"Idle")


## A part glued to a bone, placed by its position in the rest pose.
func _attach(bone: String, global_rest: Transform3D, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var att: BoneAttachment3D = BoneAttachment3D.new()
	att.bone_name = bone
	_skel.add_child(att)
	var bi: int = _skel.find_bone(bone)
	var bone_rest: Transform3D = _skel.get_bone_global_rest(bi)
	# model space (glTF root, unscaled) -> skeleton space (the armature is x100)
	var rel: Transform3D = Transform3D.IDENTITY
	var n: Node = _skel
	while n != _model and n is Node3D:
		rel = (n as Node3D).transform * rel
		n = n.get_parent()
	var in_skel: Transform3D = rel.affine_inverse() * global_rest
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	att.add_child(part)
	part.transform = bone_rest.affine_inverse() * in_skel
	return part


## Rest pose, model space (horse units: about 4.8 tall, facing +z).
func _add_horn() -> void:
	var horn: CylinderMesh = MeshKit.cylinder(0.0, 0.24, 1.6, 12)
	var mat: ShaderMaterial = MeshKit.with_outline(
		MeshKit.char_toon(GameTune.PIP_HORN, false), 0.003
	)
	mat.set_shader_parameter("emission", Color(0.45, 0.33, 0.05))
	var up: Vector3 = Vector3(0, 0.82, 0.57).normalized()
	var b: Basis = Basis(Quaternion(Vector3.UP, up))
	var base: Vector3 = Vector3(0, 4.42, 2.78)
	_attach("Head", Transform3D(b, base + up * 0.75), horn, mat)


func _add_mane() -> void:
	var a: Vector3 = Vector3(0, 2.95, 1.30)
	var c: Vector3 = Vector3(0, 4.30, 2.30)
	var back: Vector3 = Vector3(0, 0.64, -0.77)
	for k in STRIPES:
		var t: float = float(k) / float(STRIPES - 1)
		var p: Vector3 = a.lerp(c, t) + back * 0.42
		var bone: String = "Neck1" if t < 0.3 else ("Neck2" if t < 0.6 else "Neck3")
		var m: ShaderMaterial = MeshKit.with_outline(MeshKit.char_toon(GREY, false), 0.003)
		var mesh: SphereMesh = MeshKit.sphere(0.36, 12, 8)
		var bs: Basis = (
			Basis.from_euler(Vector3(deg_to_rad(-40.0), 0, 0))
			* Basis.from_scale(Vector3(0.55, 1.3, 0.9))
		)
		_attach(bone, Transform3D(bs, p), mesh, m)
		_ribbon_mats.append(m)


func play(clip: StringName, blend: float = 0.3) -> void:
	if anim and anim.has_animation(clip):
		anim.play(clip, blend)


## How many mane ribbons have their colour (0-6).
func set_stripes(n: int) -> void:
	stripes = clampi(n, 0, STRIPES)
	for k in _ribbon_mats.size():
		var on: bool = k < stripes
		_ribbon_mats[k].set_shader_parameter("albedo", STRIPE_COLORS[k] if on else GREY)
		_ribbon_mats[k].set_shader_parameter(
			"emission", Color(STRIPE_COLORS[k], 1.0) * 0.25 if on else Color(0, 0, 0)
		)
	_apply_colour()


## 0 = grey and sad (head low), 1 = its own colours.
func set_colour(k: float) -> void:
	_colour = clampf(k, 0.0, 1.0)
	_apply_colour()


func _apply_colour() -> void:
	var hair_k: float = _colour * maxf(float(stripes) / float(STRIPES), 0.0)
	for i in _body_mats.size():
		var base: Color = SURFACE_COLORS[mini(i, SURFACE_COLORS.size() - 1)]
		if i == 1:
			_body_mats[i].set_shader_parameter("albedo", GREY.lerp(base, hair_k))
		elif i < 5:
			_body_mats[i].set_shader_parameter("albedo", GREY.lerp(base, _colour))


func sad() -> void:
	play(&"Idle_Headlow", 0.6)


func happy() -> void:
	play(&"Idle", 0.4)


## A new colour ribbon: a little jump, then a happy idle.
func gain_stripe() -> void:
	set_stripes(stripes + 1)
	play(&"Jump_toIdle", 0.2)
	await get_tree().create_timer(1.2).timeout
	happy()
