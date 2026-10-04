class_name Stone
extends Node3D
## A letter stone for Ordbroa: a rounded pebble with a gold letter on top.
## Becomes a wooden plank when it lands in the right slot.

var letter: String = ""
var skill: String = ""
var home: Vector3
var placed: bool = false
var glyph: GlowLetter
var _pebble: MeshInstance3D


func setup(p_letter: String, p_skill: String) -> void:
	letter = p_letter
	skill = p_skill
	var mat: ShaderMaterial = MeshKit.with_outline(
		MeshKit.char_toon(Color(0.86, 0.82, 0.76), false), 0.0035
	)
	mat.set_shader_parameter("rim_strength", 0.2)
	_pebble = MeshKit.instance(MeshKit.sphere(0.5, 16, 10), mat, self)
	_pebble.scale = Vector3(1.25, 0.5, 1.05)
	_pebble.position.y = 0.2
	glyph = GlowLetter.new()
	glyph.setup(p_letter, 1.2, false)
	glyph.idle_motion = false
	glyph.position = Vector3(0, 0.35, 0.1)
	add_child(glyph)


func screen_pos(cam: Camera3D) -> Vector2:
	return cam.unproject_position(global_position + Vector3(0, 0.6, 0))


func screen_radius(cam: Camera3D) -> float:
	var a: Vector2 = cam.unproject_position(global_position)
	var b: Vector2 = cam.unproject_position(global_position + Vector3(0, 1.2, 0))
	return maxf(a.distance_to(b) * 0.75, GameTune.TAP_RADIUS_MIN_PX)


func slide_home() -> Tween:
	var tw: Tween = create_tween()
	tw.tween_property(self, "global_position", home, 0.4).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	return tw


func wobble() -> Tween:
	var tw: Tween = create_tween()
	var a: float = deg_to_rad(GameTune.WRONG_WOBBLE_DEG)
	var step: float = GameTune.WRONG_WOBBLE_SEC / 6.0
	for i in 3:
		tw.tween_property(self, "rotation:z", a, step)
		tw.tween_property(self, "rotation:z", -a, step)
	tw.tween_property(self, "rotation:z", 0.0, step)
	return tw


## `width` is the plank's length along the bridge in the stone's own units.
func become_plank(width: float = 1.0) -> void:
	placed = true
	var wood: ShaderMaterial = MeshKit.toon(GameTune.WOOD_LIGHT, false)
	var plank: MeshInstance3D = MeshKit.instance(MeshKit.box(Vector3(width, 0.16, 1.5)), wood, self)
	plank.position.y = 0.05
	plank.scale = Vector3(0.2, 1, 0.2)
	(
		create_tween()
		. tween_property(plank, "scale", Vector3.ONE, 0.3)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	var tw: Tween = create_tween()
	tw.tween_property(_pebble, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
	tw.tween_callback(_pebble.hide)
	glyph.position = Vector3(0, 0.12, 0.25)
