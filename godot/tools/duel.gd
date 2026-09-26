extends Node
## One fight, printed second by second:  --play --nomonsters --bots=0 --duel=wild_boar:5 --class=warrior --level=3
var p: Player
var m: Monster
var brain: Brain
var t := 0.0
var tick := 0.0
func _ready() -> void:
	await get_tree().process_frame
	p = get_tree().get_first_node_in_group("player")
	var spec: PackedStringArray = get_parent().args["duel"].split(":")
	m = Monster.new(); m.setup(spec[0], int(spec[1]))
	get_tree().current_scene.add_child(m)
	var at := Nav.nearest_open(p.global_position + Vector3(12, 0, 0)); at.y = WorldData.h(at.x, at.z)
	m.global_position = at; m.home = at
	brain = Brain.new(p); p.add_child(brain)
	for id in Npcs.TRAINING[p.cls]:
		if int(id[1]) <= p.level and not (id[0] in p.known): p.known.append(id[0])
	brain._fill_bar()
	await get_tree().physics_frame
	brain.focus = m
	print("duel: %s L%d (%d hp, armor %d, weapon %s) vs %s L%d (%d hp, armor %d, weapon %s)" % [p.cls, p.level, int(p.max_hp), int(p.armor), str(p.weapon), m.uname, m.level, int(m.max_hp), int(m.armor), str(m.weapon)])
func _physics_process(delta: float) -> void:
	if m == null: return
	t += delta; tick += delta
	if tick >= 1.0:
		tick = 0.0
		print("t=%2d  me %d/%d %s %d  tgt=%s atk=%s cast=%s d=%.1f | mon %d/%d tgt=%s combat=%s evading=%s" % [int(t), int(p.hp), int(p.max_hp), p.power_kind, int(p.power), p.target.uname if p.target else "-", p.attacking, p.casting.get("id", "-"), p.distance_to(m), int(m.hp), int(m.max_hp), m.target.uname if m.target else "-", m.in_combat, m.evading])
	if m.dead or p.dead or t > 90:
		print("END t=%d  %s" % [int(t), "WON" if m.dead else ("LOST" if p.dead else "TIMEOUT")]); get_tree().quit()
