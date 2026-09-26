class_name Save
## Characters are kept in the user's save folder (on Windows: %APPDATA%\Godot\app_userdata\Ashvale Online)
## as one small JSON file. The world itself is rebuilt each time you play.

const PATH := "user://characters.json"

static func load_all() -> Array:
	if not FileAccess.file_exists(PATH): return []
	var t := FileAccess.get_file_as_string(PATH)
	var d = JSON.parse_string(t)
	if d is Dictionary and d.has("characters"):
		var out: Array = d["characters"]
		for c in out: _fix(c)
		return out
	return []

static func store_all(chars: Array) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null: push_warning("could not save characters"); return
	f.store_string(JSON.stringify({"version": 1, "characters": chars}, "  "))
	f.close()

static func upsert(ch: Dictionary) -> void:
	var all := load_all()
	for i in all.size():
		if all[i].get("name", "") == ch.get("name", ""):
			all[i] = ch; store_all(all); return
	all.append(ch); store_all(all)

static func remove(name: String) -> void:
	var all := load_all()
	all = all.filter(func(c): return c.get("name", "") != name)
	store_all(all)

## JSON turns colours into strings; bring them back
static func _fix(c: Dictionary) -> void:
	var look: Dictionary = c.get("look", {})
	if look.get("hair_color") is String: look["hair_color"] = Color(look["hair_color"])
	if look.get("hair_color") is Array:
		var a: Array = look["hair_color"]; look["hair_color"] = Color(a[0], a[1], a[2])

static func encode_look(look: Dictionary) -> Dictionary:
	var l := look.duplicate(true)
	if l.get("hair_color") is Color:
		var c: Color = l["hair_color"]; l["hair_color"] = [c.r, c.g, c.b]
	return l

## the names people pick, when they can't think of one
const NAMES := ["Aldren", "Brisa", "Cael", "Delphine", "Edric", "Fenna", "Garrick", "Hollis", "Isolde", "Jory", "Kestra", "Lowen",
	"Maelis", "Neve", "Orrin", "Perrin", "Quill", "Rosalind", "Soren", "Tamsin", "Ulric", "Vesper", "Wynn", "Yara", "Bram", "Ottilie", "Rook", "Ember"]
