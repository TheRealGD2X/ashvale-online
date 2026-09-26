class_name Talents
## Talent trees, World of Warcraft (Classic) style: from level 10 you earn one point per level
## (51 by level 60) to spend in your class's three trees. A tier opens for every 5 points spent in
## that tree. Deep talents change how you play; shallow ones make you a little better at a thing.
##
## effect keys (per rank): dmg_<school> · dmg_melee · crit · crit_spell · hp_pct · armor_pct · heal ·
##   cost_pct · rage_gen · threat · cast_<ability> (seconds off) · cd_<ability> (seconds off) ·
##   str/agi/sta/int/spi (% of that attribute) · dodge · resist · proc effects are marked "note".

const TREES := {
	"warrior": [
		{"name": "Arms", "color": Color(0.8, 0.55, 0.35), "talents": [
			{"id": "improved_heroic_strike", "name": "Improved Heroic Strike", "tier": 1, "max": 3, "fx": {"cost_heroic_strike": -1.0}, "desc": "Heroic Strike costs %s less Rage.", "per": 1},
			{"id": "deflection", "name": "Deflection", "tier": 1, "max": 5, "fx": {"dodge": 0.01}, "desc": "+%s%% chance to avoid attacks.", "per": 1},
			{"id": "improved_rend", "name": "Improved Rend", "tier": 1, "max": 3, "fx": {"dmg_rend": 0.15}, "desc": "Rend deals %s%% more damage.", "per": 15},
			{"id": "improved_charge", "name": "Improved Charge", "tier": 2, "max": 2, "fx": {"charge_rage": 3.0}, "desc": "Charge generates %s more Rage.", "per": 3},
			{"id": "tactical_mastery", "name": "Tactical Mastery", "tier": 2, "max": 5, "fx": {"rage_gen": 0.04}, "desc": "Gain %s%% more Rage from your attacks.", "per": 4},
			{"id": "improved_thunder_clap", "name": "Improved Thunder Clap", "tier": 3, "max": 3, "fx": {"cost_thunder_clap": -1.0}, "desc": "Thunder Clap costs %s less Rage.", "per": 1},
			{"id": "impale", "name": "Impale", "tier": 3, "max": 2, "fx": {"crit_bonus": 0.1}, "desc": "Your critical strikes deal %s%% more damage.", "per": 10},
			{"id": "two_handed_spec", "name": "Weapon Specialization", "tier": 4, "max": 5, "fx": {"dmg_melee": 0.01}, "desc": "+%s%% damage with weapons.", "per": 1},
			{"id": "sweeping_strikes", "name": "Sweeping Strikes", "tier": 5, "max": 1, "fx": {"cleave": 1.0}, "desc": "Your melee attacks also strike a nearby enemy.", "per": 0},
			{"id": "mortal_strike", "name": "Mortal Strike", "tier": 7, "max": 1, "fx": {"learn": "mortal_strike"}, "desc": "Learn Mortal Strike: a vicious strike that also halves healing on the target.", "per": 0},
		]},
		{"name": "Fury", "color": Color(0.85, 0.3, 0.25), "talents": [
			{"id": "booming_voice", "name": "Booming Voice", "tier": 1, "max": 5, "fx": {"dur_battle_shout": 0.1}, "desc": "Battle Shout lasts %s%% longer.", "per": 10},
			{"id": "cruelty", "name": "Cruelty", "tier": 1, "max": 5, "fx": {"crit": 0.01}, "desc": "+%s%% chance to critically strike with melee.", "per": 1},
			{"id": "unbridled_wrath", "name": "Unbridled Wrath", "tier": 2, "max": 5, "fx": {"rage_gen": 0.05}, "desc": "Your hits have a chance to give extra Rage (%s%% more).", "per": 5},
			{"id": "improved_battle_shout", "name": "Improved Battle Shout", "tier": 3, "max": 5, "fx": {"shout_ap": 0.05}, "desc": "Battle Shout gives %s%% more attack power.", "per": 5},
			{"id": "improved_execute", "name": "Improved Execute", "tier": 3, "max": 2, "fx": {"cost_execute": -2.5}, "desc": "Execute costs %s less Rage.", "per": 2.5},
			{"id": "enrage", "name": "Enrage", "tier": 4, "max": 5, "fx": {"dmg_melee": 0.02}, "desc": "+%s%% melee damage.", "per": 2},
			{"id": "flurry", "name": "Flurry", "tier": 5, "max": 5, "fx": {"haste": 0.03}, "desc": "Attack %s%% faster.", "per": 3},
			{"id": "bloodthirst", "name": "Bloodthirst", "tier": 7, "max": 1, "fx": {"learn": "bloodthirst"}, "desc": "Learn Bloodthirst: a strike that heals you a little.", "per": 0},
		]},
		{"name": "Protection", "color": Color(0.55, 0.65, 0.8), "talents": [
			{"id": "anticipation", "name": "Anticipation", "tier": 1, "max": 5, "fx": {"dodge": 0.01}, "desc": "+%s%% chance to avoid attacks.", "per": 1},
			{"id": "toughness", "name": "Toughness", "tier": 1, "max": 5, "fx": {"armor_pct": 0.02}, "desc": "+%s%% armour from items.", "per": 2},
			{"id": "iron_will", "name": "Iron Will", "tier": 2, "max": 5, "fx": {"resist": 0.03}, "desc": "Shrug off stuns and charms %s%% more often.", "per": 3},
			{"id": "improved_taunt", "name": "Improved Taunt", "tier": 2, "max": 2, "fx": {"cd_taunt": -1.0}, "desc": "Taunt's cooldown is %s seconds shorter.", "per": 1},
			{"id": "defiance", "name": "Defiance", "tier": 3, "max": 5, "fx": {"threat": 0.03}, "desc": "Your attacks cause %s%% more threat.", "per": 3},
			{"id": "vitality", "name": "Vitality", "tier": 4, "max": 5, "fx": {"sta": 0.02, "hp_pct": 0.01}, "desc": "+%s%% Stamina and health.", "per": 2},
			{"id": "last_stand", "name": "Last Stand", "tier": 5, "max": 1, "fx": {"learn": "last_stand"}, "desc": "Learn Last Stand: briefly gain 30% more health.", "per": 0},
			{"id": "shield_slam", "name": "Shield Slam", "tier": 7, "max": 1, "fx": {"learn": "shield_slam"}, "desc": "Learn Shield Slam: a crushing blow with great threat.", "per": 0},
		]},
	],
	"wizard": [
		{"name": "Arcane", "color": Color(0.8, 0.55, 1.0), "talents": [
			{"id": "arcane_subtlety", "name": "Arcane Subtlety", "tier": 1, "max": 2, "fx": {"threat": -0.1}, "desc": "Your spells cause %s%% less threat.", "per": 10},
			{"id": "arcane_focus", "name": "Arcane Focus", "tier": 1, "max": 5, "fx": {"hit": 0.02}, "desc": "Your spells are resisted %s%% less often.", "per": 2},
			{"id": "arcane_concentration", "name": "Arcane Concentration", "tier": 2, "max": 5, "fx": {"cost_pct": -0.02}, "desc": "Your spells cost %s%% less mana.", "per": 2},
			{"id": "improved_blink", "name": "Improved Blink", "tier": 2, "max": 2, "fx": {"cd_blink": -2.0}, "desc": "Blink's cooldown is %s seconds shorter.", "per": 2},
			{"id": "arcane_mind", "name": "Arcane Mind", "tier": 3, "max": 5, "fx": {"int": 0.02}, "desc": "+%s%% Intellect.", "per": 2},
			{"id": "arcane_instability", "name": "Arcane Instability", "tier": 4, "max": 3, "fx": {"dmg_all": 0.01, "crit_spell": 0.01}, "desc": "+%s%% spell damage and critical strike chance.", "per": 1},
			{"id": "presence_of_mind", "name": "Presence of Mind", "tier": 5, "max": 1, "fx": {"learn": "presence_of_mind"}, "desc": "Learn Presence of Mind: your next spell is instant.", "per": 0},
			{"id": "arcane_power", "name": "Arcane Power", "tier": 7, "max": 1, "fx": {"learn": "arcane_power"}, "desc": "Learn Arcane Power: your spells hit much harder for a short time.", "per": 0},
		]},
		{"name": "Fire", "color": Color(1.0, 0.45, 0.15), "talents": [
			{"id": "improved_fireball", "name": "Improved Fireball", "tier": 1, "max": 5, "fx": {"cast_fireball": -0.1}, "desc": "Fireball casts %s seconds faster.", "per": 0.1},
			{"id": "impact", "name": "Impact", "tier": 1, "max": 5, "fx": {"stun_fire": 0.02}, "desc": "Your fire spells have a %s%% chance to stun.", "per": 2},
			{"id": "ignite", "name": "Ignite", "tier": 2, "max": 5, "fx": {"ignite": 0.08}, "desc": "Your fire crits set the target burning for %s%% more.", "per": 8},
			{"id": "improved_fire_blast", "name": "Improved Fire Blast", "tier": 2, "max": 3, "fx": {"cd_fire_blast": -0.5}, "desc": "Fire Blast's cooldown is %s seconds shorter.", "per": 0.5},
			{"id": "incinerate", "name": "Incinerate", "tier": 3, "max": 2, "fx": {"crit_fire": 0.02}, "desc": "+%s%% critical strike chance with fire.", "per": 2},
			{"id": "master_of_elements", "name": "Master of Elements", "tier": 4, "max": 3, "fx": {"cost_pct": -0.03}, "desc": "Your spells cost %s%% less mana.", "per": 3},
			{"id": "fire_power", "name": "Fire Power", "tier": 5, "max": 5, "fx": {"dmg_fire": 0.02}, "desc": "+%s%% fire damage.", "per": 2},
			{"id": "pyroblast", "name": "Pyroblast", "tier": 7, "max": 1, "fx": {"learn": "pyroblast"}, "desc": "Learn Pyroblast: a slow, enormous fireball.", "per": 0},
		]},
		{"name": "Frost", "color": Color(0.5, 0.8, 1.0), "talents": [
			{"id": "frost_warding", "name": "Frost Warding", "tier": 1, "max": 2, "fx": {"armor_pct": 0.15}, "desc": "Frost Armor gives %s%% more armour.", "per": 15},
			{"id": "improved_frostbolt", "name": "Improved Frostbolt", "tier": 1, "max": 5, "fx": {"cast_frostbolt": -0.1}, "desc": "Frostbolt casts %s seconds faster.", "per": 0.1},
			{"id": "elemental_precision", "name": "Elemental Precision", "tier": 2, "max": 3, "fx": {"hit": 0.02}, "desc": "Your fire and frost spells are resisted %s%% less.", "per": 2},
			{"id": "ice_shards", "name": "Ice Shards", "tier": 2, "max": 5, "fx": {"crit_bonus_frost": 0.2}, "desc": "Your frost crits deal %s%% more damage.", "per": 20},
			{"id": "permafrost", "name": "Permafrost", "tier": 3, "max": 3, "fx": {"slow_dur": 1.0}, "desc": "Your slows last %s seconds longer.", "per": 1},
			{"id": "piercing_ice", "name": "Piercing Ice", "tier": 3, "max": 3, "fx": {"dmg_frost": 0.02}, "desc": "+%s%% frost damage.", "per": 2},
			{"id": "shatter", "name": "Shatter", "tier": 4, "max": 5, "fx": {"shatter": 0.1}, "desc": "+%s%% critical chance against frozen targets.", "per": 10},
			{"id": "ice_barrier", "name": "Ice Barrier", "tier": 7, "max": 1, "fx": {"learn": "ice_barrier"}, "desc": "Learn Ice Barrier: a shield of ice that absorbs damage.", "per": 0},
		]},
	],
	"cleric": [
		{"name": "Discipline", "color": Color(0.95, 0.95, 0.85), "talents": [
			{"id": "unbreakable_will", "name": "Unbreakable Will", "tier": 1, "max": 5, "fx": {"resist": 0.03}, "desc": "Shrug off stuns and fears %s%% more often.", "per": 3},
			{"id": "wand_spec", "name": "Wand Specialization", "tier": 1, "max": 5, "fx": {"dmg_wand": 0.05}, "desc": "Your wand deals %s%% more damage.", "per": 5},
			{"id": "improved_ward", "name": "Improved Ward of Light", "tier": 2, "max": 3, "fx": {"absorb": 0.05}, "desc": "Ward of Light absorbs %s%% more.", "per": 5},
			{"id": "improved_inner_fire", "name": "Improved Inner Fire", "tier": 2, "max": 3, "fx": {"armor_pct": 0.1}, "desc": "Inner Fire gives %s%% more armour.", "per": 10},
			{"id": "meditation", "name": "Meditation", "tier": 3, "max": 3, "fx": {"combat_regen": 0.05}, "desc": "%s%% of your mana regeneration continues while casting.", "per": 5},
			{"id": "mental_agility", "name": "Mental Agility", "tier": 4, "max": 5, "fx": {"cost_pct": -0.02}, "desc": "Your instant spells cost %s%% less mana.", "per": 2},
			{"id": "mental_strength", "name": "Mental Strength", "tier": 5, "max": 5, "fx": {"int": 0.02}, "desc": "+%s%% Intellect.", "per": 2},
			{"id": "power_infusion", "name": "Power Infusion", "tier": 7, "max": 1, "fx": {"learn": "power_infusion"}, "desc": "Learn Power Infusion: fill a friend with power.", "per": 0},
		]},
		{"name": "Holy", "color": Color(1.0, 0.85, 0.4), "talents": [
			{"id": "healing_focus", "name": "Healing Focus", "tier": 1, "max": 2, "fx": {"resist": 0.35}, "desc": "Damage pushes back your heals %s%% less.", "per": 35},
			{"id": "improved_renewal", "name": "Improved Renewal", "tier": 1, "max": 3, "fx": {"heal_renewal": 0.05}, "desc": "Renewal heals %s%% more.", "per": 5},
			{"id": "holy_specialization", "name": "Holy Specialization", "tier": 2, "max": 5, "fx": {"crit_holy": 0.01}, "desc": "+%s%% critical chance with holy spells.", "per": 1},
			{"id": "divine_fury", "name": "Divine Fury", "tier": 2, "max": 5, "fx": {"cast_smite": -0.1, "cast_mend": -0.1}, "desc": "Smite and Mend cast %s seconds faster.", "per": 0.1},
			{"id": "holy_reach", "name": "Holy Reach", "tier": 3, "max": 2, "fx": {"range": 0.1}, "desc": "Your holy spells reach %s%% further.", "per": 10},
			{"id": "spiritual_guidance", "name": "Spiritual Guidance", "tier": 4, "max": 5, "fx": {"spi": 0.03}, "desc": "+%s%% Spirit.", "per": 3},
			{"id": "spiritual_healing", "name": "Spiritual Healing", "tier": 5, "max": 5, "fx": {"heal": 0.02}, "desc": "Your heals are %s%% stronger.", "per": 2},
			{"id": "lightwell", "name": "Lightwell", "tier": 7, "max": 1, "fx": {"learn": "lightwell"}, "desc": "Learn Lightwell: a spring of light friends can drink from.", "per": 0},
		]},
		{"name": "Shadow", "color": Color(0.6, 0.35, 0.95), "talents": [
			{"id": "spirit_tap", "name": "Spirit Tap", "tier": 1, "max": 5, "fx": {"spirit_tap": 0.2}, "desc": "Killing a foe that gives experience restores %s%% of your mana.", "per": 4},
			{"id": "blackout", "name": "Blackout", "tier": 1, "max": 5, "fx": {"stun_shadow": 0.02}, "desc": "Your shadow spells have a %s%% chance to stun.", "per": 2},
			{"id": "improved_shadow_rot", "name": "Improved Shadow Rot", "tier": 2, "max": 2, "fx": {"dmg_shadow_rot": 0.1}, "desc": "Shadow Rot deals %s%% more damage.", "per": 10},
			{"id": "shadow_focus", "name": "Shadow Focus", "tier": 2, "max": 5, "fx": {"hit": 0.02}, "desc": "Your shadow spells are resisted %s%% less.", "per": 2},
			{"id": "darkness", "name": "Darkness", "tier": 3, "max": 5, "fx": {"dmg_shadow": 0.02}, "desc": "+%s%% shadow damage.", "per": 2},
			{"id": "shadow_reach", "name": "Shadow Reach", "tier": 4, "max": 3, "fx": {"range": 0.06}, "desc": "Your shadow spells reach %s%% further.", "per": 6},
			{"id": "vampiric_embrace", "name": "Vampiric Embrace", "tier": 5, "max": 1, "fx": {"vampiric": 0.2}, "desc": "Your shadow damage heals you for 20% of it.", "per": 0},
			{"id": "shadowform", "name": "Shadowform", "tier": 7, "max": 1, "fx": {"learn": "shadowform"}, "desc": "Learn Shadowform: become shadow; +15% shadow damage, -15% physical damage taken.", "per": 0},
		]},
	],
}

static func points_total(level: int) -> int:
	return maxi(0, level - 9)

static func spent(p) -> int:
	var n := 0
	for k in p.talents: n += int(p.talents[k])
	return n

static func spent_in_tree(p, tree: Dictionary) -> int:
	var n := 0
	for t in tree["talents"]: n += int(p.talents.get(t["id"], 0))
	return n

static func find(cls: String, id: String) -> Dictionary:
	for tree in TREES.get(cls, []):
		for t in tree["talents"]:
			if t["id"] == id: return t
	return {}

static func tree_of(cls: String, id: String) -> Dictionary:
	for tree in TREES.get(cls, []):
		for t in tree["talents"]:
			if t["id"] == id: return tree
	return {}

## can one more point go into this talent?
static func can_learn(p, id: String) -> bool:
	var t := find(p.cls, id)
	if t.is_empty(): return false
	if spent(p) >= points_total(p.level): return false
	if int(p.talents.get(id, 0)) >= int(t["max"]): return false
	var tree := tree_of(p.cls, id)
	return spent_in_tree(p, tree) >= (int(t["tier"]) - 1) * 5

## the sum of a talent effect over what you've learned
static func mod(p, key: String) -> float:
	var s := 0.0
	for id in p.talents:
		var t := find(p.cls, id)
		if t.has("fx") and t["fx"].has(key) and not (t["fx"][key] is String): s += float(t["fx"][key]) * int(p.talents[id])
	return s

## attribute percentages from talents, as flat numbers for the stat sheet
static func stat_bonus(p) -> Dictionary:
	var out := {}
	if not (p.cls in Rules.CLASSES): return out
	var base := Rules.attrs(p.cls, p.level)
	for k in ["str", "agi", "sta", "int", "spi"]:
		var m := mod(p, k)
		if m > 0.0: out[k] = int(round(base[k] * m))
	return out
