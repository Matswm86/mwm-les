class_name Props
extends RefCounted
## Word pictures built from primitives in the cel-shaded look, one merged mesh
## + outline each, about 2 m tall, standing on their local origin:
## sun (sol), ice cream (is), lamb (lam), llama (lama), slime (slim),
## glue bottle (lim), salami (salami), and the things a found sound brings
## back in Hør og finn (docs/SCRIPT.md 2d): monkey in a palm (ape), cheese
## (ost), mouse by a rock (mus); the bridge word pictures seal (sel), boat
## (båt), a bowl of hay (mat) and an open book (les). Placeholder primitives
## (docs/ASSETS.md).


static func make(kind: String) -> Node3D:
	match kind:
		"sun":
			return _sun()
		"lamb":
			return _lamb()
		"ice":
			return _ice_cream()
		"llama":
			return _llama()
		"slime":
			return _slime()
		"glue":
			return _glue()
		"salami":
			return _salami()
		"monkey":
			return _monkey()
		"cheese":
			return _cheese()
		"mouse":
			return _mouse()
		"seal":
			return _seal()
		"boat":
			return _boat()
		"food":
			return _food()
		"book":
			return _book()
	return null


## Two dot eyes with a shine and pink cheeks on a face looking +z at `c`.
static func _face(p: Array, c: Vector3, spread: float, size: float) -> void:
	for x: float in [-spread, spread]:
		p.append([MeshKit.sphere(size, 10, 6), MeshKit.xf(c + Vector3(x, 0, 0)), GameTune.EYE])
		p.append(
			[
				MeshKit.sphere(size * 0.35, 8, 5),
				MeshKit.xf(c + Vector3(x + size * 0.3, size * 0.35, size * 0.8)),
				Color(1, 1, 1)
			]
		)
		p.append(
			[
				MeshKit.sphere(size * 1.1, 10, 6),
				MeshKit.xf(c + Vector3(x * 1.5, -size * 1.6, -size * 0.2), Vector3(1, 0.55, 0.4)),
				GameTune.PIP_CHEEK
			]
		)


static func _finish(p: Array) -> Node3D:
	var root: Node3D = Node3D.new()
	var mat: ShaderMaterial = MeshKit.with_outline(MeshKit.char_toon(), 0.0035)
	mat.set_shader_parameter("rim_strength", 0.2)
	MeshKit.instance(MeshKit.merge(p), mat, root)
	return root


static func _ice_cream() -> Node3D:
	var p: Array = []
	var cone: Color = Color(0.93, 0.68, 0.36)
	p.append([MeshKit.cylinder(0.5, 0.06, 1.2, 14), MeshKit.xf(Vector3(0, 0.6, 0)), cone])
	for k in 3:  # waffle bands
		p.append(
			[
				MeshKit.cylinder(0.43 - 0.13 * k, 0.4 - 0.13 * k, 0.05, 14),
				MeshKit.xf(Vector3(0, 1.0 - 0.3 * k, 0)),
				cone.darkened(0.2)
			]
		)
	var scoops: Array = [
		[Vector3(0, 1.45, 0), Color(1.0, 0.72, 0.82)],
		[Vector3(0, 2.0, 0), Color(1.0, 0.95, 0.80)],
	]
	for sc: Array in scoops:
		p.append([MeshKit.sphere(0.55, 16, 10), MeshKit.xf(sc[0], Vector3(1, 0.85, 1)), sc[1]])
	p.append([MeshKit.sphere(0.13, 10, 6), MeshKit.xf(Vector3(0, 2.55, 0)), Color(0.9, 0.15, 0.2)])
	_face(p, Vector3(0, 1.5, 0.5), 0.17, 0.07)
	return _finish(p)


static func _llama() -> Node3D:
	var p: Array = []
	var wool: Color = Color(0.98, 0.93, 0.82)
	var dark: Color = Color(0.45, 0.33, 0.25)
	p.append(
		[
			MeshKit.sphere(0.55, 14, 10),
			MeshKit.xf(Vector3(0, 0.95, 0), Vector3(1.0, 0.75, 1.5)),
			wool
		]
	)
	p.append(
		[
			MeshKit.cylinder(0.2, 0.26, 1.1, 12),
			MeshKit.xf(Vector3(0, 1.6, 0.55), Vector3.ONE, Vector3(12, 0, 0)),
			wool
		]
	)
	p.append(
		[MeshKit.sphere(0.28, 14, 10), MeshKit.xf(Vector3(0, 2.2, 0.7), Vector3(1, 1, 1.15)), wool]
	)
	p.append(
		[
			MeshKit.sphere(0.16, 10, 6),
			MeshKit.xf(Vector3(0, 2.1, 0.95), Vector3(1, 0.8, 1)),
			Color(1, 0.86, 0.78)
		]
	)
	for x: float in [-0.15, 0.15]:
		p.append(
			[
				MeshKit.cylinder(0.02, 0.07, 0.35, 8),
				MeshKit.xf(Vector3(x, 2.5, 0.62), Vector3.ONE, Vector3(-10, 0, x * 60.0)),
				wool
			]
		)
	for leg: Vector3 in [
		Vector3(0.28, 0.4, 0.5),
		Vector3(-0.28, 0.4, 0.5),
		Vector3(0.28, 0.4, -0.5),
		Vector3(-0.28, 0.4, -0.5)
	]:
		p.append([MeshKit.cylinder(0.1, 0.1, 0.8, 8), MeshKit.xf(leg), wool])
		p.append(
			[MeshKit.cylinder(0.11, 0.11, 0.1, 8), MeshKit.xf(leg - Vector3(0, 0.38, 0)), dark]
		)
	# a pink saddle blanket with a stripe
	p.append(
		[
			MeshKit.box(Vector3(0.95, 0.12, 0.8)),
			MeshKit.xf(Vector3(0, 1.38, 0)),
			GameTune.UNICORN_PINK
		]
	)
	p.append(
		[
			MeshKit.box(Vector3(0.97, 0.13, 0.15)),
			MeshKit.xf(Vector3(0, 1.38, 0)),
			Color(1, 0.85, 0.3)
		]
	)
	_face(p, Vector3(0, 2.3, 0.97), 0.12, 0.05)
	return _finish(p)


static func _slime() -> Node3D:
	var p: Array = []
	var green: Color = Color(0.45, 0.88, 0.40)
	p.append(
		[
			MeshKit.sphere(0.85, 18, 12),
			MeshKit.xf(Vector3(0, 0.6, 0), Vector3(1.2, 0.75, 1.0)),
			green
		]
	)
	p.append([MeshKit.sphere(0.45, 14, 10), MeshKit.xf(Vector3(0.1, 1.15, 0.05)), green])
	for d: Vector3 in [Vector3(-0.85, 0.15, 0.4), Vector3(0.95, 0.12, 0.2), Vector3(0.3, 0.1, 0.8)]:
		p.append([MeshKit.sphere(0.24, 10, 6), MeshKit.xf(d, Vector3(1, 0.5, 1)), green])
	p.append(
		[MeshKit.sphere(0.14, 10, 6), MeshKit.xf(Vector3(-0.4, 1.0, 0.55)), Color(0.8, 1.0, 0.75)]
	)
	_face(p, Vector3(0, 0.85, 0.82), 0.25, 0.09)
	return _finish(p)


static func _glue() -> Node3D:
	var p: Array = []
	var white: Color = Color(0.97, 0.97, 0.95)
	p.append([MeshKit.cylinder(0.42, 0.45, 1.5, 16), MeshKit.xf(Vector3(0, 0.75, 0)), white])
	p.append(
		[
			MeshKit.cylinder(0.43, 0.46, 0.7, 16),
			MeshKit.xf(Vector3(0, 0.75, 0)),
			Color(0.35, 0.62, 0.95)
		]
	)
	p.append([MeshKit.cylinder(0.25, 0.42, 0.3, 16), MeshKit.xf(Vector3(0, 1.62, 0)), white])
	p.append(
		[
			MeshKit.cylinder(0.04, 0.16, 0.55, 12),
			MeshKit.xf(Vector3(0, 2.02, 0)),
			Color(1.0, 0.55, 0.15)
		]
	)
	p.append(
		[MeshKit.sphere(0.1, 10, 6), MeshKit.xf(Vector3(0.0, 2.38, 0), Vector3(1, 1.4, 1)), white]
	)
	_face(p, Vector3(0, 0.8, 0.45), 0.15, 0.065)
	return _finish(p)


static func _salami() -> Node3D:
	var p: Array = []
	var red: Color = Color(0.78, 0.22, 0.22)
	var fat: Color = Color(1.0, 0.88, 0.85)
	p.append(
		[
			MeshKit.cylinder(0.42, 0.42, 1.9, 18),
			MeshKit.xf(Vector3(0, 0.55, 0), Vector3.ONE, Vector3(0, 0, 90)),
			red
		]
	)
	for x: float in [-0.95, 0.95]:
		p.append(
			[
				MeshKit.sphere(0.42, 16, 10),
				MeshKit.xf(Vector3(x, 0.55, 0), Vector3(0.45, 1, 1)),
				red
			]
		)
	p.append(
		[
			MeshKit.cylinder(0.05, 0.05, 0.3, 6),
			MeshKit.xf(Vector3(1.2, 0.6, 0), Vector3.ONE, Vector3(0, 0, 90)),
			Color(0.8, 0.7, 0.5)
		]
	)
	for d: Vector3 in [
		Vector3(-0.5, 0.85, 0.3),
		Vector3(0.45, 0.3, 0.35),
		Vector3(-0.2, 0.25, 0.38),
		Vector3(0.6, 0.8, 0.28)
	]:
		p.append([MeshKit.sphere(0.07, 8, 5), MeshKit.xf(d), fat])
	# one round slice leaning on the front
	p.append(
		[
			MeshKit.cylinder(0.38, 0.38, 0.1, 18),
			MeshKit.xf(Vector3(1.55, 0.4, 0.3), Vector3.ONE, Vector3(70, 0, -10)),
			Color(0.9, 0.35, 0.35)
		]
	)
	_face(p, Vector3(-0.1, 0.62, 0.43), 0.17, 0.065)
	return _finish(p)


static func _sun() -> Node3D:
	var root: Node3D = Node3D.new()
	var p: Array = []
	var gold: Color = Color(1.0, 0.78, 0.16)
	var orange: Color = Color(1.0, 0.55, 0.12)
	p.append([MeshKit.sphere(0.85, 24, 14), MeshKit.xf(Vector3.ZERO, Vector3(1, 1, 0.7)), gold])
	for k in 10:
		var a: float = TAU * float(k) / 10.0
		var d: Vector3 = Vector3(cos(a), sin(a), 0)
		p.append(
			[
				MeshKit.cylinder(0.0, 0.22, 0.55, 8),
				MeshKit.xf(d * 1.18, Vector3.ONE, Vector3(0, 0, rad_to_deg(a) - 90.0)),
				orange
			]
		)
	for x: float in [-0.3, 0.3]:
		p.append([MeshKit.sphere(0.1, 10, 6), MeshKit.xf(Vector3(x, 0.18, 0.56)), GameTune.EYE])
		p.append(
			[
				MeshKit.sphere(0.11, 10, 6),
				MeshKit.xf(Vector3(x * 1.6, -0.12, 0.5), Vector3(1, 0.6, 0.4)),
				GameTune.PIP_CHEEK
			]
		)
	p.append(
		[
			MeshKit.sphere(0.16, 10, 6),
			MeshKit.xf(Vector3(0, -0.2, 0.55), Vector3(1.2, 0.45, 0.4)),
			Color(0.75, 0.3, 0.12)
		]
	)
	var mat: ShaderMaterial = MeshKit.with_outline(MeshKit.char_toon(), 0.0035)
	mat.set_shader_parameter("emission", Color(0.35, 0.22, 0.0))
	MeshKit.instance(MeshKit.merge(p), mat, root)
	return root


static func _lamb() -> Node3D:
	var root: Node3D = Node3D.new()
	var p: Array = []
	var wool: Color = Color(0.99, 0.98, 0.95)
	var face: Color = Color(0.32, 0.30, 0.34)
	var blobs: Array = [
		Vector3(0, 0.75, 0),
		Vector3(0.35, 0.8, 0.1),
		Vector3(-0.35, 0.78, -0.05),
		Vector3(0.1, 1.0, -0.1),
		Vector3(-0.15, 0.95, 0.2),
		Vector3(0.0, 0.7, 0.3)
	]
	for b: Vector3 in blobs:
		p.append([MeshKit.sphere(0.36, 12, 8), MeshKit.xf(b), wool])
	p.append(
		[
			MeshKit.sphere(0.26, 12, 8),
			MeshKit.xf(Vector3(0.62, 0.95, 0.18), Vector3(1.0, 1.1, 0.9)),
			face
		]
	)
	p.append([MeshKit.sphere(0.18, 10, 6), MeshKit.xf(Vector3(0.55, 1.17, 0.18)), wool])
	for z: float in [-0.12, 0.3]:
		p.append(
			[
				MeshKit.sphere(0.1, 8, 5),
				MeshKit.xf(
					Vector3(0.6, 1.05, z + 0.08 * (1.0 if z > 0.0 else -1.0)),
					Vector3(0.6, 0.3, 1.4)
				),
				face
			]
		)
	p.append([MeshKit.sphere(0.05, 8, 5), MeshKit.xf(Vector3(0.82, 1.0, 0.3)), Color(1, 1, 1)])
	for leg: Vector3 in [
		Vector3(0.25, 0.25, 0.2),
		Vector3(-0.25, 0.25, 0.2),
		Vector3(0.25, 0.25, -0.2),
		Vector3(-0.25, 0.25, -0.2)
	]:
		p.append([MeshKit.cylinder(0.07, 0.07, 0.5, 6), MeshKit.xf(leg), face])
	MeshKit.instance(MeshKit.merge(p), MeshKit.with_outline(MeshKit.char_toon(), 0.0035), root)
	return root


## A small palm with a brown monkey hugging the trunk, face to +z.
static func _monkey() -> Node3D:
	var p: Array = []
	World.palm_tree(p, Vector3(0, 0, -0.25), 1.0, Vector3(0.2, 0, -0.1))
	var fur: Color = Color(0.48, 0.30, 0.17)
	var skin: Color = Color(0.93, 0.76, 0.58)
	var c: Vector3 = Vector3(0.0, 1.45, 0.05)
	p.append([MeshKit.sphere(0.32, 14, 10), MeshKit.xf(c, Vector3(0.9, 1.15, 0.8)), fur])
	p.append(
		[
			MeshKit.sphere(0.22, 12, 8),
			MeshKit.xf(c + Vector3(0, 0, 0.18), Vector3(0.8, 0.9, 0.5)),
			skin
		]
	)
	var h: Vector3 = c + Vector3(0, 0.55, 0.06)
	p.append([MeshKit.sphere(0.28, 14, 10), MeshKit.xf(h), fur])
	p.append(
		[
			MeshKit.sphere(0.2, 12, 8),
			MeshKit.xf(h + Vector3(0, -0.05, 0.16), Vector3(1.1, 0.85, 0.6)),
			skin
		]
	)
	for x: float in [-0.3, 0.3]:
		p.append([MeshKit.sphere(0.11, 10, 6), MeshKit.xf(h + Vector3(x, 0.04, 0)), skin])
		# arms and legs round the trunk
		p.append(
			[
				MeshKit.cylinder(0.06, 0.07, 0.5, 6),
				MeshKit.xf(c + Vector3(x * 0.9, 0.2, -0.12), Vector3.ONE, Vector3(70, 0, 0)),
				fur
			]
		)
		p.append(
			[
				MeshKit.cylinder(0.07, 0.08, 0.45, 6),
				MeshKit.xf(c + Vector3(x * 0.85, -0.3, -0.1), Vector3.ONE, Vector3(65, 0, 0)),
				fur
			]
		)
	p.append(
		[
			MeshKit.cylinder(0.04, 0.05, 0.7, 6),
			MeshKit.xf(c + Vector3(0.3, -0.45, 0.1), Vector3.ONE, Vector3(0, 0, -50)),
			fur
		]
	)
	_face(p, h + Vector3(0, 0.03, 0.27), 0.08, 0.045)
	return _finish(p)


## A big block of cheese with holes on the front and top, and a face.
static func _cheese() -> Node3D:
	var p: Array = []
	var gold: Color = Color(1.0, 0.84, 0.32)
	var hole: Color = Color(0.86, 0.62, 0.16)
	p.append([MeshKit.box(Vector3(1.7, 1.0, 1.1)), MeshKit.xf(Vector3(0, 0.5, 0)), gold])
	for h: Vector3 in [
		Vector3(-0.55, 0.25, 0.55),
		Vector3(0.6, 0.72, 0.55),
		Vector3(0.62, 0.22, 0.55),
		Vector3(-0.68, 0.78, 0.55)
	]:
		p.append([MeshKit.sphere(0.13, 12, 8), MeshKit.xf(h, Vector3(1, 1, 0.25)), hole])
	for h2: Vector3 in [
		Vector3(-0.3, 1.0, -0.2), Vector3(0.45, 1.0, 0.15), Vector3(0.05, 1.0, -0.35)
	]:
		p.append([MeshKit.sphere(0.15, 12, 8), MeshKit.xf(h2, Vector3(1, 0.2, 1)), hole])
	_face(p, Vector3(0.0, 0.55, 0.56), 0.2, 0.08)
	return _finish(p)


## A grey mouse peeking out beside a rock.
static func _mouse() -> Node3D:
	var p: Array = []
	var grey: Color = Color(0.66, 0.64, 0.68)
	var pink: Color = Color(1.0, 0.68, 0.74)
	p.append(
		[
			MeshKit.sphere(0.7, 12, 8),
			MeshKit.xf(Vector3(-0.55, 0.45, -0.2), Vector3(1.2, 0.85, 1.0)),
			GameTune.ROCK
		]
	)
	p.append(
		[
			MeshKit.sphere(0.32, 14, 10),
			MeshKit.xf(Vector3(0.25, 0.3, 0.1), Vector3(1.0, 0.85, 1.2)),
			grey
		]
	)
	var h: Vector3 = Vector3(0.3, 0.62, 0.3)
	p.append([MeshKit.sphere(0.22, 14, 10), MeshKit.xf(h, Vector3(1.0, 0.95, 1.1)), grey])
	p.append([MeshKit.sphere(0.06, 8, 5), MeshKit.xf(h + Vector3(0, -0.04, 0.24)), pink])
	for x: float in [-0.18, 0.18]:
		p.append(
			[
				MeshKit.sphere(0.15, 12, 8),
				MeshKit.xf(h + Vector3(x, 0.2, -0.02), Vector3(1, 1, 0.35)),
				grey
			]
		)
		p.append(
			[
				MeshKit.sphere(0.1, 10, 6),
				MeshKit.xf(h + Vector3(x, 0.2, 0.02), Vector3(1, 1, 0.3)),
				pink
			]
		)
	p.append(
		[
			MeshKit.cylinder(0.025, 0.03, 0.6, 6),
			MeshKit.xf(Vector3(0.5, 0.15, -0.15), Vector3.ONE, Vector3(0, 30, 70)),
			pink
		]
	)
	_face(p, h + Vector3(0, 0.05, 0.19), 0.08, 0.035)
	return _finish(p)


## A grey seal in the water: body and head up, flippers, whiskers; faces +z.
## Its origin is the waterline, the lower body is under water.
static func _seal() -> Node3D:
	var p: Array = []
	var grey: Color = Color(0.52, 0.56, 0.62)
	var belly: Color = Color(0.74, 0.76, 0.78)
	var dark: Color = Color(0.30, 0.33, 0.38)
	p.append(
		[
			MeshKit.sphere(0.55, 16, 10),
			MeshKit.xf(Vector3(0, 0.05, -0.35), Vector3(0.9, 0.7, 1.5)),
			grey
		]
	)
	p.append(
		[
			MeshKit.sphere(0.42, 16, 10),
			MeshKit.xf(Vector3(0, 0.45, 0.25), Vector3(0.95, 1.2, 0.95)),
			grey
		]
	)
	p.append(
		[
			MeshKit.sphere(0.3, 14, 8),
			MeshKit.xf(Vector3(0, 0.3, 0.5), Vector3(0.9, 1.1, 0.6)),
			belly
		]
	)
	var h: Vector3 = Vector3(0, 1.0, 0.35)
	p.append([MeshKit.sphere(0.34, 16, 10), MeshKit.xf(h), grey])
	p.append([MeshKit.sphere(0.17, 12, 8), MeshKit.xf(h + Vector3(0, -0.08, 0.27)), belly])
	p.append([MeshKit.sphere(0.06, 8, 5), MeshKit.xf(h + Vector3(0, -0.02, 0.42)), dark])
	for x: float in [-1.0, 1.0]:
		p.append(
			[
				MeshKit.sphere(0.2, 10, 6),
				MeshKit.xf(
					Vector3(x * 0.45, 0.2, 0.35), Vector3(0.5, 0.25, 1.0), Vector3(0, 0, x * 35)
				),
				dark
			]
		)
		for k in 2:
			p.append(
				[
					MeshKit.cylinder(0.01, 0.01, 0.28, 4),
					MeshKit.xf(
						h + Vector3(x * 0.16, -0.08 + 0.05 * float(k), 0.37),
						Vector3.ONE,
						Vector3(0, 0, x * (80.0 + 12.0 * float(k)))
					),
					dark
				]
			)
	_face(p, h + Vector3(0, 0.1, 0.27), 0.13, 0.055)
	return _finish(p)


## A small rowing boat with a red stripe and a mast with a white sail, the
## hull along x. Its origin is the waterline.
static func _boat() -> Node3D:
	var p: Array = []
	var hull: Color = Color(0.85, 0.35, 0.25)
	var stripe: Color = Color(0.98, 0.96, 0.9)
	p.append(
		[
			MeshKit.sphere(1.0, 20, 10),
			MeshKit.xf(Vector3(0, 0.05, 0), Vector3(1.6, 0.45, 0.62)),
			hull
		]
	)
	p.append(
		[
			MeshKit.box(Vector3(2.9, 0.12, 1.05)),
			MeshKit.xf(Vector3(0, 0.42, 0)),
			GameTune.WOOD_LIGHT
		]
	)
	p.append(
		[
			MeshKit.sphere(1.0, 20, 6),
			MeshKit.xf(Vector3(0, 0.34, 0), Vector3(1.62, 0.08, 0.64)),
			stripe
		]
	)
	p.append(
		[MeshKit.cylinder(0.05, 0.06, 2.2, 8), MeshKit.xf(Vector3(0.1, 1.5, 0)), GameTune.WOOD]
	)
	p.append(
		[
			MeshKit.box(Vector3(1.1, 1.5, 0.04)),
			MeshKit.xf(Vector3(-0.5, 1.55, 0), Vector3.ONE, Vector3(0, 0, -4)),
			stripe
		]
	)
	p.append(
		[
			MeshKit.box(Vector3(0.5, 0.28, 0.04)),
			MeshKit.xf(Vector3(0.38, 2.5, 0)),
			Color(0.95, 0.3, 0.3)
		]
	)
	return _finish(p)


## Food for the lamb: a wooden bowl heaped with hay and a carrot or two.
static func _food() -> Node3D:
	var p: Array = []
	var hay: Color = Color(0.93, 0.80, 0.38)
	var hay_dark: Color = Color(0.82, 0.66, 0.26)
	var carrot: Color = Color(1.0, 0.52, 0.12)
	p.append(
		[MeshKit.cylinder(0.75, 0.55, 0.45, 20), MeshKit.xf(Vector3(0, 0.23, 0)), GameTune.WOOD]
	)
	p.append(
		[
			MeshKit.cylinder(0.78, 0.78, 0.08, 20),
			MeshKit.xf(Vector3(0, 0.46, 0)),
			GameTune.WOOD_LIGHT
		]
	)
	p.append([MeshKit.sphere(0.7, 16, 8), MeshKit.xf(Vector3(0, 0.5, 0), Vector3(1, 0.55, 1)), hay])
	for k in 7:
		var a: float = TAU * float(k) / 7.0
		p.append(
			[
				MeshKit.cylinder(0.02, 0.03, 0.6, 4),
				MeshKit.xf(
					Vector3(cos(a) * 0.35, 0.78, sin(a) * 0.35),
					Vector3.ONE,
					Vector3(rad_to_deg(sin(a)) * 0.6, 0, rad_to_deg(cos(a)) * 0.6)
				),
				hay_dark
			]
		)
	for c: Vector3 in [Vector3(0.25, 0.85, 0.3), Vector3(-0.3, 0.82, 0.15)]:
		p.append(
			[
				MeshKit.cylinder(0.0, 0.08, 0.5, 8),
				MeshKit.xf(c, Vector3.ONE, Vector3(70, 0, 20)),
				carrot
			]
		)
	return _finish(p)


## An open picture book standing a little tilted toward the camera (+z).
static func _book() -> Node3D:
	var p: Array = []
	var cover: Color = Color(0.20, 0.50, 0.80)
	var page: Color = Color(0.99, 0.97, 0.90)
	var ink: Color = Color(0.35, 0.40, 0.50)
	for x: float in [-1.0, 1.0]:
		p.append(
			[
				MeshKit.box(Vector3(0.75, 0.05, 1.0)),
				MeshKit.xf(Vector3(x * 0.38, 0.0, 0), Vector3.ONE, Vector3(0, 0, -x * 8)),
				cover
			]
		)
		p.append(
			[
				MeshKit.box(Vector3(0.68, 0.06, 0.92)),
				MeshKit.xf(Vector3(x * 0.36, 0.05, 0), Vector3.ONE, Vector3(0, 0, -x * 8)),
				page
			]
		)
		for k in 3:
			p.append(
				[
					MeshKit.box(Vector3(0.48, 0.02, 0.05)),
					MeshKit.xf(Vector3(x * 0.37, 0.09 + 0.03, -0.25 + 0.2 * float(k))),
					ink
				]
			)
	p.append(
		[
			MeshKit.sphere(0.12, 10, 6),
			MeshKit.xf(Vector3(0.38, 0.12, 0.3), Vector3(1, 0.3, 1)),
			GameTune.GOLD
		]
	)
	var root: Node3D = _finish(p)
	(root.get_child(0) as Node3D).rotation_degrees = Vector3(55, 0, 0)  # page faces up and to +z
	(root.get_child(0) as Node3D).position = Vector3(0, 0.45, 0)
	return root
