class_name Props
extends RefCounted
## Word pictures built from primitives (placeholders): the sun for "sol" and
## a lamb for "lam". Each is one merged mesh + outline.


static func make(kind: String) -> Node3D:
	match kind:
		"sun":
			return _sun()
		"lamb":
			return _lamb()
	return null


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
