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
	for i in n:
		var b := Bot.new()
		var lv: int = [1, 1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 3, 2, 6][i % 14]
		var cls: String = ["warrior", "wizard", "cleric"][rng.randi() % 3]
		b.setup_bot(names[i % names.size()], cls, lv, rng)
		add_child(b)
		var at := Vector2(rng.randf_range(-12, 12), rng.randf_range(-6, 18)) if lv <= 3 else Vector2(rng.randf_range(58, 76), rng.randf_range(4, 18))
		var p := Nav.nearest_open(Vector3(at.x, 0, at.y)); p.y = WorldData.h(p.x, p.z)
		b.global_position = p; b.home = p
		bots.append(b)
