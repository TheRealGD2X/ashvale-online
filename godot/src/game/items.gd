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
	# ---- Ashen Highlands and Varn Plateau
	"khar_horn_chip": {"name": "Chipped Khar Horn", "q": 0, "stack": 20, "sell": 70},
	"highland_bloom": {"name": "Highland Bloom", "q": 1, "quest": true, "stack": 20},
	"soul_shard": {"name": "Soul Shard", "q": 1, "quest": true, "stack": 20},
	"roarks_dispatch": {"name": "Roark's Dispatch", "q": 1, "quest": true},
	"neds_notes": {"name": "Old Ned's Notes", "q": 1, "quest": true, "desc": "Stories of the Sanctum, in a hand that shakes."},
	"sanctum_key": {"name": "Sanctum Key", "q": 3, "desc": "Cold, and heavier than it looks. It opens the Sanctum Gate.", "bind": "bop"},
	"heather_cloak": {"name": "Heather-Dyed Cloak", "q": 2, "slot": "back", "ilvl": 30, "armor": 22, "stats": {"sta": 7, "agi": 4}, "sell": 1600, "bind": "quest"},
	"watch_pauldrons": {"name": "Highland Watch Pauldrons", "q": 2, "slot": "shoulders", "armor_type": "mail", "ilvl": 31, "armor": 200, "stats": {"str": 9, "sta": 8}, "look": ["Knight_Acc_Pauldron_Round", "Knight", 2], "sell": 1700, "bind": "quest"},
	"herbalists_gloves": {"name": "Herbalist's Gloves", "q": 2, "slot": "hands", "armor_type": "cloth", "ilvl": 31, "armor": 30, "stats": {"int": 8, "spi": 7}, "look": ["Wizard_Arms", "Wizard", 2], "sell": 1600, "bind": "quest"},
	"brandmasters_axe": {"name": "Brandmaster's Axe", "q": 2, "slot": "main_hand", "wtype": "axe", "ilvl": 33, "weapon": [46, 86, 2.7], "stats": {"str": 10, "sta": 7}, "model": "greataxe", "sell": 2400, "bind": "quest"},
	"raiders_band": {"name": "Old Raider's Band", "q": 2, "slot": "finger1", "ilvl": 33, "stats": {"sta": 8, "str": 5, "int": 5}, "sell": 2200, "bind": "quest"},
	"siltveil_cowl": {"name": "Siltveil Cowl", "q": 3, "slot": "head", "armor_type": "cloth", "ilvl": 35, "armor": 60, "stats": {"int": 15, "spi": 12, "sta": 11}, "sp": 18, "sell": 4000, "bind": "bop"},
	"drowned_kings_blade": {"name": "Drowned King's Blade", "q": 3, "slot": "main_hand", "wtype": "sword", "ilvl": 35, "weapon": [52, 96, 2.6], "stats": {"str": 13, "sta": 11}, "model": "abyssblade", "sell": 4400, "bind": "bop"},
	"cryptlord_greaves": {"name": "Cryptlord Greaves", "q": 3, "slot": "legs", "armor_type": "mail", "ilvl": 36, "armor": 340, "stats": {"str": 15, "sta": 15}, "look": ["Knight_Legs", "Knight", 3], "sell": 4400, "bind": "bop"},
	"lakebound_band": {"name": "Lakebound Band", "q": 3, "slot": "finger1", "ilvl": 36, "stats": {"sta": 13, "int": 9, "spi": 8}, "sell": 4200, "bind": "bop"},
	"sunken_staff": {"name": "Staff of the Sunken", "q": 3, "slot": "main_hand", "wtype": "staff", "ilvl": 36, "weapon": [66, 104, 3.0], "stats": {"int": 18, "spi": 13, "sta": 12}, "sp": 24, "model": "crystalstaff", "sell": 4600, "bind": "bop"},
	"marshals_girdle": {"name": "Marshal's Girdle", "q": 2, "slot": "waist", "armor_type": "mail", "ilvl": 38, "armor": 190, "stats": {"str": 12, "sta": 11}, "sell": 3200, "bind": "quest"},
	"lichhunter_wraps": {"name": "Lich-Hunter's Wraps", "q": 2, "slot": "wrist", "armor_type": "cloth", "ilvl": 38, "armor": 28, "stats": {"int": 10, "spi": 9}, "sell": 3100, "bind": "quest"},
	"gravewarden_plate": {"name": "Gravewarden's Breastplate", "q": 3, "slot": "chest", "armor_type": "mail", "ilvl": 41, "armor": 460, "stats": {"str": 18, "sta": 18}, "look": ["Knight_Body_Armor", "Knight", 3], "sell": 6200, "bind": "bop"},
	"catacomb_lantern": {"name": "Catacomb Lantern", "q": 3, "slot": "trinket1", "ilvl": 41, "stats": {"int": 12, "spi": 12, "sta": 8}, "sp": 16, "sell": 6000, "bind": "bop"},
	"varns_crown": {"name": "Crown of Varn", "q": 3, "slot": "head", "armor_type": "mail", "ilvl": 43, "armor": 330, "stats": {"str": 20, "sta": 19}, "look": ["Knight_Head_Armet", "Knight", 3], "sell": 7000, "bind": "bop"},
	"lichbone_staff": {"name": "Lichbone Staff", "q": 3, "slot": "main_hand", "wtype": "staff", "ilvl": 43, "weapon": [80, 124, 3.0], "stats": {"int": 22, "spi": 16, "sta": 15}, "sp": 30, "model": "skullstaff", "sell": 7200, "bind": "bop"},
	"varn_signet": {"name": "Signet of House Varn", "q": 3, "slot": "finger1", "ilvl": 43, "stats": {"sta": 16, "str": 10, "int": 10}, "sell": 6800, "bind": "bop"},
	"deathwalker_boots": {"name": "Deathwalker Boots", "q": 3, "slot": "feet", "armor_type": "leather", "ilvl": 43, "armor": 160, "stats": {"agi": 16, "sta": 15, "str": 8}, "look": ["Ranger_Feet", "Ranger", 3], "sell": 6800, "bind": "bop"},
	# ---- Ash Slopes

	"cultist_robe_scrap": {"name": "Scorched Robe Scrap", "q": 0, "stack": 20, "sell": 40},
	"guardian_arrow_scrap": {"name": "Broken Arrow", "q": 0, "stack": 20, "sell": 20},
	"khar_ledger": {"name": "Khar Ledger", "q": 1, "quest": true, "stack": 10, "desc": "Names, dates, and a great many tallies of ash."},
	"guardian_arrow": {"name": "Guardian Arrow", "q": 1, "quest": true, "stack": 20},
	"moras_seal": {"name": "Mora's Seal", "q": 1, "quest": true, "desc": "A seal of black glass, still warm."},
	"highland_oats": {"name": "Highland Oats", "q": 1, "quest": true, "stack": 20},
	"sentinel_core": {"name": "Sentinel Core", "q": 1, "quest": true, "stack": 10},
	"pilgrims_robe": {"name": "Pilgrim's Robe", "q": 2, "slot": "chest", "armor_type": "cloth", "ilvl": 24, "armor": 40, "stats": {"int": 7, "spi": 6, "sta": 4}, "look": ["Noble_Body", "Noble", 2], "sell": 900, "bind": "quest"},
	"temple_guard_girdle": {"name": "Temple Guard Girdle", "q": 2, "slot": "waist", "armor_type": "mail", "ilvl": 24, "armor": 110, "stats": {"str": 6, "sta": 5}, "sell": 880, "bind": "quest"},
	"nells_longbow_charm": {"name": "Nell's Fletching Charm", "q": 2, "slot": "neck", "ilvl": 25, "stats": {"agi": 5, "sta": 5}, "sell": 950, "bind": "quest"},
	"masons_hammer": {"name": "Mason's Hammer", "q": 2, "slot": "main_hand", "wtype": "mace", "ilvl": 25, "weapon": [30, 54, 2.7], "stats": {"str": 6, "sta": 5}, "model": "club", "sell": 1100, "bind": "quest"},
	"abbots_prayer_staff": {"name": "Abbot's Prayer Staff", "q": 2, "slot": "main_hand", "wtype": "staff", "ilvl": 26, "weapon": [44, 68, 3.0], "stats": {"int": 9, "spi": 8, "sta": 5}, "sp": 12, "model": "staff", "sell": 1200, "bind": "quest"},
	"cindersteel_helm": {"name": "Cindersteel Helm", "q": 2, "slot": "head", "armor_type": "mail", "ilvl": 26, "armor": 180, "stats": {"str": 8, "sta": 7}, "look": ["Knight_Head_Armet", "Knight", 3], "sell": 1150, "bind": "quest"},
	"bellringers_cowl": {"name": "Bellringer's Cowl", "q": 3, "slot": "head", "armor_type": "cloth", "ilvl": 28, "armor": 48, "stats": {"int": 11, "spi": 9, "sta": 8}, "sp": 13, "sell": 2400, "bind": "bop"},
	"tolling_mace": {"name": "The Tolling Mace", "q": 3, "slot": "main_hand", "wtype": "mace", "ilvl": 28, "weapon": [38, 70, 2.7], "stats": {"str": 10, "sta": 8}, "model": "club", "sell": 2600, "bind": "bop"},
	"ashmaw_hide_mantle": {"name": "Ashmaw Hide Mantle", "q": 3, "slot": "shoulders", "armor_type": "leather", "ilvl": 29, "armor": 120, "stats": {"agi": 9, "sta": 10, "str": 6}, "look": ["Ranger_Acc_Pauldron", "Ranger", 3], "sell": 2600, "bind": "bop"},
	"cinderheart_ring": {"name": "Cinderheart Ring", "q": 3, "slot": "finger1", "ilvl": 29, "stats": {"sta": 9, "int": 6, "str": 6}, "sell": 2500, "bind": "bop"},
	"moras_ashen_staff": {"name": "Mora's Ashen Staff", "q": 3, "slot": "main_hand", "wtype": "staff", "ilvl": 30, "weapon": [56, 88, 3.0], "stats": {"int": 15, "spi": 10, "sta": 10}, "sp": 20, "model": "skullstaff", "sell": 3200, "bind": "bop"},
	"soulthread_robe": {"name": "Soulthread Robe", "q": 3, "slot": "chest", "armor_type": "cloth", "ilvl": 30, "armor": 62, "stats": {"int": 13, "spi": 12, "sta": 10}, "sp": 15, "look": ["Wizard_Body", "Wizard", 3], "sell": 3100, "bind": "bop"},
	"khar_signet": {"name": "Signet of the Khar", "q": 3, "slot": "finger1", "ilvl": 30, "stats": {"str": 9, "sta": 10, "agi": 5}, "sell": 3000, "bind": "bop"},
	# ---- Mirewood

	"goblin_ear": {"name": "Goblin Ear", "q": 0, "stack": 20, "sell": 28},
	"viper_fang": {"name": "Viper Fang", "q": 0, "stack": 10, "sell": 30},
	"moth_wing": {"name": "Dusty Moth Wing", "q": 0, "stack": 10, "sell": 26},
	"viper_gland": {"name": "Viper Venom Gland", "q": 1, "quest": true, "stack": 20},
	"moth_dust": {"name": "Temple Moth Dust", "q": 1, "quest": true, "stack": 20},
	"totem_smashed": {"name": "Totems Smashed", "q": 1, "quest": true, "stack": 10},
	"warlords_horn": {"name": "The Warlord's Horn", "q": 1, "quest": true, "desc": "Blow it and people follow. That's the idea, anyway."},
	"elsbeths_map": {"name": "The Shaman's Map", "q": 1, "quest": true, "desc": "Crude, but someone has marked the Temple of Ash with a skull."},
	"landing_wader_boots": {"name": "Landing Wader Boots", "q": 2, "slot": "feet", "armor_type": "leather", "ilvl": 18, "armor": 48, "stats": {"agi": 4, "sta": 4}, "look": ["Ranger_Feet", "Ranger", 2], "sell": 520, "bind": "quest"},
	"reedweave_mantle": {"name": "Reedweave Mantle", "q": 2, "slot": "shoulders", "armor_type": "cloth", "ilvl": 18, "armor": 22, "stats": {"int": 5, "spi": 3}, "look": ["Noble_Acc_Pauldron", "Noble", 2], "sell": 520, "bind": "quest"},
	"wardens_halberd": {"name": "Warden's Hookblade", "q": 2, "slot": "main_hand", "wtype": "sword", "ilvl": 19, "weapon": [22, 42, 2.6], "stats": {"str": 5, "sta": 3}, "model": "hook", "sell": 700, "bind": "quest"},
	"witchs_charm": {"name": "Marsh-Witch's Charm", "q": 2, "slot": "trinket1", "ilvl": 19, "stats": {"int": 4, "spi": 4}, "sell": 650, "bind": "quest"},
	"fenns_bracers": {"name": "Fenn's Bridge Bracers", "q": 2, "slot": "wrist", "armor_type": "mail", "ilvl": 19, "armor": 60, "stats": {"str": 3, "sta": 4}, "sell": 560, "bind": "quest"},
	"ferrymans_cord": {"name": "Ferryman's Cord", "q": 2, "slot": "waist", "armor_type": "cloth", "ilvl": 19, "armor": 16, "stats": {"int": 3, "sta": 3, "spi": 2}, "sell": 560, "bind": "quest"},
	"broodsilk_mantle": {"name": "Broodsilk Mantle", "q": 3, "slot": "shoulders", "armor_type": "cloth", "ilvl": 23, "armor": 34, "stats": {"int": 8, "spi": 6, "sta": 5}, "sp": 9, "look": ["Noble_Acc_Pauldron", "Noble", 3], "sell": 1500, "bind": "bop"},
	"venomfang_dirk": {"name": "Venomfang Dirk", "q": 3, "slot": "main_hand", "wtype": "dagger", "ilvl": 23, "weapon": [20, 38, 1.8], "stats": {"agi": 6, "sta": 5}, "model": "fang", "sell": 1600, "bind": "bop"},
	"rootmaw_heartwood_staff": {"name": "Heartwood of Rootmaw", "q": 3, "slot": "main_hand", "wtype": "staff", "ilvl": 24, "weapon": [40, 64, 3.0], "stats": {"int": 11, "spi": 8, "sta": 7}, "sp": 14, "model": "bough", "sell": 1900, "bind": "bop"},
	"barkskin_legguards": {"name": "Barkskin Legguards", "q": 3, "slot": "legs", "armor_type": "mail", "ilvl": 24, "armor": 210, "stats": {"str": 9, "sta": 9}, "look": ["Knight_Legs", "Knight", 3], "sell": 1800, "bind": "bop"},
	"mirewarden_signet": {"name": "Mirewarden's Signet", "q": 3, "slot": "finger1", "ilvl": 24, "stats": {"sta": 8, "str": 4, "int": 4}, "sell": 1800, "bind": "bop"},
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
	# ---- Milestone 7: the Abyssal Sanctum (raid)
	"colossus_knuckles": {"name": "Gauntlets of the Colossus", "q": 4, "slot": "hands", "ilvl": 66, "st": "str sta", "bind": "bop", "armor_type": "plate"},
	"cinderstone_ring": {"name": "Cinderstone Ring", "q": 4, "slot": "finger1", "ilvl": 66, "st": "sta int spi", "bind": "bop"},
	"ashfall_cord": {"name": "Ashfall Cord", "q": 4, "slot": "waist", "ilvl": 66, "st": "int spi", "bind": "bop", "armor_type": "cloth"},
	"golemheart": {"name": "Golemheart", "q": 4, "slot": "trinket1", "ilvl": 66, "st": "sta str", "bind": "bop"},
	"colossus_maul": {"name": "Maul of the Colossus", "q": 4, "slot": "main_hand", "ilvl": 66, "st": "str sta", "bind": "bop", "wtype": "mace", "model": "worldbreaker"},
	"tome_of_the_archivist": {"name": "Last Page of the Archive", "q": 4, "slot": "trinket1", "ilvl": 68, "st": "int spi sta", "bind": "bop"},
	"inkstained_wraps": {"name": "Inkstained Wraps", "q": 4, "slot": "wrist", "ilvl": 68, "st": "int spi", "bind": "bop", "armor_type": "cloth"},
	"lorekeepers_legplates": {"name": "Lorekeeper's Legplates", "q": 4, "slot": "legs", "ilvl": 68, "st": "str sta", "bind": "bop", "armor_type": "plate"},
	"runed_quill": {"name": "The Runed Quill", "q": 4, "slot": "main_hand", "ilvl": 68, "st": "int spi", "bind": "bop", "wtype": "wand"},
	"silent_word": {"name": "The Silent Word", "q": 4, "slot": "neck", "ilvl": 68, "st": "str sta", "bind": "bop"},
	"ashurs_edge": {"name": "Ashur's Edge", "q": 4, "slot": "main_hand", "ilvl": 70, "st": "str sta", "bind": "bop", "wtype": "sword", "model": "dragonblade"},
	"seths_gaze": {"name": "Seth's Gaze", "q": 4, "slot": "main_hand", "ilvl": 70, "st": "int spi sta", "bind": "bop", "wtype": "staff", "model": "abyssstaff"},
	"chainlinked_girdle": {"name": "Chainlinked Girdle", "q": 4, "slot": "waist", "ilvl": 70, "st": "str sta", "bind": "bop", "armor_type": "plate"},
	"twinbound_band": {"name": "Twinbound Band", "q": 4, "slot": "finger1", "ilvl": 70, "st": "int spi", "bind": "bop"},
	"wardens_cloak": {"name": "Cloak of the Wardens", "q": 4, "slot": "back", "ilvl": 70, "st": "sta str int", "bind": "bop"},
	"vaals_eye": {"name": "Eye of Vaal", "q": 4, "slot": "trinket1", "ilvl": 72, "st": "int spi sta", "bind": "bop"},
	"undying_greaves": {"name": "Undying Sabatons", "q": 4, "slot": "feet", "ilvl": 72, "st": "str sta", "bind": "bop", "armor_type": "plate"},
	"voidstep_slippers": {"name": "Voidstep Slippers", "q": 4, "slot": "feet", "ilvl": 72, "st": "int spi", "bind": "bop", "armor_type": "cloth"},
	"crown_of_the_undying": {"name": "Crown of the Undying", "q": 4, "slot": "head", "ilvl": 72, "st": "int spi sta", "bind": "bop", "armor_type": "cloth"},
	"soulreaver": {"name": "Soulreaver", "q": 4, "slot": "main_hand", "ilvl": 72, "st": "str sta", "bind": "bop", "wtype": "axe", "model": "abyssfang"},
	"token_hands": {"name": "Gauntlets of the Unbroken Oath", "q": 4, "bind": "bop", "token": "hands", "sell": 0, "desc": "Take it to the Keeper of the Sanctum Vault at the Last Watch, and it becomes a piece of your Order's set."},
	"token_head": {"name": "Helm of the Unbroken Oath", "q": 4, "bind": "bop", "token": "head", "sell": 0, "desc": "Take it to the Keeper of the Sanctum Vault at the Last Watch, and it becomes a piece of your Order's set."},
	"token_legs": {"name": "Legguards of the Unbroken Oath", "q": 4, "bind": "bop", "token": "legs", "sell": 0, "desc": "Take it to the Keeper of the Sanctum Vault at the Last Watch, and it becomes a piece of your Order's set."},
	"token_shoulders": {"name": "Mantle of the Unbroken Oath", "q": 4, "bind": "bop", "token": "shoulders", "sell": 0, "desc": "Take it to the Keeper of the Sanctum Vault at the Last Watch, and it becomes a piece of your Order's set."},
	"token_chest": {"name": "Breastplate of the Unbroken Oath", "q": 4, "bind": "bop", "token": "chest", "sell": 0, "desc": "Take it to the Keeper of the Sanctum Vault at the Last Watch, and it becomes a piece of your Order's set."},
	"set_warrior_head": {"name": "Oathbreaker's Crown", "q": 4, "slot": "head", "ilvl": 70, "st": "str sta", "bind": "bop", "armor_type": "plate", "set": "warrior"},
	"set_warrior_shoulders": {"name": "Oathbreaker's Pauldrons", "q": 4, "slot": "shoulders", "ilvl": 70, "st": "str sta", "bind": "bop", "armor_type": "plate", "set": "warrior"},
	"set_warrior_chest": {"name": "Oathbreaker's Chestguard", "q": 4, "slot": "chest", "ilvl": 70, "st": "str sta", "bind": "bop", "armor_type": "plate", "set": "warrior"},
	"set_warrior_hands": {"name": "Oathbreaker's Gloves", "q": 4, "slot": "hands", "ilvl": 70, "st": "str sta", "bind": "bop", "armor_type": "plate", "set": "warrior"},
	"set_warrior_legs": {"name": "Oathbreaker's Legguards", "q": 4, "slot": "legs", "ilvl": 70, "st": "str sta", "bind": "bop", "armor_type": "plate", "set": "warrior"},
	"set_wizard_head": {"name": "Voidweave Circlet", "q": 4, "slot": "head", "ilvl": 70, "st": "int spi sta", "bind": "bop", "armor_type": "cloth", "set": "wizard"},
	"set_wizard_shoulders": {"name": "Voidweave Mantle", "q": 4, "slot": "shoulders", "ilvl": 70, "st": "int spi sta", "bind": "bop", "armor_type": "cloth", "set": "wizard"},
	"set_wizard_chest": {"name": "Voidweave Robe", "q": 4, "slot": "chest", "ilvl": 70, "st": "int spi sta", "bind": "bop", "armor_type": "cloth", "set": "wizard"},
	"set_wizard_hands": {"name": "Voidweave Handwraps", "q": 4, "slot": "hands", "ilvl": 70, "st": "int spi sta", "bind": "bop", "armor_type": "cloth", "set": "wizard"},
	"set_wizard_legs": {"name": "Voidweave Leggings", "q": 4, "slot": "legs", "ilvl": 70, "st": "int spi sta", "bind": "bop", "armor_type": "cloth", "set": "wizard"},
	"set_cleric_head": {"name": "Embersworn Circlet", "q": 4, "slot": "head", "ilvl": 70, "st": "spi int sta", "bind": "bop", "armor_type": "cloth", "set": "cleric"},
	"set_cleric_shoulders": {"name": "Embersworn Mantle", "q": 4, "slot": "shoulders", "ilvl": 70, "st": "spi int sta", "bind": "bop", "armor_type": "cloth", "set": "cleric"},
	"set_cleric_chest": {"name": "Embersworn Robe", "q": 4, "slot": "chest", "ilvl": 70, "st": "spi int sta", "bind": "bop", "armor_type": "cloth", "set": "cleric"},
	"set_cleric_hands": {"name": "Embersworn Handwraps", "q": 4, "slot": "hands", "ilvl": 70, "st": "spi int sta", "bind": "bop", "armor_type": "cloth", "set": "cleric"},
	"set_cleric_legs": {"name": "Embersworn Leggings", "q": 4, "slot": "legs", "ilvl": 70, "st": "spi int sta", "bind": "bop", "armor_type": "cloth", "set": "cleric"},
	"mythic_worldbreaker": {"name": "Worldbreaker", "q": 5, "slot": "main_hand", "ilvl": 78, "st": "str sta", "bind": "bop", "wtype": "axe", "model": "worldbreaker", "use_power": "myth_quake", "desc": "Use (R): split the earth — heavy damage to every enemy within 10 metres. 2 min cooldown."},
	"mythic_eternity": {"name": "Eternity, Staff of Hours", "q": 5, "slot": "main_hand", "ilvl": 78, "st": "int spi sta", "bind": "bop", "wtype": "staff", "model": "eternity", "use_power": "myth_hours", "desc": "Use (R): stop the hours — your spells cost nothing and cast twice as fast for 10 seconds. 3 min cooldown."},
	"mythic_dawnbringer": {"name": "Dawnbringer", "q": 5, "slot": "main_hand", "ilvl": 78, "st": "spi int sta", "bind": "bop", "wtype": "mace", "model": "moon", "use_power": "myth_dawn", "desc": "Use (R): a second sunrise — heals you and everyone near you for a third of their health. 3 min cooldown."},
	# ---- Milestone 6 (levels 40–60)
	"crab_shell": {"name": "Cracked Crab Shell", "q": 0, "stack": 10, "sell": 64},
	"wreckers_trinket": {"name": "Wrecker's Trinket", "q": 0, "stack": 10, "sell": 72},
	"sea_glass": {"name": "Sea Glass", "q": 0, "stack": 10, "sell": 70},
	"serpent_scale": {"name": "Serpent Scale", "q": 0, "stack": 10, "sell": 78},
	"slag_lump": {"name": "Lump of Slag", "q": 0, "stack": 10, "sell": 84},
	"drake_scale": {"name": "Scorched Drake Scale", "q": 0, "stack": 10, "sell": 92},
	"obsidian_shard": {"name": "Obsidian Chip", "q": 0, "stack": 10, "sell": 88},
	"charred_fang": {"name": "Charred Fang", "q": 0, "stack": 10, "sell": 90},
	"frost_fang": {"name": "Frozen Fang", "q": 0, "stack": 10, "sell": 104},
	"rime_crystal": {"name": "Rime Crystal", "q": 0, "stack": 10, "sell": 110},
	"ram_wool": {"name": "Tuft of Ram's Wool", "q": 0, "stack": 10, "sell": 96},
	"void_ichor": {"name": "Void Residue", "q": 0, "stack": 10, "sell": 126},
	"voidstone": {"name": "Voidstone Fragment", "q": 0, "stack": 10, "sell": 132},
	"greaves_requisition": {"name": "Greaves' Requisition", "q": 1, "quest": true, "desc": "Salt fish, 40 barrels. Rivets, 12 crates. Patience, none left."},
	"tender_claw": {"name": "Tender Claw", "q": 1, "quest": true, "stack": 20},
	"lamp_oil_cask": {"name": "Cask of Lamp Oil", "q": 1, "quest": true, "stack": 20, "desc": "Stamped with a lighthouse."},
	"dry_driftwood": {"name": "Dry Driftwood", "q": 1, "quest": true, "stack": 20, "desc": "Pale, light, and bone-dry."},
	"drowned_locket": {"name": "Drowned Locket", "q": 1, "quest": true, "stack": 20, "desc": "There's a name inside."},
	"marens_cargo_note": {"name": "Maren's Cargo Note", "q": 1, "quest": true, "desc": "Addressed to Forgemaster Brunna, Forgehold. Smells of fish."},
	"obsidian_shard_q": {"name": "Obsidian Shard", "q": 1, "quest": true, "stack": 20, "desc": "Black glass with an edge like a razor."},
	"perfect_drake_scale": {"name": "Perfect Drake Scale", "q": 1, "quest": true, "stack": 20, "desc": "Shoulder scale, unscorched."},
	"brunnas_letter": {"name": "Brunna's Letter", "q": 1, "quest": true, "desc": "Addressed to Huntmaster Aldric, Wintermere. Warm to the touch."},
	"thick_white_pelt": {"name": "Thick White Pelt", "q": 1, "quest": true, "stack": 20},
	"ram_horn": {"name": "Ram's Horn", "q": 1, "quest": true, "stack": 20},
	"rune_shard": {"name": "Rune Shard", "q": 1, "quest": true, "stack": 20, "desc": "A flake of stone with a blue rune on it, still glowing faintly."},
	"aldrics_dispatch": {"name": "Aldric's Dispatch", "q": 1, "quest": true, "desc": "Addressed to High Marshal Corvin, the Last Watch."},
	"void_ichor_q": {"name": "Vial of Void Ichor", "q": 1, "quest": true, "stack": 20, "desc": "Don't drink it."},
	"salted_fish": {"name": "Salted Fish", "q": 1, "use": "food", "heal": 900, "stack": 20, "sell": 60, "desc": "Gullhaven's finest. Restores health while sitting."},
	"gullhaven_chowder": {"name": "Gullhaven Chowder", "q": 1, "use": "food", "heal": 1300, "stack": 20, "sell": 90, "desc": "Cask's crab chowder. Restores health while sitting."},
	"mountain_water": {"name": "Snowmelt Water", "q": 1, "use": "drink", "mana": 1100, "stack": 20, "sell": 60, "desc": "So cold it hurts your teeth."},
	"major_healing_potion": {"name": "Major Healing Potion", "q": 1, "use": "potion", "heal": 1400, "stack": 5, "sell": 120},
	"netmenders_gloves": {"name": "Netmender's Gloves", "q": 2, "slot": "hands", "ilvl": 42, "st": "int spi", "armor_type": "cloth", "bind": "quest"},
	"saltwind_cord": {"name": "Saltwind Cord", "q": 2, "slot": "waist", "ilvl": 42, "st": "int sta", "armor_type": "cloth", "bind": "quest"},
	"harbor_watch_girdle": {"name": "Harbour Watch Girdle", "q": 2, "slot": "waist", "ilvl": 43, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"keepers_lantern": {"name": "Keeper's Lantern", "q": 2, "slot": "trinket1", "ilvl": 43, "st": "int spi", "bind": "quest"},
	"tobiahs_oilskin": {"name": "Tobiah's Oilskin", "q": 2, "slot": "chest", "ilvl": 43, "st": "sta int", "armor_type": "cloth", "bind": "quest"},
	"lamplighters_rod": {"name": "Lamplighter's Rod", "q": 2, "slot": "main_hand", "ilvl": 43, "st": "int spi", "wtype": "wand", "bind": "quest"},
	"merrows_bell": {"name": "The Merrow's Bell", "q": 2, "slot": "neck", "ilvl": 44, "st": "sta spi", "bind": "quest"},
	"ioness_prayer_shawl": {"name": "Ione's Prayer Shawl", "q": 2, "slot": "shoulders", "ilvl": 44, "st": "spi int", "armor_type": "cloth", "bind": "quest"},
	"saltstone_signet": {"name": "Saltstone Signet", "q": 2, "slot": "finger1", "ilvl": 44, "st": "str sta", "bind": "quest"},
	"tidecallers_mantle": {"name": "Tidecaller's Mantle", "q": 2, "slot": "shoulders", "ilvl": 45, "st": "int sta", "armor_type": "cloth", "bind": "quest"},
	"brinewarden_helm": {"name": "Brinewarden Helm", "q": 2, "slot": "head", "ilvl": 45, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"coral_band": {"name": "Coral Band", "q": 2, "slot": "finger1", "ilvl": 45, "st": "int spi", "bind": "quest"},
	"snapjaw_shell_buckler": {"name": "Snapjaw Shell Pauldrons", "q": 3, "slot": "shoulders", "ilvl": 46, "st": "sta str", "armor_type": "plate", "bind": "quest"},
	"wrecker_kings_cleaver": {"name": "Wrecker King's Cleaver", "q": 2, "slot": "main_hand", "ilvl": 46, "st": "str sta", "wtype": "axe", "bind": "quest", "model": "axe"},
	"gutbags_crown_bell": {"name": "Gutbag's Bell-Crown", "q": 2, "slot": "head", "ilvl": 46, "st": "int sta", "armor_type": "cloth", "bind": "quest", "desc": "It still rings when you nod."},
	"vesks_cutlass_q": {"name": "Tidebreaker Cutlass", "q": 3, "slot": "main_hand", "ilvl": 48, "st": "str sta", "wtype": "sword", "bind": "quest", "model": "curved"},
	"admirals_greatcoat": {"name": "Admiral's Greatcoat", "q": 3, "slot": "chest", "ilvl": 48, "st": "int spi sta", "armor_type": "cloth", "bind": "quest"},
	"tidebound_signet": {"name": "Tidebound Signet", "q": 3, "slot": "finger1", "ilvl": 48, "st": "sta str int", "bind": "quest"},
	"glassedge_blade": {"name": "Glassedge Blade", "q": 2, "slot": "main_hand", "ilvl": 49, "st": "str sta", "wtype": "sword", "bind": "quest", "model": "serrated"},
	"obsidian_focus": {"name": "Obsidian Focus", "q": 2, "slot": "trinket1", "ilvl": 49, "st": "int spi", "bind": "quest"},
	"blackglass_legguards": {"name": "Blackglass Legguards", "q": 2, "slot": "legs", "ilvl": 49, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"smelters_gauntlets": {"name": "Smelter's Gauntlets", "q": 2, "slot": "hands", "ilvl": 50, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"furnaceheart_band": {"name": "Furnaceheart Band", "q": 2, "slot": "finger1", "ilvl": 50, "st": "int sta", "bind": "quest"},
	"ashworks_cloak": {"name": "Ashworks Cloak", "q": 2, "slot": "back", "ilvl": 50, "st": "sta spi", "bind": "quest"},
	"drakescale_vest": {"name": "Drakescale Vest", "q": 2, "slot": "chest", "ilvl": 50, "st": "sta str", "armor_type": "plate", "bind": "quest"},
	"drakehunters_boots": {"name": "Drakehunter's Treads", "q": 2, "slot": "feet", "ilvl": 50, "st": "int spi", "armor_type": "cloth", "bind": "quest"},
	"roostkeepers_charm": {"name": "Roostkeeper's Charm", "q": 2, "slot": "neck", "ilvl": 50, "st": "str sta", "bind": "quest"},
	"ketchs_longbow_charm": {"name": "Ketch's Bowstring", "q": 3, "slot": "trinket1", "ilvl": 52, "st": "str sta", "bind": "quest", "desc": "Eleven years of hunting, wound round your wrist."},
	"wardens_emberstave": {"name": "Warden's Emberstave", "q": 2, "slot": "main_hand", "ilvl": 51, "st": "int spi", "wtype": "staff", "bind": "quest", "model": "emberstaff"},
	"slagforged_pauldrons": {"name": "Slagforged Pauldrons", "q": 2, "slot": "shoulders", "ilvl": 51, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"cinderweave_wraps": {"name": "Cinderweave Wraps", "q": 2, "slot": "wrist", "ilvl": 51, "st": "int sta", "armor_type": "cloth", "bind": "quest"},
	"heart_of_azhul_q": {"name": "Cooling Ember of Azhul", "q": 3, "slot": "trinket1", "ilvl": 54, "st": "int spi sta", "bind": "quest"},
	"tharns_last_work": {"name": "Tharn's Last Work", "q": 3, "slot": "main_hand", "ilvl": 54, "st": "str sta", "wtype": "mace", "bind": "quest", "model": "club", "desc": "The last thing Tharn made before the mountain took him. It's perfect."},
	"emberheart_signet": {"name": "Emberheart Signet", "q": 3, "slot": "finger1", "ilvl": 54, "st": "str sta int", "bind": "quest"},
	"whitepelt_hood_cloak": {"name": "Whitepelt Cloak", "q": 2, "slot": "back", "ilvl": 54, "st": "sta str", "bind": "quest"},
	"tovess_mittens": {"name": "Tove's Mittens", "q": 2, "slot": "hands", "ilvl": 54, "st": "int spi", "armor_type": "cloth", "bind": "quest", "desc": "Knitted with love and a lot of wool."},
	"fur_lined_boots": {"name": "Fur-Lined Sabatons", "q": 2, "slot": "feet", "ilvl": 54, "st": "sta str", "armor_type": "plate", "bind": "quest"},
	"runescribes_circlet": {"name": "Runescribe's Circlet", "q": 2, "slot": "head", "ilvl": 55, "st": "int spi", "armor_type": "cloth", "bind": "quest"},
	"iceward_girdle": {"name": "Iceward Girdle", "q": 2, "slot": "waist", "ilvl": 55, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"barrow_kings_ring": {"name": "Barrow-King's Ring", "q": 2, "slot": "finger1", "ilvl": 55, "st": "sta int", "bind": "quest"},
	"sigruns_ember_charm": {"name": "Sigrun's Ember Charm", "q": 2, "slot": "neck", "ilvl": 56, "st": "spi int", "bind": "quest"},
	"frostbinder_robe": {"name": "Frostbinder Robe", "q": 2, "slot": "chest", "ilvl": 56, "st": "int sta", "armor_type": "cloth", "bind": "quest"},
	"wintersteel_legplates": {"name": "Wintersteel Legplates", "q": 2, "slot": "legs", "ilvl": 56, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"whitefang_mantle": {"name": "Whitefang Mantle", "q": 3, "slot": "shoulders", "ilvl": 57, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"crown_of_hrimgar_q": {"name": "Circlet of the Reach", "q": 3, "slot": "head", "ilvl": 59, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"frostspire_greatstaff": {"name": "Frostspire Greatstaff", "q": 3, "slot": "main_hand", "ilvl": 59, "st": "int spi sta", "wtype": "staff", "bind": "quest", "model": "moon"},
	"winterheart_pendant": {"name": "Winterheart Pendant", "q": 3, "slot": "neck", "ilvl": 59, "st": "int spi sta", "bind": "quest"},
	"watchguard_plate": {"name": "Watchguard Breastplate", "q": 2, "slot": "chest", "ilvl": 59, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"voidwarded_robe": {"name": "Voidwarded Robe", "q": 2, "slot": "chest", "ilvl": 59, "st": "int spi", "armor_type": "cloth", "bind": "quest"},
	"last_watch_signet": {"name": "Last Watch Signet", "q": 2, "slot": "finger1", "ilvl": 59, "st": "str sta", "bind": "quest"},
	"seers_voidglass": {"name": "Seer's Voidglass", "q": 2, "slot": "trinket1", "ilvl": 60, "st": "int spi", "bind": "quest"},
	"horrorbane_gauntlets": {"name": "Horrorbane Gauntlets", "q": 2, "slot": "hands", "ilvl": 60, "st": "str sta", "armor_type": "plate", "bind": "quest"},
	"unmade_cloak": {"name": "Cloak of the Unmade", "q": 2, "slot": "back", "ilvl": 60, "st": "sta int", "bind": "quest"},
	"heralds_bane": {"name": "Herald's Bane", "q": 3, "slot": "main_hand", "ilvl": 62, "st": "str sta", "wtype": "sword", "bind": "quest", "model": "abyssblade"},
	"kesss_voidmantle": {"name": "Kess's Voidmantle", "q": 3, "slot": "shoulders", "ilvl": 62, "st": "int spi sta", "armor_type": "cloth", "bind": "quest"},
	"crown_breaker_band": {"name": "Crown-Breaker Band", "q": 3, "slot": "finger1", "ilvl": 62, "st": "str sta int", "bind": "quest"},
	"bosuns_whistle": {"name": "Bosun's Whistle", "q": 3, "slot": "trinket1", "ilvl": 47, "st": "sta spi", "bind": "bop"},
	"barnacled_greaves": {"name": "Barnacled Greaves", "q": 3, "slot": "legs", "ilvl": 47, "st": "str sta", "armor_type": "plate", "bind": "bop"},
	"saltstained_wraps": {"name": "Saltstained Wraps", "q": 3, "slot": "wrist", "ilvl": 47, "st": "int spi", "armor_type": "cloth", "bind": "bop"},
	"brinemother_carapace": {"name": "Brine Mother's Carapace", "q": 3, "slot": "chest", "ilvl": 48, "st": "sta str", "armor_type": "plate", "bind": "bop"},
	"pearl_of_the_deep": {"name": "Pearl of the Deep", "q": 3, "slot": "neck", "ilvl": 48, "st": "int spi", "bind": "bop"},
	"tidewoven_mantle": {"name": "Tidewoven Mantle", "q": 3, "slot": "shoulders", "ilvl": 48, "st": "int sta", "armor_type": "cloth", "bind": "bop"},
	"vesks_cutlass": {"name": "Vesk's Cutlass", "q": 3, "slot": "main_hand", "ilvl": 50, "st": "str sta", "wtype": "sword", "bind": "bop", "model": "curved"},
	"drowned_admirals_coat": {"name": "Drowned Admiral's Coat", "q": 3, "slot": "chest", "ilvl": 50, "st": "int spi sta", "armor_type": "cloth", "bind": "bop"},
	"coral_crown": {"name": "Coral Crown", "q": 3, "slot": "head", "ilvl": 50, "st": "str sta", "armor_type": "plate", "bind": "bop"},
	"anchor_of_vesk": {"name": "Anchor of Vesk", "q": 3, "slot": "main_hand", "ilvl": 50, "st": "str sta", "wtype": "mace", "bind": "bop", "model": "worldbreaker"},
	"slagjaw_tooth": {"name": "Slagjaw's Tooth", "q": 3, "slot": "main_hand", "ilvl": 53, "st": "int sta", "wtype": "dagger", "bind": "bop", "model": "fang"},
	"molten_core_band": {"name": "Molten Core Band", "q": 3, "slot": "finger1", "ilvl": 53, "st": "str sta", "bind": "bop"},
	"smeltwalker_boots": {"name": "Smeltwalker Boots", "q": 3, "slot": "feet", "ilvl": 53, "st": "int spi", "armor_type": "cloth", "bind": "bop"},
	"tharns_forgehammer": {"name": "Tharn's Forgehammer", "q": 3, "slot": "main_hand", "ilvl": 55, "st": "str sta", "wtype": "mace", "bind": "bop", "model": "club"},
	"anvilplate_chest": {"name": "Anvilplate Chestguard", "q": 3, "slot": "chest", "ilvl": 55, "st": "str sta", "armor_type": "plate", "bind": "bop"},
	"bellows_gloves": {"name": "Bellows-Worker's Gloves", "q": 3, "slot": "hands", "ilvl": 55, "st": "int spi", "armor_type": "cloth", "bind": "bop"},
	"azhuls_emberstaff": {"name": "Azhul's Emberstaff", "q": 3, "slot": "main_hand", "ilvl": 56, "st": "int spi sta", "wtype": "staff", "bind": "bop", "model": "emberstaff"},
	"crown_of_cinders": {"name": "Crown of Cinders", "q": 3, "slot": "head", "ilvl": 56, "st": "str sta", "armor_type": "plate", "bind": "bop"},
	"pyrelord_pauldrons": {"name": "Pyrelord Pauldrons", "q": 3, "slot": "shoulders", "ilvl": 56, "st": "str sta", "armor_type": "plate", "bind": "bop"},
	"heart_of_the_forge": {"name": "Heart of the Forge", "q": 3, "slot": "trinket1", "ilvl": 56, "st": "int spi sta", "bind": "bop"},
	"frostmaw_hide": {"name": "Frostmaw Hide", "q": 3, "slot": "back", "ilvl": 58, "st": "sta str", "bind": "bop"},
	"ursoths_claw": {"name": "Ursoth's Claw", "q": 3, "slot": "main_hand", "ilvl": 58, "st": "str sta", "wtype": "axe", "bind": "bop", "model": "greataxe"},
	"icebound_girdle": {"name": "Icebound Girdle", "q": 3, "slot": "waist", "ilvl": 58, "st": "int spi", "armor_type": "cloth", "bind": "bop"},
	"skadis_frostcall": {"name": "Skadi's Frostcall", "q": 3, "slot": "main_hand", "ilvl": 60, "st": "int spi", "wtype": "wand", "bind": "bop"},
	"rimewoven_robe": {"name": "Rimewoven Robe", "q": 3, "slot": "chest", "ilvl": 60, "st": "int spi sta", "armor_type": "cloth", "bind": "bop"},
	"circlet_of_winter": {"name": "Circlet of Winter", "q": 3, "slot": "head", "ilvl": 60, "st": "int spi", "armor_type": "cloth", "bind": "bop"},
	"hrimgars_crown": {"name": "Hrimgar's Crown", "q": 3, "slot": "head", "ilvl": 61, "st": "str sta", "armor_type": "plate", "bind": "bop"},
	"frozen_kings_greatsword": {"name": "Frozen King's Greatsword", "q": 3, "slot": "main_hand", "ilvl": 61, "st": "str sta", "wtype": "sword", "bind": "bop", "model": "dragonblade"},
	"kingsfrost_legplates": {"name": "Kingsfrost Legplates", "q": 3, "slot": "legs", "ilvl": 61, "st": "str sta", "armor_type": "plate", "bind": "bop"},
	"shard_of_eternal_winter": {"name": "Shard of Eternal Winter", "q": 3, "slot": "trinket1", "ilvl": 61, "st": "int spi sta", "bind": "bop"},
}

## the starting kit for each class (equipped, then a little food in the bag)
const START := {
	"warrior": ["recruit_sword", "recruit_chest", "recruit_legs", "recruit_boots", "recruit_gloves"],
	"wizard": ["apprentice_staff", "apprentice_robe", "apprentice_pants", "apprentice_boots", "apprentice_wraps"],
	"cleric": ["acolyte_mace", "acolyte_vestment", "acolyte_pants", "acolyte_shoes", "acolyte_sleeves", "acolyte_collar"],
}

static var _mats := {}

static func get_def(it: Dictionary) -> Dictionary:
	if _mats.is_empty(): _mats = Crafting.materials()
	var id: String = it.get("id", "")
	var base: Dictionary = LIST.get(id, _mats.get(id, {}))
	if base.has("st"): base = _expand(id, base)
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
	return clampi(il - [0, 0, 5, 8, 10, 12][int(d.get("q", 1))], 1, Rules.MAX_LEVEL)

static func color(d: Dictionary) -> Color:
	return QUALITY[clampi(int(d.get("q", 1)), 0, 5)]["color"]

static func def(id: String) -> Dictionary:
	return get_def({"id": id})

## Compact item specs: {"name", "q", "slot", "armor_type" or "wtype", "ilvl", "st": "str sta"} — the
## stats it leans on. Armour, stat amounts, weapon damage, spell power, the look and the sell price
## are worked out from the item level, quality and slot the first time the item is asked for.
static var _gen := {}
const SLOT_BUDGET := {"chest": 1.0, "legs": 1.0, "head": 1.0, "shoulders": 0.8, "hands": 0.75, "feet": 0.75, "waist": 0.7, "wrist": 0.6,
	"back": 0.6, "finger": 0.7, "neck": 0.7, "trinket": 0.75, "main_hand": 0.75, "off_hand": 0.6}
const SLOT_LOOK := {"chest": ["Body_Armor", "Body"], "legs": ["Legs", "Legs"], "head": ["Head_Armet", ""], "hands": ["Arms", "Arms"], "feet": ["Feet", "Feet"],
	"shoulders": ["Acc_Pauldron_Round", "Acc_Pauldron"]}
const WTYPE := {"sword": [2.6, "long", 1.0], "axe": [2.7, "greataxe", 1.0], "mace": [2.6, "club", 1.0], "staff": [3.0, "crystalstaff", 1.3],
	"wand": [1.8, "wand", 0.9], "dagger": [1.8, "dagger", 0.95]}

static func _expand(id: String, s: Dictionary) -> Dictionary:
	if _gen.has(id): return _gen[id]
	var d := s.duplicate(true); d.erase("st")
	var il := int(d.get("ilvl", 40)); var q := int(d.get("q", 2))
	var slot := slot_of(d)
	var qm: float = {2: 1.0, 3: 1.45, 4: 1.85, 5: 2.3}.get(q, 0.8)
	var budget: float = il * 0.62 * qm * float(SLOT_BUDGET.get(slot, 0.75))
	var keys := String(s["st"]).split(" ", false)
	var wt: String = d.get("wtype", "")
	if wt == "staff": budget *= 1.7
	var stats := {}
	var wsum := 0.0
	for i in keys.size(): wsum += 1.25 if i == 0 else 1.0
	for i in keys.size():
		if keys[i] == "sp": continue
		stats[keys[i]] = maxi(1, int(round(budget * (1.25 if i == 0 else 1.0) / wsum)))
	if not stats.is_empty(): d["stats"] = stats
	if "sp" in keys or wt in ["staff", "wand"]: d["sp"] = int(il * 0.45 * qm * (1.4 if wt == "staff" else 0.8))
	if d.has("armor_type") and not d.has("armor"):
		var at: String = d["armor_type"]
		d["armor"] = int(ARMOR_PER[at] * float(SLOT_ARMOR.get(slot, 0.5)) * (1.0 + il * 0.35) * {2: 2.2, 3: 2.6, 4: 3.0, 5: 3.4}.get(q, 2.0))
		if SLOT_LOOK.has(slot) and not d.has("look"):
			var fam: String = LOOK_FAMILY[at]
			var part: String = SLOT_LOOK[slot][0] if fam == "Knight" else SLOT_LOOK[slot][1]
			if part != "": d["look"] = ["%s_%s" % [fam, part], fam, 3 if q >= 3 else 2]
			if fam == "Wizard" and slot == "shoulders": d["look"] = ["Noble_Acc_Pauldron", "Noble", 3 if q >= 3 else 2]
			if fam == "Knight" and slot == "head" and q >= 4 and not d.has("set"): d["look"] = ["Knight_Head_Horns", "Knight", 3]
			if fam == "Knight" and slot == "shoulders" and q >= 3: d["look"] = ["Knight_Acc_Pauldron_Spike", "Knight", 3]
	if wt != "" and not d.has("weapon"):
		var w: Array = WTYPE[wt]
		var dps: float = (1.5 + 0.55 * il) * float(w[2]) * {2: 1.0, 3: 1.12, 4: 1.25, 5: 1.4}.get(q, 1.0)
		var spd: float = w[0]
		d["weapon"] = [int(dps * spd * 0.75), int(ceil(dps * spd * 1.25)), spd]
		if not d.has("model"): d["model"] = w[1]
	if not d.has("sell"): d["sell"] = int(il * il * 1.6 * {2: 1.4, 3: 2.2, 4: 3.0, 5: 4.0}.get(q, 1.0))
	_gen[id] = d
	return d

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
const ARMOR_PER := {"cloth": 3.0, "leather": 6.0, "mail": 12.0, "plate": 15.0}
const SLOT_ARMOR := {"chest": 1.0, "legs": 0.85, "head": 0.8, "shoulders": 0.7, "feet": 0.6, "hands": 0.55, "waist": 0.45, "wrist": 0.4, "back": 0.4}

## weapons that drop: [weapon type, name, speed, model, dps scale]
const WEAPON_BASES := [["sword", "Blade", 2.4, "sword", 1.0], ["sword", "Longsword", 2.6, "long", 1.0], ["axe", "Hatchet", 2.5, "axe", 1.0],
	["mace", "Cudgel", 2.6, "club", 1.0], ["staff", "Staff", 3.0, "staff", 1.3], ["staff", "Walking Staff", 2.9, "wood", 1.3], ["wand", "Wand", 1.8, "wand", 0.9],
	["dagger", "Dirk", 1.8, "dagger", 0.95]]

static func roll(level: int, rng: RandomNumberGenerator, quality := 2) -> Dictionary:
	if rng.randf() < 0.3: return _roll_weapon(level, rng, quality)
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

static func _roll_weapon(level: int, rng: RandomNumberGenerator, quality: int) -> Dictionary:
	var b: Array = WEAPON_BASES[rng.randi() % WEAPON_BASES.size()]
	var ilvl := maxi(2, level + rng.randi_range(0, 3))
	var affix: String = AFFIX.keys()[rng.randi() % AFFIX.size()]
	var dps: float = (1.5 + 0.55 * ilvl) * float(b[4]) * (1.0 if quality == 2 else 1.12)
	var spd: float = b[2]
	var stats := {}
	var budget: float = ilvl * (0.9 if quality == 2 else 1.3) * 0.55 + 1.0
	for k in AFFIX[affix]: stats[k] = maxi(1, int(round(budget * AFFIX[affix][k])))
	var d := {"name": "%s %s %s" % [PREFIX[rng.randi() % PREFIX.size()], b[1], affix], "q": quality, "slot": "main_hand", "wtype": b[0], "ilvl": ilvl,
		"weapon": [int(dps * spd * 0.75), int(ceil(dps * spd * 1.25)), spd], "stats": stats, "model": b[3],
		"sell": int(ilvl * ilvl * 2.0 * (1.0 if quality == 2 else 2.2)) + 15, "bind": "boe"}
	if b[0] in ["staff", "wand"]: d["sp"] = int(ilvl * 0.4)
	return {"id": "rolled", "rolled": d, "n": 1}

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
		if d.has("mana_now"): t += "[color=#1eff00]Use: Restores %d mana.[/color]\n" % int(d["mana_now"])
	if d.has("mat"): t += "[color=#9ad0ff]Crafting material (tier %d)[/color]\n" % int(d["tier"])
	if d.get("crafted", false): t += "[color=#9a9a9a]Crafted[/color]\n"

	var rl := req_level(d)
	if d.has("slot") and rl > 1: t += ("[color=#ff2020]" if level < rl else "") + "Requires Level %d" % rl + ("[/color]" if level < rl else "") + "\n"
	if cls != "" and d.has("slot") and not can_use(cls, d, 99): t += "[color=#ff2020]Your class can't use this[/color]\n"
	if d.has("desc"): t += "[color=#ffd100]\"%s\"[/color]\n" % d["desc"]
	if int(d.get("sell", 0)) > 0: t += "Sell Price: %s" % money(int(d["sell"]))
	return t.strip_edges()
