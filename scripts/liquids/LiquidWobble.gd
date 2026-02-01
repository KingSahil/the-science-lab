@tool
extends MeshInstance3D

# ... (Keep your existing export variables: max_wobble, wobble_speed, etc.) ...
@export var max_wobble := 0.1
@export var movement_to_max_wobble := 0.3
@export var rotation_to_max_wobble := PI / 2.0
@export var wobble_damping := 1.0
@export var wobble_speed := 2.0

var _accumulated_time := 0.0
var _wobble_intensity := 0.0
@onready var _prev_pos := global_transform.origin
@onready var _prev_rot := rotation

func _process(delta: float) -> void:
	# ... (Keep your existing wobble logic here) ...
	# ... (The calculation of _wobble_intensity, etc.) ...
	
	var current_movement_len := (global_transform.origin - _prev_pos).length()
	var current_rotation_len := (rotation - _prev_rot).length()
	_prev_pos = global_transform.origin
	_prev_rot = rotation
	
	_wobble_intensity -= delta / wobble_damping * _wobble_intensity
	_wobble_intensity += current_movement_len / movement_to_max_wobble
	_wobble_intensity += current_rotation_len / rotation_to_max_wobble
	_wobble_intensity = clamp(_wobble_intensity, 0.0, 1.0)
	
	_accumulated_time += delta * _wobble_intensity * wobble_speed
	
	if material_override:
		material_override.set_shader_parameter(
			"wobble",
			(Vector2.RIGHT.rotated(_accumulated_time * TAU) * max_wobble * _wobble_intensity)
		)

# --- ADD THIS NEW FUNCTION TO THE BOTTOM ---
# Paste this at the very bottom of LiquidWobble.gd

func update_liquid_height(new_height: float):
	# This safety check prevents crashes if the material is missing
	if material_override:
		material_override.set_shader_parameter("liquid_height", new_height)	
