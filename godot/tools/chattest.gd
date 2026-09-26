extends Node
## Talks to the simulated players and prints the chat:  --play --chattest --bots=8
var t := 0.0
var step := 0
var p: Player
var lines := [
	[4.0, "general", "hi all"],
	[12.0, "general", "where are the boars?"],
	[25.0, "general", "anyone know where the grizzled rat is?"],
	[40.0, "whisper", "hey, how's it going?"],
	[55.0, "whisper", "what are you doing?"],
	[70.0, "whisper", "want to group up?"],
	[85.0, "invite", ""],
	[100.0, "party", "thanks for joining! where should we go?"],
	[118.0, "say", "hello there"],
	[135.0, "general", "lol these scarecrows"],
]
func _ready() -> void:
	await get_tree().process_frame
	p = get_tree().get_first_node_in_group("player")
	var chat: ChatBox = get_tree().get_first_node_in_group("chat")
	chat.set_meta("print", true)
func _process(delta: float) -> void:
	t += delta
	if step < lines.size() and t >= lines[step][0]:
		var s: Array = lines[step]; step += 1
		var bots := get_tree().get_nodes_in_group("bots")
		var who: String = bots[0].uname if not bots.is_empty() else "Nobody"
		var chat: ChatBox = get_tree().get_first_node_in_group("chat")
		match s[1]:
			"whisper": chat._send("/w %s %s" % [who, s[2]])
			"invite": chat._send("/invite %s" % who)
			"party": chat._send("/p " + s[2])
			"say": chat._send("/s " + s[2])
			_: chat._send("/g " + s[2])
	if t > 170.0: get_tree().quit()
