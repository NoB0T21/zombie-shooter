extends RigidBody3D

const TTL := 4.0
func _ready():
	linear_velocity = global_transform.basis.z * -3.0 + global_transform.basis.y * 1.5
	angular_velocity = Vector3(
		randf_range(-10, 10),
		randf_range(-10, 10),
		randf_range(-10, 10)
	)
	await get_tree().create_timer(TTL).timeout
	queue_free()
