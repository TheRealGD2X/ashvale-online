class_name Avatar extends Humanoid
## A player-style person assembled from the paid Quaternius packs: a Universal Base Character head,
## a hairstyle, eyebrows and facial hair, and outfit pieces from Modular Character Outfits - Fantasy,
## all bound to one skeleton so the whole animation library drives them together.
##
##   var a := Avatar.new()
##   a.look = {"sex": "m", "skin": 2, "hair": "Hair_SimpleParted", "hair_color": Color(...),
##             "brows": "Eyebrows_Regular", "beard": "Hair_Beard",
##             "gear": {"chest": "Knight_Body_Armor", "hands": "Knight_Arms", "legs": "Knight_Legs",
##                      "feet": "Knight_Feet", "head": "", "shoulders": "Knight_Acc_Pauldron_Round"},
##             "tint": {"Knight": 1}}      # texture variant per outfit family (1, 2 or 3)
##   add_child(a)
##
## Missing art (the packs are not unpacked on this machine) falls back to the free hero model.

const DIR := "res://assets/licensed/chars/"

## skin tones, light to dark (the average colour the skin ends up with)
const SKIN := [Color(0.97, 0.82, 0.72), Color(0.91, 0.72, 0.59), Color(0.8, 0.59, 0.45),
	Color(0.68, 0.49, 0.35), Color(0.52, 0.35, 0.24), Color(0.36, 0.24, 0.16)]
## the average colour of the kit's skin texture, so a tone can be applied as tone / average
const SKIN_TEX_AVG := Color(0.65, 0.47, 0.34)
const HAIR_COLORS := [Color(0.12, 0.09, 0.07), Color(0.3, 0.19, 0.1), Color(0.52, 0.33, 0.17),
	Color(0.78, 0.6, 0.35), Color(0.62, 0.22, 0.1), Color(0.75, 0.74, 0.72), Color(0.95, 0.93, 0.88)]
const HAIR_M := ["Hair_SimpleParted", "Hair_SlickBack", "Hair_Buzzed", "Hair_Ponytail", "Hair_Dreads", "Hair_Mohawk", "Hair_Balding", "Hair_Long", ""]
const HAIR_F := ["Hair_Long", "Hair_Bob", "Hair_Buns", "Hair_Ponytail_2", "Hair_LongDreads", "Hair_BuzzedFemale", "Hair_SimpleParted", ""]
const BEARDS := ["", "Hair_Beard", "Hair_Moustache", "Hair_MuttonChops"]
const BROWS_M := ["Eyebrows_Regular", "Eyebrows_Thick"]
const BROWS_F := ["Eyebrows_Female"]

## the look each class starts in (its level 1 gear is shown in these families)
const CLASS_GEAR := {
	"warrior": {"chest": "Knight_Body_Armor", "hands": "Knight_Arms", "legs": "Knight_Legs", "feet": "Knight_Feet", "shoulders": "Knight_Acc_Pauldron_Round"},
	"wizard": {"chest": "Wizard_Body", "hands": "Wizard_Arms", "legs": "Wizard_Legs", "feet": "Wizard_Feet"},
	"cleric": {"chest": "Noble_Body", "hands": "Noble_Arms", "legs": "Noble_Legs", "feet": "Noble_Feet", "neck": "Noble_Acc_Gorget"},
	"peasant": {"chest": "Peasant_Body", "hands": "Peasant_Arms", "legs": "Peasant_Legs", "feet": "Peasant_Feet"},
	"ranger": {"chest": "Ranger_Body", "hands": "Ranger_Arms", "legs": "Ranger_Legs", "feet": "Ranger_Feet", "shoulders": "Ranger_Acc_Pauldron"},
}

var look := {}

static func available() -> bool:
	return ResourceLoader.exists(DIR + "Regular_Male_OnlyHead.gltf")

## a random but sensible look (for simulated players and townsfolk)
static func random_look(rng: RandomNumberGenerator, cls := "peasant", sex := "") -> Dictionary:
	if sex == "": sex = "m" if rng.randf() < 0.5 else "f"
	var hairs: Array = HAIR_M if sex == "m" else HAIR_F
	var tint := {}
	for fam in ["Knight", "Wizard", "Noble", "Peasant", "Ranger"]: tint[fam] = rng.randi_range(1, 3)
	return {"sex": sex, "skin": rng.randi_range(0, SKIN.size() - 1), "hair": hairs[rng.randi() % hairs.size()],
		"hair_color": HAIR_COLORS[rng.randi() % HAIR_COLORS.size()],
		"brows": (BROWS_M if sex == "m" else BROWS_F)[rng.randi() % (2 if sex == "m" else 1)],
		"beard": BEARDS[rng.randi() % BEARDS.size()] if sex == "m" and rng.randf() < 0.6 else "",
		"gear": CLASS_GEAR.get(cls, CLASS_GEAR["peasant"]).duplicate(), "tint": tint}

func _make_body() -> Node3D:
	if not available():
		model = "hero_m" if look.get("sex", "m") == "m" else "hero_f"
		return super._make_body()
	var sex: String = look.get("sex", "m")
	hair_color = look.get("hair_color", hair_color)
	var who := "Male" if sex == "m" else "Female"
	var gear: Dictionary = look.get("gear", {})
	var root: Node3D = load(DIR + "Regular_%s_%s.gltf" % [who, "OnlyHead" if not gear.is_empty() else "FullBody"]).instantiate()
	var sk: Skeleton3D = root.get_node("Armature/Skeleton3D")
	var parts: Array = []
	for slot in gear:
		var p: String = gear[slot]
		if p == "": continue
		parts.append(_part_file(who, p))
	for k in ["hair", "brows", "beard"]:
		var h: String = look.get(k, "")
		if h != "" and not (k == "hair" and gear.has("head") and gear["head"] != "" and not String(gear["head"]).contains("Crown")):
			parts.append(h)
	for p in parts:
		var path: String = DIR + p + ".gltf"
		if not ResourceLoader.exists(path): push_warning("missing avatar part " + p); continue
		var scene: Node = load(path).instantiate()
		for mi in scene.find_children("*", "MeshInstance3D", true, false):
			mi.owner = null
			mi.get_parent().remove_child(mi)
			sk.add_child(mi)
			mi.skeleton = NodePath("..")
		scene.free()
	_paint(root)
	return root

## outfit names are written without the sex ("Knight_Body_Armor"); the kit's male and female files differ
func _part_file(who: String, p: String) -> String:
	var f := "%s_%s" % [who, p]
	if ResourceLoader.exists(DIR + f + ".gltf"): return f
	# the few pieces named differently for each sex
	var alt := {"Knight_Feet": "Knight_Feet_Armor", "Knight_Legs": "Knight_Legs_Armor", "Knight_Acc_Pauldron_Round": "Knight_Acc_Pauldrons_Round",
		"Knight_Acc_Pauldron_Spike": "Knight_Acc_Pauldrons_Spike", "Ranger_Feet": "Ranger_Feet_Boots", "Ranger_Acc_Pauldron": "Ranger_Acc_Pauldrons"}
	for a in [alt.get(p, ""), alt.find_key(p) if alt.values().has(p) else ""]:
		if a != "" and ResourceLoader.exists(DIR + "%s_%s.gltf" % [who, a]): return "%s_%s" % [who, a]
	return f

## skin tone, hair colour and outfit colour variants
func _paint(root: Node) -> void:
	var skin_col: Color = SKIN[clampi(int(look.get("skin", 1)), 0, SKIN.size() - 1)]
	var hair_col: Color = look.get("hair_color", Color(0.3, 0.19, 0.1))
	var tint: Dictionary = look.get("tint", {})
	var cache := {}
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(s)
			if not (mat is BaseMaterial3D): continue
			var n: String = mat.resource_name
			var key := n
			var nm: BaseMaterial3D
			if n.begins_with("MI_Regular"):
				key = n + str(skin_col)
				if not cache.has(key):
					nm = mat.duplicate()
					nm.albedo_color = Color(skin_col.r / SKIN_TEX_AVG.r, skin_col.g / SKIN_TEX_AVG.g, skin_col.b / SKIN_TEX_AVG.b)
					var light := DIR + ("T_Regular_%s_Light_BaseColor.png" % ("Male" if n.contains("Male") and not n.contains("Female") else "Female"))
					if ResourceLoader.exists(light): nm.albedo_texture = load(light)
					cache[key] = nm
			elif n.begins_with("MI_Hair"):
				key = n + str(hair_col)
				if not cache.has(key):
					nm = mat.duplicate(); nm.albedo_color = hair_col.lightened(0.15); cache[key] = nm
			else:
				var fam := n.trim_prefix("MI_")
				var v := int(tint.get(fam, 1))
				if v <= 1: continue
				key = n + str(v)
				if not cache.has(key):
					var tex := DIR + "T_%s_%d_BaseColor.png" % [fam, v]
					if not ResourceLoader.exists(tex): continue
					nm = mat.duplicate(); nm.albedo_texture = load(tex); cache[key] = nm
			m.set_surface_override_material(s, cache[key])
