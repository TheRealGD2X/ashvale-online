class_name Rules
## The numbers of Ashvale: classes, their stats by level, the formulas combat uses, monster
## strength by level and the experience curve. Modelled on World of Warcraft (Classic era) and
## tuned from docs/DESIGN.md (sections 3, 4 and 12), stretched to the level 60 cap.

const MAX_LEVEL := 60
const GCD := 1.5
const MELEE_RANGE := 2.6          # metres, from edge to edge of two bodies
const SPELL_RANGE := 30.0
const RUN_SPEED := 5.2            # metres per second
const COMBAT_TEXT := true

## base attributes at level 1 and gained per level
const CLASSES := {
	"warrior": {"name": "Warrior", "power": "rage", "armor": "plate",
		"base": {"str": 23, "agi": 20, "sta": 22, "int": 8, "spi": 10}, "per": {"str": 2.2, "agi": 1.2, "sta": 2.0, "int": 0.2, "spi": 0.4},
		"hp": [20, 14.0], "mp": [0, 0.0], "color": Color(0.78, 0.61, 0.43),
		"blurb": "A plate-clad fighter who lives in the thick of it. Builds Rage by hitting and being hit, and spends it on mighty blows. Can hold a monster's attention to protect friends.",
		"trees": ["Arms", "Fury", "Protection"]},
	"wizard": {"name": "Wizard", "power": "mana", "armor": "cloth",
		"base": {"str": 8, "agi": 12, "sta": 14, "int": 24, "spi": 18}, "per": {"str": 0.2, "agi": 0.5, "sta": 1.0, "int": 2.2, "spi": 1.3},
		"hp": [20, 7.0], "mp": [30, 9.0], "color": Color(0.41, 0.8, 0.94),
		"blurb": "A scholar of fire and frost who ends fights from afar. Fragile up close, so slows, roots and blinks are as important as the big spells.",
		"trees": ["Fire", "Frost", "Arcane"]},
	"cleric": {"name": "Cleric", "power": "mana", "armor": "cloth",
		"base": {"str": 10, "agi": 12, "sta": 16, "int": 20, "spi": 24}, "per": {"str": 0.4, "agi": 0.6, "sta": 1.1, "int": 1.8, "spi": 2.0},
		"hp": [20, 8.0], "mp": [30, 8.0], "color": Color(1.0, 0.96, 0.84),
		"blurb": "A keeper of the Order of the Ember. Heals friends, shields them from harm and smites the dead. Can also walk the shadow path and wither foes with dark magic.",
		"trees": ["Holy", "Discipline", "Shadow"]},
}

static func attrs(cls: String, level: int) -> Dictionary:
	var c: Dictionary = CLASSES[cls]
	var out := {}
	for k in c["base"]: out[k] = int(round(c["base"][k] + c["per"][k] * (level - 1)))
	return out

static func base_hp(cls: String, level: int) -> int:
	var h: Array = CLASSES[cls]["hp"]; return int(h[0] + h[1] * level)

static func base_mp(cls: String, level: int) -> int:
	var m: Array = CLASSES[cls]["mp"]; return int(m[0] + m[1] * level)

## experience to go from this level to the next (WoW-like: slow ramp, ~tripled by 60)
static func xp_need(level: int) -> int:
	if level >= MAX_LEVEL: return 0
	return int(round(400.0 + 180.0 * level + 38.0 * pow(level, 2.05)))

## experience from killing a monster of monster_level when you are level
static func kill_xp(level: int, mon_level: int, elite := false) -> int:
	var diff := mon_level - level
	var base := 45.0 + 5.0 * mon_level
	var m := 1.0
	if diff <= -grey_gap(level): return 0
	elif diff <= -3: m = 0.6
	elif diff < 0: m = 0.85
	elif diff >= 5: m = 1.3
	elif diff >= 3: m = 1.2
	return int(base * m * (2.0 if elite else 1.0))

static func grey_gap(level: int) -> int:
	return 5 + int(level / 10.0)

## the colour of a monster's name by level difference (grey, green, yellow, orange, red)
static func con_color(level: int, mon_level: int) -> Color:
	var d := mon_level - level
	if d <= -grey_gap(level): return Color(0.62, 0.62, 0.62)
	if d <= -3: return Color(0.25, 0.85, 0.3)
	if d <= 2: return Color(1.0, 0.9, 0.25)
	if d <= 4: return Color(1.0, 0.55, 0.15)
	return Color(1.0, 0.2, 0.15)

## ---- monsters by level (normal; elites, rares and bosses multiply) ----
static func mon_hp(level: int) -> int:
	# quadratic to 30, then gentle: abilities grow in a straight line, so fights would drag at 50+
	var l := mini(level, 30)
	return int(42 + 14.0 * level + 0.5 * l * l + 8.0 * maxi(0, level - 30))

static func mon_hit(level: int) -> float:
	# WoW-like curve to 30, then straight (a quadratic keeps outgrowing player health past 40)
	var l := mini(level, 30)
	return 3.0 + 1.3 * l + 0.045 * l * l + 3.6 * maxi(0, level - 30)

static func mon_armor(level: int) -> int:
	return 25 * level

## physical damage reduction from armour against an attacker of attacker_level
static func armor_dr(armor: float, attacker_level: int) -> float:
	return clampf(armor / (armor + 400.0 + 85.0 * attacker_level), 0.0, 0.75)
