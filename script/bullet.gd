extends Area3D

const SPEED := 50.0
const TTL := 3.0
var direction := Vector3.ZERO
func _ready():
	await get_tree().create_timer(TTL).timeout
	queue_free()
	
func _process(delta: float):
	global_position += direction * SPEED * delta
