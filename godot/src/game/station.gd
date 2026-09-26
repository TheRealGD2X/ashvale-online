class_name Station extends Node3D
## A crafting station you click to use: a forge (bars, weapons, mail, rings), a tannery (leather,
## leather armour, cloaks), a loom (cloth, robes, staves and wands) or an alchemy table (potions).

var kind := "forge"
var sign: Label3D

func setup(k: String) -> void:
	kind = k

func _ready() -> void:
	add_to_group("stations")
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.4, 0.27, 0.16)
	var stone := StandardMaterial3D.new(); stone.albedo_color = Color(0.45, 0.43, 0.4)
	match kind:
		"forge":
			_box(Vector3(1.6, 1.2, 1.2), Vector3(0, 0.6, 0), stone)
			var glow := StandardMaterial3D.new(); glow.albedo_color = Color(1.0, 0.5, 0.15); glow.emission_enabled = true; glow.emission = Color(1.0, 0.45, 0.1); glow.emission_energy_multiplier = 3.0
			_box(Vector3(0.9, 0.35, 0.1), Vector3(0, 0.75, 0.61), glow)
			_box(Vector3(0.4, 1.6, 0.4), Vector3(0.5, 1.9, -0.3), stone)
			var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.55, 0.2); l.omni_range = 5.0; l.light_energy = 1.4; add_child(l); l.position = Vector3(0, 1.0, 1.0)
			_prop("Anvil", Vector3(1.6, 0, 0.6))
		"tannery":
			for x in [-0.9, 0.9]: _box(Vector3(0.12, 1.8, 0.12), Vector3(x, 0.9, 0), wood)
			_box(Vector3(2.0, 0.1, 0.1), Vector3(0, 1.75, 0), wood)
			var hide := StandardMaterial3D.new(); hide.albedo_color = Color(0.6, 0.45, 0.3)
			_box(Vector3(1.5, 1.2, 0.04), Vector3(0, 1.1, 0), hide)
			_prop("Bucket_Wooden_1", Vector3(1.3, 0, 0.5))
		"loom":
			for x in [-0.8, 0.8]: _box(Vector3(0.12, 1.6, 0.8), Vector3(x, 0.8, 0), wood)
			_box(Vector3(1.7, 0.1, 0.1), Vector3(0, 1.5, 0.3), wood)
			var cloth := StandardMaterial3D.new(); cloth.albedo_color = Color(0.75, 0.3, 0.25)
			_box(Vector3(1.4, 0.9, 0.03), Vector3(0, 1.0, 0.1), cloth)
		"alchemy":
			_box(Vector3(1.6, 0.9, 0.8), Vector3(0, 0.45, 0), wood)
			_prop("Cauldron", Vector3(-0.9, 0, 0.6))
			_prop("SmallBottles_1", Vector3(0.3, 0.9, 0.0))
			_prop("Potion_1", Vector3(-0.3, 0.9, 0.1))
	sign = Label3D.new(); sign.text = Crafting.STATIONS[kind]; sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED; sign.font_size = 36; sign.pixel_size = 0.006
	sign.modulate = Color(1.0, 0.9, 0.6); sign.outline_size = 8; sign.position.y = 2.6; add_child(sign)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(1.8, 1.4, 1.2); cs.shape = sh; cs.position.y = 0.7; body.add_child(cs)

func _box(size: Vector3, pos: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; bm.material = m; mi.mesh = bm; mi.position = pos; add_child(mi)

func _prop(name: String, pos: Vector3) -> void:
	var path := "res://assets/props/%s.gltf" % name
	if not ResourceLoader.exists(path): return
	var n: Node3D = load(path).instantiate(); n.position = pos; add_child(n)

func take(p: Player) -> void:
	get_tree().call_group("hud", "open_station", kind)
