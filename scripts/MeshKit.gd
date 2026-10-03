class_name MeshKit
extends RefCounted
## Builds one vertex-coloured ArrayMesh out of many primitive parts, so a whole
## prop (Pip, a tree, a lamb) costs one draw call (+1 for its outline).

const TOON: Shader = preload("res://shaders/toon.gdshader")
const OUTLINE: Shader = preload("res://shaders/outline.gdshader")


## parts: Array of [PrimitiveMesh, Transform3D, Color]
static func merge(parts: Array) -> ArrayMesh:
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for part: Array in parts:
		var mesh: PrimitiveMesh = part[0]
		var xf: Transform3D = part[1]
		var col: Color = part[2]
		var arrays: Array = mesh.get_mesh_arrays()
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var base: int = verts.size()
		var nb: Basis = xf.basis.inverse().transposed()
		for i in v.size():
			verts.append(xf * v[i])
			normals.append((nb * n[i]).normalized())
			colors.append(col)
			uvs.append(uv[i] if i < uv.size() else Vector2.ZERO)
		for i in idx:
			indices.append(base + i)
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_COLOR] = colors
	out[Mesh.ARRAY_TEX_UV] = uvs
	out[Mesh.ARRAY_INDEX] = indices
	var am: ArrayMesh = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	return am


static func toon(color: Color = Color(1, 1, 1), vertex_color: bool = true) -> ShaderMaterial:
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("use_vertex_color", vertex_color)
	m.set_shader_parameter("shadow_tint", GameTune.SHADOW_TINT)
	return m


## Toon for characters and handheld things: no received shadow.
static func char_toon(color: Color = Color(1, 1, 1), vertex_color: bool = true) -> ShaderMaterial:
	var m: ShaderMaterial = toon(color, vertex_color)
	m.set_shader_parameter("receive_shadow", false)
	return m


static func world_toon(color: Color = Color(1, 1, 1), vertex_color: bool = true) -> ShaderMaterial:
	var m: ShaderMaterial = toon(color, vertex_color)
	m.set_shader_parameter("use_zones", true)
	return m


static func outline(width: float = 0.0035) -> ShaderMaterial:
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = OUTLINE
	m.set_shader_parameter("color", GameTune.INK)
	m.set_shader_parameter("width", width)
	return m


static func with_outline(mat: ShaderMaterial, width: float = 0.0035) -> ShaderMaterial:
	mat.next_pass = outline(width)
	return mat


static func instance(
	mesh: Mesh, mat: Material, parent: Node, pos: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


static func sphere(r: float, segs: int = 16, rings: int = 10) -> SphereMesh:
	var s: SphereMesh = SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = rings
	return s


static func cylinder(r_top: float, r_bottom: float, h: float, segs: int = 12) -> CylinderMesh:
	var c: CylinderMesh = CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bottom
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return c


static func box(size: Vector3) -> BoxMesh:
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	return b


static func xf(
	pos: Vector3, scale: Vector3 = Vector3.ONE, rot_deg: Vector3 = Vector3.ZERO
) -> Transform3D:
	var b: Basis = Basis.from_euler(rot_deg * (PI / 180.0)) * Basis.from_scale(scale)
	return Transform3D(b, pos)
