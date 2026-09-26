class_name Quests
## Every quest, WoW style: a giver with a reason, an objective you can read in one line, a little
## flavour, and rewards (experience, money, an item or a choice of items, reputation).
## Text for Ashvale Province is from docs/QUESTS.md (part B), which is the model for every zone.
##
## objective kinds: talk {npc} · kill {mon, n} · collect {item, n, from: [monster kinds], chance} ·
##                  explore {at, r, name} · gather {item, n} (things to pick up off the ground)
## money is in copper (100 copper = 1 silver).

const LIST := {
	# ================================================================ Hub 1 — Ashvale town
	"word_with_elder": {"title": "A Word with the Elder", "giver": "rowan", "ender": "bess", "level": 1, "min": 1, "chain": "Welcome",
		"offer": "Welcome to Ashvale. You've the look of someone who wants to be useful. Good — we're short of those. Go and see Bess at the inn before you do anything else; she feeds everyone who lifts a sword for this town, and she'll want to know your name.",
		"goal": "Speak to Bess at the inn.",
		"done": "So you're the new one. Rowan sends me all the strays. Sit, eat — then we'll talk about rats.",
		"obj": [{"kind": "talk", "npc": "bess"}], "xp": 60, "items": ["warm_meal"], "rep": 25},
	"pests_in_fields": {"title": "Pests in the Fields", "giver": "bess", "level": 1, "min": 1, "after": ["word_with_elder"],
		"offer": "Rats in the grain again. Big ones. If I feed you, you kill rats — that's the deal in this inn. They're in the fields behind the well; mind the hens, they're not the problem.",
		"goal": "Kill 8 Field Rats in the fields behind the well.",
		"progress": "Still rats in my grain, love.", "done": "Eight. I counted. You'll do.",
		"obj": [{"kind": "kill", "mon": "field_rat", "n": 8}], "xp": 90, "money": 300, "rep": 25, "where": "the fields west of the square, behind the well"},
	"hen_feathers": {"title": "Hen Feathers", "giver": "orrin", "level": 1, "min": 1, "after": ["word_with_elder"],
		"offer": "I'm writing a history of Ashvale. It needs a quill. It needs, in fact, several quills, because I press too hard. The hens by the fountain shed plenty — bring me six good ones. Don't hurt them more than necessary.",
		"goal": "Bring Sage Orrin 6 Hen Feathers.",
		"progress": "Quills don't grow on trees. Well. They grow on hens.", "done": "Splendid! Chapter one can begin. Take this — ink's worth more than it looks.",
		"obj": [{"kind": "collect", "item": "hen_feather", "n": 6, "from": ["hen"], "chance": 0.8}], "xp": 80, "items": ["sages_ink"], "rep": 25, "where": "around the fountain in the square"},
	"blacksmiths_wager": {"title": "The Blacksmith's Wager", "giver": "grom", "level": 2, "min": 1, "after": ["word_with_elder"],
		"offer": "Old Hale's scarecrows have come alive again — bad thread, I said, use good thread. Knock six of them down and I'll sharpen that toothpick you're carrying properly.",
		"goal": "Knock down 6 Walking Scarecrows in the west fields.",
		"progress": "Still standing, are they? The scarecrows, I mean.", "done": "Ha! Good thread, bad thread, it all burns. Here, I kept my word.",
		"obj": [{"kind": "kill", "mon": "scarecrow", "n": 6}], "xp": 120, "choice": ["sharpened_sword", "ashwood_wand"], "rep": 25, "where": "the west fields along the old road"},
	"grizzled_rat": {"title": "Grizzled Rat", "giver": "bess", "level": 3, "min": 2, "after": ["pests_in_fields"],
		"offer": "There's one rat the others answer to. Big as a dog, ugly as sin, lives under the granary. Deal with it and the rest will thin out on their own.",
		"goal": "Kill the Grizzled Rat under the granary.",
		"progress": "Is it dead? Tell me it's dead.", "done": "Dead? Good. I'll sleep tonight. Here — it was my husband's, back when he chased rats himself.",
		"obj": [{"kind": "kill", "mon": "grizzled_rat", "n": 1}], "xp": 150, "items": ["rat_catcher_cap"], "rep": 50, "where": "by the granary, north of the square"},
	"road_to_mill": {"title": "The Road to the Mill", "giver": "rowan", "ender": "hale", "level": 4, "min": 3, "after": ["pests_in_fields", "blacksmiths_wager"], "chain": "Welcome",
		"offer": "Farmer Hale at the Mill has been sending word for a week and I've had nobody to send. You'll do. Follow the east road past the fountain; it's safe as far as the fence. Give him this and tell him the fence is his problem.",
		"goal": "Take Rowan's Letter to Farmer Hale at the Mill.",
		"done": "A letter. From Rowan. About the fence. The fence.", "provide": ["rowans_letter"],
		"obj": [{"kind": "talk", "npc": "hale", "take": "rowans_letter"}], "xp": 140, "rep": 25, "where": "the Mill, along the east road"},
	# ================================================================ Hub 2 — the Mill
	"fence_can_wait": {"title": "The Fence Can Wait", "giver": "hale", "level": 4, "min": 3, "after": ["road_to_mill"], "chain": "Welcome",
		"offer": "There are boars in my beet field the size of carts and he writes about the fence. Right. Here's what I actually need: the boars gone, my brother found, and someone to look at what's rooting around the old shrine at night. Go and talk to Tomas, Wren and Captain Ada — they'll tell you the rest.",
		"goal": "Speak to Tomas, Wren the hunter and Guard Captain Ada at the Mill.",
		"done": "Right. Now you know everything I know, which is too much.",
		"obj": [{"kind": "talk", "npc": "tomas"}, {"kind": "talk", "npc": "wren"}, {"kind": "talk", "npc": "ada"}], "xp": 100, "rep": 25},
	"beet_thieves": {"title": "Beet Thieves", "giver": "hale", "level": 4, "min": 3, "after": ["fence_can_wait"],
		"offer": "Ten of them. I'd say more but I'd like you to come back.",
		"goal": "Kill 10 Wild Boars in the south fields.",
		"progress": "I can still hear them chewing.", "done": "Ten! My beets thank you. My wife thanks you. I thank you, mostly.",
		"obj": [{"kind": "kill", "mon": "wild_boar", "n": 10}], "xp": 200, "money": 600, "rep": 25, "where": "the fields south of the Mill"},
	"boar_hides": {"title": "Boar Hides", "giver": "tomas", "level": 4, "min": 3, "after": ["fence_can_wait"],
		"offer": "Hale won't let me near the boars since the thing with my leg. Bring me hides and I'll tan them. Bring me a lot of hides and I'll make you something.",
		"goal": "Bring Tomas 6 Boar Hides.",
		"progress": "Hides, friend. Hides.", "done": "Good hides, these. Here's a belt — first one I've made that didn't fall apart.",
		"obj": [{"kind": "collect", "item": "boar_hide", "n": 6, "from": ["wild_boar"], "chance": 0.7}], "xp": 160, "items": ["tanned_belt"], "rep": 25, "where": "the fields south of the Mill"},
	"something_in_woods": {"title": "Something in the Woods", "giver": "wren", "level": 6, "min": 5, "after": ["fence_can_wait"],
		"offer": "Wildcats have come down from the eastern woods. Bold ones. They took a lamb from the pen in daylight. I'll pay for eight — and if you see one with a torn ear, come and tell me.",
		"goal": "Kill 8 Wildcats at the edge of the eastern woods.",
		"progress": "Still hear them at night.", "done": "Eight. Good work. And the one with the torn ear? Thought not. Take one of these.",
		"obj": [{"kind": "kill", "mon": "wildcat", "n": 8}], "xp": 220, "choice": ["hunter_bracers", "woodland_sash"], "rep": 25, "where": "the edge of the eastern woods"},
	"lost_lamb": {"title": "Lost Lamb", "giver": "wren", "level": 6, "min": 5, "after": ["fence_can_wait"],
		"offer": "That lamb's still out there, bleating. Follow the sound past the split oak. Bring it back or bring me the bell, I'll know which.",
		"goal": "Find the lost lamb past the split oak and bring back its bell.",
		"done": "Well. That's one good thing today.",
		"obj": [{"kind": "gather", "item": "lamb_bell", "n": 1}], "xp": 180, "rep": 50, "where": "past the split oak, east of the Mill"},
	"old_scratch": {"title": "Old Scratch", "giver": "wren", "level": 7, "min": 6, "after": ["something_in_woods"],
		"offer": "Torn ear. Bigger than the rest. That's Old Scratch — he's the one bringing them down. He dens in the hollow oak. Take a friend if you've one.",
		"goal": "Kill Old Scratch at the hollow oak.",
		"progress": "He's clever, that one.", "done": "You got him. You actually got him. Keep the claw — it'll bring you luck, or at least a good price.",
		"obj": [{"kind": "kill", "mon": "old_scratch", "n": 1}], "xp": 300, "items": ["scratch_claw"], "rep": 50, "where": "the hollow oak in the eastern woods"},
	"night_at_shrine": {"title": "Night at the Shrine", "giver": "ada", "level": 6, "min": 5, "after": ["fence_can_wait"], "chain": "The Shrine",
		"offer": "Lights at the old shrine after dark, and my men won't go. Go and look. Just look — I want to know what it is before I lose anyone to it.",
		"goal": "Find out what is happening at the old shrine to the north-east.",
		"done": "Bones. Walking bones. I was hoping for smugglers.",
		"obj": [{"kind": "explore", "at": [72, -84], "r": 10.0, "name": "the Old Shrine"}], "xp": 200, "rep": 25, "where": "the old shrine, north-east of the Mill"},
	"bones_dont_walk": {"title": "Bones Don't Walk", "giver": "ada", "level": 7, "min": 6, "after": ["night_at_shrine"], "chain": "The Shrine",
		"offer": "Bones. Walking. Then someone made them walk. Put them down, and bring me anything on them that isn't bone.",
		"goal": "Destroy 8 Restless Bones at the shrine and bring back what they carry.",
		"progress": "Anything? Anything at all?", "done": "A token. From the mine. Well, well.",
		"obj": [{"kind": "kill", "mon": "restless_bones", "n": 8}, {"kind": "collect", "item": "grave_token", "n": 1, "from": ["restless_bones"], "chance": 0.25}],
		"xp": 260, "choice": ["militia_bracer", "warding_charm"], "rep": 50, "where": "the shrine grounds"},
	"miners_mark": {"title": "The Miner's Mark", "giver": "ada", "level": 8, "min": 7, "after": ["bones_dont_walk"], "chain": "The Shrine",
		"offer": "This token's from the Hollow Mine — the Miners' Guild stamps everything. Someone's digging where they shouldn't. Take it to Foreman Gault at the Miners' Camp, north road past the shrine. Tell him Ada sent you, and tell him he owes me.",
		"goal": "Take the Grave Token to Foreman Gault at the Miners' Camp (the road north). [Opens with the next zone]",
		"done": "", "obj": [{"kind": "talk", "npc": "gault", "take": "grave_token"}], "xp": 320, "rep": 75},
	"hogtooth": {"title": "Hogtooth, the Boar King", "group": true, "giver": "hale", "level": 9, "min": 7, "after": ["beet_thieves"],
		"offer": "You want to know why there are so many boars? Hogtooth. Tusks like ploughshares. He's out by the eastern woods and he's killed two dogs and a mule. I wouldn't go alone. I wouldn't go at all, but that's me.",
		"goal": "Kill Hogtooth, the Boar King, near the eastern woods. (Group)",
		"progress": "Still alive, isn't he. I can tell by the beets.", "done": "The Boar King! Dead! I'm going to tell everyone I helped.",
		"obj": [{"kind": "kill", "mon": "hogtooth", "n": 1}], "xp": 500, "choice": ["boar_king_tusk", "hogtooth_vest", "ploughshare_ring"], "rep": 150, "where": "the eastern woods, south of the hollow oak"},
	"rowans_history": {"title": "Rowan's History", "giver": "orrin", "level": 8, "min": 6, "after": ["night_at_shrine"],
		"offer": "The shrine! Nobody's been in a decade. Bring me anything old — coins, tokens, a nice bit of pot — and I'll put you in the history. A footnote, but still.",
		"goal": "Pick up 5 Old Coins at the old shrine for Sage Orrin.",
		"progress": "Old things, from old places.", "done": "Marvellous. You, my friend, are now a footnote. Wear it with pride.",
		"obj": [{"kind": "gather", "item": "old_coin", "n": 5}], "xp": 200, "title_reward": "the Footnote", "rep": 25, "where": "the old shrine"},
}

## how much experience a quest gives at your level (WoW: much less once it's grey to you)
static func xp_for(id: String, level: int) -> int:
	var q: Dictionary = LIST[id]
	var x := int(q.get("xp", 0))
	var d := level - int(q.get("level", 1))
	if d >= 5: return int(x * 0.2)
	if d >= 3: return int(x * 0.6)
	return x

static func objective_text(o: Dictionary, have: int) -> String:
	match o["kind"]:
		"talk": return "Speak to %s" % Npcs.LIST.get(o["npc"], {}).get("name", o["npc"])
		"kill": return "%s slain: %d/%d" % [_mon_name(o["mon"]), mini(have, o["n"]), o["n"]]
		"collect", "gather": return "%s: %d/%d" % [Items.LIST.get(o["item"], {}).get("name", o["item"]), mini(have, o["n"]), o["n"]]
		"explore": return "Find %s%s" % [o.get("name", "the place"), " (done)" if have >= 1 else ""]
	return "?"

static func _mon_name(k: String) -> String:
	if k == "restless_bones": return "Restless Bones"
	var d: Dictionary = Monster.KINDS.get(k, {})
	var names: Array = d.get("names", [k])
	return names[0]
