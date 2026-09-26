extends Node3D
## The other "players" in Ashvale: simulated adventurers (Bot) of mixed classes and levels, spread
## over the province where their levels would put them, plus the chat voice they speak with.
## --bots=N sets how many (default 10; 0 for none).

const NAMES := ["Thornwick", "Lirael", "Brannoc", "Elspeth", "Kaelen", "Mossfoot", "Grimble", "Tamsin", "Oswin", "Vessa",
	"Rookwood", "Pipkin", "Maelis", "Dunstan", "Ysolde", "Corvin", "Hollis", "Brisa", "Fenwick", "Aldric", "Sable", "Wynn"]

var bots: Array = []

func _ready() -> void:
	add_to_group("society")
	add_child(ChatVoice.new())
	var args: Dictionary = get_parent().args if "args" in get_parent() else {}
	var n := int(args.get("bots", "10"))
	if WorldData.lite and not args.has("bots"): n = 0
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var names := NAMES.duplicate(); names.shuffle()
	var band: Array = WorldData.Z.get("band", [1, 10])
	if WorldData.Z.get("dungeon", false): n = 0          # nobody wanders a dungeon but your own group
	var hubs: Array = []
	for id in Npcs.LIST:
		if Npcs.LIST[id].get("zone", "ashvale") == WorldData.zone_id: hubs.append(Vector2(Npcs.LIST[id]["at"][0], Npcs.LIST[id]["at"][1]))
	for i in n:
		var b := Bot.new()
		var lv: int = clampi(int(band[0]) + [0, 0, 1, 2, 3, 4, 4, 5, 6, 7, 8, 2, 1, 5][i % 14], int(band[0]), int(band[1]))
		var cls: String = ["warrior", "wizard", "cleric"][rng.randi() % 3]
		b.setup_bot(names[i % names.size()], cls, lv, rng)
		add_child(b)
		var at: Vector2 = hubs[rng.randi() % hubs.size()] + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8)) if not hubs.is_empty() else Vector2.ZERO
		if WorldData.zone_id == "ashvale": at = Vector2(rng.randf_range(-12, 12), rng.randf_range(-6, 18)) if lv <= 3 else Vector2(rng.randf_range(58, 76), rng.randf_range(4, 18))
		var p := Nav.nearest_open(Vector3(at.x, 0, at.y)); p.y = WorldData.h(p.x, p.z)
		b.global_position = p; b.home = p
		bots.append(b)

## a group member following you from another zone
func bring(save: Dictionary, leader: Player) -> void:
	var b := Bot.new()
	var rng := RandomNumberGenerator.new(); rng.randomize()
	b.setup_bot(save["name"], save["cls"], int(save["level"]), rng)
	b.restore(save)
	add_child(b)
	var p := Nav.nearest_open(leader.global_position + Vector3(rng.randf_range(-2, 2), 0, rng.randf_range(1.5, 3))); p.y = WorldData.h(p.x, p.z)
	b.global_position = p; b.home = p
	b.party_with = leader; leader.party.append(b); b.brain.leader = leader
	bots.append(b)

## call for a raid (/lfm, or the Keeper at the Gate): nine level-60 players answer, walk over and
## join. Two warriors to tank, three clerics to heal, and damage. They come in their best (blues).
func gather_raid(leader: Player) -> void:
	var chat := get_tree().get_first_node_in_group("chat")
	if leader.level < 58:
		if chat: chat.post("system", "", "Nobody answers. (Raids are for level 58 and up.)")
		return
	if leader.party.size() >= 9:
		if chat: chat.post("system", "", "Your raid is already full.")
		return
	leader.raid = true
	if chat:
		chat.post("general", leader.uname, "LFM Abyssal Sanctum, need all")
	var want := [["warrior", "tank"], ["warrior", "offtank"], ["cleric", "heal"], ["cleric", "heal"], ["cleric", "heal"], ["wizard", "dps"], ["wizard", "dps"], ["wizard", "dps"], ["warrior", "dps"]]
	if leader.cls == "cleric": want.erase(["cleric", "heal"]); want.append(["wizard", "dps"])
	# people already with you count
	for m in leader.party:
		if is_instance_valid(m) and m is Bot:
			if m.raid_role == "": m.raid_role = "tank" if m.cls == "warrior" and not _has_role(leader, "tank") else ("heal" if m.cls == "cleric" else "dps")
			for w in want:
				if w[0] == m.cls: want.erase(w); break
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var names := NAMES.duplicate(); names.shuffle()
	var taken := []
	for b in get_tree().get_nodes_in_group("bots"): taken.append(b.uname)
	var delay := 2.0
	for w in want.slice(0, 9 - leader.party.size()):
		var nm := ""
		for n in names:
			if not (n in taken): nm = n; taken.append(n); break
		if nm == "": nm = "Raider%d" % rng.randi_range(10, 99)
		get_tree().create_timer(delay).timeout.connect(_raider.bind(leader, nm, w[0], w[1]))
		delay += rng.randf_range(1.5, 4.0)

func _has_role(leader: Player, role: String) -> bool:
	for m in leader.party:
		if is_instance_valid(m) and m is Bot and m.raid_role == role: return true
	return false

func _raider(leader: Player, nm: String, cls: String, role: String) -> void:
	if not is_instance_valid(leader) or not leader.raid or leader.party.size() >= 9: return
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var b := Bot.new()
	b.gear_q = 3
	b.setup_bot(nm, cls, 60, rng)
	b.raid_role = role
	b.add_item({"id": "sanctum_key", "n": 1})
	add_child(b)
	# they come walking in from somewhere nearby
	var a := rng.randf() * TAU
	var p := Nav.nearest_open(leader.global_position + Vector3(cos(a), 0, sin(a)) * rng.randf_range(12.0, 22.0)); p.y = WorldData.h(p.x, p.z)
	b.global_position = p; b.home = p
	bots.append(b)
	var v := get_tree().get_first_node_in_group("voice")
	if v: v.event(b, "lfm_answer", {"to": leader})
	get_tree().create_timer(rng.randf_range(1.0, 2.5)).timeout.connect(func():
		if is_instance_valid(b) and is_instance_valid(leader): b.invited(leader, b.uname))

