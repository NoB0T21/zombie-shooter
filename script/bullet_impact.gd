extends Node3D
const TTL := 5.0
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D
func _ready():
	gpu_particles_3d.emitting = true
	await get_tree().create_timer(TTL).timeout
	queue_free()
