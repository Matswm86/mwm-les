class_name Hero
extends Node3D
## The KayKit Knight (CC0) as the island hero: weapons and helmet hidden,
## toon material on its own atlas, outline, native clips (Idle, Walking_A, Cheer).

const MODEL: PackedScene = preload("res://assets/characters/knight/Knight.glb")
const HIDE: Array[String] = [
	"1H_Sword_Offhand",
	"Badge_Shield",
	"Rectangle_Shield",
	"Round_Shield",
	"Spike_Shield",
	"1H_Sword",
	"2H_Sword",
	"Knight_Helmet"
]

var anim: AnimationPlayer
var _model: Node3D


func _ready() -> void:
	_model = MODEL.instantiate() as Node3D
	add_child(_model)
	_model.scale = Vector3.ONE * 0.62
	for n: Node in _model.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n as MeshInstance3D
		if HIDE.has(mi.name):
			mi.visible = false
			continue
		var src: StandardMaterial3D = mi.mesh.surface_get_material(0) as StandardMaterial3D
		var m: ShaderMaterial = MeshKit.with_outline(
			MeshKit.char_toon(Color(1, 1, 1), false), 0.0028
		)
		if src and src.albedo_texture:
			m.set_shader_parameter("albedo_tex", src.albedo_texture)
		m.set_shader_parameter("rim_strength", 0.2)
		m.set_shader_parameter("ramp_edge", 0.1)
		mi.material_override = m
	anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_loop(&"Idle")
	_loop(&"Walking_A")
	play(&"Idle")


func _loop(clip: StringName) -> void:
	if anim and anim.has_animation(clip):
		anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR


func play(clip: StringName) -> void:
	if anim and anim.has_animation(clip):
		anim.play(clip, 0.2)


func cheer() -> void:
	play(&"Cheer")
	await anim.animation_finished
	play(&"Idle")


func walk_to(target: Vector3, speed: float = 1.6) -> void:
	var flat: Vector3 = Vector3(target.x, global_position.y, target.z)
	if flat.distance_to(global_position) > 0.05:
		look_at(flat, Vector3.UP, true)
	play(&"Walking_A")
	var tw: Tween = create_tween()
	tw.tween_property(self, "global_position", target, global_position.distance_to(target) / speed)
	await tw.finished
	play(&"Idle")


func face(point: Vector3) -> void:
	var flat: Vector3 = Vector3(point.x, global_position.y, point.z)
	if flat.distance_to(global_position) > 0.05:
		look_at(flat, Vector3.UP, true)
