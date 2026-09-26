extends Node
## Buildings between the camera and your hero fade to see-through, like Albion Online, so the
## tilted top-down view never loses you behind a house.

var cam: Camera3D
var fading := {}      # root Node3D -> current transparency (0 solid .. 0.8 ghost)
var want := {}
var t := 0.0

func _physics_process(delta: float) -> void:
	if cam == null: cam = get_viewport().get_camera_3d()
	var hero := get_tree().get_first_node_in_group("player") as Node3D
	t += delta
	if t > 0.1 and cam and hero:
		t = 0.0
		want.clear()
		var space := cam.get_world_3d().direct_space_state
		for h in [0.3, 1.2, 2.0]:
			var to := hero.global_position + Vector3(0, h, 0)
			var ex := []
			for i in 5:
				var q := PhysicsRayQueryParameters3D.create(cam.global_position, to, 1); q.exclude = ex
				var hit := space.intersect_ray(q)
				if hit.is_empty(): break
				ex.append(hit.rid)
				var r := _root(hit.collider)
				if r: want[r] = true
	# ease every building toward see-through or solid
	for r in want:
		if not fading.has(r): fading[r] = 0.0
	for r in fading.keys():
		if not is_instance_valid(r): fading.erase(r); continue
		var goal := 0.78 if want.has(r) else 0.0
		var v: float = move_toward(fading[r], goal, delta * 3.0)
		if v != fading[r]:
			fading[r] = v
			_apply(r, v)
		if v == 0.0 and not want.has(r): fading.erase(r)

func _root(n: Node) -> Node3D:
	while n:
		if n.name.begins_with("House") or n.has_meta("see_through"): return n
		n = n.get_parent()
	return null

func _apply(r: Node3D, v: float) -> void:
	for mi in r.find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).transparency = v
