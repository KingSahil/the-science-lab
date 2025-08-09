extends CharacterBody3D

# Movement toggles
@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = false
@export var can_freefly : bool = false

# Speeds
@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

# Input actions
@export_group("Input Actions")
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_forward : String = "ui_up"
@export var input_back : String = "ui_down"
@export var input_jump : String = "ui_accept"
@export var input_sprint : String = "sprint"
@export var input_freefly : String = "freefly"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

var picked_object
var pull_power = 10
var rotation_power = 0.15
var locked = false
var throw_power = 1.5

# references
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var interaction: RayCast3D = $Head/Camera3D/interaction
@onready var hand: Marker3D = $Head/Camera3D/hand
@onready var joint: Generic6DOFJoint3D = $Head/Camera3D/Generic6DOFJoint3D
@onready var staticbody: StaticBody3D = $Head/Camera3D/StaticBody3D
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	check_input_mappings()
	look_rotation = Vector2(0, rotation.y)
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if mouse_captured and event is InputEventMouseMotion and not locked:
		rotate_look(event.relative)

	# Rotate picked object
	if Input.is_action_pressed("rclick"):
		locked = true
		if event is InputEventMouseMotion:
			rotate_picked_object(event.relative)
	if Input.is_action_just_released("rclick"):
		locked = false

	# Pickup / drop objects
	if Input.is_action_just_pressed("pickup"):
		if picked_object:
			remove_object()
		else:
			pick_object()

	# Throw
	if Input.is_action_just_pressed("throw"):
		if picked_object:
			var knockback = picked_object.global_position - global_position
			picked_object.apply_central_impulse(knockback * throw_power)
			remove_object()

	# Freefly toggle
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

	# Mouse capture / release
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()

func _physics_process(delta: float) -> void:
	if picked_object:
		var a = picked_object.global_transform.origin
		var b = hand.global_transform.origin
		picked_object.linear_velocity = (b - a) * pull_power

	# Freefly mode
	if can_freefly and freeflying:
		var input_dir = Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion = (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return

	# Gravity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Jump
	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	# Sprint
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Movement
	if can_move:
		var input_dir = Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir != Vector3.ZERO:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

# mouse look
func rotate_look(relative: Vector2):
	look_rotation.x -= relative.y * look_speed
	look_rotation.y -= relative.x * look_speed

	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))

	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

# pickup / drop
func pick_object():
	var collider = interaction.get_collider()
	if collider and collider is RigidBody3D:
		picked_object = collider
		joint.set_node_b(picked_object.get_path())

func remove_object():
	if picked_object:
		picked_object = null
		joint.set_node_b(joint.get_path())

# rotate picked object
func rotate_picked_object(relative: Vector2):
	staticbody.rotate_x(deg_to_rad(relative.y * rotation_power))
	staticbody.rotate_y(deg_to_rad(relative.x * rotation_power))

# freefly toggles
func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

# mouse controls
func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

# input sanity checks
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("No input_left mapping, disabling movement")
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("No input_right mapping, disabling movement")
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("No input_forward mapping, disabling movement")
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("No input_back mapping, disabling movement")
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("No input_jump mapping, disabling jumping")
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("No input_sprint mapping, disabling sprint")
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("No input_freefly mapping, disabling freefly")
		can_freefly = false
