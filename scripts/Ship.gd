class_name Ship
extends Node3D
## Kaptein Hysj's ship with the big sound jar on deck (docs/SCRIPT.md). It
## glides in during the opening story, anchors in the bay off the Hør og finn
## beach and stays there; Hysj sleeps on deck by the jar. Found sounds fly out
## of the jar back to the island.

const CAPTAIN: PackedScene = preload("res://assets/characters/hysj/PirateCaptain.glb")
const JAR_LETTERS: Array[String] = ["a", "s", "i", "l", "o", "m"]

var jar: Node3D
var hysj: Node3D
var hysj_anim: AnimationPlayer
var asleep: bool = false
var _cork: MeshInstance3D
var _jar_letters: Array[GlowLetter] = []
var _zzz: Array[Label3D] = []
var _t: float = 0.0


func _ready() -> void:
	_build_hull()
	_build_jar()
	_build_captain()


## Global point just above the jar's mouth (where letters go in and out).
func jar_mouth() -> Vector3:
	return jar.global_position + Vector3(0, 2.3 * jar.scale.y, 0)


## Six small sleeping letters inside the glass (after the story).
func fill_jar() -> void:
	clear_jar()
	for l: String in JAR_LETTERS:
		add_jar_letter(l)


## One small letter lands in the glass.
func add_jar_letter(l: String) -> void:
	var k: int = _jar_letters.size()
	var gl: GlowLetter = GlowLetter.new()
	gl.setup(l, 0.42, false)
	gl.idle_motion = false
	jar.add_child(gl)
	gl.position = Vector3(-0.42 + 0.17 * float(k), 0.35 + 0.28 * float(k % 2), 0.1)
	gl.set_base_y(gl.position.y)
	_jar_letters.append(gl)


## A found sound leaves the glass. Returns where its small letter was.
func take_jar_letter(l: String) -> Vector3:
	for gl: GlowLetter in _jar_letters:
		if gl.letter == l and is_instance_valid(gl):
			var at: Vector3 = gl.global_position
			_jar_letters.erase(gl)
			gl.queue_free()
			return at
	return jar_mouth()


func clear_jar() -> void:
	for gl: GlowLetter in _jar_letters:
		if is_instance_valid(gl):
			gl.queue_free()
	_jar_letters.clear()


## The cork hops up and settles (a sound leaves the jar).
func pop_lid() -> void:
	var y0: float = 1.85
	var tw: Tween = create_tween()
	tw.tween_property(_cork, "position:y", y0 + 0.7, 0.18).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	tw.parallel().tween_property(_cork, "rotation:z", 0.5, 0.18)
	tw.tween_property(_cork, "position:y", y0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(
		Tween.EASE_OUT
	)
	tw.parallel().tween_property(_cork, "rotation:z", 0.0, 0.3)


## Hysj crouches down by the jar and snores (floating "z").
func sleep() -> void:
	asleep = true
	clip("Duck")
	if hysj_anim and hysj_anim.current_animation != "":
		# hold the crouched pose
		var a: Animation = hysj_anim.get_animation(hysj_anim.current_animation)
		hysj_anim.seek(a.length * 0.5, true)
		hysj_anim.pause()
	for z: Label3D in _zzz:
		z.visible = true


func wake() -> void:
	asleep = false
	for z: Label3D in _zzz:
		z.visible = false
	clip("Idle")


func clip(part: String) -> void:
	if hysj_anim == null:
		return
	for a: StringName in hysj_anim.get_animation_list():
		if str(a).contains("|" + part + "|") or str(a).ends_with(part):
			hysj_anim.play(a, 0.2)
			if part == "Idle":
				hysj_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
			return


func _process(delta: float) -> void:
	_t += delta
	# gentle rocking at anchor
	rotation.z = sin(_t * 0.9) * 0.025
	if not asleep:
		return
	for k in _zzz.size():
		var z: Label3D = _zzz[k]
		var ph: float = fmod(_t * 0.45 + float(k) / float(_zzz.size()), 1.0)
		z.position = hysj.position + Vector3(0.3 + ph * 0.6, 2.3 + ph * 1.6, 0.2)
		z.modulate.a = sin(ph * PI)
		z.scale = Vector3.ONE * (0.6 + ph * 0.8)


# ---------------------------------------------------------------- build


func _build_hull() -> void:
	var wood: Color = Color(0.62, 0.38, 0.20)
	var parts: Array = [
		[MeshKit.box(Vector3(5.6, 1.3, 2.4)), MeshKit.xf(Vector3(0, 0.65, 0)), wood],
		[
			MeshKit.sphere(1.2, 16, 10),
			MeshKit.xf(Vector3(2.8, 0.75, 0), Vector3(1.6, 0.75, 1.0)),
			wood
		],
		[
			MeshKit.sphere(1.2, 16, 10),
			MeshKit.xf(Vector3(-2.8, 0.85, 0), Vector3(0.7, 0.8, 1.0)),
			wood
		],
		[MeshKit.box(Vector3(5.7, 0.28, 2.5)), MeshKit.xf(Vector3(0, 1.15, 0)), GameTune.HERO_RED],
		[
			MeshKit.cylinder(0.13, 0.16, 6.2, 8),
			MeshKit.xf(Vector3(-0.3, 4.1, 0)),
			wood.darkened(0.25)
		],
		[
			MeshKit.sphere(1.0, 16, 10),
			MeshKit.xf(Vector3(-0.15, 4.2, 0), Vector3(0.22, 1.5, 1.35)),
			Color(0.98, 0.95, 0.86)
		],
		[
			MeshKit.box(Vector3(1.1, 0.7, 0.06)),
			MeshKit.xf(Vector3(0.3, 6.95, 0)),
			Color(0.15, 0.17, 0.3)
		],
		[MeshKit.sphere(0.16, 10, 6), MeshKit.xf(Vector3(0.3, 6.95, 0.06)), Color(1, 1, 1)],
		# anchor chain down into the water at the bow
		[
			MeshKit.cylinder(0.05, 0.05, 1.6, 6),
			MeshKit.xf(Vector3(3.3, 0.2, 0.6), Vector3.ONE, Vector3(0, 0, 25)),
			Color(0.35, 0.36, 0.4)
		],
	]
	for k in 4:  # portholes
		parts.append(
			[
				MeshKit.cylinder(0.18, 0.18, 0.08, 12),
				MeshKit.xf(
					Vector3(-1.8 + 1.2 * float(k), 0.6, 1.22), Vector3.ONE, Vector3(90, 0, 0)
				),
				Color(1.0, 0.9, 0.55)
			]
		)
	MeshKit.instance(MeshKit.merge(parts), MeshKit.with_outline(MeshKit.toon(), 0.003), self)


## The big sound jar on deck: glass with a cork lid.
func _build_jar() -> void:
	jar = Node3D.new()
	add_child(jar)
	jar.position = Vector3(1.7, 1.3, 0.2)
	jar.scale = Vector3.ONE * 1.2
	var glass: StandardMaterial3D = StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.75, 0.9, 1.0, 0.38)
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var body: MeshInstance3D = MeshKit.instance(MeshKit.cylinder(0.8, 0.8, 1.7, 20), glass, jar)
	body.position.y = 0.85
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cork = MeshKit.instance(
		MeshKit.cylinder(0.55, 0.6, 0.35, 16), MeshKit.toon(Color(0.8, 0.62, 0.4), false), jar
	)
	_cork.position.y = 1.85


## Kaptein Hysj (Quaternius Pirate Captain, CC0), no cutlass, by the jar.
func _build_captain() -> void:
	hysj = CAPTAIN.instantiate() as Node3D
	add_child(hysj)
	hysj.position = Vector3(0.1, 1.3, 0.35)
	for n: Node in hysj.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n as MeshInstance3D
		if mi.name.contains("Cutlass"):
			mi.visible = false
			continue
		var src: StandardMaterial3D = mi.mesh.surface_get_material(0) as StandardMaterial3D
		var m: ShaderMaterial = MeshKit.with_outline(
			MeshKit.char_toon(Color(1, 1, 1), false), 0.0028
		)
		if src and src.albedo_texture:
			m.set_shader_parameter("albedo_tex", src.albedo_texture)
		mi.material_override = m
	hysj.scale = Vector3.ONE * GameTune.HYSJ_SCALE
	hysj_anim = hysj.find_child("AnimationPlayer", true, false) as AnimationPlayer
	clip("Idle")
	for k in 3:
		var z: Label3D = Label3D.new()
		z.text = "z"
		z.font = GlowLetter.FONT
		z.font_size = 96
		z.outline_size = 18
		z.modulate = Color(1, 1, 1)
		z.outline_modulate = GameTune.INK
		z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		z.no_depth_test = false
		z.visible = false
		add_child(z)
		_zzz.append(z)
