extends Node3D
const TTL := 0.1

var Mposition := Vector3.ZERO
func _ready():
	position = Mposition
	await get_tree().create_timer(TTL).timeout
	queue_free()
