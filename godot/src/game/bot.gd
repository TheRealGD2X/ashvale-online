class_name Bot extends Player
## A simulated player: a character like yours, played by a Brain. Bots quest through the province,
## level up, loot and sell, and talk in chat like people do: asking where things are, saying ding,
## complaining about boars, answering you when you speak to them, and joining your group if you
## invite them (/invite Name). Each has a way of typing (tidy, lowercase, terse, chatty).
##
## What they say comes from ChatVoice (rules, or a small local language model if one is running).

var brain: Brain
var style := "casual"            # tidy | casual | terse | chatty
var chat_t := 0.0
var greeted := {}
var last_task := ""
var mood := 0.0                  # grumpier after dying, happier after a ding
var party_with: Player

func setup_bot(nm: String, c: String, lv: int, rng: RandomNumberGenerator) -> void:
	is_bot = true
	var look_d := Avatar.random_look(rng, c)
	setup_from({"name": nm, "cls": c, "level": lv, "look": look_d})
	# a bot that starts above level 1 has done the early quests already
	var order := ["word_with_elder", "pests_in_fields", "hen_feathers", "blacksmiths_wager", "grizzled_rat", "road_to_mill", "fence_can_wait"]
	for i in mini(order.size(), (lv - 1) * 2): done_quests.append(order[i])
	for t in Npcs.TRAINING[c]:
		if int(t[1]) <= lv and not (t[0] in known): known.append(t[0])
	gold = lv * lv * 40
	style = ["tidy", "casual", "casual", "terse", "chatty"][rng.randi() % 5]
	chat_t = rng.randf_range(20.0, 120.0)

func _ready() -> void:
	is_bot = true
	super._ready()
	brain = Brain.new(self)
	add_child(brain)
	brain._fill_bar()
	leveled.connect(_on_level)
	died.connect(func(_u): mood -= 1.0; _later(randf_range(3.0, 8.0), func(): voice_event("died")))

func auto_loot(m: Monster) -> void:
	_later(0.8, func():
		if is_instance_valid(m) and m.has_loot(self): loot_all(m); brain._wear_best())

func _later(t: float, f: Callable) -> void:
	get_tree().create_timer(t).timeout.connect(f)

func _on_level(lv: int) -> void:
	mood += 1.0
	_later(randf_range(1.0, 4.0), func(): voice_event("ding", {"level": lv}))

func _think(delta: float) -> void:
	super._think(delta)
	chat_t -= delta
	if chat_t <= 0.0:
		chat_t = randf_range(90.0, 260.0)
		voice_event("idle", {"task": brain.task})
	# say hello to the real player when they come close, now and then
	var p: Player = get_tree().get_first_node_in_group("player")
	if p and Engine.get_physics_frames() % 30 == 0 and not greeted.has(p) and global_position.distance_to(p.global_position) < 7.0 and randf() < 0.35:
		greeted[p] = true
		_later(randf_range(0.5, 2.0), func(): voice_event("near", {"who": p.uname}))

## something happened worth talking about: ask the voice what (if anything) to say
func voice_event(kind: String, info := {}) -> void:
	var v := get_tree().get_first_node_in_group("voice")
	if v: v.event(self, kind, info)

## what the chat window calls when the player writes something
func hear(ch: String, from: Player, text: String, to: String) -> void:
	if from == self: return
	if ch == "whisper" and to.to_lower() != uname.to_lower(): return
	if ch == "say" and global_position.distance_to(from.global_position) > 25.0: return
	if ch == "party" and party_with != from: return
	var v := get_tree().get_first_node_in_group("voice")
	if v: v.heard(self, ch, from, text)

func invited(by: Player, nm: String) -> void:
	if nm.to_lower() != uname.to_lower(): return
	var v := get_tree().get_first_node_in_group("voice")
	if party_with == by:
		return
	if absi(by.level - level) > 4 or not by.party.size() < 4:
		if v: v.say(self, "whisper", by, "sorry, i'm a bit off your level" if absi(by.level - level) > 4 else "your group looks full")
		return
	party_with = by
	by.party.append(self)
	brain.leader = by
	get_tree().call_group("hud", "notice", "%s joins your group." % uname)
	if v: v.event(self, "joined", {"who": by.uname})

func leave_party(by: Player) -> void:
	if party_with != by: return
	by.party.erase(self)
	party_with = null; brain.leader = null
	get_tree().call_group("hud", "notice", "%s leaves your group." % uname)

func party_members() -> Array:
	if party_with and is_instance_valid(party_with): return party_with.party_members()
	return [self]
