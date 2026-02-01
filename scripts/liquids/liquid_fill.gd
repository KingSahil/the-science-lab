 	extends RigidBody3D

@onready var source_particles: GPUParticles3D = $"../../flask/GPUParticles3D"
@onready var liquid_mesh = $lab_erlenmeyer_a_0/liquid_mesh
@onready var shader_material := liquid_mesh.material_override as ShaderMaterial

var current_liquid_height = 0.25
var initial_color : Color = Color(0.0, 0.5, 1.0)  # starting blue
var target_color  : Color = Color(0.5, 0.0, 0.5)  # purple
var color_blend_factor = 0.0

const FILL_SPEED = 0.2

func _ready():
	shader_material.set_shader_parameter("liquid_height", current_liquid_height)
	shader_material.set_shader_parameter("liquid_surface_color", initial_color)

func _physics_process(delta):
	if source_particles.emitting:
		# increase liquid level
		current_liquid_height += FILL_SPEED * delta
		current_liquid_height = clamp(current_liquid_height, 0.0, 1.0)
		shader_material.set_shader_parameter("liquid_height", current_liquid_height)
		
		# blend color toward purple
		color_blend_factor += 0.5 * delta
		color_blend_factor = clamp(color_blend_factor, 0.0, 1.0)
		var blended_color = initial_color.lerp(target_color, color_blend_factor)
		shader_material.set_shader_parameter("liquid_surface_color", blended_color)
