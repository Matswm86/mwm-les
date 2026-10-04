class_name SleepyFlower
extends Node3D
## The big flower at the listening beach (story for Hør og finn): asleep it
## hangs its head, its grey petals droop and its eyes are shut; wake() lifts
## the head, the petals spring open in colour and the eyes open.

const PETALS: int = 7
const PETAL_COLOR: Color = Color(1.00, 0.56, 0.75)
const BUD_COLOR: Color = Color(0.78, 0.78, 0.80)

var awake: bool = false
var _pivots: Array[Node3D] = []
var _petal_mat: ShaderMaterial
var _eyes_closed: MeshInstance3D
var _eyes_open: MeshInstance3D
var _head: Node3D
var _t: float = 0.0


func _ready() -> void:
	var stem: Array = [
		[MeshKit.cylinder(0.07, 0.1, 1.6, 8), MeshKit.xf(Vector3(0, 0.8, 0)), GameTune.LEAF_DARK],
		[
			MeshKit.sphere(0.4, 10, 6),
			MeshKit.xf(Vector3(0.32, 0.55, 0), Vector3(1.0, 0.18, 0.5), Vector3(0, 0, 25)),
			GameTune.LEAF
		],
		[
			MeshKit.sphere(0.4, 10, 6),
			MeshKit.xf(Vector3(-0.32, 0.8, 0), Vector3(1.0, 0.18, 0.5), Vector3(0, 0, -25)),
			GameTune.LEAF
		],
	]
	MeshKit.instance(MeshKit.merge(stem), MeshKit.with_outline(MeshKit.char_toon(), 0.003), self)
	_head = Node3D.new()
	_head.position = Vector3(0, 1.75, 0)
	add_child(_head)
	_petal_mat = MeshKit.with_outline(MeshKit.char_toon(BUD_COLOR, false), 0.003)
	var petal: SphereMesh = MeshKit.sphere(0.32, 12, 8)
	for k in PETALS:
		var pv: Node3D = Node3D.new()
		pv.rotation.z = TAU * float(k) / float(PETALS)
		_head.add_child(pv)
		var arm: Node3D = Node3D.new()
		pv.add_child(arm)
		var mi: MeshInstance3D = MeshKit.instance(petal, _petal_mat, arm)
		mi.position = Vector3(0, 0.42, 0)
		mi.scale = Vector3(0.75, 1.25, 0.35)
		arm.rotation.x = deg_to_rad(-55.0)  # asleep: petals droop backwards
		_pivots.append(arm)
	var face: Array = [
		[
			MeshKit.sphere(0.3, 14, 10),
			MeshKit.xf(Vector3.ZERO, Vector3(1, 1, 0.5)),
			Color(1, 0.86, 0.3)
		]
	]
	MeshKit.instance(MeshKit.merge(face), MeshKit.with_outline(MeshKit.char_toon(), 0.003), _head)
	var closed: Array = []
	var opened: Array = []
	for x: float in [-0.11, 0.11]:
		closed.append(
			[
				MeshKit.sphere(0.06, 8, 5),
				MeshKit.xf(Vector3(x, 0.03, 0.15), Vector3(1, 0.3, 0.5)),
				GameTune.EYE
			]
		)
		opened.append(
			[MeshKit.sphere(0.055, 8, 5), MeshKit.xf(Vector3(x, 0.04, 0.15)), GameTune.EYE]
		)
	opened.append(
		[
			MeshKit.sphere(0.07, 8, 5),
			MeshKit.xf(Vector3(0, -0.1, 0.15), Vector3(1.2, 0.5, 0.5)),
			Color(0.8, 0.3, 0.2)
		]
	)
	_eyes_closed = MeshKit.instance(MeshKit.merge(closed), MeshKit.char_toon(), _head)
	_eyes_open = MeshKit.instance(MeshKit.merge(opened), MeshKit.char_toon(), _head)
	_eyes_open.visible = false
	_head.rotation.x = deg_to_rad(28.0)  # asleep: head hangs forward


func _process(delta: float) -> void:
	_t += delta
	var sway: float = 0.06 if awake else 0.025
	_head.rotation.z = sin(_t * (1.4 if awake else 0.6)) * sway
	if not awake:
		_head.position.y = 1.75 + sin(_t * 0.8) * 0.03  # slow sleepy breathing


func sleep_now() -> void:
	awake = false
	_petal_mat.set_shader_parameter("albedo", BUD_COLOR)
	for arm: Node3D in _pivots:
		arm.rotation.x = deg_to_rad(-55.0)
	_head.rotation.x = deg_to_rad(28.0)
	_eyes_closed.visible = true
	_eyes_open.visible = false


func wake() -> void:
	awake = true
	_eyes_closed.visible = false
	_eyes_open.visible = true
	var tw: Tween = create_tween().set_parallel(true)
	for arm: Node3D in _pivots:
		(
			tw
			. tween_property(arm, "rotation:x", deg_to_rad(10.0), 0.9)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
	tw.tween_method(
		func(k: float) -> void:
			_petal_mat.set_shader_parameter("albedo", BUD_COLOR.lerp(PETAL_COLOR, k)),
		0.0,
		1.0,
		0.9
	)
	create_tween().tween_property(_head, "rotation:x", 0.0, 0.5).set_trans(Tween.TRANS_BACK)
	var pop: Tween = create_tween()
	pop.tween_property(_head, "scale", Vector3.ONE * 1.25, 0.25)
	pop.tween_property(_head, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC)
