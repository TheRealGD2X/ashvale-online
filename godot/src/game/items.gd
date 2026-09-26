class_name Items
## Items, exactly in the World of Warcraft mould: quality colours, slots, armour types, item level,
## primary stats (Strength, Agility, Stamina, Intellect, Spirit) and a few secondaries, binding,
## and a sell price. What you wear shows on your character: every armour piece names the outfit
## part and colour variant it puts on the body.
##
## An item in a bag is a small dictionary:  {"id": "militia_chest", "n": 1}  plus, for random drops,
## the rolled "stats" and "name". Templates live in LIST; random greens are made by roll().

const QUALITY := [
	{"name": "Poor", "color": Color(0.62, 0.62, 0.62)},
	{"name": "Common", "color": Color(1.0, 1.0, 1.0)},
	{"name": "Uncommon", "color": Color(0.12, 1.0, 0.0)},
	{"name": "Rare", "color": Color(0.0, 0.44, 0.87)},
	{"name": "Epic", "color": Color(0.64, 0.21, 0.93)},
	{"name": "Legendary", "color": Color(1.0, 0.5, 0.0)},
]

## the paper doll, in the order the character sheet shows them
const SLOTS := ["head", "neck", "shoulders", "back", "chest", "wrist", "hands", "waist", "legs", "feet",
	"finger1", "finger2", "trinket1", "trinket2", "main_hand", "off_hand"]
const SLOT_NAMES := {"head": "Head", "neck": "Neck", "shoulders": "Shoulder", "back": "Back", "chest": "Chest", "wrist": "Wrist",
	"hands": "Hands", "waist": "Waist", "legs": "Legs", "feet": "Feet", "finger": "Finger", "trinket": "Trinket",
	"main_hand": "Main Hand", "off_hand": "Off Hand", "two_hand": "Two-Hand", "one_hand": "One-Hand"}
const STAT_NAMES := {"str": "Strength", "agi": "Agility", "sta": "Stamina", "int": "Intellect", "spi": "Spirit"}
const CAN_WEAR := {"warrior": ["cloth", "leather", "mail", "plate"], "wizard": ["cloth"], "cleric": ["cloth"]}
const WEAPONS := {"warrior": ["sword", "axe", "mace", "two_hand_sword", "two_hand_axe", "shield"], "wizard": ["staff", "wand", "dagger", "offhand"], "cleric": ["mace", "staff", "wand", "offhand"]}

## the outfit family each armour type is drawn with (see Avatar)
const LOOK_FAMILY := {"plate": "Knight", "mail": "Knight", "leather": "Ranger", "cloth": "Wizard"}

const LIST := {
	# ---------------------------------------------------------------- starting gear (level 1)
	"recruit_sword": {"name": "Recruit's Sword", "q": 1, "slot": "main_hand", "wtype": "sword", "ilvl": 2, "weapon": [3, 7, 2.4], "model": "sword", "sell": 8},
	"apprentice_staff": {"name": "Apprentice's Staff", "q": 1, "slot": "main_hand", "wtype": "staff", "ilvl": 2, "weapon": [3, 6, 2.9], "stats": {"int": 1}, "model": "staff", "sell": 8},
	"acolyte_mace": {"name": "Acolyte's Mace", "q": 1, "slot": "main_hand", "wtype": "mace", "ilvl": 2, "weapon": [3, 6, 2.6], "stats": {"spi": 1}, "model": "club", "sell": 8},
	"recruit_chest": {"name": "Recruit's Mail Vest", "q": 1, "slot": "chest", "armor_type": "mail", "ilvl": 1, "armor": 24, "look": ["Knight_Body_Armor", "Knight", 1], "sell": 4},
	"recruit_legs": {"name": "Recruit's Leggings", "q": 1, "slot": "legs", "armor_type": "mail", "ilvl": 1, "armor": 18, "look": ["Knight_Legs", "Knight", 1], "sell": 3},
	"recruit_boots": {"name": "Recruit's Boots", "q": 1, "slot": "feet", "armor_type": "mail", "ilvl": 1, "armor": 12, "look": ["Knight_Feet", "Knight", 1], "sell": 2},
	"recruit_gloves": {"name": "Recruit's Gauntlets", "q": 1, "slot": "hands", "armor_type": "mail", "ilvl": 1, "armor": 10, "look": ["Knight_Arms", "Knight", 1], "sell": 2},
	"apprentice_robe": {"name": "Apprentice's Robe", "q": 1, "slot": "chest", "armor_type": "cloth", "ilvl": 1, "armor": 6, "look": ["Wizard_Body", "Wizard", 1], "sell": 4},
	"apprentice_pants": {"name": "Apprentice's Trousers", "q": 1, "slot": "legs", "armor_type": "cloth", "ilvl": 1, "armor": 5, "look": ["Wizard_Legs", "Wizard", 1], "sell": 3},
	"apprentice_boots": {"name": "Apprentice's Sandals", "q": 1, "slot": "feet", "armor_type": "cloth", "ilvl": 1, "armor": 3, "look": ["Wizard_Feet", "Wizard", 1], "sell": 2},
	"apprentice_wraps": {"name": "Apprentice's Wraps", "q": 1, "slot": "hands", "armor_type": "cloth", "ilvl": 1, "armor": 2, "look": ["Wizard_Arms", "Wizard", 1], "sell": 2},
	"acolyte_vestment": {"name": "Acolyte's Vestment", "q": 1, "slot": "chest", "armor_type": "cloth", "ilvl": 1, "armor": 6, "look": ["Noble_Body", "Noble", 1], "sell": 4},
	"acolyte_pants": {"name": "Acolyte's Breeches", "q": 1, "slot": "legs", "armor_type": "cloth", "ilvl": 1, "armor": 5, "look": ["Noble_Legs", "Noble", 1], "sell": 3},
	"acolyte_shoes": {"name": "Acolyte's Shoes", "q": 1, "slot": "feet", "armor_type": "cloth", "ilvl": 1, "armor": 3, "look": ["Noble_Feet", "Noble", 1], "sell": 2},
	"acolyte_sleeves": {"name": "Acolyte's Sleeves", "q": 1, "slot": "hands", "armor_type": "cloth", "ilvl": 1, "armor": 2, "look": ["Noble_Arms", "Noble", 1], "sell": 2},
	"acolyte_collar": {"name": "Acolyte's Collar", "q": 1, "slot": "neck", "ilvl": 1, "stats": {"spi": 1}, "look": ["Noble_Acc_Gorget", "Noble", 1], "sell": 3},

	# ---------------------------------------------------------------- quest rewards (Ashvale Province)
	"sharpened_sword": {"name": "Sharpened Sword", "q": 2, "slot": "main_hand", "wtype": "sword", "ilvl": 5, "weapon": [6, 12, 2.4], "stats": {"str": 1, "sta": 1}, "model": "long", "sell": 45, "bind": "quest"},
	"ashwood_wand": {"name": "Ashwood Wand", "q": 2, "slot": "main_hand", "wtype": "wand", "ilvl": 5, "weapon": [4, 8, 2.0], "stats": {"int": 2}, "sp": 3, "model": "wand", "sell": 45, "bind": "quest"},
	"rat_catcher_cap": {"name": "Rat-Catcher's Cap", "q": 2, "slot": "head", "armor_type": "leather", "ilvl": 6, "armor": 18, "stats": {"agi": 1, "sta": 2}, "look": ["Ranger_Head_Hood", "Ranger", 2], "sell": 38, "bind": "quest"},
	"tanned_belt": {"name": "Tanned Belt", "q": 1, "slot": "waist", "armor_type": "leather", "ilvl": 6, "armor": 10, "stats": {"sta": 1}, "sell": 20, "bind": "quest"},
	"hunter_bracers": {"name": "Hunter's Bracers", "q": 2, "slot": "wrist", "armor_type": "mail", "ilvl": 8, "armor": 22, "stats": {"str": 2, "sta": 1}, "sell": 55, "bind": "quest"},
	"woodland_sash": {"name": "Woodland Sash", "q": 2, "slot": "waist", "armor_type": "cloth", "ilvl": 8, "armor": 6, "stats": {"int": 2, "spi": 1}, "sell": 55, "bind": "quest"},
	"scratch_claw": {"name": "Scratch's Claw", "q": 2, "slot": "trinket1", "ilvl": 9, "stats": {"str": 2, "agi": 2}, "sell": 90, "bind": "quest", "desc": "It still twitches when a cat is near."},
	"militia_bracer": {"name": "Militia Shield Bracer", "q": 2, "slot": "wrist", "armor_type": "mail", "ilvl": 9, "armor": 25, "stats": {"sta": 3}, "sell": 70, "bind": "quest"},
	"warding_charm": {"name": "Warding Charm", "q": 2, "slot": "neck", "ilvl": 9, "stats": {"int": 2, "spi": 2}, "sell": 70, "bind": "quest"},
	"boar_king_tusk": {"name": "Boar King's Tusk", "q": 2, "slot": "main_hand", "wtype": "sword", "ilvl": 12, "weapon": [12, 22, 2.5], "stats": {"str": 3, "sta": 2}, "model": "serrated", "sell": 160, "bind": "quest"},
	"hogtooth_vest": {"name": "Hogtooth Hide Vest", "q": 2, "slot": "chest", "armor_type": "cloth", "ilvl": 12, "armor": 14, "stats": {"int": 3, "spi": 3, "sta": 2}, "look": ["Wizard_Body", "Wizard", 3], "sell": 160, "bind": "quest"},
	"ploughshare_ring": {"name": "Ploughshare Ring", "q": 2, "slot": "finger1", "ilvl": 12, "stats": {"sta": 3, "str": 1, "int": 1}, "sell": 160, "bind": "quest"},
	"tusk_blue": {"name": "Old Tusk's Grudge", "q": 3, "slot": "main_hand", "wtype": "staff", "ilvl": 16, "weapon": [16, 28, 2.9], "stats": {"int": 5, "sta": 4, "spi": 3}, "sp": 6, "model": "emberstaff", "sell": 320, "bind": "bop"},

	# ---------------------------------------------------------------- consumables and bits
	"hearthstone": {"name": "Hearthstone", "q": 1, "use": "hearth", "bind": "bop", "desc": "Bess gave you this. \"So you always find your way back.\""},
	"warm_meal": {"name": "Warm Meal", "q": 1, "use": "food", "heal": 120, "stack": 20, "sell": 1, "desc": "Bess's stew. Restores health while sitting."},
	"spring_water": {"name": "Spring Water", "q": 1, "use": "drink", "mana": 150, "stack": 20, "sell": 1, "desc": "Clear and cold, from the well by the square."},
	"minor_healing_potion": {"name": "Minor Healing Potion", "q": 1, "use": "potion", "heal": 80, "stack": 5, "sell": 5},
	"hen_feather": {"name": "Hen Feather", "q": 1, "quest": true, "stack": 20},
	"boar_hide": {"name": "Boar Hide", "q": 1, "stack": 20, "sell": 6, "quest": true},
	"grave_token": {"name": "Grave Token", "q": 1, "quest": true, "desc": "Stamped with the Miners' Guild mark."},
	"old_coin": {"name": "Old Coin", "q": 1, "quest": true, "stack": 20},
	"rowans_letter": {"name": "Rowan's Letter", "q": 1, "quest": true, "desc": "Sealed with red wax. It mentions a fence."},
	"lamb_bell": {"name": "Lamb's Bell", "q": 1, "quest": true},
	"old_tusks_tusk": {"name": "Old Tusk's Tusk", "q": 1, "quest": true, "desc": "Farmer Hale will want to see this."},
	# ---- Hollow Cliffs
	"black_iron_ore": {"name": "Black Iron Ore", "q": 1, "quest": true, "stack": 20, "desc": "Heavy, cold, and stamped nowhere."},
	"grave_blessing": {"name": "Graves Blessed", "q": 1, "quest": true, "stack": 10},
	"skarrs_key": {"name": "Skarr's Key", "q": 1, "quest": true, "desc": "Iron, old, and far too big for any door in the camp."},
	"maggot_meat": {"name": "Maggot Meat", "q": 1, "quest": true, "stack": 20, "desc": "Bram swears it's good in a stew."},
	"vales_letter": {"name": "Sister Vale's Letter", "q": 1, "quest": true, "desc": "Addressed to Warden Elsbeth, Mirewood Landing."},
	"bat_wing": {"name": "Leathery Bat Wing", "q": 0, "stack": 10, "sell": 22},
	"maggot_goo": {"name": "Maggot Goo", "q": 0, "stack": 10, "sell": 18},
	"spider_silk": {"name": "Coarse Spider Silk", "q": 0, "stack": 10, "sell": 30},
	"rough_stone": {"name": "Rough Stone", "q": 0, "stack": 10, "sell": 15},
	"miners_wages": {"name": "Miner's Wage Purse", "q": 0, "stack": 5, "sell": 60},
	# Hollow Cliffs quest rewards
	"camp_cook_gloves": {"name": "Camp Cook's Gloves", "q": 2, "slot": "hands", "armor_type": "leather", "ilvl": 13, "armor": 32, "stats": {"sta": 3, "spi": 2}, "sell": 210, "bind": "quest"},
	"foremans_gauntlets": {"name": "Foreman's Gauntlets", "q": 2, "slot": "hands", "armor_type": "mail", "ilvl": 14, "armor": 70, "stats": {"str": 4, "sta": 2}, "look": ["Knight_Arms", "Knight", 2], "sell": 260, "bind": "quest"},
	"lantern_row_cord": {"name": "Lantern Row Cord", "q": 2, "slot": "waist", "armor_type": "cloth", "ilvl": 14, "armor": 14, "stats": {"int": 4, "spi": 2}, "sell": 240, "bind": "quest"},
	"diggers_pick": {"name": "Digger's Pick", "q": 2, "slot": "main_hand", "wtype": "axe", "ilvl": 14, "weapon": [18, 34, 2.7], "stats": {"str": 3, "sta": 2}, "model": "axe", "sell": 380, "bind": "quest"},
	"vale_prayer_beads": {"name": "Vale's Prayer Beads", "q": 2, "slot": "neck", "ilvl": 14, "stats": {"int": 3, "spi": 4}, "sell": 300, "bind": "quest"},
	"cairn_warden_boots": {"name": "Cairn Warden Boots", "q": 2, "slot": "feet", "armor_type": "mail", "ilvl": 14, "armor": 60, "stats": {"sta": 4, "agi": 2}, "look": ["Knight_Feet", "Knight", 2], "sell": 250, "bind": "quest"},
	"rockjaw_hide_cloak": {"name": "Rockjaw Hide Cloak", "q": 2, "slot": "back", "ilvl": 16, "armor": 24, "stats": {"sta": 5, "str": 2}, "sell": 420, "bind": "quest"},
	"enforcers_ring": {"name": "Enforcer's Ring", "q": 2, "slot": "finger1", "ilvl": 16, "stats": {"str": 4, "sta": 3}, "sell": 420, "bind": "quest"},
	# the Hollow Mine: blues from the bosses
	"grubhide_jerkin": {"name": "Grubhide Jerkin", "q": 3, "slot": "chest", "armor_type": "leather", "ilvl": 17, "armor": 90, "stats": {"agi": 5, "sta": 7, "str": 4}, "look": ["Ranger_Body", "Ranger", 3], "sell": 700, "bind": "bop"},
	"foremans_maul": {"name": "Gault's Last Word", "q": 3, "slot": "main_hand", "wtype": "mace", "ilvl": 18, "weapon": [26, 44, 2.8], "stats": {"str": 6, "sta": 5}, "model": "club", "sell": 900, "bind": "bop"},
	"gaults_ledger_staff": {"name": "Ledger-Bound Staff", "q": 3, "slot": "main_hand", "wtype": "staff", "ilvl": 18, "weapon": [30, 48, 3.0], "stats": {"int": 8, "spi": 5, "sta": 4}, "sp": 10, "model": "skullstaff", "sell": 900, "bind": "bop"},
	"bone_kings_circlet": {"name": "Bone King's Circlet", "q": 3, "slot": "head", "armor_type": "cloth", "ilvl": 19, "armor": 30, "stats": {"int": 7, "spi": 6, "sta": 5}, "sp": 8, "sell": 1100, "bind": "bop"},
	"marrowplate_pauldrons": {"name": "Marrowplate Pauldrons", "q": 3, "slot": "shoulders", "armor_type": "mail", "ilvl": 19, "armor": 150, "stats": {"str": 7, "sta": 7}, "look": ["Knight_Acc_Pauldron_Round", "Knight", 3], "sell": 1100, "bind": "bop"},
	"hollow_crown_band": {"name": "Band of the Hollow Crown", "q": 3, "slot": "finger1", "ilvl": 19, "stats": {"sta": 6, "str": 3, "int": 3}, "sell": 1100, "bind": "bop"},


	"sages_ink": {"name": "Sage's Ink", "q": 0, "stack": 5, "sell": 500},
	# junk: Classic's pocket-fillers
	"cracked_tusk": {"name": "Cracked Boar Tusk", "q": 0, "stack": 10, "sell": 12},
	"matted_fur": {"name": "Matted Fur", "q": 0, "stack": 10, "sell": 9},
	"puglin_trinket": {"name": "Shiny Puglin Trinket", "q": 0, "stack": 10, "sell": 15},
	"bone_fragment": {"name": "Bone Fragments", "q": 0, "stack": 10, "sell": 11},
	"brimstone_chip": {"name": "Brimstone Chip", "q": 0, "stack": 10, "sell": 18},
	"straw_bundle": {"name": "Bundle of Straw", "q": 0, "stack": 10, "sell": 4},
	"rat_tail": {"name": "Rat Tail", "q": 0, "stack": 10, "sell": 3},
	"chicken_egg": {"name": "Chicken Egg", "q": 1, "stack": 10, "sell": 2, "use": "food", "heal": 40},
}

## the starting kit for each class (equipped, then a little food in the bag)
const START := {
	"warrior": ["recruit_sword", "recruit_chest", "recruit_legs", "recruit_boots", "recruit_gloves"],
	"wizard": ["apprentice_staff", "apprentice_robe", "apprentice_pants", "apprentice_boots", "apprentice_wraps"],
	"cleric": ["acolyte_mace", "acolyte_vestment", "acolyte_pants", "acolyte_shoes", "acolyte_sleeves", "acolyte_collar"],
}

static func get_def(it: Dictionary) -> Dictionary:
	var base: Dictionary = LIST.get(it.get("id", ""), {})
	if it.has("rolled"):
		var d := base.duplicate(true)
		for k in it["rolled"]: d[k] = it["rolled"][k]
		return d
	return base

static func slot_of(d: Dictionary) -> String:
	var s: String = d.get("slot", "")
	return s.trim_suffix("1").trim_suffix("2") if s.begins_with("finger") or s.begins_with("trinket") else s

static func can_use(cls: String, d: Dictionary, level: int) -> bool:
	if d.has("armor_type") and not (d["armor_type"] in CAN_WEAR.get(cls, [])): return false
	if d.has("wtype") and not (d["wtype"] in WEAPONS.get(cls, [])): return false
	return level >= req_level(d)

static func req_level(d: Dictionary) -> int:
	if d.has("req"): return int(d["req"])
	var il := int(d.get("ilvl", 1))
	return maxi(1, il - [0, 0, 5, 8, 10, 12][int(d.get("q", 1))])

static func color(d: Dictionary) -> Color:
	return QUALITY[clampi(int(d.get("q", 1)), 0, 5)]["color"]

## a random uncommon (green) drop for a monster of this level: a base piece with an affix
const BASES := [
	["chest", "cloth", "Robe", ["Wizard_Body", "Wizard"]], ["legs", "cloth", "Leggings", ["Wizard_Legs", "Wizard"]],
	["feet", "cloth", "Slippers", ["Wizard_Feet", "Wizard"]], ["hands", "cloth", "Gloves", ["Wizard_Arms", "Wizard"]],
	["chest", "cloth", "Vestments", ["Noble_Body", "Noble"]], ["shoulders", "cloth", "Mantle", ["Noble_Acc_Pauldron", "Noble"]],
	["chest", "mail", "Hauberk", ["Knight_Body_Armor", "Knight"]], ["legs", "mail", "Legguards", ["Knight_Legs", "Knight"]],
	["feet", "mail", "Sabatons", ["Knight_Feet", "Knight"]], ["hands", "mail", "Gauntlets", ["Knight_Arms", "Knight"]],
	["shoulders", "mail", "Pauldrons", ["Knight_Acc_Pauldron_Round", "Knight"]], ["head", "mail", "Helm", ["Knight_Head_Armet", "Knight"]],
	["chest", "leather", "Jerkin", ["Ranger_Body", "Ranger"]], ["legs", "leather", "Breeches", ["Ranger_Legs", "Ranger"]],
	["wrist", "cloth", "Cuffs", []], ["wrist", "mail", "Bracers", []], ["waist", "cloth", "Cord", []], ["waist", "mail", "Girdle", []],
	["back", "cloth", "Cloak", []], ["finger1", "", "Band", []], ["neck", "", "Pendant", []],
]
const PREFIX := ["Tarnished", "Sturdy", "Warden's", "Hedge-Knight's", "Pilgrim's", "Ashen", "Marsh-Walker's", "Old Guard", "Emberwoven", "Rugged"]
const AFFIX := {"of the Bear": {"sta": 0.5, "str": 0.5}, "of the Owl": {"int": 0.5, "spi": 0.5}, "of the Eagle": {"sta": 0.5, "int": 0.5},
	"of the Tiger": {"str": 0.5, "agi": 0.5}, "of the Whale": {"sta": 0.5, "spi": 0.5}, "of Strength": {"str": 1.0}, "of Intellect": {"int": 1.0},
	"of Stamina": {"sta": 1.0}, "of the Boar": {"str": 0.5, "spi": 0.5}, "of the Gorilla": {"str": 0.5, "int": 0.5}}
const ARMOR_PER := {"cloth": 3.0, "leather": 6.0, "mail": 12.0, "plate": 20.0}
const SLOT_ARMOR := {"chest": 1.0, "legs": 0.85, "head": 0.8, "shoulders": 0.7, "feet": 0.6, "hands": 0.55, "waist": 0.45, "wrist": 0.4, "back": 0.4}

static func roll(level: int, rng: RandomNumberGenerator, quality := 2) -> Dictionary:
	var b: Array = BASES[rng.randi() % BASES.size()]
	var ilvl := maxi(2, level + rng.randi_range(0, 3))
	var affix: String = AFFIX.keys()[rng.randi() % AFFIX.size()]
	var budget: float = ilvl * (0.9 if quality == 2 else 1.3) * 0.55 + 1.0
	var stats := {}
	for k in AFFIX[affix]: stats[k] = maxi(1, int(round(budget * AFFIX[affix][k])))
	var d := {"name": "%s %s %s" % [PREFIX[rng.randi() % PREFIX.size()], b[2], affix], "q": quality, "slot": b[0], "ilvl": ilvl, "stats": stats,
		"sell": int(ilvl * ilvl * 1.6 * (1.0 if quality == 2 else 2.2)) + 10, "bind": "boe"}
	if b[1] != "":
		d["armor_type"] = b[1]
		d["armor"] = int(ARMOR_PER[b[1]] * SLOT_ARMOR.get(b[0], 0.5) * (1.0 + ilvl * 0.35))
	if b[3].size() == 2: d["look"] = [b[3][0], b[3][1], rng.randi_range(2, 3)]
	return {"id": "rolled", "rolled": d, "n": 1}

## what a vendor asks (four times what they'd pay you, as in WoW)
static func buy_price(d: Dictionary) -> int:
	if d.has("price"): return int(d["price"])
	var n := 1 if int(d.get("stack", 1)) == 1 else mini(5, int(d["stack"]))
	return maxi(1, int(d.get("sell", 1)) * 4) * n

## gold amounts, WoW style: 1g 23s 45c
static func money(c: int) -> String:
	var g := c / 10000; var s := (c / 100) % 100; var cc := c % 100
	var out := ""
	if g > 0: out += "%dg " % g
	if g > 0 or s > 0: out += "%ds " % s
	return (out + "%dc" % cc).strip_edges()

## the text of a tooltip (BBCode) for an item, as WoW shows it
static func tooltip(it: Dictionary, cls := "", level := 1) -> String:
	var d := get_def(it)
	if d.is_empty(): return "?"
	var c := color(d).to_html(false)
	var t := "[font_size=19][color=#%s]%s[/color][/font_size]\n" % [c, d["name"]]
	var bind: String = d.get("bind", "")
	if bind == "bop" or bind == "quest": t += "Binds when picked up\n"
	elif bind == "boe": t += "Binds when equipped\n"
	if d.get("quest", false): t += "Quest Item\n"
	if d.has("slot"):
		var sn: String = SLOT_NAMES.get(slot_of(d), "")
		var typ: String = String(d.get("armor_type", d.get("wtype", ""))).capitalize().replace("_", " ")
		t += "%s%s%s\n" % [sn, "                  " if typ != "" else "", typ]
	if d.has("weapon"):
		var w: Array = d["weapon"]
		t += "%d - %d Damage        Speed %.2f\n(%.1f damage per second)\n" % [w[0], w[1], w[2], (w[0] + w[1]) / 2.0 / w[2]]
	if d.has("armor"): t += "%d Armor\n" % int(d["armor"])
	for k in ["str", "agi", "sta", "int", "spi"]:
		if d.get("stats", {}).has(k): t += "+%d %s\n" % [int(d["stats"][k]), STAT_NAMES[k]]
	if d.has("sp"): t += "[color=#1eff00]Equip: Increases damage and healing done by magical spells by up to %d.[/color]\n" % int(d["sp"])
	if d.has("use"):
		if d.has("heal") and d["use"] == "potion": t += "[color=#1eff00]Use: Restores %d health.[/color]\n" % int(d["heal"])
		elif d.has("heal"): t += "[color=#1eff00]Use: Restores %d health over 18 sec. Must remain seated while eating.[/color]\n" % int(d["heal"])
		if d.has("mana"): t += "[color=#1eff00]Use: Restores %d mana over 18 sec. Must remain seated while drinking.[/color]\n" % int(d["mana"])
	var rl := req_level(d)
	if d.has("slot") and rl > 1: t += ("[color=#ff2020]" if level < rl else "") + "Requires Level %d" % rl + ("[/color]" if level < rl else "") + "\n"
	if cls != "" and d.has("slot") and not can_use(cls, d, 99): t += "[color=#ff2020]Your class can't use this[/color]\n"
	if d.has("desc"): t += "[color=#ffd100]\"%s\"[/color]\n" % d["desc"]
	if int(d.get("sell", 0)) > 0: t += "Sell Price: %s" % money(int(d["sell"]))
	return t.strip_edges()
