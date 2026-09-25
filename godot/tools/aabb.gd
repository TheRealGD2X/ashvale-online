extends SceneTree
# godot --headless --path . -s tools/aabb.gd -- res://a.gltf res://b.gltf ...
func _init():
	for p in OS.get_cmdline_user_args():
		var s: Node = load(p).instantiate(); root.add_child(s)
		var bb := AABB(); var first := true
		for m in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = m.global_transform * m.get_aabb()
			bb = b if first else bb.merge(b); first = false
		print("%-40s pos %s size %s" % [p.get_file(), bb.position.snapped(Vector3.ONE*0.01), bb.size.snapped(Vector3.ONE*0.01)])
		s.queue_free()
	quit()
