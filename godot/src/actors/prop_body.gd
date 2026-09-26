class_name PropBody extends Humanoid
## A body with no bones or animations: things monsters make that can be hit (the Bone Prison's cage).

var kind := "cage"

func _ready() -> void:
	anim = null; skeleton = null
	if kind == "cage":
		var bone := StandardMaterial3D.new(); bone.albedo_color = Color(0.88, 0.85, 0.76); bone.roughness = 0.7
		bone.emission_enabled = true; bone.emission = Color(0.25, 0.4, 0.3); bone.emission_energy_multiplier = 0.3
		for k in 9:
			var a := TAU * k / 9.0
			var rib := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.03; cm.bottom_radius = 0.07; cm.height = 2.3; cm.radial_segments = 6
			cm.material = bone; rib.mesh = cm; add_child(rib)
			rib.position = Vector3(cos(a) * 0.75, 1.05, sin(a) * 0.75)
			rib.rotation = Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35)
		var top := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.35; sm.height = 0.5; sm.material = bone; top.mesh = sm
		add_child(top); top.position.y = 2.1
		var ring := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.7; tm.outer_radius = 0.86; tm.material = bone; ring.mesh = tm
		add_child(ring); ring.position.y = 0.1

func has_anim(_n: String) -> bool: return false
func play(_n: String, _speed := 1.0, _blend := -1.0) -> void: pass
func play_once(_n: String, _speed := 1.0) -> void: pass
