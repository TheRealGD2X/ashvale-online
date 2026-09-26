class_name Monster extends Unit
## A monster: wanders near its home, notices people who come too close (the higher its level
## compared to yours, the further it notices you), calls its friends, fights whoever it hates
## most (threat), gives up and walks home if dragged too far (leash), and comes back a while
## after it dies.

## body: "bestiary" (a paid-pack monster), "creature" (our animals) or "scarecrow" (a dressed-up
## person with a sack for a head). passive: only fights back. critter: harmless (hens).
const KINDS := {
	"field_rat": {"creature": "rat", "type": "beast", "scale": 1.5, "speed": 1.6, "names": ["Field Rat"], "aggro": 5.0, "loot": ["rat_tail"]},
	"grizzled_rat": {"creature": "rat", "type": "beast", "scale": 2.6, "speed": 1.8, "names": ["Grizzled Rat"], "aggro": 7.0, "named": true, "loot": ["rat_tail"]},
	"hen": {"creature": "hen", "type": "beast", "scale": 1.0, "speed": 2.0, "names": ["Hen"], "critter": true, "loot": ["chicken_egg"]},
	"wild_boar": {"creature": "boar", "type": "beast", "scale": 1.35, "speed": 2.2, "names": ["Wild Boar", "Rooting Boar"], "passive": true, "loot": ["cracked_tusk", "boar_hide"]},
	"hogtooth": {"creature": "boar", "type": "beast", "scale": 2.1, "speed": 2.4, "names": ["Hogtooth, the Boar King"], "loot": ["cracked_tusk"], "named": true},
	"old_tusk": {"creature": "boar", "type": "beast", "scale": 2.3, "speed": 2.4, "names": ["Old Tusk"], "loot": ["cracked_tusk"], "named": true, "rare": true, "drop": ["old_tusks_tusk"]},

	"wildcat": {"creature": "wildcat", "type": "beast", "scale": 1.4, "speed": 1.6, "names": ["Wildcat"], "loot": ["matted_fur"]},
	"old_scratch": {"creature": "wildcat", "type": "beast", "scale": 1.9, "speed": 1.5, "names": ["Old Scratch"], "loot": ["matted_fur"], "named": true},
	"wolf": {"creature": "wolf", "type": "beast", "scale": 1.3, "speed": 2.0, "names": ["Timber Wolf"], "loot": ["matted_fur"]},
	"scarecrow": {"scarecrow": true, "type": "elemental", "scale": 1.0, "speed": 2.6, "names": ["Walking Scarecrow"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle",
		"attack": ["Zombie_Scratch", "Punch_Cross"], "loot": ["straw_bundle"]},
	# ---- Hollow Cliffs (10–16)
	"cave_bat": {"creature": "bat", "type": "beast", "scale": 1.4, "speed": 1.5, "names": ["Cave Bat", "Screeching Bat"], "loot": ["bat_wing"]},
	"cave_maggot": {"creature": "maggot", "type": "beast", "scale": 1.6, "speed": 2.0, "names": ["Cave Maggot"], "loot": ["maggot_goo"], "aggro": 6.0},
	"rail_spider": {"creature": "spider", "type": "beast", "scale": 1.3, "speed": 1.7, "names": ["Rail Spider", "Lantern Row Lurker"], "loot": ["spider_silk"]},
	"mountain_bear": {"creature": "bear", "type": "beast", "scale": 1.2, "speed": 2.4, "names": ["Mountain Bear"], "loot": ["matted_fur"]},
	"rockjaw": {"creature": "bear", "type": "beast", "scale": 1.7, "speed": 2.4, "names": ["Rockjaw"], "named": true, "loot": ["matted_fur"], "spells": ["ravage"]},
	"hollow_digger": {"avatar": "peasant", "tool": "pickaxe", "type": "humanoid", "scale": 1.0, "speed": 2.4, "names": ["Hollow Digger", "Hollow Delver", "Tunnel Rat"],
		"attack": ["Sword_Regular_A", "Sword_Regular_B"], "loot": ["rough_stone", "miners_wages"]},
	"skarr": {"avatar": "warrior", "tool": "pickaxe", "type": "humanoid", "scale": 1.15, "speed": 2.6, "names": ["Deep Foreman Skarr"], "named": true,
		"attack": ["Sword_Regular_A", "Sword_Heavy_Combo"], "drop": ["skarrs_key"], "spells": ["ravage"]},
	"brak": {"model": "Tidebreaker", "type": "humanoid", "scale": 0.9, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.0, "names": ["Brak, Skarr's Enforcer"], "spells": ["tidal_slam"]},
	# ---- the Hollow Mine (dungeon)
	"grub_mother": {"creature": "maggot", "type": "beast", "scale": 3.6, "speed": 2.2, "names": ["The Grub Mother"], "boss": "grub", "loot": ["maggot_goo"], "drop_one": ["grubhide_jerkin", "lantern_row_cord"]},
	"gault": {"avatar": "warrior", "tool": "pickaxe", "type": "humanoid", "scale": 1.12, "speed": 2.4, "names": ["Foreman Gault"], "boss": "gault", "drop_one": ["foremans_maul", "gaults_ledger_staff"],
		"attack": ["Sword_Regular_A", "Sword_Regular_B", "Sword_Heavy_Combo"]},
	"bone_king": {"model": "Skeleton_B", "type": "undead", "scale": 1.7, "attack": ["Sword_Heavy_Combo", "Sword_Regular_C"], "speed": 3.0, "names": ["The Bone King"], "boss": "bone_king", "drop_one": ["bone_kings_circlet", "marrowplate_pauldrons", "hollow_crown_band"],
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "spells": ["hellfire_ring"]},
	"bone_cage": {"cage": true, "type": "undead", "scale": 1.0, "speed": 99.0, "names": ["Bone Prison"]},
	# ---- Mirewood (14–22)
	"mire_goblin": {"model": "Puglin", "type": "humanoid", "scale": 1.05, "attack": ["Punch_Jab", "Punch_Cross"], "speed": 2.0, "names": ["Mire Goblin", "Mire Goblin Scrapper", "Bog Snatcher"],
		"walk": "Walk", "loot": ["puglin_trinket", "goblin_ear"]},
	"goblin_shaman": {"model": "Puglin", "type": "humanoid", "scale": 0.95, "attack": ["Punch_Jab"], "speed": 2.0, "names": ["Mire Goblin Shaman"], "walk": "Walk", "caster": true,
		"spells": ["bog_bolt"], "loot": ["puglin_trinket"]},
	"goblin_lieutenant": {"model": "Puglin", "type": "humanoid", "scale": 1.35, "attack": ["Punch_Cross", "Melee_Hook"], "speed": 2.2, "names": ["Grisk, the Warlord's Lieutenant"], "named": true,
		"walk": "Walk", "spells": ["ravage"]},
	"goblin_warlord": {"model": "Puglin", "type": "humanoid", "scale": 1.7, "attack": ["Punch_Cross", "Melee_Hook"], "speed": 2.6, "names": ["Gorvok the Goblin Warlord"], "named": true,
		"walk": "Walk", "spells": ["tidal_slam"], "drop": ["warlords_horn"]},
	"viper": {"creature": "snake", "type": "beast", "scale": 1.5, "speed": 1.6, "names": ["Reed Viper", "Mire Adder"], "loot": ["viper_fang"]},
	"temple_moth": {"creature": "moth", "type": "beast", "scale": 1.6, "speed": 1.8, "names": ["Temple Moth", "Dusky Moth"], "loot": ["moth_wing"]},
	"marsh_stalker": {"model": "Lycan", "type": "beast", "scale": 0.9, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.0, "names": ["Marsh Stalker"], "walk": "Jog_Fwd", "loot": ["matted_fur"]},
	"broodmother": {"creature": "spider", "type": "beast", "scale": 3.4, "speed": 2.0, "names": ["The Broodmother"], "boss": "brood", "drop_one": ["broodsilk_mantle", "venomfang_dirk"]},
	"rootmaw": {"model": "Tidebreaker", "type": "elemental", "scale": 1.25, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.2, "names": ["Old Rootmaw"], "boss": "rootmaw",
		"spells": ["tidal_slam"], "drop_one": ["rootmaw_heartwood_staff", "barkskin_legguards", "mirewarden_signet"]},
	# ---- Ash Slopes (20–28)
	"stone_sentinel": {"model": "Tidebreaker", "type": "elemental", "scale": 0.85, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.0, "names": ["Stone Sentinel", "Cinder Sentinel"],
		"walk": "Walk", "loot": ["rough_stone"]},
	"khar_cultist": {"avatar": "wizard", "tool": "skullstaff", "type": "humanoid", "scale": 1.0, "speed": 2.6, "names": ["Khar Cultist", "Khar Initiate", "Ashen Acolyte"], "caster": true,
		"attack": ["Sword_Regular_A"], "spells": ["ember_bolt"], "loot": ["cultist_robe_scrap"], "tint": 3},
	"khar_zealot": {"avatar": "warrior", "tool": "reaver", "type": "humanoid", "scale": 1.05, "speed": 2.5, "names": ["Khar Zealot"], "attack": ["Sword_Regular_A", "Sword_Regular_B"],
		"loot": ["cultist_robe_scrap"], "tint": 3},
	"temple_archer": {"avatar": "ranger", "tool": "wood", "type": "humanoid", "scale": 1.0, "speed": 2.4, "names": ["Temple Archer"], "caster": true, "attack": ["Sword_Regular_A"],
		"spells": ["arrow_shot"], "loot": ["guardian_arrow_scrap"]},
	"cinder_imp": {"model": "Imp", "type": "demon", "scale": 1.1, "attack": ["Sword_Regular_A", "Melee_Hook"], "speed": 1.8, "names": ["Cinder Imp", "Ashen Imp"], "walk": "Walk", "caster": true,
		"spells": ["ember_bolt"], "loot": ["brimstone_chip"]},
	"stone_warden": {"model": "Hellwarden", "type": "elemental", "scale": 1.15, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["The Stone Warden"], "named": true,
		"walk": "Walk", "spells": ["hellfire_ring"]},
	"bellringer": {"avatar": "cleric", "tool": "club", "type": "humanoid", "scale": 1.15, "speed": 2.6, "names": ["Brother Kel, the Bellringer"], "boss": "bell",
		"attack": ["Sword_Regular_A", "Sword_Heavy_Combo"], "drop_one": ["bellringers_cowl", "tolling_mace"]},
	"ashmaw": {"model": "Hellwarden", "type": "demon", "scale": 1.4, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Ashmaw"], "boss": "ashmaw",
		"walk": "Walk", "spells": ["hellfire_ring"], "drop_one": ["ashmaw_hide_mantle", "cinderheart_ring"]},
	"mora": {"avatar": "wizard", "tool": "skullstaff", "type": "humanoid", "scale": 1.15, "speed": 2.6, "names": ["High Cultist Mora"], "boss": "mora", "caster": true,
		"attack": ["Sword_Regular_A"], "spells": ["ember_bolt"], "drop_one": ["moras_ashen_staff", "soulthread_robe", "khar_signet"]},
	# ---- Ashen Highlands (26–34)
	"khar_beastman": {"model": "Lycan", "type": "humanoid", "scale": 1.0, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.2, "names": ["Khar Beastman", "Khar Raider"], "walk": "Jog_Fwd", "loot": ["khar_horn_chip"]},
	"khar_elite": {"model": "Lycan", "type": "humanoid", "scale": 1.15, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.4, "names": ["Khar Bloodguard"], "walk": "Jog_Fwd", "spells": ["ravage"], "loot": ["khar_horn_chip"]},
	"brandmaster": {"model": "Lycan", "type": "humanoid", "scale": 1.35, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.4, "names": ["Ghor the Brandmaster"], "named": true, "walk": "Jog_Fwd", "spells": ["ravage", "tidal_slam"]},
	"bull_of_khar": {"model": "Hellwarden", "type": "humanoid", "scale": 1.5, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.2, "names": ["The Bull of Khar"], "named": true, "walk": "Walk", "spells": ["hellfire_ring"]},
	"highland_wolf": {"creature": "wolf", "type": "beast", "scale": 1.45, "speed": 2.0, "names": ["Highland Wolf", "Grey Runner"], "loot": ["matted_fur"]},
	"highland_bear": {"creature": "bear", "type": "beast", "scale": 1.35, "speed": 2.4, "names": ["Highland Bear"], "loot": ["matted_fur"]},
	"drowned_dead": {"model": "Skeleton_A", "type": "undead", "scale": 1.05, "attack": ["Sword_Regular_A", "Sword_Regular_B"], "speed": 2.4, "names": ["Drowned Dead", "Crypt Sleeper"],
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["bone_fragment"]},
	"lady_silt": {"model": "Skeleton_B", "type": "undead", "scale": 1.4, "attack": ["Sword_Regular_C", "Sword_Heavy_Combo"], "speed": 2.8, "names": ["Lady Silt"], "boss": "gault", "adds": "drowned_dead",
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "spells": ["tidal_slam"], "drop_one": ["siltveil_cowl", "drowned_kings_blade"]},
	"crypt_lord": {"model": "Skeleton_B", "type": "undead", "scale": 1.75, "attack": ["Sword_Heavy_Combo", "Sword_Regular_C"], "speed": 3.0, "names": ["The Crypt Lord"], "boss": "bone_king",
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "spells": ["hellfire_ring"], "drop_one": ["cryptlord_greaves", "lakebound_band", "sunken_staff"]},
	# ---- Varn Plateau (34–40)
	"fallen_wraith": {"model": "Skeleton_B", "type": "undead", "scale": 1.1, "attack": ["Sword_Regular_B", "Sword_Regular_C"], "speed": 2.4, "names": ["Fallen Wraith", "Varn Revenant"],
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["bone_fragment"]},
	"abyssal_knight": {"model": "Hellwarden", "type": "demon", "scale": 1.0, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Abyssal Knight"], "walk": "Walk", "loot": ["brimstone_chip"]},
	"lich_acolyte": {"avatar": "wizard", "tool": "skullstaff", "type": "humanoid", "scale": 1.0, "speed": 2.6, "names": ["Lich Acolyte", "Varn Deathspeaker"], "caster": true, "tint": 2,
		"attack": ["Sword_Regular_A"], "spells": ["ember_bolt"], "loot": ["cultist_robe_scrap"]},
	"circle_acolyte": {"avatar": "wizard", "tool": "skullstaff", "type": "humanoid", "scale": 1.15, "speed": 2.6, "names": ["Acolyte Veyne", "Acolyte Marr", "Acolyte Soth"], "named": true, "caster": true, "tint": 3,
		"attack": ["Sword_Regular_A"], "spells": ["ember_bolt", "hellfire_ring"]},
	"vaals_herald": {"model": "Hellwarden", "type": "demon", "scale": 1.6, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Vaal's Herald"], "named": true, "walk": "Walk", "spells": ["hellfire_ring"]},
	"gravewarden": {"model": "Hellwarden", "type": "demon", "scale": 1.3, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["The Gravewarden"], "boss": "gault", "adds": "fallen_wraith",
		"walk": "Walk", "drop_one": ["gravewarden_plate", "catacomb_lantern"]},
	"lord_varn": {"model": "Skeleton_B", "type": "undead", "scale": 1.85, "attack": ["Sword_Heavy_Combo", "Sword_Regular_C"], "speed": 3.0, "names": ["Lord Varn, the Hollow Lich"], "boss": "bone_king",
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "spells": ["hellfire_ring"], "drop_one": ["varns_crown", "lichbone_staff", "varn_signet", "deathwalker_boots"]},
	# ---- Saltmere Coast (40–46)
	"tide_crab": {"creature": "crab", "type": "beast", "scale": 2.0, "speed": 1.8, "names": ["Tide Crab", "Shore Crab"], "loot": ["crab_shell"]},
	"puglin_wrecker": {"model": "Puglin", "type": "humanoid", "scale": 1.15, "attack": ["Punch_Jab", "Punch_Cross"], "speed": 2.2, "names": ["Puglin Wrecker", "Wrecker Lookout"],
		"walk": "Walk", "loot": ["wreckers_trinket"]},
	"drowned_sailor": {"model": "Skeleton_A", "type": "undead", "scale": 1.05, "attack": ["Sword_Regular_A", "Sword_Regular_B"], "speed": 2.4, "names": ["Drowned Sailor", "Drowned Deckhand"],
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["sea_glass"]},
	"sea_serpent": {"creature": "serpent", "type": "beast", "scale": 2.6, "speed": 2.0, "names": ["Sea Serpent", "Coastcoil"], "loot": ["serpent_scale"]},
	"tidecaller": {"model": "Tidebreaker", "type": "elemental", "scale": 0.95, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.0, "names": ["Tidecaller"], "caster": true,
		"spells": ["brine_bolt", "tidal_slam"], "loot": ["sea_glass"]},
	"snapjaw": {"creature": "crab", "type": "beast", "scale": 3.4, "speed": 2.0, "names": ["Old Snapjaw"], "named": true, "loot": ["crab_shell"]},
	"gutbag": {"model": "Puglin", "type": "humanoid", "scale": 1.65, "attack": ["Punch_Jab", "Punch_Cross"], "speed": 2.4, "names": ["Gutbag, the Wrecker King"], "named": true,
		"walk": "Walk", "spells": ["ravage"], "loot": ["wreckers_trinket"]},
	"bosun_grell": {"model": "Skeleton_A", "type": "undead", "scale": 1.55, "attack": ["Sword_Heavy_Combo", "Sword_Regular_C"], "speed": 2.8, "names": ["Bosun Grell"], "boss": "gault",
		"adds": "drowned_sailor", "yell": ["All hands! All hands!", "Man the lines, you dogs!", "Up from the bilge, lads!"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle",
		"spells": ["tidal_slam"], "drop_one": ["bosuns_whistle", "barnacled_greaves", "saltstained_wraps"]},
	"brine_mother": {"creature": "crab", "type": "beast", "scale": 4.4, "speed": 2.2, "names": ["The Brine Mother"], "boss": "brood", "hatch": ["tide_crab", "Brineling", 4],
		"hatch_yell": "The brood spills out of the shallows!", "drop_one": ["brinemother_carapace", "pearl_of_the_deep", "tidewoven_mantle"]},
	"admiral_vesk": {"model": "Skeleton_B", "type": "undead", "scale": 1.95, "attack": ["Sword_Heavy_Combo", "Sword_Regular_C"], "speed": 3.0, "names": ["Admiral Vesk, the Drowned"],
		"boss": "bone_king", "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "spells": ["tidal_slam"], "drop_one": ["vesks_cutlass", "drowned_admirals_coat", "coral_crown", "anchor_of_vesk"]},
	# ---- Emberreach (46–52)
	"magma_worm": {"creature": "magmaworm", "type": "elemental", "scale": 2.2, "speed": 1.8, "names": ["Magma Worm", "Cinder Crawler"], "aggro": 6.0, "loot": ["slag_lump"]},
	"ember_drake": {"creature": "drake", "type": "dragonkin", "scale": 2.0, "speed": 1.6, "names": ["Ember Drake", "Ash Drake"], "loot": ["drake_scale"]},
	"cinder_fiend": {"model": "Imp", "type": "demon", "scale": 1.25, "attack": ["Sword_Regular_A", "Melee_Hook"], "speed": 1.9, "names": ["Cinder Fiend", "Forge Imp"], "walk": "Walk",
		"caster": true, "spells": ["ember_bolt"], "loot": ["brimstone_chip"]},
	"obsidian_guard": {"model": "Hellwarden", "type": "elemental", "scale": 1.1, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Obsidian Guardian"], "walk": "Walk",
		"loot": ["obsidian_shard"]},
	"cinderhide": {"model": "Lycan", "type": "humanoid", "scale": 1.1, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.3, "names": ["Cinderhide Ravager", "Cinderhide Howler"],
		"walk": "Jog_Fwd", "spells": ["ravage"], "loot": ["charred_fang"]},
	"slag_elemental": {"model": "Tidebreaker", "type": "elemental", "scale": 1.1, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.0, "names": ["Slag Elemental"],
		"spells": ["magma_spit"], "loot": ["slag_lump"]},
	"pyreclaw": {"creature": "drake", "type": "dragonkin", "scale": 3.2, "speed": 1.8, "names": ["Pyreclaw"], "named": true, "spells": ["magma_spit"], "loot": ["drake_scale"]},
	"the_smelter": {"model": "Hellwarden", "type": "elemental", "scale": 1.65, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["The Smelter"], "named": true,
		"walk": "Walk", "spells": ["hellfire_ring"], "loot": ["obsidian_shard"]},
	"slagjaw": {"creature": "magmaworm", "type": "elemental", "scale": 4.6, "speed": 2.0, "names": ["Slagjaw"], "boss": "grub", "dive_yell": "The rock melts and heaves...",
		"drop_one": ["slagjaw_tooth", "molten_core_band", "smeltwalker_boots"]},
	"forgemaster_tharn": {"avatar": "warrior", "tool": "club", "type": "humanoid", "scale": 1.3, "speed": 2.6, "names": ["Forgemaster Tharn"], "boss": "bell", "bell_yell": "Feel the hammer!",
		"attack": ["Sword_Regular_A", "Sword_Heavy_Combo"], "drop_one": ["tharns_forgehammer", "anvilplate_chest", "bellows_gloves"]},
	"pyrelord_azhul": {"model": "Hellwarden", "type": "demon", "scale": 2.1, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Pyrelord Azhul"], "boss": "nova",
		"nova": "pyre_nova", "nova_yell": ["Burn!", "The forge remembers its master!", "Into the fire!"], "walk": "Walk", "spells": ["magma_spit"],
		"drop_one": ["azhuls_emberstaff", "crown_of_cinders", "pyrelord_pauldrons", "heart_of_the_forge"]},
	# ---- The Pale Reach (52–57)
	"frost_wolf": {"creature": "frostwolf", "type": "beast", "scale": 1.5, "speed": 2.0, "names": ["Frost Wolf", "Rimefang"], "loot": ["frost_fang"]},
	"snow_bear": {"creature": "snowbear", "type": "beast", "scale": 1.45, "speed": 2.4, "names": ["Snow Bear", "Whitepelt"], "loot": ["frost_fang"]},
	"mountain_ram": {"creature": "ram", "type": "beast", "scale": 1.3, "speed": 1.8, "names": ["Mountain Ram"], "passive": true, "loot": ["ram_horn"]},
	"rimeborn": {"model": "Skeleton_B", "type": "undead", "scale": 1.1, "attack": ["Sword_Regular_B", "Sword_Regular_C"], "speed": 2.4, "names": ["Rimeborn Warrior", "Rimeborn Thane"],
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["rime_crystal"]},
	"ice_golem": {"model": "Tidebreaker", "type": "elemental", "scale": 1.15, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.0, "names": ["Ice Golem"], "spells": ["tidal_slam"],
		"loot": ["rime_crystal"]},
	"snowmane": {"model": "Lycan", "type": "humanoid", "scale": 1.15, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.3, "names": ["Snowmane Lycan", "Snowmane Howler"], "walk": "Jog_Fwd",
		"spells": ["ravage"], "loot": ["frost_fang"]},
	"rime_witch": {"avatar": "wizard", "tool": "crystalstaff", "type": "humanoid", "scale": 1.0, "speed": 2.6, "names": ["Rime Witch", "Frostbinder"], "caster": true, "tint": 1,
		"attack": ["Sword_Regular_A"], "spells": ["frost_lance"], "loot": ["rime_crystal"]},
	"old_whitefang": {"creature": "frostwolf", "type": "beast", "scale": 2.4, "speed": 2.2, "names": ["Old Whitefang"], "named": true, "spells": ["ravage"], "loot": ["frost_fang"]},
	"ursoth": {"creature": "snowbear", "type": "beast", "scale": 3.4, "speed": 2.6, "names": ["Ursoth the Frostmaw"], "boss": "rootmaw", "roots_yell": "The ice holds you fast!",
		"rage_yell": "RRRAAAWR!", "drop_one": ["frostmaw_hide", "ursoths_claw", "icebound_girdle"]},
	"skadi": {"avatar": "wizard", "tool": "crystalstaff", "type": "humanoid", "scale": 1.2, "speed": 2.6, "names": ["Rime Witch Skadi"], "boss": "mora", "caster": true, "tint": 1,
		"drain_yell": "Your warmth is mine, %s!", "attack": ["Sword_Regular_A"], "spells": ["frost_lance"], "drop_one": ["skadis_frostcall", "rimewoven_robe", "circlet_of_winter"]},
	"hrimgar": {"model": "Skeleton_B", "type": "undead", "scale": 2.05, "attack": ["Sword_Heavy_Combo", "Sword_Regular_C"], "speed": 3.0, "names": ["Hrimgar, the Frozen King"],
		"boss": "bone_king", "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "spells": ["glacial_nova"],
		"drop_one": ["hrimgars_crown", "frozen_kings_greatsword", "kingsfrost_legplates", "shard_of_eternal_winter"]},
	# ---- Vaal's Scar (57–60)
	"void_imp": {"model": "Imp", "type": "demon", "scale": 1.1, "attack": ["Sword_Regular_A", "Melee_Hook"], "speed": 1.9, "names": ["Void Imp", "Voidling"], "walk": "Walk",
		"caster": true, "spells": ["void_bolt"], "loot": ["void_ichor"]},
	"voidforged": {"model": "Hellwarden", "type": "demon", "scale": 1.1, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Voidforged Knight"], "walk": "Walk",
		"loot": ["voidstone"]},
	"soul_wraith": {"model": "Skeleton_B", "type": "undead", "scale": 1.1, "attack": ["Sword_Regular_B", "Sword_Regular_C"], "speed": 2.5, "names": ["Soul Wraith", "Scar Revenant"],
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["void_ichor"]},
	"void_horror": {"model": "Tidebreaker", "type": "demon", "scale": 1.25, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.0, "names": ["Void Horror"], "spells": ["void_nova"],
		"loot": ["voidstone"]},
	"vaals_chosen": {"model": "Lycan", "type": "demon", "scale": 1.2, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.4, "names": ["Vaal's Chosen"], "walk": "Jog_Fwd",
		"spells": ["ravage"], "loot": ["voidstone"]},
	"voidcaller": {"avatar": "wizard", "tool": "abyssstaff", "type": "humanoid", "scale": 1.0, "speed": 2.6, "names": ["Voidcaller", "Scar Cultist"], "caster": true, "tint": 3,
		"attack": ["Sword_Regular_A"], "spells": ["void_bolt"], "loot": ["cultist_robe_scrap"]},
	"doomherald_kess": {"model": "Hellwarden", "type": "demon", "scale": 1.75, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Doomherald Kess"], "named": true,
		"walk": "Walk", "spells": ["hellfire_ring", "void_nova"], "loot": ["voidstone"]},
	# ---- the Abyssal Sanctum (raid, 60): every boss has two mechanics, a turn at half health, and a six-minute enrage
	"sanctum_knight": {"model": "Hellwarden", "type": "demon", "scale": 1.25, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Sanctum Knight"], "walk": "Walk",
		"raid_trash": true, "loot": ["voidstone"]},
	"sanctum_voidcaller": {"avatar": "wizard", "tool": "abyssstaff", "type": "humanoid", "scale": 1.1, "speed": 2.6, "names": ["Sanctum Voidcaller"], "caster": true, "tint": 3,
		"attack": ["Sword_Regular_A"], "spells": ["void_bolt"], "raid_trash": true, "loot": ["cultist_robe_scrap"]},
	"ash_golem": {"model": "Tidebreaker", "type": "elemental", "scale": 1.5, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.0, "names": ["Ash Golem"], "raid_trash": true},
	"lore_rune": {"model": "Imp", "type": "elemental", "scale": 0.8, "attack": ["Sword_Regular_A"], "speed": 2.0, "names": ["Rune of Lore"], "caster": true, "still": true, "hp_mult": 2.0,
		"spells": ["void_bolt"], "raid_trash": true},
	"void_spawn": {"model": "Imp", "type": "demon", "scale": 1.2, "attack": ["Sword_Regular_A", "Melee_Hook"], "speed": 1.9, "names": ["Spawn of Vaal"], "walk": "Walk", "raid_trash": true},
	"ashen_colossus": {"model": "Tidebreaker", "type": "elemental", "scale": 2.9, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.2, "names": ["The Ashen Colossus"],
		"boss": "colossus", "raid": true, "nova": "colossus_stomp", "yell_pull": "INTRUDERS. IN THE SANCTUM.", "yell_die": "The... fire... goes... out.",
		"raid_loot": ["colossus_knuckles", "cinderstone_ring", "ashfall_cord", "golemheart", "colossus_maul"], "token": "token_hands", "mythic": "mythic_worldbreaker"},
	"the_archivist": {"avatar": "wizard", "tool": "abyssstaff", "type": "humanoid", "scale": 1.7, "speed": 2.6, "names": ["The Archivist"], "caster": true, "tint": 3,
		"attack": ["Sword_Regular_A"], "spells": ["void_bolt"], "boss": "archivist", "raid": true, "yell_pull": "You are late. You were always going to be late. It is written.",
		"yell_die": "The last... page...", "raid_loot": ["tome_of_the_archivist", "inkstained_wraps", "lorekeepers_legplates", "runed_quill", "silent_word"], "token": "token_head",
		"mythic": "mythic_eternity"},
	"warden_ashur": {"model": "Hellwarden", "type": "demon", "scale": 2.0, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Ashur, the Left Hand"], "walk": "Walk",
		"boss": "twins", "twin": "warden_seth", "raid": true, "hp_mult": 42.0, "spells": ["hellfire_ring"], "yell_pull": "Two doors. Two keys. Two deaths.", "yell_die": "Brother...",
		"raid_loot": ["ashurs_edge", "chainlinked_girdle", "wardens_cloak"], "token": "token_legs", "mythic": "mythic_dawnbringer"},
	"warden_seth": {"model": "Skeleton_B", "type": "undead", "scale": 2.1, "attack": ["Sword_Heavy_Combo", "Sword_Regular_C"], "speed": 3.0, "names": ["Seth, the Right Hand"],
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "boss": "twins", "twin": "warden_ashur", "raid": true, "hp_mult": 42.0, "spells": ["void_nova"], "yell_die": "Brother...",
		"raid_loot": ["seths_gaze", "twinbound_band", "wardens_cloak"], "token": "token_shoulders"},
	"vaal": {"model": "Hellwarden", "type": "demon", "scale": 2.7, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0, "names": ["Vaal the Undying"], "walk": "Walk",
		"boss": "vaal", "raid": true, "nova": "vaal_nova", "yell_pull": "Ten of you. Only ten. I have eaten kingdoms.", "yell_die": "I... am... undying...",
		"raid_loot": ["vaals_eye", "undying_greaves", "voidstep_slippers", "crown_of_the_undying", "soulreaver"], "token": "token_chest", "mythic": "mythic_worldbreaker"},
	"puglin": {"model": "Puglin", "type": "humanoid", "scale": 1.0, "attack": ["Punch_Jab", "Punch_Cross"], "speed": 2.0,
		"names": ["Puglin Scavenger", "Puglin Snout", "Puglin Tusker"], "walk": "Walk", "loot": ["puglin_trinket"]},
	"imp": {"model": "Imp", "type": "demon", "scale": 1.0, "attack": ["Sword_Regular_A", "Melee_Hook"], "speed": 1.8,
		"names": ["Ember Imp", "Cinder Imp"], "walk": "Walk", "caster": true, "spells": ["ember_bolt"], "loot": ["brimstone_chip"]},
	"skeleton_a": {"model": "Skeleton_A", "type": "undead", "scale": 1.0, "attack": ["Sword_Regular_A", "Sword_Regular_B"], "speed": 2.4,
		"names": ["Restless Bones"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["bone_fragment"], "as": "restless_bones", "aggro": 7.0},
	"skeleton_b": {"model": "Skeleton_B", "type": "undead", "scale": 1.0, "attack": ["Sword_Regular_B", "Sword_Regular_C"], "speed": 2.4,
		"names": ["Restless Bones"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["bone_fragment"], "as": "restless_bones", "aggro": 7.0},
	"lycan": {"model": "Lycan", "type": "beast", "scale": 1.05, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.0,
		"names": ["Moonfang Stalker"], "walk": "Jog_Fwd", "spells": ["ravage"]},
	"hellwarden": {"model": "Hellwarden", "type": "demon", "scale": 1.0, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0,
		"names": ["The Ashen Warden"], "walk": "Walk", "spells": ["hellfire_ring"]},
	"tidebreaker": {"model": "Tidebreaker", "type": "elemental", "scale": 1.0, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.2,
		"names": ["Old Tidebreaker"], "walk": "Walk", "spells": ["tidal_slam"]},
}

var kind := "puglin"
var passive := false
var critter := false
var loot: Array = []                 # what the corpse holds: [{"id":..., "n":...}] and money
var loot_money := 0
var looted := false
var camp: Array = []                 # the other monsters of this camp (social aggro)
var aggro_r := 9.0
var leash := 38.0
var evading := false
var wander_t := 0.0
var respawn_t := 0.0
var corpse_t := 0.0
var rng := RandomNumberGenerator.new()
var loot_gold := 0
var killer: Unit
var boss := false
var boss_t := 0.0
var boss_phase := 0
var adds: Array = []

func setup(k: String, lv: int, is_elite := false) -> void:
	kind = k; level = lv; elite = is_elite; cls = "monster"; faction = "hostile"
	var d: Dictionary = KINDS[k]
	var names: Array = d["names"]
	uname = names[rng.randi() % names.size()]
	creature_type = d["type"]
	power_kind = "none"
	passive = d.get("passive", false) or d.get("critter", false) or d.get("cage", false)
	critter = d.get("critter", false)
	if passive: faction = "neutral"
	aggro_r = float(d.get("aggro", 9.0))

func _ready() -> void:
	super._ready()
	rng.randomize()
	var d: Dictionary = KINDS[kind]
	if d.has("creature"):
		model = CreatureBody.new(); model.model = d["creature"]
	elif d.has("avatar"):
		var ava := Avatar.new()
		var r2 := RandomNumberGenerator.new(); r2.randomize()
		ava.look = Avatar.random_look(r2, d["avatar"], "m")
		if kind == "gault": ava.look["beard"] = "Hair_Beard"; ava.look["hair"] = "Hair_Balding"; ava.look["hair_color"] = Avatar.HAIR_COLORS[5]
		if d.has("tint"):
			for fam in ava.look["tint"]: ava.look["tint"][fam] = int(d["tint"])

		model = ava
	elif d.get("cage", false):
		model = _cage_body()
	elif d.get("scarecrow", false):

		var av := Avatar.new()
		av.look = {"sex": "m", "skin": 2, "hair": "", "brows": "", "beard": "", "gear": Avatar.CLASS_GEAR["peasant"].duplicate(), "tint": {"Peasant": rng.randi_range(1, 3)}}
		model = av
	else:
		model = Humanoid.new(); model.model = "res://assets/licensed/monsters/%s.glb" % d["model"]
	model.scale = Vector3.ONE * float(d["scale"]) * (1.15 if elite and not boss else 1.0)
	add_child(model)
	if d.has("tool") and model is Avatar: model.wield.call_deferred("res://assets/weapons/%s.glb" % d["tool"], 0.62, "hand_r", -30.0)
	if kind == "bone_king": _crown()

	if d.get("scarecrow", false):
		# a sack with a stitched face where the head should be
		var ba := BoneAttachment3D.new(); ba.bone_name = "Head"; model.skeleton.add_child(ba)
		var sack := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.16; sm.height = 0.36
		var mt := StandardMaterial3D.new(); mt.albedo_color = Color(0.72, 0.6, 0.4); mt.roughness = 1.0; sm.material = mt; sack.mesh = sm
		ba.add_child(sack); sack.position = Vector3(0, 0.1, 0.02)
		for ex in [-0.06, 0.06]:
			var e := MeshInstance3D.new(); var em := SphereMesh.new(); em.radius = 0.028; em.height = 0.056
			var emt := StandardMaterial3D.new(); emt.albedo_color = Color(0.05, 0.04, 0.03); emt.emission_enabled = true; emt.emission = Color(1.0, 0.6, 0.2); emt.emission_energy_multiplier = 1.5
			em.material = emt; e.mesh = em; sack.add_child(e); e.position = Vector3(ex, 0.03, 0.14)
		var hat := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.08; cm.bottom_radius = 0.26; cm.height = 0.14
		var hmt := StandardMaterial3D.new(); hmt.albedo_color = Color(0.5, 0.42, 0.25); cm.material = hmt; hat.mesh = cm; sack.add_child(hat); hat.position = Vector3(0, 0.16, 0)
	radius = 0.5 * float(d["scale"]) * (1.2 if elite else 1.0)
	move_speed = Rules.RUN_SPEED * 0.95
	_stats()
	wander_t = rng.randf_range(2.0, 8.0)
	if KINDS[kind].get("raid", false): (func(): Raid.check_lock(self)).call_deferred()

func _stats() -> void:
	var named: bool = KINDS[kind].get("named", false)
	max_hp = Rules.mon_hp(level) * (2.5 if elite else (1.8 if named else 1.0))
	if boss: max_hp = Rules.mon_hp(level) * 9.0
	# the raid: bosses built for ten (DESIGN §12: raid boss ×60 of a dungeon trash mob, here scaled to our damage)
	if KINDS[kind].get("raid", false): max_hp = Rules.mon_hp(level) * float(KINDS[kind].get("hp_mult", 70.0)); leash = 90.0
	elif KINDS[kind].get("raid_trash", false): max_hp = Rules.mon_hp(level) * float(KINDS[kind].get("hp_mult", 5.0))
	if KINDS[kind].get("cage", false): max_hp = 40 * level
	if critter: max_hp = 6 + level * 2
	hp = max_hp
	armor = Rules.mon_armor(level)
	var hit := Rules.mon_hit(level) * (1.5 if elite else 1.0)
	if KINDS[kind].get("raid", false): hit = Rules.mon_hit(level) * 3.2
	elif KINDS[kind].get("raid_trash", false): hit = Rules.mon_hit(level) * 1.7
	var spd: float = KINDS[kind]["speed"]
	weapon = {"min": hit * spd / 2.0 * 0.85, "max": hit * spd / 2.0 * 1.15, "speed": spd}
	loot_gold = int((level * 3 + rng.randi_range(0, level * 4)) * (3 if elite else 1))
	if critter: loot_gold = 0; weapon = {"min": 0.0, "max": 0.0, "speed": 99.0}
	changed.emit()

func attack_power() -> float: return 0.0
func spell_power() -> float: return 0.0
func cost_of(_id: String) -> float: return 0.0
func crit_chance(_spell: bool) -> float: return 0.05
func _armed() -> bool: return false

func _animate(v: float) -> void:
	if model == null or model.anim == null: return
	if busy_anim > 0.0 and v < 0.4: return
	var d: Dictionary = KINDS[kind]
	if v < 0.3: model.play(d.get("idle", "Idle") if not in_combat else d.get("idle", "Idle"))
	elif v < 3.4: model.play(d.get("walk", "Walk"), clampf(v / 1.7, 0.6, 1.4))
	else: model.play("Jog_Fwd", clampf(v / 4.4, 0.8, 1.4))

func _tick_swing(delta: float) -> void:
	swing_t = maxf(0.0, swing_t - delta)
	if evading or not attacking or target == null or not is_instance_valid(target) or target.dead or stunned > 0.0: return
	if distance_to(target) > swing_range() or swing_t > 0.0: return
	swing_t = weapon["speed"] * (1.0 + _aura_sum("slow_attack"))
	var r := randf()
	var t := target
	var atk: Array = KINDS[kind].get("attack", ["Attack"])
	act(atk[rng.randi() % atk.size()], 1.1)
	if r < 0.05: t.show_text("Miss", Color(1, 1, 1), self); _swing_sound(t, "miss"); return
	if r < 0.05 + 0.05 + t.attrs.get("agi", 0) / 2500.0 + t.tmod("dodge"): t.show_text("Dodge", Color(1, 1, 1), self); t._on_dodge(); _swing_sound(t, "miss"); return
	var dmg := randf_range(weapon["min"], weapon["max"])
	var crit := randf() < 0.05
	if crit: dmg *= 1.5
	_swing_sound(t, "crit" if crit else "hit")
	dmg *= 1.0 - Rules.armor_dr(t.armor, level)
	t.take_damage(self, dmg, "physical", crit, "white")

# ------------------------------------------------------------------ thinking

# ------------------------------------------------------------------ dungeon bosses: one mechanic each (DESIGN §7.2)

func _boss_tick(delta: float) -> void:
	boss_t += delta
	match KINDS[kind].get("boss", ""):
		"grub":
			# Burrow: dives under the floor and erupts beneath someone (the ring on the ground warns you)
			if boss_phase == 1:
				if casting.is_empty():
					boss_phase = 0; visible = true; collision_layer = 2
					global_position = Vector3(get_meta("dive").x, WorldData.h(get_meta("dive").x, get_meta("dive").z), get_meta("dive").z)
					get_tree().call_group("fx", "burst", global_position + Vector3(0, 0.3, 0), Color(0.45, 0.38, 0.3), 50, 7.0, 0.7, 1.1, -6.0, Fx.smoke, 70.0, Vector3.UP, false, 1.5)
					get_tree().call_group("fx", "shake", 0.5, global_position)
				return
			if boss_t > 16.0 and not threat.is_empty():
				boss_t = 0.0
				var v := _random_foe()
				if v:
					boss_phase = 1; set_meta("dive", v.global_position)
					visible = false; collision_layer = 0; stop_moving(); attacking = false

					casting.clear()
					use("grub_eruption", v, v.global_position)
					_yell(KINDS[kind].get("dive_yell", "The ground heaves..."))
		"gault":
			# every 30 s he calls two diggers; any still standing 10 s later work him into a fury
			if boss_t > 30.0:
				boss_t = 0.0
				var gy: Array = KINDS[kind].get("yell", ["Diggers! To me!", "Put your backs into it, lads!", "Nobody leaves till the Hollow's open!"] if kind == "gault" else ["Rise, and serve!"])
				_yell(gy[rng.randi() % gy.size()])

				for i in 2:
					var m := Monster.new(); m.setup(KINDS[kind].get("adds", "hollow_digger"), level - 2)
					get_parent().add_child(m)
					var p := Nav.nearest_open(global_position + Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6)))
					p.y = WorldData.h(p.x, p.z); m.global_position = p; m.home = p; m.respawn_t = 1e9
					m.died.connect(func(_u): m.get_tree().create_timer(15.0).timeout.connect(m.queue_free))
					adds.append(m)
					if target: m.get_tree().create_timer(0.3).timeout.connect(func(): if is_instance_valid(m) and is_instance_valid(target): m.aggro(target))
				get_tree().create_timer(10.0).timeout.connect(_gault_fury)
		"brood":
			# every 20 s a clutch of spiderlings hatches and runs at whoever is nearest
			if boss_t > 20.0:
				boss_t = 0.0
				var hatch: Array = KINDS[kind].get("hatch", ["rail_spider", "Spiderling", 3])
				_yell(KINDS[kind].get("hatch_yell", "The eggs split open!"))
				for i in int(hatch[2]):
					var m := Monster.new(); m.setup(hatch[0], level - 4)
					m.uname = hatch[1]
					get_parent().add_child(m)
					var p := Nav.nearest_open(global_position + Vector3(rng.randf_range(-7, 7), 0, rng.randf_range(-7, 7)))
					p.y = WorldData.h(p.x, p.z); m.global_position = p; m.home = p; m.respawn_t = 1e9
					m.model.scale *= 0.6
					m.died.connect(func(_u): m.get_tree().create_timer(10.0).timeout.connect(m.queue_free))
					var v := _random_foe()
					if v: m.get_tree().create_timer(0.3).timeout.connect(func(): if is_instance_valid(m) and is_instance_valid(v): m.aggro(v))
		"bell":
			# the Great Bell: every 18 s he strikes it and everyone near him is knocked senseless for 2 s
			if boss_t > 18.0:
				boss_t = 0.0
				_yell(KINDS[kind].get("bell_yell", "Hear the bell!"))
				get_tree().call_group("fx", "play", "thunder_clap", self, self, global_position)
				for u in enemies_near(global_position, 9.0): u.stunned = maxf(u.stunned, 2.0); u.take_damage(self, max_hp * 0.02, "holy", false, "spell")
		"ashmaw":
			if boss_t > 12.0 and not casting.is_empty() == false:
				boss_t = 0.0
		"mora":
			# Soul Drain: she channels on someone for 6 s, taking their life; hit her hard enough and it breaks
			if boss_phase == 3:
				var v = get_meta("drain_on") if has_meta("drain_on") else null
				var t_left: float = get_meta("drain_t") - get_process_delta_time()
				set_meta("drain_t", t_left)
				if v == null or not is_instance_valid(v) or v.dead or t_left <= 0.0 or hp < float(get_meta("drain_hp")) - max_hp * 0.06:
					if t_left > 0.0 and hp < float(get_meta("drain_hp")) - max_hp * 0.06: _yell("No! My focus!")
					boss_phase = 0; remove_meta("drain_on"); return
				if Engine.get_physics_frames() % 30 == 0:
					var dmg: float = v.max_hp * 0.05
					v.take_damage(self, dmg, "shadow", false, "dot"); heal(self, dmg * 2.0)
					get_tree().call_group("fx", "play", "shadow_rot", self, v, v.global_position)
				return
			if boss_t > 16.0:
				boss_t = 0.0
				var dv := _random_foe()
				if dv:
					boss_phase = 3; set_meta("drain_on", dv); set_meta("drain_t", 6.0); set_meta("drain_hp", hp)
					stop_moving(); attacking = false
					_yell(KINDS[kind].get("drain_yell", "Your soul is ash, %s!") % dv.uname)
		"rootmaw":

			# Entangle: roots hold everyone near him; below half health he slams harder and faster
			if boss_t > 15.0:
				boss_t = 0.0
				_yell(KINDS[kind].get("roots_yell", "The roots remember!"))
				for u in enemies_near(global_position, 10.0):
					u.add_aura("entangle", self, 4.0, {"root": true, "cage": true, "debuff": true})
			if hp < max_hp * 0.5 and boss_phase == 0:
				boss_phase = 2; add_aura("rootmaw_rage", self, 999.0, {"dmg_pct": 0.3}); _yell(KINDS[kind].get("rage_yell", "You will feed the marsh!"))

		"nova":
			# every 15 s a ring of fire (or frost, or void) grows around him: get out of it before it goes off
			if boss_t > 15.0 and casting.is_empty() and not threat.is_empty():
				boss_t = 0.0
				var ny: Array = KINDS[kind].get("nova_yell", ["Burn!"])
				_yell(ny[rng.randi() % ny.size()])
				stop_moving(); use(KINDS[kind].get("nova", "hellfire_ring"), self, global_position)
		"colossus", "archivist", "twins", "vaal":
			Raid.boss_tick(self, delta)
		"bone_king":
			# Bone Prison: a cage of bone closes on someone; break it in 6 seconds or it crushes them
			if boss_t > 20.0 and threat.size() >= 1:
				boss_t = 0.0
				var v2 := _random_foe(true)
				if v2: _bone_prison(v2)

func _random_foe(not_tank := false) -> Unit:
	var foes := threat.keys().filter(func(u): return is_instance_valid(u) and not u.dead)
	if not_tank and foes.size() > 1: foes.erase(target)
	return foes[rng.randi() % foes.size()] if not foes.is_empty() else null

func _gault_fury() -> void:
	if dead or not is_instance_valid(self): return
	var alive := adds.filter(func(a): return is_instance_valid(a) and not a.dead).size()
	if alive > 0:
		add_aura("foremans_fury", self, 30.0, {"dmg_pct": 0.2 * alive})
		_yell("That's the spirit!")

func _bone_prison(v: Unit) -> void:
	_yell("Stay a while. Stay forever.")
	var cage := Monster.new(); cage.setup("bone_cage", level)
	get_parent().add_child(cage)
	cage.global_position = v.global_position; cage.home = v.global_position; cage.respawn_t = 1e9
	v.add_aura("bone_prison", self, 6.0, {"root": true, "cage": true, "debuff": true})
	v.stop_moving()
	cage.died.connect(func(_u):
		if is_instance_valid(v): v.remove_aura("bone_prison")
		cage.get_tree().create_timer(2.0).timeout.connect(cage.queue_free))
	get_tree().create_timer(6.0).timeout.connect(func():
		if is_instance_valid(cage) and not cage.dead:
			if is_instance_valid(v) and not v.dead:
				v.take_damage(self, v.max_hp * 0.4, "shadow", false, "spell")
				get_tree().call_group("fx", "burst", v.global_position + Vector3(0, 1, 0), Color(0.9, 0.9, 0.8), 40, 6.0, 0.2, 0.7, -8.0)
			cage.die(null))

func _yell(t: String) -> void:
	get_tree().call_group("chat", "post", "yell", uname, t)
	show_text(t, Color(1.0, 0.3, 0.2))

## a cage of ribs and bone for the Bone Prison
func _cage_body() -> Humanoid:
	var h := PropBody.new(); h.kind = "cage"
	return h


func _crown() -> void:
	if model == null or model.skeleton == null: return
	var ba := BoneAttachment3D.new(); ba.bone_name = "Head"; model.skeleton.add_child(ba)
	var c := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.17; cm.bottom_radius = 0.14; cm.height = 0.12; cm.radial_segments = 8
	var mt := StandardMaterial3D.new(); mt.albedo_color = Color(0.85, 0.65, 0.25); mt.metallic = 0.9; mt.roughness = 0.3
	mt.emission_enabled = true; mt.emission = Color(0.6, 0.35, 0.1); mt.emission_energy_multiplier = 0.4
	cm.material = mt; c.mesh = cm; ba.add_child(c); c.position = Vector3(0, 0.22, 0)
	for k in 5:
		var sp := MeshInstance3D.new(); var sm := CylinderMesh.new(); sm.top_radius = 0.0; sm.bottom_radius = 0.035; sm.height = 0.12; sm.material = mt; sp.mesh = sm
		c.add_child(sp); var a := TAU * k / 5.0; sp.position = Vector3(cos(a) * 0.15, 0.1, sin(a) * 0.15)

func _think(delta: float) -> void:
	if KINDS[kind].get("cage", false): attacking = false; return
	if boss and in_combat and not dead: _boss_tick(delta)
	if boss_phase == 1 or boss_phase == 3: return



	if has_meta("taunted"):
		var tt: float = get_meta("taunted") - delta
		if tt <= 0.0: remove_meta("taunted")
		else: set_meta("taunted", tt)
	if evading:
		evade_t += delta
		if path.is_empty() and global_position.distance_to(home) > 1.5:
			path = PackedVector3Array([home])     # no route found: walk straight home
		# stuck on the way home: just be home (as WoW does)
		if evade_t > 8.0: global_position = home; evade_t = 0.0
		if global_position.distance_to(home) < 1.5:
			evading = false; hp = max_hp; auras.clear(); threat.clear(); target = null; attacking = false; in_combat = false
			changed.emit()
		return
	# forget the dead and the gone
	for k in threat.keys():
		if not is_instance_valid(k) or k.dead: threat.erase(k)
	if in_combat:
		if global_position.distance_to(home) > leash or (threat.is_empty() and combat_t > 1.0):
			if KINDS[kind].get("raid", false) and OS.get_cmdline_user_args().has("--raidtest"):
				print("  EVADE %s: %.0f m from home (leash %.0f), threat %d, combat_t %.1f" % [uname, global_position.distance_to(home), leash, threat.size(), combat_t])
			_evade(); return
		_pick_target()
		if critter:
			# run away from whoever is bothering us
			if target and is_instance_valid(target) and path.is_empty():
				var away := (global_position - target.global_position); away.y = 0
				var p := global_position + away.normalized() * 8.0
				if Nav.walkable(p): path = Nav.path(global_position, p)
			if combat_t > 5.0: threat.clear(); in_combat = false; target = null
			return
		if target and is_instance_valid(target) and not target.dead:
			attacking = true
			if not casting.is_empty(): return
			var caster: bool = KINDS[kind].get("caster", false)
			if KINDS[kind].get("still", false):
				stop_moving()
				for sp2 in KINDS[kind].get("spells", []):
					if check_use(sp2, target) == "": use(sp2, target); return
				return
			# special attacks when they are ready
			for sp in KINDS[kind].get("spells", []):
				if check_use(sp, target) == "" and (not caster or distance_to(target) > 4.0 or rng.randf() < 0.3):
					stop_moving(); use(sp, target); return
			if caster and distance_to(target) > 4.0:
				if distance_to(target) > 22.0: chase(target, 20.0)
				else: stop_moving()
				attacking = distance_to(target) <= swing_range()
			elif distance_to(target) > swing_range() * 0.85: chase(target, swing_range() * 0.8)
			else: stop_moving()
		return
	# idle: look around for trouble
	wander_t -= delta
	if not passive and Engine.get_physics_frames() % 8 == get_instance_id() % 8: _look_for_trouble()
	if wander_t <= 0.0 and path.is_empty():
		wander_t = rng.randf_range(5.0, 14.0)
		var p := home + Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6))
		if Nav.walkable(p): path = Nav.path(global_position, p)

func _look_for_trouble() -> void:
	for u in get_tree().get_nodes_in_group("units"):
		if u.dead or not is_enemy(u) or u.has_meta("ghost"): continue
		var r := clampf(aggro_r + (level - u.level) * 1.2, 3.0, 20.0)
		if global_position.distance_to(u.global_position) < r:
			aggro(u); return

func aggro(u: Unit) -> void:
	if dead or evading: return
	add_threat(u, 1.0); target = u; enter_combat(); attacking = true
	if passive: return
	for m in camp:
		if is_instance_valid(m) and m != self and not m.dead and not m.in_combat and not m.evading and m.global_position.distance_to(global_position) < 6.0:
			m.add_threat(u, 0.5); m.target = u; m.enter_combat(); m.attacking = true

func enter_combat() -> void:
	var was := in_combat
	super.enter_combat()
	if not was and target and is_instance_valid(target) and not passive:
		for m in camp:
			if is_instance_valid(m) and m != self and not m.dead and not m.in_combat and not m.evading and m.global_position.distance_to(global_position) < 6.0:
				m.add_threat(target, 0.5); m.target = target; m.in_combat = true; m.combat_t = 0.0; m.attacking = true

func _pick_target() -> void:
	if has_meta("taunted") and target and is_instance_valid(target) and not target.dead: return
	var best: Unit = null; var bt := -1.0
	for k in threat:
		if threat[k] > bt: bt = threat[k]; best = k
	if best == null: return
	if target == null or not is_instance_valid(target) or target.dead or not threat.has(target):
		target = best; return
	# the 110% / 130% rule: switch only when someone clearly out-threatens the current target
	var cur: float = threat[target]
	var near := distance_to(best) <= swing_range() + 0.5
	if best != target and bt > cur * (1.1 if near else 1.3): target = best

var evade_t := 0.0

func _evade() -> void:
	evading = true; attacking = false; target = null; evade_t = 0.0
	if KINDS[kind].get("raid", false): Raid.reset(self)

	threat.clear(); casting.clear()
	path = Nav.path(global_position, home)
	show_text("Evade", Color(1, 1, 1))

func take_damage(src: Unit, amount: float, school := "physical", crit := false, kind_ := "", threat_mult := 1.0) -> int:
	if evading:
		show_text("Evade", Color(1, 1, 1)); return 0
	if not in_combat and src and is_instance_valid(src): target = src
	return super.take_damage(src, amount, school, crit, kind_, threat_mult)

func _on_death(k: Unit) -> void:
	killer = k
	# experience, quest credit and the loot go to whoever tagged it / did the most
	var best: Unit = k; var bt := -1.0
	for u in threat:
		if is_instance_valid(u) and threat[u] > bt: bt = threat[u]; best = u
	looter = best if best and is_instance_valid(best) and best.has_method("gain_xp") else null
	# in your group, you loot (the bots are polite)
	if looter is Bot and looter.party_with and is_instance_valid(looter.party_with): looter = looter.party_with

	loot = []; loot_money = 0
	if looter:
		var party: Array = looter.party_members() if looter.has_method("party_members") else [looter]
		for m in party:
			if not is_instance_valid(m) or m.dead or m.global_position.distance_to(global_position) > 60.0: continue
			if not critter: m.gain_xp(int(Rules.kill_xp(m.level, level, elite) / (1.0 if party.size() == 1 else party.size() * 0.75)), self)
			if m.has_method("on_kill"): m.on_kill(self)
		_roll_loot()
	threat.clear()
	corpse_t = 60.0 if not loot.is_empty() or loot_money > 0 else 18.0
	respawn_t = rng.randf_range(40.0, 70.0) * (3.0 if elite else 1.0)
	if boss and WorldData.Z.get("dungeon", false): respawn_t = 1e9          # a cleared boss stays cleared
	if KINDS[kind].get("raid", false): Raid.boss_died(self)

var looter: Unit                     # who may loot this corpse
var sparkle: Node3D

## what the corpse holds: coins, a grey or two, quest items the looter needs, sometimes a green
func _roll_loot() -> void:
	var d: Dictionary = KINDS[kind]
	if critter:
		if rng.randf() < 0.3 and d.has("loot"): loot.append({"id": d["loot"][0], "n": 1})
	else:
		loot_money = loot_gold if rng.randf() < 0.85 or elite or d.get("named", false) else 0
		if d.has("loot") and rng.randf() < 0.55:
			loot.append({"id": d["loot"][rng.randi() % d["loot"].size()], "n": 1})
		if d.has("drop"):
			for it in d["drop"]: loot.append({"id": it, "n": 1})
		if d.has("drop_one"):
			var pick: Array = d["drop_one"]
			loot.append({"id": pick[rng.randi() % pick.size()], "n": 1})
		if boss: loot_money = level * 60 + rng.randi_range(0, level * 30)
		var green := 0.05 + (0.9 if d.get("named", false) or elite else 0.0)
		if rng.randf() < green: loot.append(Items.roll(level, rng, 3 if elite and rng.randf() < 0.3 else 2))
		if rng.randf() < 0.04: loot.append({"id": "minor_healing_potion", "n": 1})
		# crafting materials: hides from beasts, cloth scraps from people
		var tier := Crafting.tier_for_level(level)
		if creature_type == "beast" and rng.randf() < 0.4: loot.append({"id": "hide_%d" % tier, "n": rng.randi_range(1, 2)})
		if creature_type == "humanoid" and rng.randf() < 0.35: loot.append({"id": "linen_%d" % tier, "n": rng.randi_range(1, 3)})

	if looter.has_method("quest_drops"): loot.append_array(looter.quest_drops(self))
	if looter.has_method("auto_loot"): looter.auto_loot(self); return
	if not loot.is_empty() or loot_money > 0: _show_sparkle(true)

func has_loot(p: Unit) -> bool:
	return dead and p == looter and (not loot.is_empty() or loot_money > 0)

## after someone took something
func loot_taken() -> void:
	if loot.is_empty() and loot_money <= 0:
		_show_sparkle(false); corpse_t = minf(corpse_t, 6.0)

func _show_sparkle(on: bool) -> void:
	if on and sparkle == null:
		var fx := get_tree().get_first_node_in_group("fx")
		if fx == null: return
		sparkle = fx.twinkle(self, Color(1.0, 0.85, 0.35))
		sparkle.position = Vector3(0, 0.4, 0)
	elif not on and sparkle:
		sparkle.queue_free(); sparkle = null

func _physics_process(delta: float) -> void:
	if dead:
		corpse_t -= delta; respawn_t -= delta
		if corpse_t < 0.0 and visible: visible = false
		if respawn_t <= 0.0: _respawn()
		return
	super._physics_process(delta)

func _respawn() -> void:
	global_position = home; visible = true
	loot = []; loot_money = 0; looter = null; _show_sparkle(false)
	dead = false; collision_layer = 2; busy_anim = 0.0; in_combat = false; evading = false
	auras.clear(); threat.clear(); target = null; attacking = false
	if model: model._once = false; model.current = ""
	_stats()
