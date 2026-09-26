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
