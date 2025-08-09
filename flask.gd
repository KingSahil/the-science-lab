extends RigidBody3D

@onready var particles = $GPUParticles3D
@onready var liquid_mesh = $lab_erlenmeyer_a_0/liquid_mesh
@onready var shader_material = liquid_mesh.material_override

@export var target_flask_path : NodePath
var target_flask

const TILT_THRESHOLD = 90
const DRAIN_SPEED = 0.2
const FILL_SPEED = 0.2

var current_liquid_height = 0.25

func _ready():
	shader_material.set_shader_parameter("liquid_height", current_liquid_height)
	if target_flask_path:
		target_flask = get_node(target_flask_path)

func _physics_process(delta):
	var rot = rotation_degrees
	
	if abs(rot.x) > TILT_THRESHOLD or abs(rot.z) > TILT_THRESHOLD:
		if current_liquid_height > -0.6:
			particles.emitting = true
			current_liquid_height -= DRAIN_SPEED * delta
			shader_material.set_shader_parameter("liquid_height", current_liquid_height)

			# fill other flask if exists
			if target_flask:
				target_flask.fill_liquid(FILL_SPEED * delta)
		else:
			particles.emitting = false
	else:
		particles.emitting = false
