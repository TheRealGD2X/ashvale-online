class_name Terrain extends Node3D
## The ground: 16 mesh chunks built from WorldData's baked grid, one collision heightfield, and the
## shared noise textures other shaders (grass, water) sample so everything agrees.

const CHUNKS := 8                     # 8 x 8 chunks of 32 m
static var noise_big: Texture2D
static var noise_fine: Texture2D
static var mask_tex: Texture2D
var material: ShaderMaterial

static func make_noise_textures() -> void:
	mask_tex = ImageTexture.create_from_image(WorldData.mask)
	if noise_big: return

	var n := FastNoiseLite.new(); n.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC; n.frequency = 1.0 / 48.0; n.fractal_octaves = 3; n.seed = 11
	var img := n.get_seamless_image(512, 512); img.convert(Image.FORMAT_L8); img.generate_mipmaps()
	noise_big = ImageTexture.create_from_image(img)
	var f := FastNoiseLite.new(); f.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC; f.frequency = 1.0 / 12.0; f.fractal_octaves = 2; f.seed = 5
	var img2 := f.get_seamless_image(256, 256); img2.convert(Image.FORMAT_L8); img2.generate_mipmaps()
	noise_fine = ImageTexture.create_from_image(img2)
	mask_tex = ImageTexture.create_from_image(WorldData.mask)

func _ready() -> void:
	WorldData.bake()
	make_noise_textures()
	material = ShaderMaterial.new()
	material.shader = load("res://shaders/terrain.gdshader")
	material.set_shader_parameter("world_mask", mask_tex)
	material.set_shader_parameter("noise_big", noise_big)
	material.set_shader_parameter("noise_fine", noise_fine)
	material.set_shader_parameter("cobble_albedo", load("res://assets/village/T_UnevenBrick_BaseColor.png"))
	material.set_shader_parameter("cobble_normal", load("res://assets/village/T_UnevenBrick_Normal.png"))
	material.set_shader_parameter("rock_albedo", load("res://assets/nature/Rocks_Diffuse.png"))
	material.set_shader_parameter("half_size", WorldData.HALF)
	material.set_shader_parameter("water_h", WorldData.WATER_H)
	material.set_shader_parameter("cave_dark", 1.0 if WorldData.CAVE else 0.0)
	# each zone has its own ground colours
	var pal: Dictionary = WorldData.Z.get("palette", {})
	for k in pal: material.set_shader_parameter(k, pal[k])

	var per := (WorldData.RES - 1) / CHUNKS
	for cj in CHUNKS:
		for ci in CHUNKS:
			var mi := MeshInstance3D.new(); mi.mesh = _chunk(ci * per, cj * per, per); mi.material_override = material
			mi.name = "Chunk_%d_%d" % [ci, cj]; mi.layers = 2; add_child(mi)
	_collision()

func _chunk(i0: int, j0: int, n: int) -> ArrayMesh:
	var R := WorldData.RES; var S := WorldData.STEP; var H := WorldData.heights
	var verts := PackedVector3Array(); var nrms := PackedVector3Array(); var idx := PackedInt32Array()
	verts.resize((n + 1) * (n + 1)); nrms.resize(verts.size())
	for j in n + 1:
		for i in n + 1:
			var gi := i0 + i; var gj := j0 + j
			var x := -WorldData.HALF + gi * S; var z := -WorldData.HALF + gj * S
			verts[j * (n + 1) + i] = Vector3(x, H[gj * R + gi], z)
			var l := H[gj * R + maxi(gi - 1, 0)]; var r := H[gj * R + mini(gi + 1, R - 1)]
			var u := H[maxi(gj - 1, 0) * R + gi]; var d := H[mini(gj + 1, R - 1) * R + gi]
			nrms[j * (n + 1) + i] = Vector3(l - r, 2.0 * S, u - d).normalized()
	for j in n:
		for i in n:
			var a := j * (n + 1) + i; var b := a + 1; var c := a + n + 1; var dd := c + 1
			idx.append_array([a, b, c, b, dd, c])
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts; arr[Mesh.ARRAY_NORMAL] = nrms; arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new(); m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

func _collision() -> void:
	var body := StaticBody3D.new(); body.name = "Ground"; add_child(body)
	var shape := HeightMapShape3D.new(); shape.map_width = WorldData.RES; shape.map_depth = WorldData.RES
	shape.map_data = WorldData.heights
	var cs := CollisionShape3D.new(); cs.shape = shape
	cs.scale = Vector3(WorldData.STEP, 1.0, WorldData.STEP)   # the heightfield is centred on the origin
	body.add_child(cs)
