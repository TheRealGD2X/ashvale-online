class_name Npcs
## The people of Ashvale who give quests, sell things and train you. Each has a place to stand,
## a look, a line or two of greeting, and what they do.

const LIST := {
	# ---- Ashvale town
	"rowan": {"name": "Elder Rowan", "title": "Elder of Ashvale", "at": [2.0, -10.0], "face": 180, "sex": "m", "look": "noble", "beard": "Hair_Beard", "hair_color": 5,
		"greet": "The mountain's been restless, and so have the young. Which are you?", "anim": "Idle_FoldArms"},
	"bess": {"name": "Bess", "title": "Innkeeper", "at": [-16.5, 6.5]
, "face": 110, "sex": "f", "look": "peasant", "hair": "Hair_Buns", "hair_color": 4,
		"greet": "Sit down, love, you look half-starved.", "vendor": ["warm_meal", "spring_water", "minor_healing_potion"], "inn": true, "anim": "Idle_Talking"},
	"grom": {"name": "Blacksmith Grom", "title": "Blacksmith", "at": [17.0, -15.0], "face": 200, "sex": "m", "look": "peasant", "hair": "Hair_Buzzed", "beard": "Hair_MuttonChops", "skin": 3,
		"greet": "Mind the anvil. It bites.", "vendor": ["recruit_sword", "apprentice_staff", "acolyte_mace", "recruit_chest", "recruit_legs", "apprentice_robe", "acolyte_vestment"], "repair": true, "anim": "Idle_FoldArms"},
	"orrin": {"name": "Sage Orrin", "title": "Historian", "at": [-7.5, -18.5], "face": 150, "sex": "m", "look": "wizard", "hair": "Hair_Balding", "beard": "Hair_Beard", "hair_color": 6,
		"greet": "Ah! A visitor. Have you come about the history? Everyone comes about the history. Nobody comes about the history.", "anim": "Idle"},
	"lyle": {"name": "Lyle Pennyworth", "title": "Market Keeper", "at": [5.0, -8.0], "face": 200, "sex": "m", "look": "noble", "hair": "Hair_SlickBack", "beard": "Hair_Moustache", "hair_color": 2,
		"greet": "Buying, selling, or just looking? Looking's free. Everything else has a price.", "market": true, "anim": "Idle_Talking"},
	"trainer_warrior": {
"name": "Sergeant Maddox", "title": "Warrior Trainer", "at": [14.0, 4.0], "face": 250, "sex": "m", "look": "warrior", "hair": "Hair_Buzzed", "skin": 4,
		"greet": "Shoulders back. Weight forward. Again.", "trainer": "warrior", "anim": "Idle_Shield"},
	"trainer_wizard": {"name": "Magistra Elowen", "title": "Wizard Trainer", "at": [-15.0, -3.0], "face": 80, "sex": "f", "look": "wizard", "hair": "Hair_Ponytail_2", "hair_color": 4,
		"greet": "Fire is a question. Frost is an answer. Which do you want to learn today?", "trainer": "wizard", "anim": "Idle"},
	"trainer_cleric": {"name": "Brother Aldous", "title": "Cleric Trainer", "at": [8.0, 11.0], "face": 300, "sex": "m", "look": "cleric", "hair": "Hair_SimpleParted", "hair_color": 1,
		"greet": "The Ember keeps us warm. Let it keep you too.", "trainer": "cleric", "anim": "Idle"},
	# ---- the Mill
	"hale": {"name": "Farmer Hale", "title": "", "at": [67.0, 9.5], "face": 200, "sex": "m", "look": "peasant", "hair": "Hair_SimpleParted", "beard": "Hair_Moustache", "hair_color": 2,
		"greet": "If it's about the fence, I don't want to hear it.", "anim": "Idle_FoldArms"},
	"tomas": {"name": "Tomas", "title": "Hale's brother", "at": [70.5, 14.5], "face": 230, "sex": "m", "look": "peasant", "hair": "Hair_Long", "hair_color": 2,
		"greet": "Don't tell Hale I was sitting down.", "anim": "Sitting_Idle", "vendor": ["warm_meal", "spring_water"]},
	"wren": {"name": "Wren", "title": "Hunter", "at": [77.0, 11.0], "face": 260, "sex": "f", "look": "ranger", "hair": "Hair_Ponytail_2", "hair_color": 4,
		"greet": "Quiet. You'll scare the birds. Or worse, you won't.", "anim": "Idle"},
	# ---- the Miners' Camp (Hollow Cliffs)
	"gault": {"zone": "hollow", "name": "Foreman Gault", "title": "Miners' Guild", "at": [11.0, 21.0], "face": 200, "sex": "m", "look": "warrior", "hair": "Hair_Balding", "beard": "Hair_Beard", "hair_color": 5, "skin": 2,
		"greet": "If you're here for work, the pay's bad and the bats are worse. If you're here for trouble, get in line.", "anim": "Idle_FoldArms", "weapon": "pickaxe", "gone_after": "foremans_key"},
	"bram": {"zone": "hollow", "name": "Bram", "title": "Camp Cook", "at": [-1.5, 32.5], "face": 120, "sex": "m", "look": "peasant", "hair": "Hair_Buzzed", "beard": "Hair_MuttonChops", "hair_color": 3,
		"greet": "Stew's on. Stew's always on. Don't ask what's in it.", "vendor": ["warm_meal", "spring_water", "minor_healing_potion"], "inn": true, "anim": "Idle_Talking"},
	"vale": {"zone": "hollow", "name": "Sister Vale", "title": "Order of the Ember", "at": [16.0, 33.0], "face": 250, "sex": "f", "look": "cleric", "hair": "Hair_Long", "hair_color": 6,
		"greet": "The mountain remembers everyone who dies in it. I try to help it forget.", "anim": "Idle"},
	"hux": {"zone": "hollow", "name": "Quartermaster Hux", "title": "Guild Quartermaster", "at": [3.0, 19.0], "face": 170, "sex": "m", "look": "noble", "hair": "Hair_SlickBack", "hair_color": 1,
		"greet": "Everything in this camp belongs to the guild. Including, technically, the air. Breathe carefully.", "market": true, "vendor": ["recruit_sword", "apprentice_staff", "acolyte_mace", "minor_healing_potion"], "repair": true, "anim": "Idle_FoldArms"},
	# ---- Mirewood Landing
	"elsbeth": {"zone": "mirewood", "name": "Warden Elsbeth", "title": "Mirewood Wardens", "at": [-38.0, 24.0], "face": 160, "sex": "f", "look": "ranger", "hair": "Hair_Ponytail_2", "hair_color": 4,
		"greet": "Mind the boards; half of them are older than me and the other half are older than the Landing.", "anim": "Idle_FoldArms"},
	"dodd": {"zone": "mirewood", "name": "Ferryman Dodd", "title": "Ferryman", "at": [-31.0, 21.0], "face": 230, "sex": "m", "look": "peasant", "hair": "Hair_Long", "beard": "Hair_Beard", "hair_color": 5,
		"greet": "Ferry's not running. Water's too black. Buy something while you wait.", "vendor": ["warm_meal", "spring_water", "minor_healing_potion"], "inn": true, "market": true, "anim": "Idle"},
	"ivo": {"zone": "mirewood", "name": "Ivo", "title": "Marsh-Witch", "at": [-43.0, 25.0], "face": 90, "sex": "m", "look": "wizard", "hair": "Hair_Dreads", "hair_color": 0, "skin": 4,
		"greet": "Everything in the marsh is either medicine or poison. Usually both. Sit down.", "anim": "Idle"},
	"fenn": {"zone": "mirewood", "name": "Corporal Fenn", "title": "Mirewood Wardens", "at": [-34.0, 36.0], "face": 200, "sex": "m", "look": "warrior", "hair": "Hair_Buzzed", "hair_color": 1,
		"greet": "Corporal Fenn. I hold the bridge. Well — I'm meant to.", "repair": true, "vendor": ["recruit_sword", "apprentice_staff", "acolyte_mace"], "anim": "Idle_Shield"},
	# ---- Temple Gate (Ash Slopes)
	"sorin": {"zone": "ashslopes", "name": "Abbot Sorin", "title": "Order of the Temple", "at": [22.0, 30.0], "face": 180, "sex": "m", "look": "cleric", "hair": "Hair_Balding", "beard": "Hair_Beard", "hair_color": 6,
		"greet": "The temple was ours for four hundred years. It has been theirs for four. I count every day.", "anim": "Idle"},
	"nell": {"zone": "ashslopes", "name": "Archer Captain Nell", "title": "Temple Archers", "at": [30.0, 40.0], "face": 250, "sex": "f", "look": "ranger", "hair": "Hair_Bob", "hair_color": 1,
		"greet": "Keep low when you cross the cinders. They've got better archers than we have. Had. We had better archers.", "anim": "Idle_FoldArms"},
	"pell": {"zone": "ashslopes", "name": "Stonemason Pell", "title": "Stonemason", "at": [16.0, 38.0], "face": 120, "sex": "m", "look": "peasant", "hair": "Hair_Buzzed", "beard": "Hair_MuttonChops", "hair_color": 2, "skin": 3,
		"greet": "Every statue on this mountain has a name. I know most of them. Some of them owe me money.", "repair": true, "vendor": ["minor_healing_potion", "warm_meal", "spring_water"], "inn": true, "market": true, "anim": "Idle"},
	"prisoner": {"zone": "ashslopes", "name": "The Prisoner", "title": "a captured cultist", "at": [34.0, 28.0], "face": 200, "sex": "m", "look": "wizard", "hair": "", "hair_color": 0,
		"greet": "...I'm not saying anything. Not to you. Not without the ledgers.", "anim": "Sitting_Idle"},
	"stablehand": {"zone": "ashslopes", "name": "Tam the Stablehand", "title": "Temple Stables", "at": [12.0, 30.0], "face": 90, "sex": "f", "look": "peasant", "hair": "Hair_Buns", "hair_color": 3,
		"greet": "Horses? We had forty. Now we have one, and she's in a mood.", "anim": "Idle_Talking"},
	# ---- Highland Watch (Ashen Highlands)
	"roark": {"zone": "highlands", "name": "Captain Roark", "title": "Highland Watch", "at": [-30.0, 36.0], "face": 180, "sex": "m", "look": "warrior", "hair": "Hair_Buzzed", "beard": "Hair_Beard", "hair_color": 4, "skin": 1,
		"greet": "Wind's from the north. That's where the Khar are. Wind's always from the north.", "anim": "Idle_FoldArms"},
	"mira": {"zone": "highlands", "name": "Herbalist Mira", "title": "Herbalist", "at": [-38.0, 44.0], "face": 120, "sex": "f", "look": "ranger", "hair": "Hair_Long", "hair_color": 2,
		"greet": "Mind the heather. It's older than you and it knows it.", "anim": "Idle"},
	"ned": {"zone": "highlands", "name": "Old Ned", "title": "retired raider", "at": [-22.0, 48.0], "face": 220, "sex": "m", "look": "peasant", "hair": "Hair_Balding", "beard": "Hair_Beard", "hair_color": 6,
		"greet": "Forty years I went into the Sanctum. Came out thirty-nine times. Sit down, I'll tell you about the fortieth.", "anim": "Sitting_Idle"},
	"oda": {"zone": "highlands", "name": "Quartermaster Oda", "title": "Highland Watch", "at": [-24.0, 32.0], "face": 200, "sex": "f", "look": "noble", "hair": "Hair_Bob", "hair_color": 0,
		"greet": "Sign here. And here. And here — no, the other here.", "vendor": ["warm_meal", "spring_water", "minor_healing_potion"], "repair": true, "inn": true, "market": true, "anim": "Idle_FoldArms"},
	"stray": {"zone": "highlands", "name": "A Wild Stag", "title": "", "at": [-86.0, -22.0], "face": 30, "creature": "deer", "scale": 1.6,
		"greet": "The stag watches you over the oats. It doesn't run. Not yet.", "anim": "Idle"},
	# ---- Varn's Rest (Varn Plateau)
	"greaves": {"zone": "varn", "name": "Marshal Greaves", "title": "Varn's Rest", "at": [10.0, 64.0], "face": 180, "sex": "m", "look": "warrior", "hair": "Hair_SlickBack", "beard": "Hair_MuttonChops", "hair_color": 5, "skin": 2,
		"greet": "We hold the plateau by day and pray by night. Which are you here to help with?", "anim": "Idle_Shield"},
	"tessaly": {"zone": "varn", "name": "Tessaly", "title": "Lich-Hunter", "at": [2.0, 72.0], "face": 110, "sex": "f", "look": "cleric", "hair": "Hair_Ponytail_2", "hair_color": 0,
		"greet": "Every soul they take, I take back. One shard at a time.", "anim": "Idle"},
	"durn": {"zone": "varn", "name": "Smith Durn", "title": "Blacksmith", "at": [18.0, 66.0], "face": 250, "sex": "m", "look": "peasant", "hair": "Hair_Buzzed", "beard": "Hair_Beard", "hair_color": 1, "skin": 4,
		"greet": "Horseshoes, swords, the odd saddle buckle. I make what keeps people alive.", "vendor": ["minor_healing_potion", "warm_meal", "spring_water"], "repair": true, "inn": true, "market": true, "anim": "Idle_FoldArms"},
	"sanctum_qm": {"zone": "varn", "name": "Keeper Ansel", "title": "Sanctum Quartermaster", "at": [17.0, 73.0], "face": 200, "sex": "m", "look": "noble", "hair": "Hair_Long", "hair_color": 5,
		"greet": "The Sanctum is not for the curious. It is for the ready. Are you ready?", "anim": "Idle"},
	"ada": {"name": "Guard Captain Ada",



 "title": "Ashvale Militia", "at": [61.0, 12.0], "face": 160, "sex": "f", "look": "warrior", "hair": "Hair_Bob", "hair_color": 0,
		"greet": "Militia business. Unless you're here to help, in which case it's your business too.", "anim": "Idle_Shield"},
	# ---- masters of the three Orders: train any class, in the bigger camps
	"trainer_hollin": {"zone": "hollow", "name": "Master Hollin", "title": "Master of the Three Orders", "at": [7.0, 34.0], "face": 0, "sex": "m", "look": "warrior", "hair": "Hair_Buzzed", "hair_color": 1, "skin": 1,
		"greet": "Warrior, wizard or cleric, I can teach you. The Orders send their masters out to where the fighting is.", "trainer": "all", "anim": "Idle"},
	"trainer_reed": {"zone": "mirewood", "name": "Master Reed", "title": "Master of the Three Orders", "at": [-40.0, 32.0], "face": 70, "sex": "f", "look": "wizard", "hair": "Hair_Ponytail", "hair_color": 0, "skin": 2,
		"greet": "Sword, spell or prayer: sit down, and let's see what you've forgotten since Ashvale.", "trainer": "all", "anim": "Idle"},
	"trainer_cindra": {"zone": "ashslopes", "name": "Master Cindra", "title": "Master of the Three Orders", "at": [24.0, 43.0], "face": 140, "sex": "f", "look": "cleric", "hair": "Hair_Bob", "hair_color": 4, "skin": 3,
		"greet": "The three Orders train together out here. There isn't room to be proud.", "trainer": "all", "anim": "Idle"},
	"trainer_brand": {"zone": "highlands", "name": "Master Brand", "title": "Master of the Three Orders", "at": [-34.0, 40.0], "face": 210, "sex": "m", "look": "warrior", "hair": "Hair_SlickBack", "hair_color": 2, "skin": 4,
		"greet": "You've come a long way from the trainers in Ashvale. Let me show you what they didn't.", "trainer": "all", "anim": "Idle"},
	"trainer_aurek": {"zone": "varn", "name": "Master Aurek", "title": "Master of the Three Orders", "at": [6.0, 66.0], "face": 280, "sex": "m", "look": "wizard", "hair": "Hair_Long", "hair_color": 5, "skin": 1,
		"greet": "Warrior, wizard or cleric, I can teach you. The Orders send their masters out to where the fighting is.", "trainer": "all", "anim": "Idle"},
	"trainer_idris": {"zone": "saltmere", "name": "Master Idris", "title": "Master of the Three Orders", "at": [-38.0, 14.0], "face": 350, "sex": "m", "look": "cleric", "hair": "Hair_SimpleParted", "hair_color": 0, "skin": 2,
		"greet": "Sword, spell or prayer: sit down, and let's see what you've forgotten since Ashvale.", "trainer": "all", "anim": "Idle"},
	"trainer_tamsin": {"zone": "emberreach", "name": "Master Tamsin", "title": "Master of the Three Orders", "at": [20.0, 67.0], "face": 60, "sex": "f", "look": "warrior", "hair": "Hair_Ponytail_2", "hair_color": 4, "skin": 3,
		"greet": "The three Orders train together out here. There isn't room to be proud.", "trainer": "all", "anim": "Idle"},
	"trainer_oren": {"zone": "palereach", "name": "Master Oren", "title": "Master of the Three Orders", "at": [57.0, -10.0], "face": 130, "sex": "m", "look": "wizard", "hair": "Hair_Long", "hair_color": 6, "skin": 4,
		"greet": "You've come a long way from the trainers in Ashvale. Let me show you what they didn't.", "trainer": "all", "anim": "Idle"},
	"trainer_vel": {"zone": "scar", "name": "Master Vel", "title": "Master of the Three Orders", "at": [-7.0, 75.0], "face": 200, "sex": "f", "look": "cleric", "hair": "Hair_Long", "hair_color": 0, "skin": 1,
		"greet": "Warrior, wizard or cleric, I can teach you. The Orders send their masters out to where the fighting is.", "trainer": "all", "anim": "Idle"},
	# ---- Milestone 6: Gullhaven, Forgehold, Wintermere, the Last Watch
	"maren": {"zone": "saltmere", "name": "Maren Holt", "title": "Harbormaster", "at": [-35.0, 23.0], "face": 250, "sex": "f", "look": "noble", "hair": "Hair_Bob", "hair_color": 4, "skin": 1, "greet": "Gullhaven's harbour. Mind the ropes, mind the gulls, and don't mind me — I'm shouting at everyone today.", "anim": "Idle_FoldArms"},
	"ione": {"zone": "saltmere", "name": "Sister Ione", "title": "Order of the Ember", "at": [-45.0, 15.0], "face": 60, "sex": "f", "look": "cleric", "hair": "Hair_Long", "hair_color": 6, "skin": 3, "greet": "The sea gives, and the sea takes back. Lately it's been taking more than its share.", "anim": "Idle"},
	"cask": {"zone": "saltmere", "name": "Cask", "title": "Innkeeper, the Salted Gull", "at": [-47.0, 27.0], "face": 120, "sex": "m", "look": "peasant", "hair": "Hair_Balding", "beard": "Hair_Beard", "hair_color": 2, "skin": 2, "vendor": ["salted_fish", "mountain_water", "major_healing_potion"], "repair": true, "inn": true, "market": true, "greet": "Sit down, sit down. Chowder's hot, fire's hot, and the beds are only a little damp.", "anim": "Idle_FoldArms"},
	"tobiah": {"zone": "saltmere", "name": "Old Tobiah", "title": "Lighthouse Keeper", "at": [46.0, -62.0], "face": 200, "sex": "m", "look": "peasant", "hair": "Hair_Long", "beard": "Hair_Beard", "hair_color": 6, "skin": 1, "greet": "Forty years I've kept this light. It's never gone out. Not once. Don't you be the first thing that puts it out.", "anim": "Idle"},
	"brunna": {"zone": "emberreach", "name": "Forgemaster Brunna", "title": "Forgehold", "at": [24.0, 56.0], "face": 220, "sex": "f", "look": "warrior", "hair": "Hair_Ponytail_2", "hair_color": 4, "skin": 2, "greet": "Forgehold never sleeps and neither do I. What do you need? Quickly — the metal's hot.", "anim": "Idle_Shield"},
	"ysolde": {"zone": "emberreach", "name": "Warden Ysolde", "title": "Emberwarden", "at": [15.0, 64.0], "face": 90, "sex": "f", "look": "wizard", "hair": "Hair_Long", "hair_color": 0, "skin": 4, "greet": "Twenty years watching a lake of fire. You'd think I'd be bored by now. I am never bored.", "anim": "Idle"},
	"ketch": {"zone": "emberreach", "name": "Ketch", "title": "Drake Hunter", "at": [26.0, 65.0], "face": 250, "sex": "m", "look": "ranger", "hair": "Hair_Ponytail", "beard": "Hair_MuttonChops", "hair_color": 1, "skin": 2, "greet": "Keep your voice down. They can hear you from the Roost. No, really.", "anim": "Idle_FoldArms"},
	"dain": {"zone": "emberreach", "name": "Quartermaster Dain", "title": "Forgehold Stores", "at": [14.0, 55.0], "face": 140, "sex": "m", "look": "noble", "hair": "Hair_SlickBack", "beard": "Hair_Beard", "hair_color": 5, "skin": 1, "vendor": ["salted_fish", "mountain_water", "major_healing_potion"], "repair": true, "inn": true, "market": true, "greet": "Iron, bread, bandages and bad news. We're well stocked in all four.", "anim": "Idle"},
	"aldric": {"zone": "palereach", "name": "Huntmaster Aldric", "title": "Wintermere", "at": [56.0, -16.0], "face": 160, "sex": "m", "look": "ranger", "hair": "Hair_Long", "beard": "Hair_Beard", "hair_color": 5, "skin": 1, "greet": "Come in from the cold. Everybody's welcome at Wintermere's fire, even lowlanders.", "anim": "Idle_FoldArms"},
	"sigrun": {"zone": "palereach", "name": "Mother Sigrun", "title": "Order of the Ember", "at": [65.0, -25.0], "face": 300, "sex": "f", "look": "cleric", "hair": "Hair_Buns", "hair_color": 6, "skin": 1, "greet": "The Ember burns hotter where it's coldest. That's why I came north, and why I stay.", "anim": "Idle"},
	"eir": {"zone": "palereach", "name": "Runescribe Eir", "title": "Keeper of Stones", "at": [63.0, -13.0], "face": 220, "sex": "f", "look": "wizard", "hair": "Hair_Ponytail", "hair_color": 3, "skin": 1, "greet": "Every stone in the Reach has something written on it. Most of it's warnings.", "anim": "Idle"},
	"tove": {"zone": "palereach", "name": "Tove", "title": "Lodge-keeper", "at": [53.0, -25.0], "face": 60, "sex": "f", "look": "peasant", "hair": "Hair_Buns", "hair_color": 3, "skin": 2, "vendor": ["salted_fish", "mountain_water", "major_healing_potion"], "repair": true, "inn": true, "market": true, "greet": "Boots off, cloak on the hook, and sit by the fire. You look frozen through.", "anim": "Idle"},
	"corvin": {"zone": "scar", "name": "High Marshal Corvin", "title": "The Last Watch", "at": [3.0, 76.0], "face": 180, "sex": "m", "look": "warrior", "hair": "Hair_Buzzed", "beard": "Hair_MuttonChops", "hair_color": 5, "skin": 3, "greet": "This is the last wall between the Scar and everything you love. We hold it. Will you?", "anim": "Idle_Shield"},
	"amara": {"zone": "scar", "name": "Seer Amara", "title": "Order of the Ember", "at": [-5.0, 84.0], "face": 90, "sex": "f", "look": "cleric", "hair": "Hair_Long", "hair_color": 0, "skin": 4, "greet": "I see what's on the other side of the Gate. I'd rather not. But somebody has to.", "anim": "Idle"},
	"rusk": {"zone": "scar", "name": "Quartermaster Rusk", "title": "Watch Stores", "at": [7.0, 86.0], "face": 250, "sex": "m", "look": "noble", "hair": "Hair_Balding", "beard": "Hair_Beard", "hair_color": 1, "skin": 2, "vendor": ["salted_fish", "mountain_water", "major_healing_potion"], "repair": true, "inn": true, "market": true, "greet": "Last stores before the end of the world. Prices are fair. I'm told that's unusual, at the end of the world.", "anim": "Idle"},
}

## abilities each class learns, and when (from its trainer, for a fee in copper)
const TRAINING := {
	"warrior": [["heroic_strike", 1, 0], ["battle_shout", 1, 0], ["charge", 2, 10], ["rend", 4, 60], ["thunder_clap", 6, 100], ["hamstring", 8, 200], ["taunt", 10, 300], ["execute", 12, 500],
		["shield_block", 16, 2400], ["mortal_strike", 20, 6000], ["whirlwind", 26, 12000], ["recklessness", 32, 20000], ["shield_wall", 40, 32000], ["rallying_cry", 50, 50000], ["cleaving_slam", 56, 64000]],
	"wizard": [["fireball", 1, 0], ["frost_armor", 1, 0], ["frostbolt", 2, 10], ["fire_blast", 4, 60], ["arcane_missiles", 6, 100], ["frost_nova", 8, 200], ["blink", 10, 300], ["flamestrike", 12, 500],
		["ice_barrier", 16, 2400], ["pyroblast", 20, 6000], ["cone_of_cold", 26, 12000], ["arcane_power", 32, 20000], ["evocation", 40, 32000], ["meteor", 50, 50000], ["time_warp", 56, 64000]],
	"cleric": [["smite", 1, 0], ["mend", 1, 0], ["inner_fire", 2, 10], ["shadow_rot", 4, 60], ["ward_of_light", 6, 100], ["renewal", 8, 200], ["holy_nova", 10, 300],
		["greater_mend", 14, 1800], ["mind_blast", 20, 6000], ["prayer_of_healing", 26, 12000], ["divine_protection", 32, 20000], ["radiance", 40, 32000], ["holy_fire", 50, 50000], ["salvation", 56, 64000]],
}

static func starting_abilities(cls: String) -> Array:
	var out := []
	for t in TRAINING[cls]:
		if int(t[1]) <= 1: out.append(t[0])
	return out

## the look of an NPC as an Avatar look dictionary
static func look_of(id: String) -> Dictionary:
	var n: Dictionary = LIST[id]
	var gear: Dictionary = Avatar.CLASS_GEAR.get(n.get("look", "peasant"), Avatar.CLASS_GEAR["peasant"]).duplicate()
	var hc: Color = Avatar.HAIR_COLORS[int(n.get("hair_color", 1))]
	var sex: String = n.get("sex", "m")
	return {"sex": sex, "skin": int(n.get("skin", 1)), "hair": n.get("hair", "Hair_SimpleParted" if sex == "m" else "Hair_Long"), "hair_color": hc,
		"brows": "Eyebrows_Regular" if sex == "m" else "Eyebrows_Female", "beard": n.get("beard", ""), "gear": gear, "tint": {"Knight": 2, "Wizard": 2, "Noble": 1, "Peasant": 2, "Ranger": 1}}
