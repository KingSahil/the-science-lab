extends Node3D

@onready var flask_a = $flask
@onready var flask_b = $flask2

var shader_material_a : ShaderMaterial
var shader_material_b : ShaderMaterial
var particles_a : GPUParticles3D
var particles_b : GPUParticles3D

const TILT_THRESHOLD = 90
const DRAIN_SPEED = 0.2

var liquid_height_a = 0.25
var liquid_height_b = 0.007

func _ready():
	# lookup flask A
	var liquid_mesh_a = flask_a.get_node("lab_erlenmeyer_a_0/liquid_mesh")
	if liquid_mesh_a and liquid_mesh_a.material_override:
		shader_material_a = liquid_mesh_a.material_override as ShaderMaterial
	else:
		push_error("flask_a liquid_mesh or its material_override is missing!")

	# lookup flask B
	var liquid_mesh_b = flask_b.get_node("lab_erlenmeyer_a_0/liquid_mesh")
	if liquid_mesh_b and liquid_mesh_b.material_override:
		shader_material_b = liquid_mesh_b.material_override as ShaderMaterial
	else:
		push_error("flask_b liquid_mesh or its material_override is missing!")

	# particle systems
	particles_a = flask_a.get_node_or_null("GPUParticles3D")
	particles_b = flask_b.get_node_or_null("GPUParticles3D")

	# safe initialize
	if shader_material_a:
		shader_material_a.set_shader_parameter("liquid_height", liquid_height_a)
	if shader_material_b:
		shader_material_b.set_shader_parameter("liquid_height", liquid_height_b)

func _physics_process(delta):
	if shader_material_a and particles_a:
		handle_flask(
			flask_a,
			shader_material_a,
			particles_a,
			flask_b,
			shader_material_b,
			delta
		)
	if shader_material_b and particles_b:
		handle_flask(
			flask_b,
			shader_material_b,
			particles_b,
			flask_a,
			shader_material_a,
			delta
		)

func handle_flask(source_flask, source_material, source_particles, target_flask, target_material, delta):
	var rot = source_flask.rotation_degrees
	var is_tilted = abs(rot.x) > TILT_THRESHOLD or abs(rot.z) > TILT_THRESHOLD
	
	if is_tilted:
		var current_height = source_material.get_shader_parameter("liquid_height")
		if current_height > -0.6:
			source_particles.emitting = true
			var new_height = current_height - DRAIN_SPEED * delta
			source_material.set_shader_parameter("liquid_height", new_height)
			
			# Add to target
			if target_material:
				var target_height = target_material.get_shader_parameter("liquid_height") + DRAIN_SPEED * delta
				target_material.set_shader_parameter("liquid_height", target_height)
		else:
			source_particles.emitting = false
	else:
		source_particles.emitting = false
