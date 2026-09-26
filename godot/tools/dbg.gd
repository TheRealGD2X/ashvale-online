extends Node
func _ready():
	await get_tree().create_timer(3.0).timeout
	var p = get_tree().get_first_node_in_group("player")
	var cam = get_viewport().get_camera_3d()
	print("player ", p.global_position, " cam ", cam.global_position if cam else null, " dist ", cam.dist if cam else 0)
	for ba in p.model.skeleton.find_children("*", "BoneAttachment3D", false, false):
		for c in ba.get_children():
			print("held ", c.name, " scale ", c.global_transform.basis.get_scale(), " pos ", c.global_position)
	print("model scale ", p.model.global_transform.basis.get_scale())
	get_tree().quit()
