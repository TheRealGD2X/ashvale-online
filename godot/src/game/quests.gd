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
	"something_in_woods": {"title": "Something in the Woods", "giver": "wren", "level": 5, "min": 4, "after": ["fence_can_wait"],
		"offer": "Wildcats have come down from the eastern woods. Bold ones. They took a lamb from the pen in daylight. I'll pay for eight — and if you see one with a torn ear, come and tell me.",
		"goal": "Kill 8 Wildcats at the edge of the eastern woods.",
		"progress": "Still hear them at night.", "done": "Eight. Good work. And the one with the torn ear? Thought not. Take one of these.",
		"obj": [{"kind": "kill", "mon": "wildcat", "n": 8}], "xp": 220, "choice": ["hunter_bracers", "woodland_sash"], "rep": 25, "where": "the edge of the eastern woods"},
	"lost_lamb": {"title": "Lost Lamb", "giver": "wren", "level": 5, "min": 4, "after": ["fence_can_wait"],
		"offer": "That lamb's still out there, bleating. Follow the sound past the split oak. Bring it back or bring me the bell, I'll know which.",
		"goal": "Find the lost lamb past the split oak and bring back its bell.",
		"done": "Well. That's one good thing today.",
		"obj": [{"kind": "gather", "item": "lamb_bell", "n": 1}], "xp": 180, "rep": 50, "where": "past the split oak, east of the Mill"},
	"old_scratch": {"title": "Old Scratch", "giver": "wren", "level": 7, "min": 6, "after": ["something_in_woods"],
		"offer": "Torn ear. Bigger than the rest. That's Old Scratch — he's the one bringing them down. He dens in the hollow oak. Take a friend if you've one.",
		"goal": "Kill Old Scratch at the hollow oak.",
		"progress": "He's clever, that one.", "done": "You got him. You actually got him. Keep the claw — it'll bring you luck, or at least a good price.",
		"obj": [{"kind": "kill", "mon": "old_scratch", "n": 1}], "xp": 300, "items": ["scratch_claw"], "rep": 50, "where": "the hollow oak in the eastern woods"},
	"night_at_shrine": {"title": "Night at the Shrine", "giver": "ada", "level": 5, "min": 4, "after": ["fence_can_wait"], "chain": "The Shrine",
		"offer": "Lights at the old shrine after dark, and my men won't go. Go and look. Just look — I want to know what it is before I lose anyone to it.",
		"goal": "Find out what is happening at the old shrine to the north-east.",
		"done": "Bones. Walking bones. I was hoping for smugglers.",
		"obj": [{"kind": "explore", "at": [72, -84], "r": 20.0, "name": "the Old Shrine", "spawn": ["skeleton_a", 2, 6]}]
, "xp": 200, "rep": 25, "where": "the old shrine, north-east of the Mill"},
	"bones_dont_walk": {"title": "Bones Don't Walk", "giver": "ada", "level": 7, "min": 6, "after": ["night_at_shrine"], "chain": "The Shrine",
		"offer": "Bones. Walking. Then someone made them walk. Put them down, and bring me anything on them that isn't bone.",
		"goal": "Destroy 8 Restless Bones at the shrine and bring back what they carry.",
		"progress": "Anything? Anything at all?", "done": "A token. From the mine. Well, well.",
		"obj": [{"kind": "kill", "mon": "restless_bones", "n": 8}, {"kind": "collect", "item": "grave_token", "n": 1, "from": ["restless_bones"], "chance": 0.2, "sure_after": 0}],

		"xp": 260, "choice": ["militia_bracer", "warding_charm"], "rep": 50, "where": "the shrine grounds"},
	"miners_mark": {"title": "The Miner's Mark", "giver": "ada", "level": 8, "min": 7, "after": ["bones_dont_walk"], "chain": "The Shrine",
		"offer": "This token's from the Hollow Mine — the Miners' Guild stamps everything. Someone's digging where they shouldn't. Take it to Foreman Gault at the Miners' Camp, north road past the shrine. Tell him Ada sent you, and tell him he owes me.",
		"goal": "Take the Grave Token to Foreman Gault at the Miners' Camp, up the north road past the wolves.",
		"ender": "gault", "done": "Ada sent you? Then she's worried, and Ada doesn't worry. That's our mark, all right. Stamped last month. Nobody's been down the old shafts since the rockfall... nobody who told me.",
		"obj": [{"kind": "talk", "npc": "gault", "take": "grave_token"}], "xp": 320, "rep": 75, "where": "the Miners' Camp, north up the Hollow Road"},
	"hogtooth": {"title": "Hogtooth, the Boar King", "group": true, "giver": "hale", "level": 9, "min": 7, "after": ["beet_thieves"],
		"offer": "You want to know why there are so many boars? Hogtooth. Tusks like ploughshares. He's out by the eastern woods and he's killed two dogs and a mule. I wouldn't go alone. I wouldn't go at all, but that's me.",
		"goal": "Kill Hogtooth, the Boar King, near the eastern woods. (Group)",
		"progress": "Still alive, isn't he. I can tell by the beets.", "done": "The Boar King! Dead! I'm going to tell everyone I helped.",
		"obj": [{"kind": "kill", "mon": "hogtooth", "n": 1}], "xp": 500, "choice": ["boar_king_tusk", "hogtooth_vest", "ploughshare_ring"], "rep": 150, "where": "the eastern woods, south of the hollow oak"},
	# ================================================================ Hub 3 — the Miners' Camp (10–16)
	"tokens_and_trouble": {"title": "Tokens and Trouble", "giver": "gault", "level": 10, "min": 9, "after": ["miners_mark"], "chain": "The Foreman",
		"offer": "Bats. Thousands of them, since the rockfall opened the Scree. They get in the lamps, they get in the stew, they got in Bram's hat and he hasn't been right since. Clear ten out of the Scree, west of camp, and I'll start taking you seriously.",
		"goal": "Kill 10 Cave Bats in the Scree, west of the camp.",
		"progress": "I can still hear them.", "done": "Ten. Good. You can swing a thing. Here — buy yourself something that doesn't smell of guano.",
		"obj": [{"kind": "kill", "mon": "cave_bat", "n": 10}], "xp": 420, "money": 900, "rep": 50, "where": "the Scree, west of the Miners' Camp"},
	"digging_where": {"title": "Digging Where They Shouldn't", "giver": "gault", "level": 11, "min": 10, "after": ["tokens_and_trouble"], "chain": "The Foreman",
		"offer": "Someone's been cutting black iron out of the old veins and it isn't my crews. I've marked the veins with chalk along Lantern Row and in the Upper Tunnels. Bring me eight pieces of what's left before it all walks off.",
		"goal": "Gather 8 Black Iron Ore from the chalk-marked veins on Lantern Row and in the Upper Tunnels.",
		"progress": "Eight. Black. Iron. Not rocks painted black, I've had that.", "done": "That's guild ore, cut with guild tools. Somebody inside the camp is selling us out. Keep that to yourself.",
		"obj": [{"kind": "gather", "item": "black_iron_ore", "n": 8}], "xp": 460, "choice": ["foremans_gauntlets", "lantern_row_cord"], "rep": 50, "where": "Lantern Row (north) and the Upper Tunnels (west)"},
	"foremans_key": {"title": "The Foreman's Key", "giver": "gault", "level": 13, "min": 12, "after": ["digging_where"], "chain": "The Foreman",
		"offer": "Skarr. Deep Foreman Skarr, who I sacked a year ago, has set up in the cut east of camp with a crew of diggers who used to be mine. He has the key to the old shafts. I want it. I want it more than I want him, and I want him a great deal.",
		"goal": "Kill Deep Foreman Skarr at Skarr's Cut and bring Gault Skarr's Key.",
		"progress": "The key. Have you got the key?", "done": "...That's it. That's the key to the Hollow. Leave it with me. You've done well. Get some rest.",
		"obj": [{"kind": "kill", "mon": "skarr", "n": 1}, {"kind": "collect", "item": "skarrs_key", "n": 1, "from": ["skarr"], "chance": 1.0}], "xp": 620, "money": 1500, "choice": ["diggers_pick", "cairn_warden_boots"], "rep": 75, "where": "Skarr's Cut, east of the camp"},
	"wheres_gault": {"title": "Where's Gault?", "giver": "hux", "ender": "vale", "level": 14, "min": 13, "after": ["foremans_key"], "chain": "The Foreman",
		"offer": "Have you seen the foreman? Took a lantern and your key and went up Lantern Row an hour ago. Said not to follow. Sister Vale was up at the cairns; she might have seen which way he went. I don't like it.",
		"goal": "Ask Sister Vale if she saw where Foreman Gault went.",
		"done": "I saw him. He went into the Hollow, and he wasn't alone, though I couldn't see who walked beside him. There's something under this mountain that has been whispering to the diggers for a year. I think Gault listened.",
		"obj": [{"kind": "talk", "npc": "vale"}], "xp": 300, "rep": 25},
	"into_the_hollow": {"title": "Into the Hollow", "giver": "vale", "level": 16, "min": 13, "after": ["wheres_gault"], "chain": "The Foreman", "group": true, "dungeon": "mine",
		"offer": "The mine mouth is at the top of Lantern Row. Don't go alone — find at least one other soul. Stop Foreman Gault if you can, and whatever sits in the deepest hall, put it back in the ground. It calls itself a king.",
		"goal": "In the Hollow Mine, defeat Foreman Gault and the Bone King. (Dungeon: group of 2 or more)",
		"progress": "You're back. Is it done?", "done": "Gault's dead, then. He was a good foreman, once. The mountain's quieter already — can you hear it? Take this, and thank you. The camp won't forget.",
		"obj": [{"kind": "kill", "mon": "gault", "n": 1}, {"kind": "kill", "mon": "bone_king", "n": 1}], "xp": 1600, "money": 3500, "choice": ["vale_prayer_beads", "enforcers_ring", "rockjaw_hide_cloak"], "rep": 250, "where": "the Hollow Mine, at the top of Lantern Row"},
	"maggot_stew": {"title": "Maggot Stew", "giver": "bram", "level": 11, "min": 10, "after": ["miners_mark"],
		"offer": "Don't make that face. Cave maggot's good eating if you boil it long enough and don't look at it. The Upper Tunnels, west and up. Eight good pieces. Big ones.",
		"goal": "Bring Bram 8 pieces of Maggot Meat from the Cave Maggots in the Upper Tunnels.",
		"progress": "Stew's not going to stew itself.", "done": "Look at that. Look at it. Tonight, we eat like foremen. Here, have a bowl on me. And these.",
		"obj": [{"kind": "collect", "item": "maggot_meat", "n": 8, "from": ["cave_maggot"], "chance": 0.75}], "xp": 440, "items": ["camp_cook_gloves"], "rep": 50, "where": "the Upper Tunnels, west of the camp"},
	"bear_took_pot": {"title": "The Bear Took My Pot", "giver": "bram", "level": 14, "min": 12, "after": ["maggot_stew"], "group": true,
		"offer": "Rockjaw. Big as a cart, bad as a debt collector. He came into camp, took my second-best pot, and walked off with it like he'd paid. South-east, in the den under the crag. Bring friends. Bring my pot.",
		"goal": "Kill Rockjaw in his den south-east of the camp. (Group)",
		"progress": "No pot, no stew.", "done": "My pot! A bit chewed. Still better than my first-best. Thank you — take this, he won't be needing it.",
		"obj": [{"kind": "kill", "mon": "rockjaw", "n": 1}], "xp": 760, "items": ["rockjaw_hide_cloak"], "rep": 75, "where": "Rockjaw's Den, south-east of the camp"},
	"rest_for_restless": {"title": "Rest for the Restless", "giver": "vale", "level": 12, "min": 11, "after": ["miners_mark"],
		"offer": "The miners who died in the rockfall are buried at the Cairn Field, up on the high ground north-west. Something has been disturbing them. Go and say the words over five of their graves — just stand by the stone and be still. I'll teach you the words. They're short.",
		"goal": "Bless 5 miners' graves at the Cairn Field, north-west of the camp.",
		"progress": "Did they rest?", "done": "Thank you. They were good people, most of them. The ones who weren't are resting too, now.",
		"obj": [{"kind": "gather", "item": "grave_blessing", "n": 5}], "xp": 480, "items": ["vale_prayer_beads"], "rep": 50, "where": "the Cairn Field, high up to the north-west"},
	"guild_business": {"title": "Guild Business", "giver": "hux", "level": 13, "min": 12, "after": ["miners_mark"],
		"offer": "Skarr's crews at the cut east of here are still digging in guild ground. Guild ground is guild business, and I'm the guild's business. Put eight of them down. Hard enough that they stay down.",
		"goal": "Defeat 8 Hollow Diggers at Skarr's Cut.",
		"progress": "The guild keeps count, you know.", "done": "Eight. Guild thanks you. Guild pays you, which is rarer.",
		"obj": [{"kind": "kill", "mon": "hollow_digger", "n": 8}], "xp": 520, "money": 1800, "rep": 50, "where": "Skarr's Cut, east of the camp"},
	"webs_on_rails": {"title": "Webs on the Rails", "giver": "hux", "level": 13, "min": 12, "after": ["guild_business"],
		"offer": "Lantern Row's full of spiders. The carts can't get through, and the lamp-lighter won't go up. Seven of them. Big ones count double, but I'm still paying for seven.",
		"goal": "Kill 7 Rail Spiders along Lantern Row, north of the camp.",
		"progress": "The lamp-lighter's still hiding in the tent.", "done": "Lantern Row's lit tonight for the first time in a month. That's your doing.",
		"obj": [{"kind": "kill", "mon": "rail_spider", "n": 7}], "xp": 540, "money": 1200, "rep": 50, "where": "Lantern Row, north of the camp"},
	"skarrs_enforcer": {"title": "Skarr's Enforcer", "giver": "hux", "level": 15, "min": 13, "after": ["foremans_key"], "group": true,
		"offer": "Skarr's dead but his enforcer isn't. Brak. Half man, half anvil, all temper. He's holed up past the cut, and the guild would like its cut back. Take friends; he's broken better folk than you.",
		"goal": "Defeat Brak, Skarr's Enforcer, beyond Skarr's Cut. (Group)",
		"progress": "Brak's still breathing. I can tell; the rocks are still shaking.", "done": "Brak down. The cut's ours again. Here — wear this and people will think twice.",
		"obj": [{"kind": "kill", "mon": "brak", "n": 1}], "xp": 800, "items": ["enforcers_ring"], "rep": 100, "where": "past Skarr's Cut, east"},
	"vales_letter": {"title": "A Letter for Mirewood", "giver": "vale", "level": 16, "min": 15, "after": ["into_the_hollow"], "chain": "The Road",
		"offer": "Warden Elsbeth at Mirewood Landing should hear about the Hollow from someone who was there. The Cliff Road east is washed out for now; when it opens, take her this.",
		"goal": "Take Sister Vale's letter to Warden Elsbeth at Mirewood Landing. [Mirewood opens in a later update]",
		"done": "", "provide": ["vales_letter"], "obj": [{"kind": "talk", "npc": "elsbeth", "take": "vales_letter"}], "xp": 400, "rep": 25},
	"old_tusk": {"title": "Old Tusk",
 "giver": "hale", "level": 10, "min": 8, "needs_item": "old_tusks_tusk",
		"offer": "Is that — you killed Old Tusk? The one from the stories? My father swore that boar ate a plough. Give it here, let me look at it.",
		"goal": "Show Old Tusk's tusk to Farmer Hale.",
		"done": "You killed Old Tusk? The one from the stories? Have a drink. Have two. And take this — it was meant for whoever did it.",
		"obj": [{"kind": "talk", "npc": "hale", "take": "old_tusks_tusk"}], "xp": 400, "items": ["tusk_blue"], "rep": 100},
	"rowans_history": {"title": "Rowan's History",
 "giver": "orrin", "level": 8, "min": 6, "after": ["night_at_shrine"],
		"offer": "The shrine! Nobody's been in a decade. Bring me anything old — coins, tokens, a nice bit of pot — and I'll put you in the history. A footnote, but still.",
		"goal": "Pick up 5 Old Coins at the old shrine for Sage Orrin.",
		"progress": "Old things, from old places.", "done": "Marvellous. You, my friend, are now a footnote. Wear it with pride.",
		"obj": [{"kind": "gather", "item": "old_coin", "n": 5}], "xp": 200, "title_reward": "the Footnote", "rep": 25, "where": "the old shrine"},
}

## how much experience a quest gives at your level (WoW: much less once it's grey to you)
static func xp_for(id: String, level: int) -> int:
	var q: Dictionary = LIST[id]
	# the numbers in the quest text are the document's; our experience curve wants about four times that
	var x := int(q.get("xp", 0)) * 4

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
