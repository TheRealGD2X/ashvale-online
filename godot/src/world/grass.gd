class_name Grass extends Node3D
## Meadow grass over the whole map in 16 m chunks: a dense near layer and a sparse, larger-clumped
## far layer, both positioned on the GPU (shaders/grass.gdshader). Clearings come from
## WorldData.clear (houses, rocks, fields register themselves there before the grass is built).

const CHUNK := 16.0
var near_mat: ShaderMaterial
var far_mat: ShaderMaterial
var lite := false

static func blade_clump(blades: int, height: float, width: float, radius: float, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new(); rng.seed = seed
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 4
	for b in blades:
		var a := rng.randf() * TAU
		var base := Vector3(cos(a), 0, sin(a)) * radius * sqrt(rng.randf())
		var face := rng.randf() * TAU
		var side := Vector3(cos(face), 0, sin(face))
		var bend := Vector3(-side.z, 0, side.x) * rng.randf_range(0.1, 0.35)
		var hh := height * rng.randf_range(0.6, 1.15)
		var w := width * rng.randf_range(0.8, 1.2)
		var nrm := bend.normalized() if bend.length() > 0 else Vector3.FORWARD
		var pts := []
		for s in segs + 1:
			var t := float(s) / segs
			var c := base + Vector3(0, t * hh, 0) + bend * t * t * hh
			var ww := w * (1.0 - t * t * 0.8) * 0.5
			pts.append([c - side * ww, c + side * ww, t])
		var tip := base + Vector3(0, hh * 1.08, 0) + bend * 1.1 * hh
		for s in segs:
			var p0: Array = pts[s]; var p1: Array = pts[s + 1]
			for v in [[p0[0], p0[2]], [p0[1], p0[2]], [p1[0], p1[2]], [p0[1], p0[2]], [p1[1], p1[2]], [p1[0], p1[2]]]:
				st.set_normal(nrm); st.set_uv(Vector2(0, v[1])); st.add_vertex(v[0])
		var pl: Array = pts[segs]
		for v in [[pl[0], pl[2]], [pl[1], pl[2]], [tip, 1.0]]:
			st.set_normal(nrm); st.set_uv(Vector2(0, v[1])); st.add_vertex(v[0])
	return st.commit()

func _ready() -> void:
	var sh: Shader = load("res://shaders/grass.gdshader")
	var hm := Image.create_from_data(WorldData.RES, WorldData.RES, false, Image.FORMAT_RF, WorldData.heights.to_byte_array())
	var hmt := ImageTexture.create_from_image(hm)
	var clear := ImageTexture.create_from_image(WorldData.clear)
	var near_sp := 0.16
	var far_sp := 0.34
	near_mat = _mat(sh, hmt, clear, near_sp, 1.0, 22.0, 34.0)
	far_mat = _mat(sh, hmt, clear, far_sp, 1.5, 62.0, 95.0)
	var near_mesh := blade_clump(6, 0.27, 0.075, 0.1, 1)
	var far_mesh := blade_clump(5, 0.27, 0.1, 0.13, 2)
	var n := int(2.0 * WorldData.HALF / CHUNK)
	for j in n:
		for i in n:
			var o := Vector3(-WorldData.HALF + i * CHUNK, 0, -WorldData.HALF + j * CHUNK)
			# skip chunks that are all road/water/town square (cheap test on a few samples)
			_layer(o, near_mesh, near_mat, near_sp, 0.0, 40.0)
			_layer(o, far_mesh, far_mat, far_sp, 18.0, 100.0)

func _mat(sh: Shader, hmt: Texture2D, clear: Texture2D, sp: float, sc: float, f0: float, f1: float) -> ShaderMaterial:
	var m := ShaderMaterial.new(); m.shader = sh
	m.set_shader_parameter("height_map", hmt)
	m.set_shader_parameter("world_mask", Terrain.mask_tex)
	m.set_shader_parameter("clear_mask", clear)
	m.set_shader_parameter("noise_big", Terrain.noise_big)
	m.set_shader_parameter("noise_fine", Terrain.noise_fine)
	m.set_shader_parameter("half_size", WorldData.HALF)
	m.set_shader_parameter("water_h", WorldData.WATER_H)
	m.set_shader_parameter("spacing", sp)
	m.set_shader_parameter("per_row", int(ceil(CHUNK / sp)))
	m.set_shader_parameter("clump_scale", sc)
	m.set_shader_parameter("fade_near", f0)
	m.set_shader_parameter("fade_far", f1)
	return m

func _layer(o: Vector3, mesh: Mesh, mat: ShaderMaterial, sp: float, vis0: float, vis1: float) -> void:
	var per := int(ceil(CHUNK / sp))
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = mesh
	mm.instance_count = per * per
	var mi := MultiMeshInstance3D.new(); mi.multimesh = mm; mi.material_override = mat
	mi.position = o
	var y0 := 1e9; var y1 := -1e9
	for s in [Vector2(0, 0), Vector2(CHUNK, 0), Vector2(0, CHUNK), Vector2(CHUNK, CHUNK), Vector2(CHUNK / 2, CHUNK / 2)]:
		var hh := WorldData.h(o.x + s.x, o.z + s.y); y0 = minf(y0, hh); y1 = maxf(y1, hh)
	mi.custom_aabb = AABB(Vector3(-1, y0 - 3, -1), Vector3(CHUNK + 2, y1 - y0 + 6, CHUNK + 2))
	mi.visibility_range_begin = vis0; mi.visibility_range_end = vis1
	mi.visibility_range_begin_margin = 6.0 if vis0 > 0 else 0.0; mi.visibility_range_end_margin = 8.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = 2
	add_child(mi)

