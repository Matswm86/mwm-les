class_name GlowLetter
extends Node3D
## A gold 3D letter (DESIGN 7.3): extruded Andika glyph, ink outline (a flat
## outlined glyph just behind it), additive halo, a few sparkles, idle bob and
## sway. Stands on its local origin.

const LETTER_SHADER: Shader = preload("res://shaders/letter.gdshader")
const HALO_SHADER: Shader = preload("res://shaders/halo.gdshader")
const FONT: FontFile = preload("res://assets/fonts/Andika-Bold.ttf")
const FONT_SIZE: int = 64
const OUTLINE_PX: int = 10

var letter: String = ""
var height_m: float = 1.4
var idle_motion: bool = true
var hint_pulse: bool = false
var _glyph: Node3D
var _body: MeshInstance3D
var _halo: MeshInstance3D
var _mat: ShaderMaterial
var _halo_mat: ShaderMaterial
var _t: float = 0.0
var _base_y: float = 0.0


func setup(text: String, height: float = GameTune.LETTER_HEIGHT_M, with_halo: bool = true) -> void:
	letter = text
	var shown: String = LetterRules.glyph(text)  # the id "aa" shows as å
	height_m = height
	_t = randf() * 10.0
	_glyph = Node3D.new()
	add_child(_glyph)
	var em: float = height_m * 1.25
	var px: float = em / float(FONT_SIZE)
	var tm: TextMesh = TextMesh.new()
	tm.text = shown
	tm.font = FONT
	tm.font_size = FONT_SIZE
	tm.pixel_size = px
	tm.depth = height_m * 0.11
	tm.curve_step = 1.0
	_mat = ShaderMaterial.new()
	_mat.shader = LETTER_SHADER
	_mat.set_shader_parameter("gold", GameTune.GOLD)
	_body = MeshInstance3D.new()
	_body.mesh = tm
	_body.material_override = _mat
	_glyph.add_child(_body)
	var back: Label3D = Label3D.new()
	back.text = shown
	back.font = FONT
	back.font_size = FONT_SIZE
	back.pixel_size = px
	back.modulate = GameTune.INK
	back.outline_modulate = GameTune.INK
	back.outline_size = OUTLINE_PX
	back.shaded = false
	back.double_sided = true
	back.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	back.position = Vector3(0, 0, -tm.depth * 0.5 - 0.01)
	_glyph.add_child(back)
	var aabb: AABB = tm.get_aabb()
	_glyph.position = Vector3(-aabb.get_center().x, -aabb.position.y, 0)
	if with_halo:
		var q: QuadMesh = QuadMesh.new()
		q.size = Vector2.ONE * height_m * 2.1
		_halo_mat = ShaderMaterial.new()
		_halo_mat.shader = HALO_SHADER
		_halo_mat.set_shader_parameter("color", GameTune.GOLD)
		_halo = MeshInstance3D.new()
		_halo.mesh = q
		_halo.material_override = _halo_mat
		_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_halo.position = Vector3(0, height_m * 0.45, -0.25)
		add_child(_halo)
		add_child(_make_sparkles())


func _make_sparkles() -> CPUParticles3D:
	var p: CPUParticles3D = CPUParticles3D.new()
	p.amount = 7
	p.lifetime = 1.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = height_m * 0.5
	p.position = Vector3(0, height_m * 0.5, 0.1)
	p.gravity = Vector3(0, 0.25, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.2
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var q: QuadMesh = QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	var g: GradientTexture2D = GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(1, 1, 0.9, 1))
	grad.set_color(1, Color(1, 0.8, 0.2, 0))
	g.gradient = grad
	g.width = 32
	g.height = 32
	m.albedo_texture = g
	q.material = m
	p.mesh = q
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1, 0.9, 0.4, 0))
	ramp.add_point(0.3, Color(1, 0.95, 0.6, 1))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 0.8, 0.2, 0))
	p.color_ramp = ramp
	return p


func _ready() -> void:
	_base_y = position.y


func set_base_y(y: float) -> void:
	_base_y = y
	position.y = y


func _process(delta: float) -> void:
	_t += delta
	if idle_motion and _glyph:
		var bob: float = sin(_t * TAU * GameTune.LETTER_BOB_HZ) * GameTune.LETTER_BOB_M
		_glyph.position.y = bob + 0.1 - _glyph_floor()
		_glyph.rotation.y = deg_to_rad(GameTune.LETTER_SWAY_DEG) * sin(_t * 0.7)
	if _halo:
		var k: float = 1.0 + 0.05 * sin(_t * TAU * GameTune.HALO_PULSE_HZ)
		if hint_pulse:
			k *= 1.25 + 0.2 * sin(_t * TAU / GameTune.HINT_PULSE_PERIOD_SEC)
		_halo.scale = Vector3.ONE * k
	var pulse: float = 0.0
	if hint_pulse:
		pulse = 0.5 + 0.5 * sin(_t * TAU / GameTune.HINT_PULSE_PERIOD_SEC)
	_mat.set_shader_parameter("pulse", pulse)


func _glyph_floor() -> float:
	var tm: TextMesh = _body.mesh as TextMesh
	return tm.get_aabb().position.y


func center_world() -> Vector3:
	return global_position + Vector3(0, height_m * 0.5, 0)


## Screen-space hit test: within the projected letter size x 0.75 (the 1.5x
## touch collider) or the minimum tap radius, whichever is larger.
func screen_radius(cam: Camera3D) -> float:
	var a: Vector2 = cam.unproject_position(global_position)
	var b: Vector2 = cam.unproject_position(global_position + Vector3(0, height_m, 0))
	return maxf(a.distance_to(b) * 0.75, GameTune.TAP_RADIUS_MIN_PX)


## Height of the visible glyph on screen in px (screenshot bot, size checks).
func glyph_screen_height(cam: Camera3D) -> float:
	var ab: AABB = _body.global_transform * _body.mesh.get_aabb()
	var c: Vector3 = ab.get_center()
	var top: Vector2 = cam.unproject_position(Vector3(c.x, ab.end.y, c.z))
	var bot: Vector2 = cam.unproject_position(Vector3(c.x, ab.position.y, c.z))
	return top.distance_to(bot)


func screen_pos(cam: Camera3D) -> Vector2:
	return cam.unproject_position(center_world())


func pop() -> void:
	var tw: Tween = create_tween()
	(
		tw
		. tween_property(self, "scale", Vector3.ONE * 1.3, 0.25)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_OUT)
	)
	tw.tween_property(self, "scale", Vector3.ONE, 0.3)


func tap_bounce() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.12, 0.1)
	tw.tween_property(self, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)


func wobble() -> void:
	var tw: Tween = create_tween()
	var a: float = deg_to_rad(GameTune.WRONG_WOBBLE_DEG)
	var step: float = GameTune.WRONG_WOBBLE_SEC / 6.0
	for i in 3:
		tw.tween_property(self, "rotation:z", a, step)
		tw.tween_property(self, "rotation:z", -a, step)
	tw.tween_property(self, "rotation:z", 0.0, step)


func rise_from(depth: float, delay: float) -> void:
	position.y = _base_y - depth
	var tw: Tween = create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "position:y", _base_y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)


func sink(depth: float) -> Tween:
	var tw: Tween = create_tween()
	tw.tween_property(self, "position:y", _base_y - depth, 0.5).set_trans(Tween.TRANS_SINE)
	return tw
