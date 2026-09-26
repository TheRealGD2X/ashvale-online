class_name Soundscape extends Node
## What you hear when nothing is fighting: music for where you are and the time of day (the town
## tune by day in Ashvale, the wilds tune out in the fields, the night tune after dark), crossfading
## as you go, and the outdoor ambience under it (birds by day, crickets at night).
## The Esc menu turns the music on and off.

static var music_on := true
static var music_db := -13.0
var players := {}                 # track -> AudioStreamPlayer
var amb := {}
var current := ""

func _ready() -> void:
	add_to_group("soundscape")
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in ["town", "wilds", "night"]: players[n] = _player("res://assets/music/%s.wav" % n)
	for n in ["amb_day", "amb_night"]: amb[n] = _player("res://assets/music/%s.wav" % n)

func _player(path: String) -> AudioStreamPlayer:
	if not ResourceLoader.exists(path): return null
	var st: AudioStream = load(path)
	if st is AudioStreamWAV:
		var w := st as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_begin = 0; w.loop_end = int(w.get_length() * w.mix_rate) - 1
	var a := AudioStreamPlayer.new(); a.stream = st; a.volume_db = -80.0
	add_child(a)
	return a

func _process(delta: float) -> void:
	var hero := get_tree().get_first_node_in_group("hero") as Node3D
	var pos := hero.global_position if hero else Vector3.ZERO
	var mus: Dictionary = WorldData.Z.get("music", {"town": "town", "wild": "wilds"})
	var want: String = "night" if DayNight.night > 0.6 else (mus["town"] if WorldData.town_w(Vector2(pos.x, pos.z)) > 0.4 else mus["wild"])

	if not music_on: want = ""
	current = want
	for n in players:
		var p: AudioStreamPlayer = players[n]
		if p == null: continue
		var target := music_db if n == want else -60.0
		p.volume_db = move_toward(p.volume_db, target, delta * (8.0 if target > p.volume_db else 12.0))
		if p.volume_db > -59.0 and not p.playing: p.play()
		elif p.volume_db <= -59.5 and p.playing: p.stop()
	var rain_quiet := 1.0 - DayNight.rain * 0.7
	for n in amb:
		var a: AudioStreamPlayer = amb[n]
		if a == null: continue
		if WorldData.CAVE: a.volume_db = -80.0; continue

		var w := (1.0 - DayNight.night) if n == "amb_day" else DayNight.night
		a.volume_db = linear_to_db(maxf(w * rain_quiet, 0.0005)) - 12.0
		if not a.playing: a.play()
