class_name Nav
## Walking routes for everyone (the player's click-to-move, monsters, townsfolk, simulated players).
## The map is a 1 m grid; a cell is blocked by anything solid standing on it (houses, market stalls,
## tree trunks), by deep water and by slopes too steep to climb. Paths are found with A* and then
## straightened, so people walk in natural lines rather than grid steps.

const CELL := 1.0
static var astar: AStarGrid2D
static var n := 0
static var ready := false

static func _cell(p: Vector3) -> Vector2i:
	return Vector2i(clampi(int(floor((p.x + WorldData.HALF) / CELL)), 0, n - 1), clampi(int(floor((p.z + WorldData.HALF) / CELL)), 0, n - 1))

static func _pos(c: Vector2i) -> Vector3:
	var x := -WorldData.HALF + (c.x + 0.5) * CELL; var z := -WorldData.HALF + (c.y + 0.5) * CELL
	return Vector3(x, WorldData.h(x, z), z)

## build once the world's solid things exist (call after the village and trees are placed)
static func build(tree: SceneTree) -> void:
	var t0 := Time.get_ticks_msec()
	n = int(WorldData.HALF * 2.0 / CELL)
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, n, n); astar.cell_size = Vector2(CELL, CELL)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	# terrain: deep water and steep ground
	for j in n:
		for i in n:
			var p := _pos(Vector2i(i, j))
			var slope := maxf(absf(WorldData.h(p.x + 0.5, p.z) - WorldData.h(p.x - 0.5, p.z)), absf(WorldData.h(p.x, p.z + 0.5) - WorldData.h(p.x, p.z - 0.5)))
			var rock := WorldData.CAVE and WorldData.rock_w(Vector2(p.x, p.z)) > 0.2
			# (only the pond is water: low ground elsewhere, and cave floors, are just low ground)
			var wet := WorldData.POND_R > 0.0 and p.y < WorldData.WATER_H - 0.25 and Vector2(p.x, p.z).distance_to(WorldData.POND) < WorldData.POND_R * 1.9
			if rock or wet or slope > 0.95 or absf(p.x) > WorldData.HALF - 3.0 or absf(p.z) > WorldData.HALF - 3.0:

				astar.set_point_solid(Vector2i(i, j), true)
	# solid things: test the cells under each static body's shapes
	var space := tree.root.get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new(); q.collide_with_areas = false
	for body in tree.root.find_children("*", "StaticBody3D", true, false):
		if body.name == "Ground": continue
		for cs in body.find_children("*", "CollisionShape3D", false, false):
			if cs.disabled or cs.shape == null: continue
			var bb: AABB = cs.global_transform * cs.shape.get_debug_mesh().get_aabb()
			var c0 := _cell(bb.position - Vector3(0.4, 0, 0.4)); var c1 := _cell(bb.end + Vector3(0.4, 0, 0.4))
			for j in range(c0.y, c1.y + 1):
				for i in range(c0.x, c1.x + 1):
					var p := _pos(Vector2i(i, j))
					var hit := false
					for dy in [0.5, 1.2]:
						for off in [Vector3.ZERO, Vector3(0.35, 0, 0), Vector3(-0.35, 0, 0), Vector3(0, 0, 0.35), Vector3(0, 0, -0.35)]:
							q.position = p + off + Vector3(0, dy, 0)
							for r in space.intersect_point(q, 4):
								if r.collider == body: hit = true; break
							if hit: break
						if hit: break
					if hit: astar.set_point_solid(Vector2i(i, j), true)
	ready = true
	print("navigation grid built in %d ms" % (Time.get_ticks_msec() - t0))

static func walkable(p: Vector3) -> bool:
	return ready and not astar.is_point_solid(_cell(p))

## the nearest open cell to p (e.g. when someone clicks on a wall)
static func nearest_open(p: Vector3) -> Vector3:
	if not ready: return p
	var c := _cell(p)
	if not astar.is_point_solid(c): return p
	for r in range(1, 12):
		for dj in range(-r, r + 1):
			for di in range(-r, r + 1):
				if maxi(absi(di), absi(dj)) != r: continue
				var cc := c + Vector2i(di, dj)
				if cc.x < 0 or cc.y < 0 or cc.x >= n or cc.y >= n: continue
				if not astar.is_point_solid(cc): return _pos(cc)
	return p

## a list of points from a to b (a not included), straightened; empty if no way
static func path(a: Vector3, b: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	if not ready:
		out.append(b); return out
	b = nearest_open(b)
	if _clear(a, b):
		out.append(b); return out
	var ca := _cell(nearest_open(a)); var cb := _cell(b)
	var ids := astar.get_id_path(ca, cb, true)
	if ids.is_empty(): return out
	# string-pull: keep only the corners we cannot see past
	var pts: Array[Vector3] = []
	for c in ids: pts.append(_pos(c))
	pts[pts.size() - 1] = b
	var from := a
	var i := 0
	while i < pts.size():
		var j := pts.size() - 1
		while j > i and not _clear(from, pts[j]): j -= 1
		out.append(pts[j]); from = pts[j]; i = j + 1
	return out

## can you walk straight from a to b?
static func _clear(a: Vector3, b: Vector3) -> bool:
	var d := Vector2(b.x - a.x, b.z - a.z)
	var steps := int(d.length() / (CELL * 0.4)) + 1
	for s in range(1, steps + 1):
		var t := float(s) / steps
		var p := a.lerp(b, t)
		if astar.is_point_solid(_cell(p)): return false
	return true
