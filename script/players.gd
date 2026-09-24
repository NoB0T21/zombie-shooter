extends CharacterBody3D

@export var MOUSE_SENSITIVE :float = 0.5
@export var TILT_LOWER_LIMITE := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMITE := deg_to_rad(90.0)
@export var CAMERA: Camera3D
@export var TOGGLE_SPEED : bool

@onready var anim_tree: AnimationTree = $CollisionShape3D/Sketchfab_Scene/AnimationTree
@onready var muzzle: Node3D = $"CollisionShape3D/Sketchfab_Scene/Sketchfab_model/77abeb46cd9149069cb93d7b9ff932ee_fbx/Object_2/RootNode/Object_4/bullet"
@onready var label: Label = $"../Control/Label"
@onready var shellsPo: Node3D = $"CollisionShape3D/Sketchfab_Scene/Sketchfab_model/77abeb46cd9149069cb93d7b9ff932ee_fbx/Object_2/RootNode/Object_4/shells"
const SHELLS = preload("uid://cffgbhxrumisr")

const MUZZLE_FLASH = preload("uid://dwaoj6p2ot6tb")
const bullet_scene :PackedScene= preload("uid://dyi85y0qttjmf")
var max_ammo := 40
var current_ammo := 12

const SPEED_DEFAULT = 3.0
const SPEED_SPRINT = 5.0
const JUMP_VELOCITY = 4.5

var _speed :float
var _is_sprinting :bool
var is_paused:bool = false
var _mouse_input:bool = false
var _mouse_rotation:Vector3
var _rotation_input: float
var _tilt_inpute:float 
var _player_rotation:Vector3
var _camera_rotation:Vector3

var shoot_time := 0.5
var shoot_count := 0.0
@export var spread := 0.01

var recoil := Vector2.ZERO
const IMPACT_SCENE: PackedScene = preload("uid://d3npym0k48igw")
	
func update_ui():
	label.text = "Bullets: %d/%d" % [current_ammo,max_ammo]

var is_reloading := false
func reload():
	if max_ammo <= 0 or current_ammo >= 12:
		return
	if is_reloading:
		return
	is_reloading = true
	if _is_sprinting == true:
		sprinting(false)
	anim_tree.set("parameters/movement/transition_request", "reload")
	await get_tree().create_timer(2.8).timeout
	if not is_reloading:
		return
	var needed := 12 - current_ammo
	var loaded :int= min(needed, max_ammo)

	current_ammo += loaded
	max_ammo -= loaded
	update_ui()
	is_reloading = false
	
func shoot():
	var origin := CAMERA.global_position

	var dir := -CAMERA.global_basis.z
	dir -= CAMERA.global_transform.basis.x * randf_range(-spread, spread)
	dir -= CAMERA.global_transform.basis.y * randf_range(-spread, spread)
	dir = dir.normalized()

	recoil.x -= randf_range(1.0, 3.0)
	recoil.y -= randf_range(-0.4, 0.4)

	var target := origin + dir * 1000.0

	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_bodies = true
	var result := get_world_3d().direct_space_state.intersect_ray(query)

	var hit_point := target

	var bullet = bullet_scene.instantiate()
	var muzzleFlash = MUZZLE_FLASH.instantiate()
	var shells = SHELLS.instantiate()
	bullet.global_transform = muzzle.global_transform
	bullet.direction = (target).normalized()
	muzzleFlash.global_transform = muzzle.global_transform
	muzzleFlash.Mposition = muzzle.global_position
	shells.position = shellsPo.global_position
	get_tree().current_scene.add_child(bullet)
	get_tree().current_scene.add_child(muzzleFlash)
	shells.add_collision_exception_with(self)
	get_tree().current_scene.add_child(shells)

	anim_tree.set("parameters/movement/transition_request", "fire")
	if result:
		hit_point = result.position
		var impact = IMPACT_SCENE.instantiate()
		get_tree().root.add_child(impact)
		impact.global_position = result.position
		var n = result.normal
		impact.global_transform.basis = Basis().looking_at(n, Vector3.UP)

	
func _process(delta: float) -> void:
	rotation_degrees.x -= recoil.x
	CAMERA.rotation_degrees.y += recoil.y
	recoil = recoil.lerp(Vector2.ZERO, delta * 12)
	shoot_count+=delta
	
	#and shoot_count>shoot_time and current_ammo > 0
	if Input.is_action_pressed("shoot") and shoot_count >= shoot_time and current_ammo > 0:
		shoot_count = 0.0
		current_ammo -= 1
		update_ui()
		shoot()
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_speed = SPEED_DEFAULT
	update_ui()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not is_paused:
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().quit()
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	if event.is_action_pressed("hold_sprint") and is_on_floor() and TOGGLE_SPEED == true and is_reloading == false:
		toggle_sprint()
	if event.is_action_pressed("hold_sprint") and is_on_floor() and _is_sprinting == false and TOGGLE_SPEED == false and is_reloading == false:
		sprinting(true)
	if event.is_action_released("hold_sprint") and is_on_floor() and TOGGLE_SPEED == false and is_reloading == false:
		sprinting(false)

func _unhandled_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVE
		_tilt_inpute = -event.relative.y * MOUSE_SENSITIVE
	#else:
		#var look_input := Input.get_vector("view_right","view_left","view_down","view_up")
		#_rotation_input = look_input.x
		#_tilt_inpute = look_input.y

func _update_camera(delta: float) -> void:
	_mouse_rotation.x += _tilt_inpute * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMITE, TILT_UPPER_LIMITE)
	_mouse_rotation.y+= _rotation_input * delta
	
	_player_rotation = Vector3(0.0, _mouse_rotation.y, 0.0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0.0, 0.0)
	
	CAMERA.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA.rotation.z = 0.0
	
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input=0.0
	_tilt_inpute=0.0
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	_update_camera(delta)
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		is_reloading = false
		velocity.y = JUMP_VELOCITY
		anim_tree.set("parameters/movement/transition_request", "jump")

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
	else:
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)

	move_and_slide()
	
	var current_speed := velocity.length()
	const RUN_SPEED := 4.2
	if is_on_floor():
		if(current_speed > RUN_SPEED) and not Input.is_action_just_pressed("reload"):
			anim_tree.set("parameters/movement/transition_request", "run")
		elif Input.is_action_just_pressed("reload") or is_reloading:
			reload()
		elif(current_speed > 0.0):
			is_reloading = false
			anim_tree.set("parameters/movement/transition_request", "walk")
			var walk_speed = lerpf(0.5,1.75, current_speed/RUN_SPEED)
			anim_tree.set("parameters/TimeScale/scale", walk_speed)
		else:
			anim_tree.set("parameters/movement/transition_request", "idle")

func toggle_sprint() -> void:
	if _is_sprinting == true:
		sprinting(false)
	elif _is_sprinting == false:
		sprinting(true)

func sprinting(state: bool) -> void:
	match state:
		true:
			set_movement_speed("sprint")
		false:
			set_movement_speed("default")
	_is_sprinting = !_is_sprinting

func set_movement_speed(state: String) -> void:
	match state:
		"default":
			_speed = SPEED_DEFAULT
		"sprint":
			_speed = SPEED_SPRINT
