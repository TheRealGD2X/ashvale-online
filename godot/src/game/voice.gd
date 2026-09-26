class_name ChatVoice extends Node
## What simulated players say, and when. Two ways of speaking:
##  - rules (always there): lines for each situation (a ding, a death, looking for something,
##    saying hi, answering a question) shaped by the bot's typing style, with the world's facts
##    (where the boars are, who sells what) so the answers are right;
##  - a small language model running on this computer through Ollama (http://127.0.0.1:11434),
##    used for replies to you when it's there. Nothing leaves the machine. If Ollama isn't running
##    the rules answer instead. Pick a model with the environment variable ASHVALE_LLM
##    (e.g. llama3.2:3b or qwen2.5:7b); otherwise the first chat model Ollama has is used.
##
## Bots also talk to each other: a question in General is sometimes answered by another bot who
## knows, and a ding gets a "grats" or two.

const OLLAMA := "http://127.0.0.1:11434"

## where things are, the way a player would say it
const PLACES := {
	"bess": "bess is at the inn, west side of the square", "inn": "the inn is on the west side of the square, bess runs it",
	"rowan": "elder rowan stands just north of the square", "elder": "elder rowan is just north of the square",
	"grom": "grom's forge is south-east of the square, he repairs too", "blacksmith": "the blacksmith (grom) is south-east of the square",
	"orrin": "sage orrin is north of the square by the houses", "sage": "orrin the sage hangs around north of the square",
	"trainer": "trainers are round the square: warrior east, wizard west, cleric south-east",
	"rat": "rats are in the fields behind the well, west of the square", "grizzled": "grizzled rat is under the granary north of town",
	"granary": "granary is north of the square, up the north road a bit", "hen": "hens are by the fountain in the square",
	"feather": "hens by the square drop feathers", "scarecrow": "scarecrows are in the west fields along the road",
	"mill": "follow the road east out of town, you can't miss the windmill", "hale": "farmer hale is at the mill, east road",
	"boar": "boars are all over the fields south of the mill", "hide": "boars south of the mill drop hides, takes a while",
	"wildcat": "wildcats are at the edge of the eastern woods, past the mill", "cat": "cats are at the eastern woods edge, east of the mill",
	"scratch": "old scratch dens in the hollow oak in the eastern woods. he hits hard", "oak": "split oak is east of the mill, the hollow oak is further into the woods north-east",
	"lamb": "the lamb's past the split oak, east of the mill. look for the bell", "bell": "bell's on the ground past the split oak",
	"shrine": "the old shrine is up the path north-east of the mill", "bones": "the bones are at the old shrine, north-east of the mill",
	"skeleton": "skeletons are at the old shrine up the path from the mill", "coin": "old coins are lying around the shrine, they glint",
	"hogtooth": "hogtooth is out east near the woods, south of the hollow oak. elite, bring a friend",
	"tusk": "old tusk wanders east of the boar fields. rare spawn", "wolf": "wolves are up the north road. nasty",
	"mine": "the mine is up the north road but i heard it's not open yet", "ada": "captain ada is at the mill with the militia",
	"wren": "wren the hunter is at the mill", "tomas": "tomas sits by the mill, he'll buy junk", "vendor": "bess sells food, grom sells gear, tomas at the mill buys junk",
	"food": "bess at the inn sells food and water", "water": "bess sells water at the inn", "repair": "grom repairs, south-east of the square",
	# the Hollow Cliffs
	"camp": "the miners' camp is straight up the hollow road from ashvale's north road", "gault": "gault's the foreman at the miners' camp. well, he was",
	"bram": "bram cooks at the miners' camp, sells food too", "vale": "sister vale is at the miners' camp by the tents", "hux": "hux the quartermaster is at the camp, he repairs",
	"bat": "bats are in the scree, west of the camp under the rocks", "scree": "the scree is west of the miners' camp",
	"maggot": "maggots are up in the upper tunnels, west and north of camp", "tunnel": "upper tunnels are north-west of the camp",
	"ore": "the ore veins have chalk marks, along lantern row and in the upper tunnels", "vein": "chalk-marked veins on lantern row and the upper tunnels",
	"skarr": "skarr's cut is east of the camp, he's the big one with the pick", "digger": "the diggers are at skarr's cut east of camp",
	"spider": "spiders are all along lantern row, the rails going north to the mine", "lantern": "lantern row is the old cart rails north of the camp",
	"grave": "the cairn field is way up north-west, stand by the headstones", "cairn": "cairn field is the high ground north-west",
	"rockjaw": "rockjaw's den is south-east of camp. elite bear, bring a friend", "bear": "bears are south-east of the camp, near rockjaw's den",
	"brak": "brak's past skarr's cut, elite. group up", "hollow mine": "the mine mouth is at the top of lantern row. need a group of 2+",
	"dungeon": "the hollow mine, top of lantern row. go with at least one other person", "bone king": "the bone king's at the very bottom of the mine. break the cages fast",
	"grub": "grub mother dives under the floor, get out of the ring when it shows up",
}


var rng := RandomNumberGenerator.new()
var llm_model := ""
var llm_busy := false
var general_t := 0.0             # keeps General from getting spammy
var pending_q := {}              # a question someone asked in General, for other bots to answer

func _ready() -> void:
	add_to_group("voice")
	rng.randomize()
	_probe_llm()

# ------------------------------------------------------------------ talking

## put a line in the chat window
func say(b: Bot, ch: String, to: Player, text: String) -> void:
	if text == "" or not is_instance_valid(b): return
	var chat := get_tree().get_first_node_in_group("chat")
	if chat == null: return
	match ch:
		"whisper": chat.post("whisper", b.uname, text)
		"general": chat.post("general", b.uname, text); general_t = 25.0
		"party": chat.post("party", b.uname, text)
		"emote": chat.post("system", "", "%s %s" % [b.uname, text])
		_: chat.post("say", b.uname, text)
	# questions in General get answered by someone who knows, sometimes
	if ch == "general" and text.ends_with("?"): pending_q = {"from": b, "text": text, "t": rng.randf_range(4.0, 14.0)}
	if ch == "general" and (text.begins_with("ding") or text.contains(" ding")):
		for other in _others(b, 2):
			var o: Bot = other
			_after(rng.randf_range(3.0, 10.0), func(): say(o, "general", null, _style(o, _pick(["grats", "gz", "grats!", "congrats", "gz " + b.uname.to_lower()]))))

func _process(delta: float) -> void:
	general_t = maxf(0.0, general_t - delta)
	if not pending_q.is_empty():
		pending_q["t"] -= delta
		if pending_q["t"] <= 0.0:
			var q: Dictionary = pending_q; pending_q = {}
			var ans := _fact(q["text"])
			if ans != "" and rng.randf() < 0.75:
				var others := _others(q["from"], 1)
				if not others.is_empty(): say(others[0], "general", null, _style(others[0], ans))

func _after(t: float, f: Callable) -> void:
	get_tree().create_timer(t).timeout.connect(f)

func _others(not_me: Node, n: int) -> Array:
	var all := get_tree().get_nodes_in_group("bots").filter(func(x): return x != not_me and not x.dead)
	all.shuffle()
	return all.slice(0, n)

func _pick(a: Array) -> String:
	return a[rng.randi() % a.size()]

## typing style: tidy players capitalise and punctuate, casual ones don't, terse ones cut it short
func _style(b: Bot, t: String) -> String:
	match b.style:
		"tidy":
			t = t.substr(0, 1).to_upper() + t.substr(1)
			if not (t.ends_with(".") or t.ends_with("?") or t.ends_with("!") or t.ends_with(")")): t += "."
			t = t.replace(" i ", " I ").replace("i'm", "I'm").replace("i'll", "I'll")
		"terse":
			t = t.to_lower().split(",")[0].split(". ")[0]
		"chatty":
			t = t.to_lower()
			if rng.randf() < 0.3: t += " " + _pick(["haha", ":)", "lol", "tbh", "anyway"])
		_:
			t = t.to_lower().trim_suffix(".")
			if rng.randf() < 0.1 and t.length() > 6:
				# a typo now and then
				var i := rng.randi_range(1, t.length() - 2)
				t = t.substr(0, i) + t.substr(i + 1, 1) + t.substr(i, 1) + t.substr(i + 2)
	return t

# ------------------------------------------------------------------ things that happen to bots

func event(b: Bot, kind: String, info := {}) -> void:
	match kind:
		"ding":
			if rng.randf() < 0.7 and general_t <= 0.0:
				say(b, "general", null, _style(b, _pick(["ding", "ding!", "ding %d" % info["level"], "finally %d" % info["level"], "ding %d :)" % info["level"]])))
			elif b.party_with: say(b, "party", null, _style(b, "ding!"))
		"died":
			if b.party_with: say(b, "party", null, _style(b, _pick(["sorry, died", "oops", "rip me", "brb running back"])))
			elif rng.randf() < 0.4 and general_t <= 0.0:
				say(b, "general", null, _style(b, _pick(["ugh, died again", "these %s hit hard" % _what(b.brain.task), "rip", "why is everything so angry today"])))
		"near":
			if rng.randf() < 0.5: say(b, "emote", null, _pick(["waves at %s." % info["who"], "nods at %s." % info["who"], "bows to %s." % info["who"]]))
			else: say(b, "say", null, _style(b, _pick(["hi", "hey", "o/", "hello", "evening", "hey there"])))
		"joined":
			say(b, "party", null, _style(b, _pick(["hey! where to?", "sure, lead the way", "hi! what are you on?", "ok, i'll follow you"])))
		"idle":
			if general_t > 0.0 or b.party_with: return
			var t: String = info.get("task", "")
			var line := ""
			var r := rng.randf()
			if t.begins_with("looking for") and r < 0.6:
				line = _pick(["anyone seen %s?" % _what(t), "where do %s spawn?" % _what(t), "been looking for %s forever, where are they?" % _what(t), "where are the %s?" % _what(t)])

			elif (t.contains("Hogtooth") or (b.level >= 8 and "hogtooth" in b.quests)) and r < 0.8:
				line = _pick(["lfg hogtooth", "anyone want to do hogtooth?", "need 1-2 for hogtooth, /w me"])
			elif WorldData.zone_id == "hollow" and b.level >= 13 and r < 0.35:
				line = _pick(["lfg hollow mine", "LF1M hollow mine, need heals", "anyone for the mine? /w me", "lf tank for the mine", "rockjaw anyone?"])
			elif WorldData.zone_id == "hollow" and r < 0.3:
				line = _pick(["these bats are relentless", "where's the chalk ore, i can't find the last one", "bram's stew is actually good??", "anyone seen gault?", "the view from the cairn field is amazing"])

			elif r < 0.35: line = _pick(["this music is so nice", "the mill at sunset though", "anyone know if grom sells better swords?", "wts boar hides, cheap", "lol the scarecrows in the west field",
				"is it just me or are the boars everywhere", "where do people sell junk?", "how do talents work? do i get them at 10?", "anyone else get lost looking for the split oak",
				"orrin talks a lot huh", "bess's stew is op", "love this zone"])
			elif t != "" and r < 0.55: line = _pick(["%s is taking forever" % t.to_lower(), "doing %s, anyone else on it?" % t.to_lower()])
			if line != "": say(b, "general", null, _style(b, line))

## the thing a task is about ("looking for field_rat" -> "field rats")
func _what(t: String) -> String:
	var w := t.trim_prefix("looking for ").trim_prefix("hunting").replace("_", " ").strip_edges()
	if w == "": return "monsters"
	for k in Monster.KINDS:
		if t.contains(k): return str(Monster.KINDS[k]["names"][0]).to_lower() + "s"
	return w

# ------------------------------------------------------------------ you talking to bots

func heard(b: Bot, ch: String, from: Player, text: String) -> void:
	var low := text.to_lower()
	var mentioned := low.contains(b.uname.to_lower())
	# in General only a question, or someone named, gets an answer, and only from one bot
	if ch == "general":
		# a hello in General gets a hello or two back
		if _has(low, ["hi all", "hello all", "hey all", "hi everyone", "hello everyone", "hey everyone", "evening all", "morning all"]) or low.strip_edges() in ["hi", "hello", "hey", "yo"]:
			if rng.randf() < 0.25: _after(rng.randf_range(2.0, 9.0), func(): say(b, "general", null, _style(b, _pick(["hi", "hey", "o/", "hello", "hiya", "evening"]))))
			return
		if not (low.contains("?") or mentioned or low.begins_with("lfg") or low.contains("anyone")): return

		if not mentioned and (b != _chosen(from, text) ): return
	var reply_ch := "whisper" if ch == "whisper" else ch
	var delay := rng.randf_range(1.5, 3.0) + text.length() * 0.03
	if llm_model != "" and not llm_busy:
		_llm_reply(b, reply_ch, from, text, delay)
		return
	var ans := _rule_reply(b, ch, from, low)
	if ans != "": _after(delay + ans.length() * 0.05, func(): say(b, reply_ch, from, _style(b, ans)))

var _chosen_for := ""
var _chosen_bot: Bot
func _chosen(from: Player, text: String) -> Bot:
	if _chosen_for != text:
		_chosen_for = text
		var all := get_tree().get_nodes_in_group("bots")
		_chosen_bot = all[rng.randi() % all.size()] if not all.is_empty() else null
	return _chosen_bot

var _rx := {}
func _fact(low: String) -> String:
	low = " " + low.to_lower() + " "
	var best := ""
	for k in PLACES:
		# whole words only (so "then" isn't a hen, and "more" isn't ore); plurals are fine; the most specific wins
		if not _rx.has(k): var r := RegEx.new(); r.compile("[^a-z']" + k + "(s|es)?[^a-z]"); _rx[k] = r
		if k.length() > best.length() and _rx[k].search(low): best = k
	return PLACES[best] if best != "" else ""

## what a bot is doing, the way a person would say it
func _doing(b: Bot) -> String:
	var t: String = b.brain.task
	if t == "" or t == "idle": return "just hanging around"
	if t.begins_with("looking for") or t == "hunting": return "hunting %s" % _what(t)
	if t.begins_with("picking up") or t.begins_with("handing in"): return t.to_lower()
	if t in ["eating", "drinking", "resting", "backing off to rest"]: return "taking a breather"
	if t.begins_with("back from"): return "running back from the graveyard lol"
	return "doing %s" % t.to_lower()


func _rule_reply(b: Bot, ch: String, from: Player, low: String) -> String:
	var fact := _fact(low)
	if ch == "party" and b.party_with == from:
		if _has(low, ["where", "what now", "what next", "go"]): return _pick(["your call", "wherever you want, i'll follow", "you lead", "i still need %s if you're going that way" % _what(b.brain.task)])
		if _has(low, ["thank", "ty", "thx"]): return _pick(["np!", "anytime", ":)"])
		if _has(low, ["ready", "rdy"]): return _pick(["ready", "rdy", "yep"])
		if _has(low, ["wait", "brb", "sec"]): return _pick(["np", "k", "sure"])
		if _has(low, ["pull", "go go", "lets go", "let's go"]): return _pick(["go", "ok!", "right behind you"])
	if _has(low, ["how are you", "how's it going", "hows it going", "how r u", "how you doing"]): return _pick(["good! %s" % _doing(b), "not bad, you?", "tired but ok lol", "good, levelling slowly"])
	if _has(low, ["what are you doing", "wyd", "what you up to", "what r u doing", "what are you up to"]): return _doing(b)

	if (low.contains("where") or low.contains("how do i find") or low.contains("anyone seen")) and fact != "": return fact
	if _has(low, ["invite", "group", "party", "join", "lfg", "help me", "need help", "wanna quest", "want to quest"]):
		if b.party_with == from: return "i'm already with you"
		if absi(from.level - b.level) > 4: return "i'd love to but i'm level %d, we'd be a bit far apart" % b.level
		return _pick(["sure, invite me", "yeah send an invite", "ok! /invite %s" % b.uname.to_lower(), "sure why not"])
	if _has(low, ["hello", "hi ", "hey", "yo ", "sup", "o/", "evening", "morning"]) or low in ["hi", "yo", "hey"]:
		return _pick(["hey", "hi!", "hello", "o/", "hey, how's it going?", "hiya"])
	if _has(low, ["thank", "ty", "thx", "cheers"]): return _pick(["np", "no problem", "anytime", "np :)"])

	if _has(low, ["level", "lvl"]): return "%d %s" % [b.level, Rules.CLASSES[b.cls]["name"].to_lower()]
	if _has(low, ["bye", "cya", "see you", "gn", "good night"]): return _pick(["cya", "bye!", "see ya", "night!"])
	if _has(low, ["lol", "haha", "lmao"]): return _pick([":)", "haha", "", ""])
	if _has(low, ["talent"]): return "you get your first talent point at 10, press N"
	if _has(low, ["gold", "money"]): return _pick(["sell your greys to a vendor", "quests pay best early on", "i'm broke too lol"])
	if _has(low, ["class", "best class"]): return "i like %s, it's fun" % Rules.CLASSES[b.cls]["name"].to_lower()
	if fact != "": return fact
	if ch == "whisper" or ch == "party": return _pick(["hm?", "not sure tbh", "haha yeah", "sorry, what?", "maybe? no idea"])
	return ""

func _has(low: String, words: Array) -> bool:
	for w in words:
		if low.contains(w): return true
	return false

# ------------------------------------------------------------------ a local language model (optional)

func _probe_llm() -> void:
	if OS.get_environment("ASHVALE_LLM") == "off": return
	var h := HTTPRequest.new(); h.timeout = 2.0; add_child(h)
	h.request_completed.connect(func(result, code, _hdr, body):
		h.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200: return
		var d = JSON.parse_string(body.get_string_from_utf8())
		if typeof(d) != TYPE_DICTIONARY: return
		var want := OS.get_environment("ASHVALE_LLM")
		for m in d.get("models", []):
			var nm: String = m.get("name", "")
			if want != "" and nm.begins_with(want): llm_model = nm; break
			if want == "" and llm_model == "" and not nm.contains("embed"): llm_model = nm
		if llm_model != "": print("chat: using local model ", llm_model))
	if h.request(OLLAMA + "/api/tags") != OK: h.queue_free()

func _llm_reply(b: Bot, ch: String, from: Player, text: String, delay: float) -> void:
	llm_busy = true
	var facts := "; ".join(PLACES.values().slice(0, 30))
	var sys := ("You are %s, a level %d %s playing the online fantasy game Ashvale Online. You are a real person typing in the game's chat. " +
		"Write ONE short chat message (under 20 words), casual, %s. No emojis, no quotation marks, no roleplay voice, never say you are an AI or a bot. " +
		"Right now you are %s. Facts about the world you know: %s.") % [b.uname, b.level, Rules.CLASSES[b.cls]["name"], {"tidy": "with proper capitals", "terse": "very short", "chatty": "friendly and a bit rambling"}.get(b.style, "mostly lowercase"),
		b.brain.task.to_lower() if b.brain.task != "" else "wandering around", facts]
	var body := JSON.stringify({"model": llm_model, "stream": false, "options": {"temperature": 0.8, "num_predict": 48},
		"messages": [{"role": "system", "content": sys}, {"role": "user", "content": "[%s] %s: %s" % [ch, from.uname, text]}]})
	var h := HTTPRequest.new(); h.timeout = 12.0; add_child(h)
	var t0 := Time.get_ticks_msec()
	h.request_completed.connect(func(result, code, _hdr, resp):
		h.queue_free(); llm_busy = false
		var out := ""
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var d = JSON.parse_string(resp.get_string_from_utf8())
			if typeof(d) == TYPE_DICTIONARY: out = String(d.get("message", {}).get("content", "")).strip_edges().replace("\"", "").split("\n")[0]
		if out == "": out = _style(b, _rule_reply(b, ch, from, text.to_lower()))
		var wait := maxf(0.0, delay - (Time.get_ticks_msec() - t0) / 1000.0)
		_after(wait + 0.1, func(): say(b, ch, from, out)))
	if h.request(OLLAMA + "/api/chat", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body) != OK:
		h.queue_free(); llm_busy = false
