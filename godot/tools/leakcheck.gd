extends Node
# attach via --leakcheck: prints object/node/memory counts every 5 s
var t := 0.0
func _process(d: float) -> void:
	t += d
	if fmod(t, 5.0) < d:
		print("t=%d objects=%d nodes=%d resources=%d mem=%.1fMB orphan=%d" % [t, Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)])
