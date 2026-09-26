class_name Crafting
## Albion-style crafting: gather raw resources in the world (ore veins, herbs, and hides and cloth
## from what you kill), refine them at a station (ore into bars at a forge, hides into leather at a
## tannery, linen into cloth at a loom), then craft gear and potions from recipes. Everything comes
## in tiers, one per zone band; the top tier sits just below raid loot.
##
## Skills: Mining, Herbalism, Smithing, Leatherworking, Tailoring, Alchemy, each 1–300. A tier needs
## (tier - 1) × 50 skill; working at a tier near your level raises it. Better skill, better odds of a
## finer result: Normal, Good, Excellent (blue), Masterpiece (purple).

const SKILLS := {"mining": "Mining", "herbalism": "Herbalism", "smithing": "Smithing", "leatherworking": "Leatherworking",
	"tailoring": "Tailoring", "alchemy": "Alchemy"}
const TIER_ILVL := [8, 16, 24, 34, 44, 56]
const TIER_NAME := ["Copper", "Black Iron", "Bog Iron", "Ashsteel", "Highland Steel", "Starmetal"]
const LEATHER_NAME := ["Rough", "Rugged", "Mire", "Cinder", "Highland", "Wyrm"]
const CLOTH_NAME := ["Linen", "Wool", "Reedweave", "Ashsilk", "Frostweave", "Runecloth"]
const HERB_NAME := ["Hearthleaf", "Cliffmoss", "Bogbell", "Emberroot", "Frostthistle", "Starbloom"]
const QUALITY_NAMES := ["Normal", "Good", "Excellent", "Masterpiece"]

## raw and refined materials, generated per tier: ore_1, bar_1, hide_1, leather_1, linen_1, cloth_1, herb_1
static func materials() -> Dictionary:
	var out := {}
	for t in range(1, 7):
		var i := t - 1
		out["ore_%d" % t] = {"name": "%s Ore" % TIER_NAME[i], "q": 1, "stack": 20, "sell": 4 * t * t, "mat": "ore", "tier": t}
		out["bar_%d" % t] = {"name": "%s Bar" % TIER_NAME[i], "q": 1, "stack": 20, "sell": 10 * t * t, "mat": "bar", "tier": t}
		out["hide_%d" % t] = {"name": "%s Hide" % LEATHER_NAME[i], "q": 1, "stack": 20, "sell": 4 * t * t, "mat": "hide", "tier": t}
		out["leather_%d" % t] = {"name": "%s Leather" % LEATHER_NAME[i], "q": 1, "stack": 20, "sell": 10 * t * t, "mat": "leather", "tier": t}
		out["linen_%d" % t] = {"name": "%s Scraps" % CLOTH_NAME[i], "q": 1, "stack": 20, "sell": 3 * t * t, "mat": "linen", "tier": t}
		out["cloth_%d" % t] = {"name": "Bolt of %s" % CLOTH_NAME[i], "q": 1, "stack": 20, "sell": 9 * t * t, "mat": "cloth", "tier": t}
		out["herb_%d" % t] = {"name": HERB_NAME[i], "q": 1, "stack": 20, "sell": 5 * t * t, "mat": "herb", "tier": t}
	return out

## refining: two raw make one refined, at the right station
const REFINE := {"ore": ["bar", "forge", "smithing"], "hide": ["leather", "tannery", "leatherworking"], "linen": ["cloth", "loom", "tailoring"]}

## what can be crafted (each at every tier): [id, name, skill, station, slot/kind, materials {mat: n}]
const RECIPES := [
	["sword", "Sword", "smithing", "forge", {"wtype": "sword", "slot": "main_hand", "model": "long", "speed": 2.5}, {"bar": 6, "leather": 1}],
	["axe", "Battle Axe", "smithing", "forge", {"wtype": "axe", "slot": "main_hand", "model": "axe", "speed": 2.7}, {"bar": 6, "leather": 1}],
	["mace", "Mace", "smithing", "forge", {"wtype": "mace", "slot": "main_hand", "model": "club", "speed": 2.6}, {"bar": 7}],
	["mail_chest", "Hauberk", "smithing", "forge", {"slot": "chest", "armor_type": "mail", "look": ["Knight_Body_Armor", "Knight"]}, {"bar": 8, "leather": 2}],
	["mail_legs", "Legplates", "smithing", "forge", {"slot": "legs", "armor_type": "mail", "look": ["Knight_Legs", "Knight"]}, {"bar": 7, "leather": 1}],
	["mail_head", "Helm", "smithing", "forge", {"slot": "head", "armor_type": "mail", "look": ["Knight_Head_Armet", "Knight"]}, {"bar": 5}],
	["mail_hands", "Gauntlets", "smithing", "forge", {"slot": "hands", "armor_type": "mail", "look": ["Knight_Arms", "Knight"]}, {"bar": 4, "leather": 1}],
	["mail_feet", "Sabatons", "smithing", "forge", {"slot": "feet", "armor_type": "mail", "look": ["Knight_Feet", "Knight"]}, {"bar": 4, "leather": 1}],
	["leather_chest", "Jerkin", "leatherworking", "tannery", {"slot": "chest", "armor_type": "leather", "look": ["Ranger_Body", "Ranger"]}, {"leather": 8, "cloth": 1}],
	["leather_legs", "Breeches", "leatherworking", "tannery", {"slot": "legs", "armor_type": "leather", "look": ["Ranger_Legs", "Ranger"]}, {"leather": 7}],
	["leather_hands", "Gloves", "leatherworking", "tannery", {"slot": "hands", "armor_type": "leather", "look": ["Ranger_Arms", "Ranger"]}, {"leather": 4}],
	["leather_feet", "Boots", "leatherworking", "tannery", {"slot": "feet", "armor_type": "leather", "look": ["Ranger_Feet", "Ranger"]}, {"leather": 4}],
	["cloak", "Cloak", "leatherworking", "tannery", {"slot": "back"}, {"leather": 3, "cloth": 3}],
	["robe", "Robe", "tailoring", "loom", {"slot": "chest", "armor_type": "cloth", "look": ["Wizard_Body", "Wizard"]}, {"cloth": 8}],
	["cloth_legs", "Trousers", "tailoring", "loom", {"slot": "legs", "armor_type": "cloth", "look": ["Wizard_Legs", "Wizard"]}, {"cloth": 7}],
	["cloth_hands", "Handwraps", "tailoring", "loom", {"slot": "hands", "armor_type": "cloth", "look": ["Wizard_Arms", "Wizard"]}, {"cloth": 4}],
	["cloth_feet", "Slippers", "tailoring", "loom", {"slot": "feet", "armor_type": "cloth", "look": ["Wizard_Feet", "Wizard"]}, {"cloth": 4}],
	["staff", "Staff", "tailoring", "loom", {"wtype": "staff", "slot": "main_hand", "model": "crystalstaff", "speed": 3.0}, {"cloth": 4, "bar": 3, "herb": 2}],
	["wand", "Wand", "tailoring", "loom", {"wtype": "wand", "slot": "main_hand", "model": "wand", "speed": 1.8}, {"cloth": 2, "bar": 2, "herb": 2}],
	["ring", "Band", "smithing", "forge", {"slot": "finger1"}, {"bar": 3, "herb": 1}],
	["healing_potion", "Healing Potion", "alchemy", "alchemy", {"use": "potion"}, {"herb": 3}],
	["mana_potion", "Mana Potion", "alchemy", "alchemy", {"use": "mana_potion"}, {"herb": 3}],
]

const STATIONS := {"forge": "Forge", "tannery": "Tannery", "loom": "Loom", "alchemy": "Alchemy Table"}

static func skill_needed(tier: int) -> int:
	return (tier - 1) * 50

static func recipe(id: String) -> Array:
	for r in RECIPES:
		if r[0] == id: return r
	return []

## materials a recipe asks for at a tier: {"bar_2": 6, ...}
static func needs(r: Array, tier: int) -> Dictionary:
	var out := {}
	for m in r[5]: out["%s_%d" % [m, tier]] = int(r[5][m])
	return out

static func has_all(p: Player, need: Dictionary) -> bool:
	for id in need:
		if p.count_item(id) < int(need[id]): return false
	return true

## roll the quality of what you make: more skill beyond the tier's minimum, better odds
static func roll_quality(skill: int, tier: int, rng: RandomNumberGenerator) -> int:
	var over := clampf(float(skill - skill_needed(tier)) / 100.0, 0.0, 1.0)
	var r := rng.randf()
	var master := 0.02 + 0.06 * over
	var excellent := 0.1 + 0.2 * over
	var good := 0.3 + 0.1 * over
	if r < master: return 3
	if r < master + excellent: return 2
	if r < master + excellent + good: return 1
	return 0

## the item a recipe makes, at a tier and quality (stats scale like world drops, a step richer)
static func make(r: Array, tier: int, quality: int, rng: RandomNumberGenerator) -> Dictionary:
	var spec: Dictionary = r[4]
	var ilvl: int = TIER_ILVL[tier - 1] + quality * 2
	var q: int = [2, 2, 3, 4][quality]
	var budget: float = ilvl * [1.0, 1.1, 1.3, 1.45][quality] * 0.55 + 1.0
	var mat_name: String = TIER_NAME[tier - 1] if r[2] == "smithing" else (LEATHER_NAME[tier - 1] if r[2] == "leatherworking" else CLOTH_NAME[tier - 1])
	var prefix: String = ["", "Fine ", "Excellent ", "Masterwork "][quality]
	if spec.has("use"):
		var heal := 60 + tier * 90 + quality * 30
		var d0 := {"name": "%s%s" % [["Minor ", "", "Greater ", "Superior ", "Major ", "Grand "][tier - 1], r[1]], "q": 1, "use": spec["use"], "stack": 10,
			"sell": 6 * tier * tier, "crafted": true}
		if spec["use"] == "potion": d0["heal"] = heal
		else: d0["mana_now"] = heal
		return {"id": "rolled", "rolled": d0, "n": 2 + quality}
	var d := {"name": "%s%s %s" % [prefix, mat_name, r[1]], "q": q, "slot": spec["slot"], "ilvl": ilvl, "sell": int(ilvl * ilvl * 1.8) + 20, "bind": "boe", "crafted": true}
	# stats that suit what it is: plate and axes want strength, cloth wants intellect
	var aff := {"sta": 0.5, "str": 0.5}
	if r[2] == "tailoring": aff = {"int": 0.45, "spi": 0.3, "sta": 0.35}
	elif r[2] == "leatherworking": aff = {"agi": 0.45, "sta": 0.4, "str": 0.25}
	var stats := {}
	for k in aff: stats[k] = maxi(1, int(round(budget * aff[k])))
	d["stats"] = stats
	if spec.has("armor_type"):
		d["armor_type"] = spec["armor_type"]
		d["armor"] = int(Items.ARMOR_PER[spec["armor_type"]] * Items.SLOT_ARMOR.get(spec["slot"], 0.5) * (1.0 + ilvl * 0.38))
	if spec["slot"] == "back": d["armor"] = int(3.0 + ilvl * 0.6)
	if spec.has("look"): d["look"] = [spec["look"][0], spec["look"][1], clampi(quality + 1, 1, 3)]
	if spec.has("wtype"):
		var dps: float = (1.5 + 0.55 * ilvl) * (1.3 if spec["wtype"] == "staff" else (0.9 if spec["wtype"] == "wand" else 1.0)) * [1.0, 1.05, 1.12, 1.2][quality]
		var spd: float = spec["speed"]
		d["wtype"] = spec["wtype"]; d["model"] = spec["model"]
		d["weapon"] = [int(dps * spd * 0.75), int(ceil(dps * spd * 1.25)), spd]
		if spec["wtype"] in ["staff", "wand"]: d["sp"] = int(ilvl * 0.45 * [1.0, 1.1, 1.25, 1.4][quality])
	return {"id": "rolled", "rolled": d, "n": 1}

## refine two raw into one refined (as many as you can, up to count)
static func refine(p: Player, raw: String, count: int) -> int:
	var parts := raw.split("_")
	var kind: String = parts[0]; var tier := int(parts[1])
	var info: Array = REFINE[kind]
	var skill: String = info[2]
	if p.skill(skill) < skill_needed(tier): p._hud("error", "Requires %s %d" % [SKILLS[skill], skill_needed(tier)]); return 0
	var made := 0
	while made < count and p.count_item(raw) >= 2:
		p.remove_item(raw, 2)
		if not p.add_item({"id": "%s_%d" % [info[0], tier], "n": 1}): p.add_item({"id": raw, "n": 2}); break
		made += 1
		p.skill_up(skill, tier)
	return made

## craft one thing; returns the item made (or {} when you can't)
static func craft(p: Player, id: String, tier: int) -> Dictionary:
	var r := recipe(id)
	if r.is_empty(): return {}
	var skill: String = r[2]
	if p.skill(skill) < skill_needed(tier): p._hud("error", "Requires %s %d" % [SKILLS[skill], skill_needed(tier)]); return {}
	var need := needs(r, tier)
	if not has_all(p, need): p._hud("error", "You don't have the materials"); return {}
	if p.bags.count(null) < 1: p._hud("error", "Inventory is full"); return {}
	for m in need: p.remove_item(m, int(need[m]))
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var q := roll_quality(p.skill(skill), tier, rng)
	var it := make(r, tier, q, rng)
	p.add_item(it)
	p.skill_up(skill, tier, 2)
	return it
