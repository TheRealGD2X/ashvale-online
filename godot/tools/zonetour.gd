extends Node
## Load a zone, walk nothing, report what's there, quit:  --play --zonetour --zone=highlands
func _ready() -> void:
	var p0: Node3D = get_tree().get_first_node_in_group("player")
	if p0: print("  start at ", p0.global_position)
	var st: Vector2 = WorldData.Z["start"]
	var row := ""
	for dz in range(-6, 7, 2):
		for dx in range(-6, 7, 2): row += "#" if not Nav.walkable(Vector3(st.x + dx, 0, st.y + dz)) else "."
		row += " "
	print("  around start: ", row, "  h=", WorldData.h(st.x, st.y))
	await get_tree().create_timer(3.0).timeout
	var g := get_tree()
	print("ZONE %s: npcs %d, units %d, pickups %d, gather %d, stations %d, exits %d" % [WorldData.zone_id, g.get_nodes_in_group("npcs").size(), g.get_nodes_in_group("units").size(),
		g.get_nodes_in_group("pickups").size(), g.get_nodes_in_group("gather").size(), g.get_nodes_in_group("stations").size(), WorldData.Z.get("exits", []).size()])
	for n in g.get_nodes_in_group("npcs"):
		if not Nav.walkable(n.global_position): print("  NPC IN A WALL: ", n.npc_id)
	for ex in WorldData.Z.get("exits", []):
		var p := Vector3(ex["at"].x, 0, ex["at"].y)
		var path := Nav.path(Nav.nearest_open(Vector3(WorldData.Z["start"].x, 0, WorldData.Z["start"].y)), Nav.nearest_open(p))
		print("  exit %s reachable: %s" % [ex["name"], path.size() > 0 and path[path.size() - 1].distance_to(p) < ex["r"] + 3.0])
	g.quit()
