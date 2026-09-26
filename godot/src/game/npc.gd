class_name Npc extends Unit
## A named person of the world (Npcs.LIST): stands at their post, turns to you when you speak to
## them, and wears a mark over their head the way WoW does:
##   yellow !  a quest for you          grey !  one you'll be able to take soon
##   yellow ?  a quest to hand in       grey ?  one you're still working on
## Clicking them walks you over and opens their window (quests, goods, training).

var npc_id := ""
var info := {}
var mark: Label3D
var face_t := 0.0
var rest_yaw := 0.0
var mark_t := 0.0

func setup(id: String) -> void:
	npc_id = id
	info = Npcs.LIST[id]
	uname = info["name"]; faction = "npc"; cls = "npc"; level = int(info.get("level", 30))
	power_kind = "none"
	rest_yaw = deg_to_rad(float(info.get("face", 0)))
	yaw = rest_yaw

func _ready() -> void:
	super._ready()
	add_to_group("npcs")
	max_hp = 1500 + level * 60; hp = max_hp
	var a := Avatar.new(); a.look = Npcs.look_of(npc_id)
	model = a
	add_child(a); a.rotation.y = yaw
	if info.has("weapon"): a.wield.call_deferred("res://assets/weapons/%s.glb" % info["weapon"], 0.55)
	mark = Label3D.new(); mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED; mark.no_depth_test = true
	mark.font_size = 150; mark.pixel_size = 0.004; mark.outline_size = 28; mark.outline_modulate = Color(0.12, 0.06, 0.0)
	mark.position = Vector3(0, 2.55, 0); mark.text = ""; mark.fixed_size = false
	var f := SystemFont.new(); f.font_names = PackedStringArray(["Georgia", "serif"]); f.font_weight = 800; mark.font = f
	add_child(mark)
	_update_mark()

func is_enemy(_o: Unit) -> bool:
	return false

func _animate(_v: float) -> void:
	if model == null or model.anim == null or busy_anim > 0.0: return
	var an: String = info.get("anim", "Idle")
	if face_t > 0.0 and an == "Idle_FoldArms": an = "Idle"
	model.play(an if model.has_anim(an) else "Idle")

## turn to whoever speaks to us, and greet them
func face(u: Node3D) -> void:
	var d := u.global_position - global_position
	yaw = atan2(d.x, d.z); if model: model.rotation.y = yaw
	face_t = 10.0
	if info.get("anim", "") != "Sitting_Idle": act(["Idle_Talking", "Yes", "Interact"][randi() % 3], 1.0)

func _think(delta: float) -> void:
	if face_t > 0.0:
		face_t -= delta
		if face_t <= 0.0:
			yaw = rest_yaw
			if model: model.rotation.y = yaw
	mark_t -= delta
	if mark_t <= 0.0: mark_t = 0.5; _update_mark()
	# gentle bob of the mark
	if mark.text != "": mark.position.y = 2.55 + sin(Time.get_ticks_msec() / 400.0) * 0.06

func _update_mark() -> void:
	var p: Player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if p == null: mark.text = ""; return
	# some people leave the story (Gault goes down the mine)
	var gone: bool = info.has("gone_after") and info["gone_after"] in p.done_quests
	if gone == visible:
		visible = not gone; collision_layer = 0 if gone else 2
	if gone: return

	var yellow := Color(1.0, 0.86, 0.1); var grey := Color(0.7, 0.7, 0.7)
	var q := p.quests_at(npc_id)
	if not q["complete"].is_empty(): mark.text = "?"; mark.modulate = yellow; return
	if not q["available"].is_empty(): mark.text = "!"; mark.modulate = yellow; return
	if not q["active"].is_empty(): mark.text = "?"; mark.modulate = grey; return
	# a quest you'll be able to take in a level or two
	for id in Quests.LIST:
		if Quests.LIST[id]["giver"] == npc_id and p.quest_state(id) == "low" and int(Quests.LIST[id]["min"]) <= p.level + 2:
			mark.text = "!"; mark.modulate = grey; return
	mark.text = ""

func take_damage(_src: Unit, _amount: float, _school := "physical", _crit := false, _kind := "", _tm := 1.0) -> int:
	return 0
