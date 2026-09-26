class_name Npcs
## The people of Ashvale who give quests, sell things and train you. Each has a place to stand,
## a look, a line or two of greeting, and what they do.

const LIST := {
	# ---- Ashvale town
	"rowan": {"name": "Elder Rowan", "title": "Elder of Ashvale", "at": [2.0, -10.0], "face": 180, "sex": "m", "look": "noble", "beard": "Hair_Beard", "hair_color": 5,
		"greet": "The mountain's been restless, and so have the young. Which are you?", "anim": "Idle_FoldArms"},
	"bess": {"name": "Bess", "title": "Innkeeper", "at": [-19.5, 9.5], "face": 110, "sex": "f", "look": "peasant", "hair": "Hair_Buns", "hair_color": 4,
		"greet": "Sit down, love, you look half-starved.", "vendor": ["warm_meal", "spring_water", "minor_healing_potion"], "inn": true, "anim": "Idle_Talking"},
	"grom": {"name": "Blacksmith Grom", "title": "Blacksmith", "at": [17.0, -15.0], "face": 200, "sex": "m", "look": "peasant", "hair": "Hair_Buzzed", "beard": "Hair_MuttonChops", "skin": 3,
		"greet": "Mind the anvil. It bites.", "vendor": ["recruit_sword", "apprentice_staff", "acolyte_mace", "recruit_chest", "recruit_legs", "apprentice_robe", "acolyte_vestment"], "repair": true, "anim": "Idle_FoldArms"},
	"orrin": {"name": "Sage Orrin", "title": "Historian", "at": [-7.5, -18.5], "face": 150, "sex": "m", "look": "wizard", "hair": "Hair_Balding", "beard": "Hair_Beard", "hair_color": 6,
		"greet": "Ah! A visitor. Have you come about the history? Everyone comes about the history. Nobody comes about the history.", "anim": "Idle"},
	"trainer_warrior": {"name": "Sergeant Maddox", "title": "Warrior Trainer", "at": [14.0, 4.0], "face": 250, "sex": "m", "look": "warrior", "hair": "Hair_Buzzed", "skin": 4,
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
	"ada": {"name": "Guard Captain Ada", "title": "Ashvale Militia", "at": [61.0, 12.0], "face": 160, "sex": "f", "look": "warrior", "hair": "Hair_Bob", "hair_color": 0,
		"greet": "Militia business. Unless you're here to help, in which case it's your business too.", "anim": "Idle_Shield"},
}

## abilities each class learns, and when (from its trainer, for a fee in copper)
const TRAINING := {
	"warrior": [["heroic_strike", 1, 0], ["battle_shout", 1, 0], ["charge", 2, 10], ["rend", 4, 60], ["thunder_clap", 6, 100], ["hamstring", 8, 200], ["taunt", 10, 300], ["execute", 12, 500]],
	"wizard": [["fireball", 1, 0], ["frost_armor", 1, 0], ["frostbolt", 2, 10], ["fire_blast", 4, 60], ["arcane_missiles", 6, 100], ["frost_nova", 8, 200], ["blink", 10, 300], ["flamestrike", 12, 500]],
	"cleric": [["smite", 1, 0], ["mend", 1, 0], ["inner_fire", 2, 10], ["shadow_rot", 4, 60], ["ward_of_light", 6, 100], ["renewal", 8, 200], ["holy_nova", 10, 300]],
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
