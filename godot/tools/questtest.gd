extends Node
## Plays the Ashvale Province quests by itself with the real Player and prints how it goes.
##   godot --headless --path . --fixed-fps 30 -- --play --questtest=1800 [--class=wizard]
## (1800 = seconds of game time; --fixed-fps makes a headless run go as fast as the CPU allows)

var p: Player
var brain: Brain
var t := 0.0
var report_t := 0.0
var limit := 1800.0
var deaths := 0

func _ready() -> void:
	limit = float(get_parent().args.get("questtest", "1800"))
	await get_tree().process_frame
	p = get_tree().get_first_node_in_group("player")
	brain = Brain.new(p); brain.log_lines = true
	p.add_child(brain)
	p.died.connect(func(_u):
		deaths += 1
		var who := []
		for u in get_tree().get_nodes_in_group("units"):
			if u is Monster and u.target == p and not u.dead: who.append("%s L%d (%d/%d hp)" % [u.uname, u.level, int(u.hp), int(u.max_hp)])
		print("DIED at ", p.global_position, " doing ", brain.task, " to ", who))
	print("questtest: %s level %d for %d s" % [p.cls, p.level, int(limit)])

func _physics_process(delta: float) -> void:
	if p == null: return
	t += delta; report_t += delta
	if report_t >= 30.0:
		report_t = 0.0
		print("t=%4d L%d xp %d/%d gold %s hp %d/%d  done %d  active %s  task: %s  at (%d, %d)" % [int(t), p.level, p.xp, Rules.xp_need(p.level), Items.money(p.gold),
			int(p.hp), int(p.max_hp), p.done_quests.size(), str(p.quests.keys()), brain.task, int(p.global_position.x), int(p.global_position.z)])
	if t >= limit or p.done_quests.size() >= Quests.LIST.size() - 1:
		print("QUESTTEST END t=%d level %d done %d/%d deaths %d gold %s" % [int(t), p.level, p.done_quests.size(), Quests.LIST.size(), deaths, Items.money(p.gold)])
		print("done: ", p.done_quests)
		print("still: ", p.quests)
		var eq := []
		for s in p.equipped: eq.append(Items.get_def(p.equipped[s])["name"])
		print("wearing: ", eq)
		print("known: ", p.known, "  talents: ", p.talents)
		get_tree().quit()
